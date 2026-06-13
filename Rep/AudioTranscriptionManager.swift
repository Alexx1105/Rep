//
//  AudioTranscriptionManager.swift
//  Rep
//
//  Created by alex haidar on 6/7/26.
//
/* All requests to the supabase edge functions for the Voice
 transcription with gpt-4o-mini-transcribe or future models will be handled here  */


import Foundation
import Supabase
@preconcurrency import AVFoundation

//TODO: move all function calls into a single runner func


@MainActor
public final class AudioTranscriptionManager: ObservableObject {
    public init() {}
    public static let AudioTranscription = AudioTranscriptionManager()
    
    private var webSocketTask: URLSessionWebSocketTask?
    typealias MessageTranscription = URLSessionWebSocketTask.Message
    
    @Published var liveTranscription: String = ""
    @Published var finishedTranscript: String = ""
    @Published var isTranscribing: Bool = false
    
    
    public func openAudioSession() async throws -> AudioSession.SessionData {
        
        let url: URL = URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co/functions/v1/ai_summerizer-chat-dev")!  //TODO: change back to prod endpoint after edge function is in prod
        var urlRequest: URLRequest = URLRequest(url: url)
        
        let session = try await supabaseDBClient.auth.session
        let supabaseAccessToken: String = session.accessToken
        guard !supabaseAccessToken.isEmpty else { throw ErrorDesc.authTokenError }
        
        urlRequest.setValue("Bearer \(supabaseAccessToken)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("audio", forHTTPHeaderField: "x-rep-action")
        urlRequest.httpMethod = "POST"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            print("SESSION DATA ✅: \(data)")
            
            guard let urlResponse = response as? HTTPURLResponse else { throw ErrorDesc.serverError }
            let _ = String(data: data, encoding: .utf8)
            
            guard (200...299).contains(urlResponse.statusCode) else { throw ErrorDesc.urlResponseError }
            
            let decodeSession = try JSONDecoder().decode(AudioSession.self, from: data)
            return decodeSession.session
            
        } catch {
            print("error opening audio session", ErrorDesc.sessionError, error)
        }
        throw ErrorDesc.sessionError
    }
    
    
    public func startAudioStream(session: AudioSession.SessionData) async throws {
        do {
            let ephemeralSecret: String = session.value
            guard !ephemeralSecret.isEmpty else { throw ErrorDesc.nilValue }
            
            let openaiTranscriptionUrl: URL = URL(string: "wss://api.openai.com/v1/realtime?intent=transcription")!
            var urlRequest: URLRequest = URLRequest(url: openaiTranscriptionUrl)
            
            urlRequest.setValue("Bearer \(ephemeralSecret)", forHTTPHeaderField: "Authorization")
            
            let createSocket = URLSession.shared.webSocketTask(with: urlRequest)
            self.webSocketTask = createSocket
            
            createSocket.resume()
            
            await MainActor.run {
                isTranscribing = true
            }
            
            Task {
                try await transcriptionEventListener()
            }
            
            try configAudioSession()
            try startMicCapture()
            
            print("web socket for audio stream successfully created...")
        } catch {
            print("failed to start stream to openai transcription endpoint", ErrorDesc.webSocketError, error)
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
            print("TYPE:", response.type, "| DELTA:", response.delta ?? "","| TRANSCRIPT:", response.transcript ?? "")
            
            try await MainActor.run {
                
                if response.type == "error" { throw ErrorDesc.extractError }
                
                switch response.type {
                case "conversation.item.input_audio_transcription.delta":
                    if let delta = response.delta {
                        self.liveTranscription += delta
                    }
                    
                case "conversation.item.input_audio_transcription.completed":
                    print("audio transcription complete")
                    if let text = response.transcript {
                        self.finishedTranscript += text
                    }
                    
                default:
                    print("ignored event:", response.type)
                    break
                }
            }
            
            print("successfully appended deltas into transcipt ✅", liveTranscription)
        } catch {
            print("error extracting objects from transcript", ErrorDesc.extractError, error)
            throw ErrorDesc.extractError
        }
    }
    
    
    public func stopAudioStream() async throws {
        webSocketTask?.cancel(with: .normalClosure, reason: .none)
        webSocketTask = nil
        isTranscribing = false
        
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
    }
    
    
    public func transcriptionEventListener() async throws {
        
        do {
            while webSocketTask != nil {
                try await extractTranscriptionResponseDelta()
            }
        } catch {
            print("audio stream interrupted ❗️", ErrorDesc.webSocketError, error)
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
    
    
    private let audioEngine = AVAudioEngine()
    
    public func convertBufferToPCM16Data(_ buffer: AVAudioPCMBuffer) throws -> Data {
        guard let bufferChannelData = buffer.floatChannelData else { throw ErrorDesc.floatError }
        
        let frameLength: Int = Int(buffer.frameLength)
        let channel: UnsafeMutablePointer<Float> = bufferChannelData[0]
        
        var data = Data(capacity: frameLength * 2)
        
        for i in 0..<frameLength {
            let frameSample: Float32 = max(-1.0, min(1.0, channel[i]))
            let frameInt: Int16 = Int16(frameSample * Float(Int16.max))
            
            var littleBytes: Int16 = frameInt.littleEndian
            withUnsafeBytes(of: &littleBytes) { bytes in        ///temporary short-lived pointer
                data.append(contentsOf: bytes)
            }
        }
        return data
    }
    
    
    func configAudioSession() throws {
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.allowBluetoothHFP, .defaultToSpeaker])
            try audioSession.setPreferredSampleRate(24_000)
            try audioSession.setPreferredInputNumberOfChannels(1)
            try audioSession.setActive(true)
            
            print("audio session successfully set up")
        } catch {
            print("failed to config audio session", ErrorDesc.configError, error)
        }
    }
    
    
    
    public func startMicCapture() throws {
        let micInput = audioEngine.inputNode
        let micInputFormat = micInput.inputFormat(forBus: 0)
        
        audioEngine.inputNode.removeTap(onBus: 0)
        
        micInput.installTap(onBus: 0, bufferSize: 512, format: micInputFormat) { [weak self] buffer, _ in    //TODO: update to installAudioTap(onBus:bufferSize:format:tapProvider:)
            guard let self else { return }
            
            do {
                guard let resampleAudioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 24_000, channels: 1, interleaved: false) else { throw ErrorDesc.configError }
                guard let converter = AVAudioConverter(from: micInputFormat, to: resampleAudioFormat) else { throw ErrorDesc.configError }
                let resampledBuffer = try self.resampleBuffer(buffer, converter: converter, outputFormat: resampleAudioFormat)
                let pcmData: Data = try self.convertBufferToPCM16Data(resampledBuffer)
    
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
    
    
    nonisolated private func resampleBuffer(_ inputBuffer: AVAudioPCMBuffer, converter: AVAudioConverter, outputFormat: AVAudioFormat) throws -> AVAudioPCMBuffer {
        
        let ratio = outputFormat.sampleRate / inputBuffer.format.sampleRate
        let outputFrameCapacity = AVAudioFrameCount(Double(inputBuffer.frameLength) * ratio)
        
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrameCapacity) else { throw ErrorDesc.configError }
        
        var didProvideInput = false
        var error: NSError?
        
        
        converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            if didProvideInput {
                outStatus.pointee = .noDataNow
                return nil
            }
            
            didProvideInput = true
            outStatus.pointee = .haveData
            return inputBuffer
        }
        
        if let error { throw error }
        
        return outputBuffer
    }
}
