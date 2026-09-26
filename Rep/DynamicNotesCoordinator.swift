//
//  DynamicNotesCoordinator.swift
//  Rep
//
//  Created by alex haidar on 9/25/26.
//
/* middleware coordinator for UI slider change
 operations and interacting the supabase backend */
import Foundation
import SwiftUI
import Supabase
import KimchiKit


@MainActor
public final class DynamicNotesCoordinator: ObservableObject {
    init(dataSource: CombinedDataSource) {
        self.dataSource = dataSource
    }
    
    private var currentTask: Task<Void, Never>?
    
    let supabase = SupabaseClientManager.shared
    
    let dataSource: CombinedDataSource
    var dataSourceId: String {
        switch dataSource {
        case .notionContent(let notionPage):
            return notionPage.pageID
        case .openaiChatContent(let openaiChat):
            return openaiChat.openaiId
        case .repDesktopTranscription(let desktopTranscription):
            return desktopTranscription.userId
        case .repMobileTranscription(let mobileTranscription):
            return mobileTranscription.userId
        }
    }
    
    
    var dataSourceTitle: String {
        switch dataSource {
        case .notionContent(let notion):
            return notion.text
        case .openaiChatContent(let openai):
            return String(openai.content.prefix(20))
        case .repDesktopTranscription(let desktopAudio):
            return String(desktopAudio.fullNotes.prefix(30))
        case .repMobileTranscription(let mobileAudio):
            return String(mobileAudio.fullNotes.prefix(30))
        }
    }
    
    
    let frequencyOptions: [SliderView.SliderOption] = [
        .init(label: "Off", symbolName: "multiply.circle", interval: DateComponents(minute: 1)),
        .init(label: "1hr", symbolName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90", interval: DateComponents(minute: 60)),
        .init(label: "2h 30m", symbolName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90", interval: DateComponents(hour: 2, minute: 30)),
        .init(label: "3h 40m", symbolName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90", interval: DateComponents(hour: 3, minute: 40))
    ]
    
    let hyperModeOptions: [SliderView.SliderOption] = [
        .init(label: "Off", symbolName: "multiply.circle", interval: DateComponents(minute: 1)),
        .init(label: "10m", symbolName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90", interval: DateComponents(minute: 10)),
        .init(label: "30m", symbolName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90", interval: DateComponents(minute: 30)),
        .init(label: "45m", symbolName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90", interval: DateComponents(minute: 45))
    ]
    
    
    func staggerDateComponents(components: DateComponents, add: Int = 1, multiplier: Int) -> DateComponents {
        var new = DateComponents()
        new.hour = (components.hour ?? 0) * multiplier
        new.minute = (components.minute ?? 0) * multiplier
        return new
    }
    
    
    @MainActor
    func runSliderOperation(localPage: Binding<[String : Date]>, hyperToggleEnabled: Bool, storeSelectedOption: Int, storeSelectedHyperModeOption: Int) {
        let mode = hyperToggleEnabled ? hyperModeOptions : frequencyOptions
        let selectedIndex = hyperToggleEnabled ? storeSelectedHyperModeOption : storeSelectedOption
        guard selectedIndex < mode.count else { return }
        let opt = mode[selectedIndex]
        let intervalTitle = dataSourceTitle
        
        Task {
            do {
                try await Task.sleep(nanoseconds: 500_000_000)
                startIntervalActivity(label: opt.label, title: intervalTitle)
                await updateIntervalActivity(label: opt.label, title: intervalTitle)
            } catch is CancellationError {
                return
            } catch {
                print("failed to update interval activity:", ErrorDesc.liveActivityError)
            }
        }
        sliderChangeTask(sliderOption: opt, localPage: localPage)
    }
    
    
    func scheduleTask(selectedOption: SliderView.SliderOption, pageID: String, basePerPage: Date) async {
        do {
            let result: [QueryIDs] = try await supabase.fetchDynamicNotesQueryIDs(pageID: pageID)
            let queryID = result.map{ String($0.id) }
            
            await MainActor.run {
                Query.accessQuery.queryID = queryID
            }
            
            let rows: Int = 5
            for i in stride(from: 0, to: queryID.count, by: rows) {
                if Task.isCancelled { return }
                
                let stagger: Int = (i / rows) + 1
                let scaledOffsets = staggerDateComponents(components: selectedOption.interval, multiplier: stagger)
                let computedOffset: Date? = selectedOption.label == "Off" ? nil : Calendar.current.date(byAdding: scaledOffsets, to: basePerPage)
                let batch = min(i + rows, queryID.count)
                let idsPerBatch = Array(queryID[i..<batch])
                
                do {
                    try await supabase.updateDynamicNotesOffsetDate(computedOffset: computedOffset, idsPerBatch: idsPerBatch, pageID: pageID)
                    
                } catch {
                    print("failed to send offset timestamps to supabase:", ErrorDesc.intervalSchedulingError)
                }
            }
            
        } catch {
            print("failed to query id's from supabase:", ErrorDesc.supabaseQueryError)
        }
    }
    
    
    @MainActor
    func sliderChangeTask(sliderOption: SliderView.SliderOption, localPage: Binding<[String : Date]>) {
        currentTask?.cancel()
        
        localPage.wrappedValue[dataSourceId] = Date()
        let basePerPage: Date = localPage.wrappedValue[dataSourceId]!
        let pageID: String = dataSourceId
        
        currentTask = Task {
            await scheduleTask(selectedOption: sliderOption, pageID: pageID, basePerPage: basePerPage)
        }
    }
}
