//
//  NavPath.swift
//  MuscleMemory
//
//  Created by alex haidar on 10/29/24.
//

import SwiftUI

class NavPath: ObservableObject {
    
    static let shared = NavPath()
    
    private init() { }
    
    @Published var path = NavigationPath()
    
    func navigate(to item: NavPathItem) {
        path.append(item)
    }
}

enum NavPathItem: Hashable {
    case settings
    case home
    case importPage
    case logOut
    case importpageUser
}


