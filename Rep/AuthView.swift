//
//  authView.swift
//  MuscleMemory
//
//  Created by alex haidar on 10/12/24.
//

import SwiftUI
import AuthenticationServices
import Foundation

struct authView: View {
    
    @ObservedObject var auth = authBackend()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        
        VStack {
          
            Spacer()
            Image("auth")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 330, height: 330)
                .padding(.trailing, 10)
                .padding(.top, 60)
                
          
            Spacer()
            Text("Sign into MuscleMemory ")
                .fontWeight(.bold)
                .font(.system(size: 16))
                .padding(.trailing, 70)
                .padding(.bottom, 1)
         
            Text("Powered by Kimchi Labs  ")
                .fontWeight(.medium)
                .foregroundStyle(Color.gray)
                .font(.system(size: 14))
                .padding(.trailing, 90)
       
            Divider()
                .frame(width: 360, height: 1)
              
                .padding(.bottom, 4)
            
            Group {
                switch colorScheme {
                case .light:
                    SignInWithAppleButton(.signIn, onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    }, onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            auth.handleSuccessfulLogin(authorization)
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
        authView()
    }

