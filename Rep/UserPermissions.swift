//
//  UserPermissions.swift
//  MuscleMemory
//
//  Created by alex haidar on 2/22/25.
//

import Foundation
import UserNotifications
import UIKit



@MainActor
class UserNotificationsPermissions: NSObject, UNUserNotificationCenterDelegate {
   
    func requestPermissions(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
         UNUserNotificationCenter.current().requestAuthorization(options: [ .criticalAlert, .badge, .alert ]) { permissionGranted , error in
            
            if permissionGranted {
                print("user enabled notification permissions\(permissionGranted)")
                
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                    UNUserNotificationCenter.current().delegate = self
                }
            } else {
                print("user deneid DynamicRep notifications")
            }
        }
        return true
    }
}
