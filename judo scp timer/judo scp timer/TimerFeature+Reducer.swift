// Copyright © Occam Technologies. All rights reserved.

import ComposableArchitecture
import Foundation

@Reducer
public struct TimerFeature: Sendable {
  public init() {}
  
  // MARK: - State
  
  @ObservableState
  public struct State: Equatable {
  
    public init() {}
  }
  
  // MARK: - Action
  
  public enum Action: Equatable {
    case onAppear
  }
  
  // MARK: - Reducer Composition
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .none
        
        
      }
    }
  }
  
}

