//
//  SignInView.swift
//  CC
//
//  Created by Evan Roberts on 1/21/26.
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @ObservedObject var authManager: AuthenticationManager
    
    var body: some View {
        ZStack {
            // Black background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // App Title
                Text("CC")
                    .foregroundColor(.terminalGreen)
                    .font(.system(size: 24, design: .monospaced))
                    .fontWeight(.bold)
                
                Text("Sign in with your Apple ID to sync entries with your brother")
                    .foregroundColor(.terminalGreen.opacity(0.7))
                    .font(.system(size: 15, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Sign in with Apple Button
                SignInWithAppleButtonWrapper(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                // User signed in with Apple - mark as completed
                                print("✅ Signed in with Apple ID: \(appleIDCredential.user)")
                                authManager.hasCompletedSignIn = true
                                UserDefaults.standard.set(true, forKey: "CC_HAS_SIGNED_IN")
                                
                                // Give it a moment for iCloud to sync, then check CloudKit
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    authManager.checkAuthenticationStatus()
                                }
                            }
                        case .failure(let error):
                            print("❌ Sign in failed: \(error.localizedDescription)")
                        }
                    }
                )
                .frame(height: 50)
                .padding(.horizontal, 40)
                
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .terminalGreen))
                        .padding()
                }
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct SignInWithAppleButtonWrapper: UIViewRepresentable {
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.cornerRadius = 4
        button.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: containerView.topAnchor),
            button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        
        context.coordinator.button = button
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onRequest: onRequest, onCompletion: onCompletion)
    }
    
    class Coordinator: NSObject {
        let onRequest: (ASAuthorizationAppleIDRequest) -> Void
        let onCompletion: (Result<ASAuthorization, Error>) -> Void
        var authorizationController: ASAuthorizationController?
        weak var button: ASAuthorizationAppleIDButton?
        
        init(onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void, onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void) {
            self.onRequest = onRequest
            self.onCompletion = onCompletion
        }
        
        @objc func buttonTapped() {
            print("🔵 Button tapped!")
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            onRequest(request)
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
            self.authorizationController = controller
        }
    }
}

extension SignInWithAppleButtonWrapper.Coordinator: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("✅ Authorization completed")
        onCompletion(.success(authorization))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Authorization error: \(error.localizedDescription)")
        onCompletion(.failure(error))
    }
}

extension SignInWithAppleButtonWrapper.Coordinator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            // Fallback to any window
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                return window
            }
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                // This should never happen in normal operation
                return UIWindow()
            }
            return UIWindow(windowScene: windowScene)
        }
        return window
    }
}
