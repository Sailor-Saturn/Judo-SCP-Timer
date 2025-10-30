// Copyright © Occam Technologies. All rights reserved.

import Foundation

extension SoundClient {
  public static var test: Self {
    .init(
      playBeep: {
        print("🔊 Beep sound played (test)")
      },
      playStartBeep: {
        print("🔊🔊 Start beep sound played (test)")
      }
    )
  }
}
