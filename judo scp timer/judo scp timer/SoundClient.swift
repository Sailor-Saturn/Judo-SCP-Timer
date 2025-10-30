// Copyright © Occam Technologies. All rights reserved.

import ComposableArchitecture
import Foundation

@DependencyClient
public struct SoundClient: Sendable {
  public var playBeep: @Sendable () -> Void = {}
  public var playStartBeep: @Sendable () -> Void = {}
}

extension DependencyValues {
  public var soundClient: SoundClient {
    get { self[SoundClient.self] }
    set { self[SoundClient.self] = newValue }
  }
}

extension SoundClient: DependencyKey {
  public static let liveValue = SoundClient.live
  public static let testValue = SoundClient.test
}
