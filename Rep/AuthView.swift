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
    @State private var animateTitle: Bool = false
    
    var body: some View {
        VStack {
            
            VStack(alignment: .center, spacing: 50) {
                Text("Rep")
                    .fontWeight(.bold)
                    .font(.system(size: 105))
                    .foregroundStyle(Color.mmDark)
                    .tracking(-3)
                    .scaleEffect(animateTitle ? 1.03 : 1.0)
                    .opacity(animateTitle ? 1.0 : 0.92)
                
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
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    animateTitle = false
            
                }
            }
            
            Divider()
                .frame(maxWidth: .infinity, maxHeight: 1)
                .padding(.horizontal)
             
            
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
            .frame(maxWidth: .infinity, maxHeight:  45)
            .cornerRadius(25)
            .padding(.horizontal)
            
            
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}



#Preview {
    AuthView()
}

