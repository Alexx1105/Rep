//
//  McpClientStructs.swift
//  Rep
//
//  Created by alex haidar on 11/26/26.
//
import Foundation



struct RepGptNotesPayload: Decodable {
    let source: String
    let title: String?
    let content: String
    let format: String
    let sent_at: String
}
