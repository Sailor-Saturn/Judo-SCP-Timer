// Copyright © Occam Technologies. All rights reserved.

import SwiftUI
import UIKit

extension View {
  func supportedOrientations(_ orientations: UIInterfaceOrientationMask) -> some View {
    self.onAppear {
      AppDelegate.orientationLock = orientations
    }
  }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  static var orientationLock = UIInterfaceOrientationMask.all
  
  func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
    return AppDelegate.orientationLock
  }
}

