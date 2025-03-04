//
//  PhotoPurgeApp.swift
//  PhotoPurge
//
//  Created by Victor Ricci on 3/4/25.
//

import SwiftUI
import Photos

@main
struct PhotoPurgeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = PhotoReviewViewModel()
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    
    var body: some Scene {
        WindowGroup {
            if !hasSeenWelcome {
                WelcomeView(showWelcome: Binding(
                    get: { !self.hasSeenWelcome },
                    set: { newValue in
                        self.hasSeenWelcome = !newValue
                    }
                ), reviewMode: Binding(
                    get: { self.viewModel.reviewMode },
                    set: { self.viewModel.reviewMode = $0 }
                ))
                .onDisappear {
                    viewModel.fetchPhotos()
                }
            } else {
                PhotoReviewView(viewModel: viewModel)
                    .onAppear {
                        setupPermissions()
                        viewModel.fetchPhotos()
                    }
            }
        }
    }
    
    private func setupPermissions() {
        // Request Photo Library permissions
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                print("Photo library access granted")
                // Request notification permissions after photo access is granted
                NotificationManager.shared.requestAuthorization()
            case .denied, .restricted:
                print("Photo library access denied")
            case .limited:
                print("Limited photo library access granted")
                NotificationManager.shared.requestAuthorization()
            case .notDetermined:
                print("Photo library access not determined")
            @unknown default:
                print("Unknown photo library access status")
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
}
