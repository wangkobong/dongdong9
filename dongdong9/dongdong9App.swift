//
//  dongdong9App.swift
//  dongdong9
//
//  Created by sungyeon kim on 7/18/25.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    // GIDSignIn 전역 설정
    if let clientID = FirebaseApp.app()?.options.clientID {
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
    } else {
        print("Error: Firebase clientID not found for GIDSignIn configuration.")
    }

    return true
  }

  // Google 로그인 후 앱으로 돌아올 때 URL 처리
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
      return GIDSignIn.sharedInstance.handle(url)
  }
}

@main
struct dongdong9App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
