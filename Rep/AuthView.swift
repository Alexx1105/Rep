//
//  authView.swift
//  MuscleMemory
//
//  Created by alex haidar on 10/12/24.
//

import SwiftUI
import AuthenticationServices
import Foundation

struct AuthView: View {
    
    @ObservedObject var auth = authBackend()
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("user.signedIn") private var isUserAuthed: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            Image("AppIcon")
            Spacer()
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Sign Into Rep")
                    .fontWeight(.bold)
                    .font(.system(size: 16))
                    .padding(.trailing, 70)
                    .padding(.bottom, 1)
                
                Text("Powered by Kimchi Labs  ")
                    .fontWeight(.medium)
                    .foregroundStyle(Color.gray)
                    .font(.system(size: 14))
                    .padding(.trailing, 90)
            }
            
            Divider()
                .frame(maxWidth: .infinity, maxHeight: 1)
                .padding(.bottom, 4)
                .padding()
            
            Group {
                switch colorScheme {
                    
                case .light:
                    SignInWithAppleButton(.signIn, onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    }, onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            auth.handleSuccessfulLogin(authorization)
                            Task { @MainActor in
                                print("AuthView: sign-in succeeded — flipping user.signedIn and notifying")
                                isUserAuthed = true
                                NotificationCenter.default.post(name: Notification.Name("AuthDidSucceed"), object: nil)
                            }
                        case .failure(let error):
                            auth.handleLoginError(with: error)
                        }
                    })
                    .signInWithAppleButtonStyle(.black)
                    
                case .dark:
                    SignInWithAppleButton(.signIn, onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    }, onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            auth.handleSuccessfulLogin(authorization)
                            Task { @MainActor in
                                print("AuthView: sign-in succeeded — flipping user.signedIn and notifying")
                                isUserAuthed = true
                                NotificationCenter.default.post(name: Notification.Name("AuthDidSucceed"), object: nil)
                            }
                        case .failure(let error):
                            auth.handleLoginError(with: error)
                        }
                    })
                    .signInWithAppleButtonStyle(.white)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 297, height:  43)
            .cornerRadius(20)
            .padding(.bottom, 130)
            
        } .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}



#Preview {
    AuthView()
}

