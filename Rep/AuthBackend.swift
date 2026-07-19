import Foundation
import AuthenticationServices
import SwiftUI
import Supabase
import CryptoKit


public class viewController: UIViewController {
    let appleSignIn = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
    let backend = authBackend()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Layout the button
        view.addSubview(appleSignIn)
        appleSignIn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            appleSignIn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            appleSignIn.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            appleSignIn.heightAnchor.constraint(equalToConstant: 44),
            appleSignIn.widthAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])
        
        appleSignIn.addTarget(self, action: #selector(handleAppleSignInTapped), for: .touchUpInside)
    }
    
    @objc private func handleAppleSignInTapped() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

extension viewController: ASAuthorizationControllerDelegate {
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        backend.handleSuccessfulLogin(authorization)
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        backend.handleLoginError(with: error)
    }
}

extension viewController: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        view.window ?? ASPresentationAnchor()
    }
}

public class authBackend: ObservableObject {
    public func handleSuccessfulLogin(_ authorization: ASAuthorization) {
        if let userCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            print("User ID:", userCredential.user)
            
            if userCredential.authorizedScopes.contains(.fullName) {
                print("Given name:", userCredential.fullName?.givenName ?? "No given name")
            }
            
            if userCredential.authorizedScopes.contains(.email) {
                print("Email:", userCredential.email ?? "No email")
            }
            
            if let tokenData: Data = userCredential.identityToken,
               let tokenString: String = String(data: tokenData, encoding: .utf8) {
                print("Identity token:", tokenString)
                
                Task {
                    do {
                        let _ = try await supabaseDBClient.auth.signInWithIdToken(credentials: OpenIDConnectCredentials(provider: .apple, idToken: tokenString))  //TODO: add nonce
                        //try DesktopAppToken.sendTokenToDesktop(session: session)
                        
                    } catch {
                        print("failed to exchange tokens with supabase", ErrorDesc.authTokenError, error)
                    }
                }
            }
        }
    }
    
    public func handleLoginError(with error: Error) {
        print("Could not authenticate: \(error.localizedDescription)")
    }
}

public struct AuthControllerRepresentable: UIViewControllerRepresentable {
    public func makeUIViewController(context: Context) -> viewController {
        viewController()
    }
    
    public func updateUIViewController(_ uiViewController: viewController, context: Context) {}
}
