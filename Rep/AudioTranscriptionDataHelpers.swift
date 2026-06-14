//
//  AudioTranscriptionHelpers.swift
//  Rep
//
//  Created by alex haidar on 6/13/26.
//
/* Static data helper functions and classes for the AI Audio Transcription */

import Foundation
import SwiftData
@preconcurrency import AVFoundation


final class AudioTranscriptionHelper {
    private init() {}
    
    
    nonisolated public static func resampleBuffer(_ inputBuffer: AVAudioPCMBuffer, converter: AVAudioConverter, outputFormat: AVAudioFormat) throws -> AVAudioPCMBuffer {
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
    
    
    public static func convertBufferToPCM16Data(_ buffer: AVAudioPCMBuffer) throws -> Data {
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
}

