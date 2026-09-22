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
    @State private var isSigningIn = false
    @State private var signInError: String?
    
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
                        completeSignIn(result)
                    })
                    .signInWithAppleButtonStyle(.black)
                    
                case .dark:
                    SignInWithAppleButton(.signIn, onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    }, onCompletion: { result in
                        completeSignIn(result)
                    })
                    .signInWithAppleButtonStyle(.white)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight:  45)
            .cornerRadius(25)
            .padding(.horizontal)
            .disabled(isSigningIn)
            
            
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .alert("Sign in failed", isPresented: Binding(
                get: { signInError != nil },
                set: { if !$0 { signInError = nil } }
            )) {
                Button("OK") { signInError = nil }
            } message: {
                Text(signInError ?? "Please try again.")
            }
    }

    private func completeSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            isSigningIn = true
            signInError = nil
            Task { @MainActor in
                defer { isSigningIn = false }
                do {
                    try await auth.signIn(authorization)
                    isUserAuthed = true
                    NotificationCenter.default.post(name: Notification.Name("AuthDidSucceed"), object: nil)
                } catch {
                    isUserAuthed = false
                    signInError = error.localizedDescription
                    print("Supabase sign in failed:", error)
                }
            }
        case .failure(let error):
            isUserAuthed = false
            signInError = error.localizedDescription
        }
    }
}



#Preview {
    AuthView()
}
