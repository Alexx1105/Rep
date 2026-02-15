//
//  SyncController.swift
//  Rep
//
//  Created by alex haidar on 2/8/26.
//

import Foundation


@MainActor
final class SyncController: ObservableObject {
    static let shared = SyncController()
    @Published var isAutoSync: Bool = false
    @Published var didRunBootstrap: Bool = false
    private init() {}
}
    
