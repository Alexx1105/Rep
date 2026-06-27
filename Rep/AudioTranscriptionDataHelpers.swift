//
//  AudioTranscriptionHelpers.swift
//  Rep
//
//  Created by alex haidar on 6/13/26.
//
/* Static data helper functions and class for AI Audio Transcription */

import Foundation
import SwiftData
@preconcurrency import AVFoundation


public struct AudioBufferData {
    public let data: Data
    public let rms: Float
}


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
    
    
    public static func convertBufferToPCM16Data(_ buffer: AVAudioPCMBuffer) throws -> AudioBufferData {
        guard let bufferChannelData = buffer.floatChannelData else { throw ErrorDesc.floatError }
        
        let frameLength: Int = Int(buffer.frameLength)
        let channel: UnsafeMutablePointer<Float> = bufferChannelData[0]
        
        guard frameLength > 0 else { throw ErrorDesc.nilValue }
        
        var sumOfSampleSquares: Float = 0
        var data = Data(capacity: frameLength * 2)
        
        for i in 0..<frameLength {
            let frameSample: Float32 = max(-1.0, min(1.0, channel[i]))
            let frameInt: Int16 = Int16(frameSample * Float(Int16.max))
            
            sumOfSampleSquares += frameSample * frameSample
            
            var littleBytes: Int16 = frameInt.littleEndian
            withUnsafeBytes(of: &littleBytes) { bytes in        ///temporary short-lived pointer
                data.append(contentsOf: bytes)
            }
        }
        let rms: Float = sqrt(sumOfSampleSquares / Float(frameLength))   ///root mean squared sample for audio wave levels UI
        
        return AudioBufferData(data: data, rms: rms)
    }
    
    
    public static func scaleAudioWaves(rms: Float) -> Float {
        let scaledAmplitude: Float = 25
        let audioLevel: Float = min(max(scaledAmplitude * rms, 0), 1)
        
        return audioLevel
    }
    
    
    public static func waveHeight(for index: Int, audioLevel: CGFloat) -> CGFloat {
        let baseHeight: CGFloat = 25
        let maxGrowth: CGFloat = 55

        let multipliers: [CGFloat] = [0.75, 1.0, 1.5, 1.0, 0.75]

        return baseHeight + audioLevel * maxGrowth * multipliers[index]
    }
}

