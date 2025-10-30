// Copyright © Occam Technologies. All rights reserved.

import ComposableArchitecture
import SwiftUI

struct ContentView: View {
  @Bindable var store: StoreOf<TimerFeature>
  @Environment(\.scenePhase) private var scenePhase
  
  var body: some View {
    GeometryReader { geometry in
      let isLandscape = geometry.size.width > geometry.size.height
      
      ZStack {
        Color.black
          .ignoresSafeArea()
        
        if isLandscape {
          // Landscape: Split screen layout - use more screen space
          HStack(spacing: 0) {
            // Left side: All buttons vertically
            leftSideButtons(geometry: geometry)
              .frame(width: geometry.size.width * 0.35)
              .padding(20)
            
            // Right side: Bigger timer display - use more space
            rightSideTimer(geometry: geometry)
              .frame(width: geometry.size.width * 0.65)
          }
        } else {
          // Portrait: Original vertical layout
          ScrollView {
            VStack(spacing: min(geometry.size.height * 0.04, 30)) {
            
            
            // Timer type label
            Text(store.currentTimer.displayName)
              .font(.system(size: min(geometry.size.height * 0.04, 36), weight: .bold))
              .foregroundColor(.white)
              .opacity(0.8)
            
            // Timer display - larger in portrait
            Text(formatTime(store.timeRemaining))
              .font(.system(size: min(geometry.size.height * 0.2, 120), weight: .bold, design: .rounded))
              .foregroundColor(.white)
              .monospacedDigit()
              .minimumScaleFactor(0.4)
              .lineLimit(1)
            
            // Status indicator for last 3 seconds
            if store.timeRemaining <= 3 && store.timeRemaining > 0 && store.status == .running {
              Text("⚠️")
                .font(.system(size: min(geometry.size.height * 0.05, 45)))
                .opacity(0.8)
            }
            
            Spacer()
              .frame(height: min(geometry.size.height * 0.03, 20))
            
            // Control buttons - larger in portrait
            HStack(spacing: min(geometry.size.width * 0.1, 50)) {
              // Repeat button
              Button(action: {
                store.send(.resetTimer)
              }) {
                Image(systemName: "arrow.counterclockwise")
                  .font(.system(size: min(geometry.size.width * 0.12, 55)))
                  .foregroundColor(.white)
                  .frame(width: min(geometry.size.width * 0.22, 120), height: min(geometry.size.width * 0.22, 120))
                  .background(Color.gray.opacity(0.3))
                  .clipShape(Circle())
              }
              
              // Play/Pause button
              Button(action: {
                if store.status == .running {
                  store.send(.pauseTimer)
                } else if store.status == .paused {
                  store.send(.resumeTimer)
                } else if store.status == .preparing {
                  // Do nothing while preparing
                  return
                } else {
                  store.send(.startTimer)
                }
              }) {
                Image(systemName: store.status == .running ? "pause.fill" : "play.fill")
                  .font(.system(size: min(geometry.size.width * 0.14, 65)))
                  .foregroundColor(.white)
                  .frame(width: min(geometry.size.width * 0.25, 140), height: min(geometry.size.width * 0.25, 140))
                  .background(store.status == .preparing ? Color.gray : Color.blue)
                  .clipShape(Circle())
                  .opacity(store.status == .preparing ? 0.6 : 1.0)
              }
              .disabled(store.status == .preparing)
              
              // Skip to next interval button
              Button(action: {
                store.send(.fastForward)
              }) {
                Image(systemName: "arrow.right.circle.fill")
                  .font(.system(size: min(geometry.size.width * 0.12, 55)))
                  .foregroundColor(.white)
                  .frame(width: min(geometry.size.width * 0.22, 120), height: min(geometry.size.width * 0.22, 120))
                  .background(Color.gray.opacity(0.3))
                  .clipShape(Circle())
              }
              .disabled(store.status == .preparing)
              .opacity(store.status == .preparing ? 0.5 : 1.0)
            }
            .padding(.horizontal, max(geometry.size.width * 0.05, 20))
            
              Spacer()
                .frame(height: min(geometry.size.height * 0.05, 30))
            }
            .frame(minHeight: geometry.size.height)
          }
        }
      }
    }
    .onAppear {
      // Prevent screen from locking
      UIApplication.shared.isIdleTimerDisabled = true
      
      // Initialize timer display
      if store.status == .idle {
        store.send(.resetTimer)
      }
    }
    .onDisappear {
      // Re-enable screen lock when view disappears
      UIApplication.shared.isIdleTimerDisabled = false
    }
    .onChange(of: scenePhase) { phase in
      // Ensure idle timer stays disabled when app goes to background/foreground
      if phase == .active {
        UIApplication.shared.isIdleTimerDisabled = true
      }
    }
  }
  
  // MARK: - Landscape Left Side (Buttons)
  @ViewBuilder
  private func leftSideButtons(geometry: GeometryProxy) -> some View {
    // Calculate available space accounting for padding
    let availableHeight = geometry.size.height - 40 // 20px padding top and bottom
    let buttonSize = min(geometry.size.width * 0.25, availableHeight * 0.22)
    let playButtonSize = min(geometry.size.width * 0.3, availableHeight * 0.28)
    let spacing = min(availableHeight * 0.05, 40)
    
    VStack(spacing: 0) {
      Spacer()
      
      // Control buttons - much larger and squared, vertically arranged
      VStack(spacing: spacing) {
        // Repeat/Reset button - squared
        Button(action: {
          store.send(.resetTimer)
        }) {
          Image(systemName: "arrow.counterclockwise")
            .font(.system(size: buttonSize * 0.4))
            .foregroundColor(.white)
            .frame(width: buttonSize, height: buttonSize)
            .background(Color.gray.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 15))
        }
        
        // Play/Pause button - largest, squared
        Button(action: {
          if store.status == .running {
            store.send(.pauseTimer)
          } else if store.status == .paused {
            store.send(.resumeTimer)
          } else if store.status == .preparing {
            return
          } else {
            store.send(.startTimer)
          }
        }) {
          Image(systemName: store.status == .running ? "pause.fill" : "play.fill")
            .font(.system(size: playButtonSize * 0.42))
            .foregroundColor(.white)
            .frame(width: playButtonSize, height: playButtonSize)
            .background(store.status == .preparing ? Color.gray : Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .opacity(store.status == .preparing ? 0.6 : 1.0)
        }
        .disabled(store.status == .preparing)
        
        // Skip to next interval button - squared
        Button(action: {
          store.send(.fastForward)
        }) {
          Image(systemName: "arrow.right.circle.fill")
            .font(.system(size: buttonSize * 0.4))
            .foregroundColor(.white)
            .frame(width: buttonSize, height: buttonSize)
            .background(Color.gray.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 15))
        }
        .disabled(store.status == .preparing)
        .opacity(store.status == .preparing ? 0.5 : 1.0)
      }
      
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
  
  // MARK: - Landscape Right Side (Timer)
  @ViewBuilder
  private func rightSideTimer(geometry: GeometryProxy) -> some View {
    VStack(spacing: min(geometry.size.height * 0.08, 60)) {
      Spacer()
      
      // Timer type label - larger
      Text(store.currentTimer.displayName)
        .font(.system(size: min(geometry.size.height * 0.08, 64), weight: .bold))
        .foregroundColor(.white)
        .opacity(0.8)
      
      // Timer display - much bigger in landscape, use more of screen
      Text(formatTime(store.timeRemaining))
        .font(.system(size: min(geometry.size.height * 0.5, 300), weight: .bold, design: .rounded))
        .foregroundColor(.white)
        .monospacedDigit()
        .minimumScaleFactor(0.2)
        .lineLimit(1)
      
      // Status indicator for last 3 seconds - larger
      if store.timeRemaining <= 3 && store.timeRemaining > 0 && store.status == .running {
        Text("⚠️")
          .font(.system(size: min(geometry.size.height * 0.15, 120)))
          .opacity(0.8)
      }
      
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 40)
  }
  
  private func formatTime(_ seconds: TimeInterval) -> String {
    let totalSeconds = Int(seconds)
    let minutes = totalSeconds / 60
    let seconds = totalSeconds % 60
    return String(format: "%d:%02d", minutes, seconds)
  }
}

#Preview {
  ContentView(
    store: Store(initialState: TimerFeature.State()) {
      TimerFeature()
    }
  )
}
