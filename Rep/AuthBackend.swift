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
        Task {
            do {
                try await signIn(authorization)
            } catch {
                print("failed to exchange tokens with supabase", ErrorDesc.authTokenError, error)
            }
        }
    }

    public func signIn(_ authorization: ASAuthorization) async throws {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            throw AuthSignInError.missingIdentityToken
        }

        let session = try await supabaseDBClient.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(provider: .apple, idToken: token)
        )
        guard !session.accessToken.isEmpty else { throw AuthSignInError.missingSession }
        print("Supabase sign in success")
    }
    
    public func handleLoginError(with error: Error) {
        print("Could not authenticate: \(error.localizedDescription)")
    }
}

enum AuthSignInError: LocalizedError {
    case missingIdentityToken
    case missingSession

    var errorDescription: String? {
        switch self {
        case .missingIdentityToken: "Apple did not return a sign-in token. Please try again."
        case .missingSession: "Rep could not establish a session. Please try signing in again."
        }
    }
}

public struct AuthControllerRepresentable: UIViewControllerRepresentable {
    public func makeUIViewController(context: Context) -> viewController {
        viewController()
    }
    
    public func updateUIViewController(_ uiViewController: viewController, context: Context) {}
}
