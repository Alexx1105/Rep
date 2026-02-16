//
//  SyncController.swift
//  Rep
//
//  Created by alex haidar on 2/8/26.

/////related to sync engine and background processes that run the sync

import Foundation
import BackgroundTasks
import SwiftData


@MainActor
final class SyncController: ObservableObject {
    static let shared = SyncController()
    
    @Published var isAutoSync: Bool {
        didSet {
            UserDefaults.standard.set(isAutoSync, forKey: "isAutoSync")
        }
    }
    
    @Published var didRunBootstrap: Bool = false
    
    private init() {
        self.isAutoSync = UserDefaults.standard.bool(forKey: "isAutoSync")
    }
}


final class BackgroundRefresh {
    static let shared = BackgroundRefresh()
    
    @MainActor
    func runSyncWhenReady(context: ModelContext, pages: ModelContext) async throws {
        
        do {
            try await searchPages.shared.userEndpoint(context: pages)
            
            let description = FetchDescriptor<NotionPageMetaData>()
            let pageID = try context.fetch(description)
            
            for pg in pageID {
                try await ImportUserPage.shared.pageEndpoint(pageID: pg.pageID, context: context)
            }
            
            print("sync task ran successfully 🔄")
        } catch {
            print("auto sync task error: \(error)")
        }
    }
    
    private var autoSyncTask: Task<Void, Never>?
    
    @MainActor
    func startAutoSyncTask(pages: ModelContext, context: ModelContext) {
        
        if SyncController.shared.isAutoSync {
            autoSyncTask = Task { @MainActor in
                while !Task.isCancelled {
                    do {
                        try await runSyncWhenReady(context: context, pages: pages)
                        try await Task.sleep(nanoseconds: 120_000_000_000)      ///2 min
                        
                    } catch {
                        print("cancellation error: \(error)")
                    }
                }
            }
        }
    }
    
    
    private func bgAppRefresh(task: BGAppRefreshTask) {
        
        do {
            let container = try ModelContainer(for: NotionPageMetaData.self)
            let pages = ModelContext(container)
            let context = ModelContext(container)
            
            Task {
                try await runSyncWhenReady(context: context, pages: pages)
            }
            
        } catch {
            print("background fetch from model container failure ❗️\(error)")
        }
    }
    
    
    static func bgTaskRegister() {
        
        let identifier: String = "Musclememory.KimchiLabs.com"
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            guard let task = task as? BGAppRefreshTask else { return }
            
            BackgroundRefresh.shared.bgAppRefresh(task: task)
        }
    }
    
    static func bgTaskRequest() {
        let taskRequest = BGAppRefreshTaskRequest(identifier: "Musclememory.KimchiLabs.com")
        taskRequest.earliestBeginDate = Date(timeIntervalSinceNow: 60)
        
        do {
            try BGTaskScheduler.shared.submit(taskRequest)
        } catch {
            print("task request error ❗️: \(error)")
        }
    }
}





