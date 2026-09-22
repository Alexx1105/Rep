//
//  SyncController.swift
//  Rep
//
//  Created by alex haidar on 2/8/26.

/* sync engine and background processes that run the sync */

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
    
    func runSyncWhenReady(context: ModelContext, pages: ModelContext) async throws {
        try await NotionDataManager.shared.syncCachedPages(context: pages)
        print("sync task ran successfully 🔄")
        
        try await Task.sleep(for: .seconds(60))
    }
    
    private var autoSyncTask: Task<Void, Never>?
    
    @MainActor
    func startAutoSyncTask(pages: ModelContext, context: ModelContext) {
        if SyncController.shared.isAutoSync {
            autoSyncTask = Task {
                while !Task.isCancelled {
                    do {
                        try await runSyncWhenReady(context: context, pages: pages)
                        try await Task.sleep(for: .seconds(2 * 60))
                        
                    } catch {
                        print("cancellation error:", ErrorDesc.syncError, error)
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
                do {
                    try await runSyncWhenReady(context: context, pages: pages)
                    task.setTaskCompleted(success: true)
                } catch is CancellationError {
                    task.setTaskCompleted(success: false)
                } catch {
                    print("background sync failed:", ErrorDesc.taskError, error)
                    task.setTaskCompleted(success: false)
                }
            }
            
        } catch {
            print("background fetch from model container failure:", ErrorDesc.swiftDataQueryError, error)
        }
    }
    
    enum TaskRegister {         ///add more tasks for future bg capabilities  here
        static let syncIdentifier: String = "MuscleMemory.KimchiLabs.com"
    }
    
    static func bgTaskRegister() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: TaskRegister.syncIdentifier, using: nil) { task in
            guard let task = task as? BGAppRefreshTask else { return }
            BackgroundRefresh.shared.bgAppRefresh(task: task)
        }
    }
    
    static func bgTaskRequest() {
        let taskSyncRequest = BGAppRefreshTaskRequest(identifier: "MuscleMemory.KimchiLabs.com")
        taskSyncRequest.earliestBeginDate = Date(timeIntervalSinceNow: 60)
        
        do {
            try BGTaskScheduler.shared.submit(taskSyncRequest)
        } catch {
            print("task request error:", ErrorDesc.syncError, error)
        }
    }
}





