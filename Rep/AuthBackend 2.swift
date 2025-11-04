//
//  AuthBackend.swift
//  MuscleMemory
//
//  Created by alex haidar on 12/7/24.
//

import Foundation
import AuthenticationServices
import SwiftUI



public class viewController: UIViewController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(appleSignIn)
    }
    let appleSignIn = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
}

public class authBackend: ObservableObject {
    public func handleSuccessfulLogin(_ authorization: ASAuthorization) {
        if let userCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            print(userCredential.user)
            
            if userCredential.authorizedScopes.contains(.fullName) {
                print(userCredential.fullName?.givenName ?? "No given name")
            }
            
            if userCredential.authorizedScopes.contains(.email) {
                print(userCredential.email ?? "No email")
            }
        }
    }
    
    public func handleLoginError(with error: Error) {
        print("Could not authenticate: \(error.localizedDescription)")
    }
}

    public struct AuthControllerRepresentable: UIViewControllerRepresentable {
        public func makeUIViewController(context: Context) -> viewController {
        
            return viewController()
        }
        
        public func updateUIViewController(_ uiViewController: viewController, context: Context) {
            
        }
    }
