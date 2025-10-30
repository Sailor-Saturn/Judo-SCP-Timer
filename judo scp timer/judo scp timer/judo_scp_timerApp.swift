//
//  judo_scp_timerApp.swift
//  judo scp timer
//
//  Created by Vera Dias on 29/10/2025.
//

import ComposableArchitecture
import SwiftUI

@main
struct judo_scp_timerApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  var body: some Scene {
    WindowGroup {
      ContentView(
        store: Store(initialState: TimerFeature.State()) {
          TimerFeature()
        }
      )
      .supportedOrientations(.all) // Allow both portrait and landscape
    }
  }
}
