//
//  DynamicNotesStructs.swift
//  Rep
//
//  Created by alex haidar on 9/27/26.
/* structs and encoding helper for settings
   config and interval notes scheduling */
import Foundation


struct NotesConfig: Decodable {
    let batchSize: Int
    let cursorPosition: Int
    let scheduleStatus: String
    let nextRunAt: Date?
    let order: NotesOrder
    
    enum NotesOrder: String, CaseIterable, Decodable {
        case asc = "Ascending"
        case desc = "Descending"
    }
}


struct ScheduleNotesInterval: Codable {
    let nextRunAt: Date?
    let intervalSeconds: Int?
    let scheduleStatus: String
    
    enum CodingKeys: String, CodingKey {
        case nextRunAt = "next_run_at"
        case intervalSeconds = "interval_seconds"
        case scheduleStatus = "schedule_status"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ScheduleNotesInterval.CodingKeys.self)
        try container.encode(scheduleStatus, forKey: .scheduleStatus)
        
        if let nextRunAt {
            try container.encode(nextRunAt, forKey: .nextRunAt)
        } else {
            try container.encodeNil(forKey: .nextRunAt)
        }
        
        if let intervalSeconds {
            try container.encode(intervalSeconds, forKey: .intervalSeconds)
        } else {
            try container.encodeNil(forKey: .intervalSeconds)
        }
    }
}


extension DateComponents {
    var totalSeconds: Int {
        ((day ?? 0) * 86_400) + ((hour ?? 0) * 3_600) + ((minute ?? 0) * 60) + (second ?? 0)
    }
}
