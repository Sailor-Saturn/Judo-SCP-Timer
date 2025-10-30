// Copyright © Occam Technologies. All rights reserved.

import ComposableArchitecture
import Foundation

@Reducer
public struct TimerFeature: Sendable {
  public init() {}
  
  // MARK: - State
  
  @ObservableState
  public struct State: Equatable {
    public enum TimerType: Equatable {
      case work  // 3:30
      case rest  // 1:50
      
      var duration: TimeInterval {
        switch self {
        case .work:
          return 210 // 3:30 in seconds
        case .rest:
          return 90 // 1:30 in seconds
        }
      }
      
      var displayName: String {
        switch self {
        case .work:
          return "Randori"
        case .rest:
          return "Rest"
        }
      }
    }
    
    enum TimerStatus: Equatable {
      case idle
      case preparing // 1 second delay before starting
      case running
      case paused
      case finished
    }
    
    var currentTimer: TimerType = .work
    var timeRemaining: TimeInterval = 210
    var status: TimerStatus = .idle
    
    public init() {
      self.currentTimer = .work
      self.timeRemaining = 210
      self.status = .idle
    }
  }
  
  // MARK: - Action
  
  public enum Action: Equatable {
    case selectTimer(State.TimerType)
    case startTimer
    case pauseTimer
    case resumeTimer
    case resetTimer
    case fastForward
    case timerTick
    case timerFinished
    case preparationComplete // Action after 1 second delay
  }
  
  // MARK: - Cancellables
  
  nonisolated(unsafe) enum CancelID: Hashable, Sendable {
    case timerTick
    case preparationDelay
  }
  
  // MARK: - Dependencies
  
  @Dependency(\.mainRunLoop) var mainRunLoop
  @Dependency(\.soundClient) var soundClient
  
  // MARK: - Reducer Composition
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .selectTimer(let timerType):
        // Only allow switching when timer is idle, finished, or preparing
        guard state.status == .idle || state.status == .finished || state.status == .preparing else {
          return .none
        }
        state.currentTimer = timerType
        state.timeRemaining = timerType.duration
        // Cancel any preparation if switching timers
        if state.status == .preparing {
          state.status = .idle
          return .cancel(id: CancelID.preparationDelay)
        }
        return .none
        
      case .startTimer:
        // Wait 1 second before starting the timer
        state.status = .preparing
        // Play start beep when preparation begins
        soundClient.playStartBeep()
        return .run { send in
          try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
          await send(.preparationComplete)
        }
        
      case .preparationComplete:
        // After 1 second delay, actually start the timer
        state.status = .running
        return .run { send in
          await withTaskCancellation(id: CancelID.timerTick) {
            for await _ in self.mainRunLoop.timer(interval: 1) {
              await send(.timerTick)
            }
          }
        }
        
      case .pauseTimer:
        state.status = .paused
        return .cancel(id: CancelID.timerTick)
        
      case .resumeTimer:
        state.status = .running
        return .run { send in
          await withTaskCancellation(id: CancelID.timerTick) {
            for await _ in self.mainRunLoop.timer(interval: 1) {
              await send(.timerTick)
            }
          }
        }
        
      case .resetTimer:
        state.status = .idle
        state.timeRemaining = state.currentTimer.duration
        return .merge(
          .cancel(id: CancelID.timerTick),
          .cancel(id: CancelID.preparationDelay)
        )
        
      case .fastForward:
        // Skip to the next timer interval (work -> rest, rest -> work)
        // Works in any state - idle, running, paused, or finished
        let nextTimerType: State.TimerType = state.currentTimer == .work ? .rest : .work
        state.currentTimer = nextTimerType
        state.timeRemaining = nextTimerType.duration
        
        // If timer was running or paused, cancel it
        if state.status == .running || state.status == .paused {
          state.status = .idle
          return .merge(
            .cancel(id: CancelID.timerTick),
            .cancel(id: CancelID.preparationDelay)
          )
        } else {
          // Just reset to idle if not running
          state.status = .idle
          return .none
        }
        
      case .timerTick:
        guard state.status == .running else { return .none }
        
        if state.timeRemaining > 0 {
          // Play beep if we're in the last 3 seconds BEFORE decrementing
          // This ensures we beep at  3, 2, 1
          if state.timeRemaining <= 3 {
            soundClient.playBeep()
          }
          
          state.timeRemaining -= 1
          
          if state.timeRemaining == 0 {
            // Timer reached zero - automatically switch to next timer
            let nextTimerType: State.TimerType = state.currentTimer == .work ? .rest : .work
            state.currentTimer = nextTimerType
            state.timeRemaining = nextTimerType.duration
            
            // Cancel current timer tick
            // Then wait 1 second and start the next timer automatically
            return .merge(
              .cancel(id: CancelID.timerTick),
              .run { send in
                // Wait 1 second before starting next timer
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await send(.timerFinished)
              }
            )
          }
          
          return .none
        } else {
          // Timer already at zero - switch to next timer
          let nextTimerType: State.TimerType = state.currentTimer == .work ? .rest : .work
          state.currentTimer = nextTimerType
          state.timeRemaining = nextTimerType.duration
          
          return .merge(
            .cancel(id: CancelID.timerTick),
            .run { send in
              // Wait 1 second before starting next timer
              try? await Task.sleep(nanoseconds: 1_000_000_000)
              await send(.timerFinished)
            }
          )
        }
        
      case .timerFinished:
        // After 1 second delay, automatically start the next timer
        state.status = .preparing
        // Play start beep when preparation begins
        soundClient.playStartBeep()
        return .run { send in
          try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second preparation
          await send(.preparationComplete)
        }
      }
    }
  }
}
