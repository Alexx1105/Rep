//
//  AudioTranscriptionManager.swift
//  Rep
//
//  Created by alex haidar on 6/7/26.
//
/* All requests to the supabase edge functions
   for the voice transcription with gpt-4o-mini-transcribe
   or future models will be handled here  */


import Foundation
import Supabase
import SwiftData
import KimchiKit
@preconcurrency import AVFoundation



@MainActor
public final class AudioTranscriptionManager: ObservableObject {
    private static let pendingReservationDefaultsKey = "rep.pendingAudioReservationKey"

    private init() {
        if let storedKey = UserDefaults.standard.string(forKey: Self.pendingReservationDefaultsKey) {
            activeAudioReservationKey = UUID(uuidString: storedKey)
        }
    }

    private struct AudioFinalizeRequest: Encodable {
        let idempotency_key: String
        let duration_seconds: Double
    }

    private struct AudioReleaseRequest: Encodable {
        let idempotency_key: String
        let reason: String
    }
   
    public static let shared = AudioTranscriptionManager()
    let paymentStoreCredits = CreditBucketsManager.shared
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var activeAudioReservationKey: UUID?
    private var audioSessionStartedAt: Date?
    typealias MessageTranscription = URLSessionWebSocketTask.Message
    
    @Published public var liveTranscription: String = ""
    @Published var finishedTranscript: String = ""
    @Published var isTranscriptFinished: Bool = false
    @Published var isTranscribing: Bool = false
    @Published var isSummarizing: Bool = false
    @Published var audioLevels: CGFloat = 0
    @Published var summarizedNotes: String = ""
    @Published var didStopAudioStream: Bool = false
    
    
    func configAudioSession() throws {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetoothHFP, .defaultToSpeaker])
            try audioSession.setPreferredInputNumberOfChannels(1)
            try audioSession.setActive(true)
            
            print("audio session successfully set up")
        } catch {
            print("failed to config audio session", ErrorDesc.configError, error)
        }
    }
    
    
    private let audioEngine = AVAudioEngine()
    
    public func startMicCapture() throws {
        let micInput = audioEngine.inputNode
        let micInputFormat = micInput.inputFormat(forBus: 0)
        
        audioEngine.inputNode.removeTap(onBus: 0)
        
        micInput.installTap(onBus: 0, bufferSize: 512, format: micInputFormat) { [weak self] buffer, _ in    //TODO: update to installAudioTap(onBus:bufferSize:format:tapProvider:)
            guard let self else { return }
            
            do {
                guard let resampleAudioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 24_000, channels: 1, interleaved: false) else { throw ErrorDesc.configError }
                guard let converter = AVAudioConverter(from: micInputFormat, to: resampleAudioFormat) else { throw ErrorDesc.configError }
                
                let resampledBuffer = try AudioTranscriptionHelper.resampleBuffer(buffer, converter: converter, outputFormat: resampleAudioFormat)
                let getPcmData: AudioBufferData = try AudioTranscriptionHelper.convertBufferToPCM16Data(resampledBuffer)
                
                let pcmData: Data = getPcmData.data
                let pcmRms: Float = getPcmData.rms
                
                let getAudioLevels = AudioTranscriptionHelper.scaleAudioWaves(rms: pcmRms)
                
                Task { @MainActor in
                    self.audioLevels = CGFloat(getAudioLevels)
                }
                
                Task {
                    try? await self.sendAudioChunk(pcmData)
                }
            } catch {
                print("failed to convert PCM buffer:", error)
            }
        }
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    
    public func openAudioSession(idempotentKey: UUID) async throws -> AudioSession.SessionData {
        let url: URL = URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co/functions/v1/ai_summerizer-chat")!  
        var urlRequest: URLRequest = URLRequest(url: url)
        
        let session = try await supabaseDBClient.auth.session
        let supabaseAccessToken: String = session.accessToken
        guard !supabaseAccessToken.isEmpty else { throw ErrorDesc.authTokenError }
        
        urlRequest.setValue("Bearer \(supabaseAccessToken)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("audio", forHTTPHeaderField: "x-rep-action")
        urlRequest.setValue(idempotentKey.uuidString, forHTTPHeaderField: "x-idempotency-key")
        urlRequest.httpMethod = "POST"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            print("SESSION DATA ✅: \(data)")
            
            guard let urlResponse = response as? HTTPURLResponse else { throw ErrorDesc.serverError }
            let _ = String(data: data, encoding: .utf8)
            
            if urlResponse.statusCode == 402 { throw PaymentStoreError.insufficientTokens }
            guard (200...299).contains(urlResponse.statusCode) else { throw ErrorDesc.urlResponseError }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let audioResponse = try decoder.decode(AudioStartResponse.self, from: data)
            paymentStoreCredits.applyUpdatedBucket(audioResponse.bucket)
            activeAudioReservationKey = audioResponse.idempotency_key
            UserDefaults.standard.set(audioResponse.idempotency_key.uuidString, forKey: Self.pendingReservationDefaultsKey)
            
            return audioResponse.session
            
        } catch PaymentStoreError.insufficientTokens {
            throw PaymentStoreError.insufficientTokens
            
        } catch {
            print("error opening audio session", ErrorDesc.sessionError, error)
        }
        throw ErrorDesc.sessionError
    }
    
    
    func createWebSocket(urlRequest: URLRequest) -> URLSessionWebSocketTask {
            let socketId: String = UUID().uuidString
        print("new web socket created: \(socketId)")
        return URLSession.shared.webSocketTask(with: urlRequest)
    }
    
    
    func retryWebSocket(urlRequest: URLRequest) async throws {
        webSocketTask?.cancel(with: .goingAway, reason: .none)
        
        let newWebSocket = createWebSocket(urlRequest: urlRequest)
        self.webSocketTask = newWebSocket
        newWebSocket.resume()
        
        print("reconnected to web socket...")
        try await Task.sleep(for: .milliseconds(300))
    }
    
    
    public func startAudioStream(session: AudioSession.SessionData) async throws {
        do {
            let ephemeralSecret: String = session.value
            guard !ephemeralSecret.isEmpty else { throw ErrorDesc.nilValue }
            
            let openaiTranscriptionUrl: URL = URL(string: "wss://api.openai.com/v1/realtime?intent=transcription")!
            var urlRequest: URLRequest = URLRequest(url: openaiTranscriptionUrl)
            
            urlRequest.setValue("Bearer \(ephemeralSecret)", forHTTPHeaderField: "Authorization")
            
            let webSocket = createWebSocket(urlRequest: urlRequest)
            self.webSocketTask = webSocket
            webSocket.resume()
            
            await MainActor.run {
                isTranscribing = true
                audioSessionStartedAt = Date()
            }
            
            Task {
                try await transcriptionEventListener(urlRequest: urlRequest)
            }
            
            try configAudioSession()
            try startMicCapture()
            
        } catch {
            await releaseActiveAudioReservation(reason: "audio_start_failed")
            isTranscribing = false
            print("failed to start stream to openai transcription endpoint ❗️", ErrorDesc.webSocketError, error)
            throw error
        }
    }
    
    
    public func transcriptionEventListener(urlRequest: URLRequest) async throws {
        
        while isTranscribing {
            guard webSocketTask != nil else { throw ErrorDesc.webSocketError }
            
            do {
                try await extractTranscriptionResponseDelta()
                
                print("connected web socket, response delta being extracted...")
            } catch {
                print("audio stream interrupted ❗️", ErrorDesc.webSocketError, error)
                try await retryWebSocket(urlRequest: urlRequest)
            }
        }
    }
    
    
    public func stopAudioStream(context: ModelContext, onChunk: @escaping (String) async -> Void) async throws {
        defer {
            webSocketTask?.cancel(with: .normalClosure, reason: .none)
            webSocketTask = nil
        }

        do {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
            print("socket fully shut for this session")
            
            await MainActor.run {
                self.didStopAudioStream = true
                self.isTranscribing = false
                self.isSummarizing = true
            }
            
            try await commitAudioChunk()
            try await finalizeActiveAudioReservation()
            try await Task.sleep(for: .milliseconds(300))
            
            for i in 0..<31 {
                let finished: String = finishedTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if didStopAudioStream && !finished.isEmpty {
                    _ = try await summarizeFinishedTranscript(context: context, onChunk: onChunk)
                    return
                }
                
                try await Task.sleep(for: .milliseconds(300))
                print("wait loop re-checking: \(i) time(s)")
            }
            
            let live: String = liveTranscription.trimmingCharacters(in: .whitespacesAndNewlines)   ///Fallback is retry loop fails
            
            if didStopAudioStream && !live.isEmpty {
                finishedTranscript = liveTranscription
                _ = try await summarizeFinishedTranscript(context: context, onChunk: onChunk)
                return
            }
            
            await MainActor.run {
                self.isSummarizing = false
            }
            throw ErrorDesc.nilValue

        } catch {
            await releaseActiveAudioReservation(reason: "audio_stop_failed")
            await MainActor.run {
                self.isSummarizing = false
            }
            print("failed to summarize finished transcript", ErrorDesc.callsiteError, error)
            throw error
        }
    }


    private func finalizeActiveAudioReservation() async throws {            //TODO: move finalization and recovery functions into separate classes
        guard let idempotencyKey = activeAudioReservationKey, let startedAt = audioSessionStartedAt else { throw ErrorDesc.sessionError }

        let durationSeconds = max(Date().timeIntervalSince(startedAt), 1)
        let url = URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co/functions/v1/ai_summerizer-chat")!
        var request = URLRequest(url: url)
        let session = try await supabaseDBClient.auth.session

        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("audio_finalize", forHTTPHeaderField: "x-rep-action")
        request.setValue(idempotencyKey.uuidString, forHTTPHeaderField: "x-idempotency-key")
        request.httpBody = try JSONEncoder().encode(
            AudioFinalizeRequest(idempotency_key: idempotencyKey.uuidString, duration_seconds: durationSeconds))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw ErrorDesc.serverError }
        if httpResponse.statusCode == 402 { throw PaymentStoreError.insufficientTokens }
        guard (200...299).contains(httpResponse.statusCode) else { throw ErrorDesc.urlResponseError }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let settlement = try decoder.decode(AudioBillingSettlementResponse.self, from: data)
        paymentStoreCredits.applyUpdatedBucket(settlement.bucket)
        activeAudioReservationKey = nil
        audioSessionStartedAt = nil
        UserDefaults.standard.removeObject(forKey: Self.pendingReservationDefaultsKey)
    }


    func cancelActiveAudioSession(reason: String = "audio_session_cancelled") async {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        webSocketTask?.cancel(with: .goingAway, reason: .none)
        webSocketTask = nil
        isTranscribing = false
        isSummarizing = false
        await releaseActiveAudioReservation(reason: reason)
    }


    func recoverInterruptedAudioReservation() async {
        guard !isTranscribing, activeAudioReservationKey != nil else { return }
        await releaseActiveAudioReservation(reason: "recover_interrupted_audio_session")
    }


    private func releaseActiveAudioReservation(reason: String) async {
        guard let idempotencyKey = activeAudioReservationKey else { return }

        do {
            let url = URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co/functions/v1/ai_summerizer-chat")!
            var request = URLRequest(url: url)
            let session = try await supabaseDBClient.auth.session

            request.httpMethod = "POST"
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("audio_release", forHTTPHeaderField: "x-rep-action")
            request.setValue(idempotencyKey.uuidString, forHTTPHeaderField: "x-idempotency-key")
            request.httpBody = try JSONEncoder().encode(AudioReleaseRequest(idempotency_key: idempotencyKey.uuidString, reason: reason))

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else { throw ErrorDesc.urlResponseError }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let settlement = try decoder.decode(AudioBillingSettlementResponse.self, from: data)
            paymentStoreCredits.applyUpdatedBucket(settlement.bucket)
            activeAudioReservationKey = nil
            audioSessionStartedAt = nil
            UserDefaults.standard.removeObject(forKey: Self.pendingReservationDefaultsKey)
        } catch {
            print("failed to release audio credit reservation", ErrorDesc.callsiteError, error)
        }
    }
    
    
    public func decodeTranscriptionResponse() async throws -> TranscriptionStream {
        guard let webSocketTask else { throw ErrorDesc.webSocketError }
        
        let streamMessage: MessageTranscription = try await webSocketTask.receive()
        
        switch streamMessage {
            
        case .data(let data):
            return try JSONDecoder().decode(TranscriptionStream.self, from: data)
            
        case .string(let text):
            guard let text = text.data(using: .utf8) else { throw ErrorDesc.encodeError }
            return try JSONDecoder().decode(TranscriptionStream.self, from: text)
            
        @unknown default:
            throw ErrorDesc.decodeError
        }
    }
    
    
    public func extractTranscriptionResponseDelta() async throws {
        do {
            let response = try await decodeTranscriptionResponse()
            
            try await MainActor.run {
                if response.type == "error" { throw ErrorDesc.extractError }
                
                switch response.type {
                case "conversation.item.input_audio_transcription.delta":
                    if let delta = response.delta {
                        self.liveTranscription += delta
                        print("text delta: \(delta)")
                    }
                    
                case "conversation.item.input_audio_transcription.completed":
                    print("audio transcription complete")
                    if let text = response.transcript {
                        self.finishedTranscript += text
                        print("finished transcript:", finishedTranscript)
                    }
                    
                default:
                    print("ignored event:", response.type)
                    break
                }
                print("appending deltas to transcript:", liveTranscription)
            }
            
        } catch {
            print("error extracting objects from transcript", ErrorDesc.extractError, error)
            throw ErrorDesc.extractError
        }
    }
    
    
    public func sendAudioChunk(_ pcm16AudioData: Data) async throws {
        guard let webSocketTask else { throw ErrorDesc.webSocketError }
        
        let base64Audio = pcm16AudioData.base64EncodedString()
        let event: [String: Any] = ["type": "input_audio_buffer.append", "audio": base64Audio]
        
        let jsonData = try JSONSerialization.data(withJSONObject: event)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { throw ErrorDesc.encodeError }
        
        try await webSocketTask.send(.string(jsonString))
        print("sent audio chunk ✅")
    }
    
    
    public func commitAudioChunk() async throws {
        let event: [String: Any] = ["type": "input_audio_buffer.commit"]
        guard !event.isEmpty else { throw ErrorDesc.nilValue }
        
        let jsonData = try JSONSerialization.data(withJSONObject: event)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { throw ErrorDesc.encodeError }
        
        try await webSocketTask?.send(.string(jsonString))
        print("audio stream session commited ✅")
    }
    
    
    public func summarizeFinishedTranscript(context: ModelContext, onChunk: @escaping(String) async -> Void) async throws -> String {
        guard !finishedTranscript.isEmpty else { throw ErrorDesc.nilValue }
        
        let fullTranscript: String = finishedTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        print("FULL TRANSCRIPT: \(fullTranscript)")
        
        let openAIRequest: URL = URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co/functions/v1/ai_summerizer-chat")!
        var urlRequest: URLRequest = URLRequest(url: openAIRequest)
        
        let session = try await supabaseDBClient.auth.session
        let supabaseAccessToken: String = session.accessToken
        
        guard !supabaseAccessToken.isEmpty else { throw ErrorDesc.authTokenError }
        let boundary: String = UUID().uuidString
        
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(supabaseAccessToken)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("chat", forHTTPHeaderField: "x-rep-action")
        urlRequest.setValue(boundary, forHTTPHeaderField: "x-idempotency-key")
        urlRequest.httpMethod = "POST"
        
        var multipartReqBody = Data()
        
        multipartReqBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        multipartReqBody.append("Content-Disposition: form-data; name=\"input\"\r\n\r\n".data(using: .utf8)!)
        multipartReqBody.append("\(fullTranscript)\r\n".data(using: .utf8)!)
        
        multipartReqBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        multipartReqBody.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        multipartReqBody.append("mini\r\n".data(using: .utf8)!)
        
        multipartReqBody.append("--\(boundary)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = multipartReqBody
        
        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else { throw ErrorDesc.serverError }
            print("==========\n status code: \(httpResponse.statusCode)")

            if httpResponse.statusCode == 402 { throw PaymentStoreError.insufficientTokens }
            guard (200...299).contains(httpResponse.statusCode) else { throw ErrorDesc.urlResponseError }
            
            for try await stream in bytes.lines {
                print("RESPONSE STREAM: \(stream)")
                guard stream.hasPrefix("data:") else { continue }
                let ssePayload = String(stream.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
                if ssePayload == "[DONE]" { break }
                
                guard let streamData = ssePayload.data(using: .utf8) else { continue }
                let streamDecoder = try JSONDecoder().decode(StreamEvent.self, from: streamData)
                
                if let delta: String = streamDecoder.delta {
                    await onChunk(delta)
                    await MainActor.run {
                        summarizedNotes += delta
                        print("deltas appended to summarized notes: \(summarizedNotes)")
                    }
                }
                
                let fullNotes: String = summarizedNotes
                let fullTranscript: String = finishedTranscript
                let title: String = String(summarizedNotes.prefix(30))
                let userId: String = streamDecoder.response?.id ?? UUID().uuidString
                
                if streamDecoder.type == "response.completed" {
                    await MainActor.run {
                        isSummarizing = false
                        isTranscriptFinished = true
                        
                        let repMobileTranscription: RepMobileTranscription = RepMobileTranscription(userId: userId, fullNotes: fullNotes, title: title, fullTranscript: fullTranscript)
                        context.insert(repMobileTranscription)
                        try? context.save()
                    }
                    
                    if !fullNotes.isEmpty && !userId.isEmpty {
                        try await SupabaseClientManager.shared.upsertRepMobileNotes(fullNotes: fullNotes, userId: userId, title: title)
                    }
                }
            }
            
        } catch PaymentStoreError.insufficientTokens {
            throw PaymentStoreError.insufficientTokens
        } catch {
            print("failed to return response ❗️", ErrorDesc.decodeError, error)
            throw ErrorDesc.decodeError
        }
        return ""
    }
}
