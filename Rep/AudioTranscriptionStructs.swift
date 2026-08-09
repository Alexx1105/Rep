//
//  AudioTranscriptionStructs.swift
//  Rep
//
//  Created by alex haidar on 7/18/26.
//
import Foundation


public struct DesktopNotes: Codable {
    let ok: Bool
    let notes: [TranscriptedDesktopNotes]
    
    public struct TranscriptedDesktopNotes: Codable {
        let id: String
        let transcript: String?
        let notes: String?
        let created_at: String
    }
}
