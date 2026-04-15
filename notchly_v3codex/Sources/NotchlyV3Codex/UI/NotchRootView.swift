import SwiftUI

struct NotchRootView: View {
    @ObservedObject var state: NotchState

    var body: some View {
        ZStack(alignment: .top) {
            stageView
                .transition(.asymmetric(
                    insertion:  .opacity.combined(with: .scale(scale: 0.97, anchor: .top)),
                    removal:    .opacity.combined(with: .scale(scale: 0.97, anchor: .top))
                ))
                .id(state.currentStage)  // forces SwiftUI to animate between stages

            if let msg = state.continuityMessage {
                ContinuityBanner(text: msg)
                    .padding(.top, state.size(for: state.currentStage).height + 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(
            width:  state.size(for: state.currentStage).width,
            height: state.size(for: state.currentStage).height,
            alignment: .top
        )
        .contentShape(Rectangle())
        .onHover { state.setHover($0) }
        .onTapGesture(count: 2) {
            withAnimation(ND.Motion.expand) { state.setStage(.s4Chat) }
        }
        .onTapGesture {
            withAnimation(ND.Motion.expand) { state.handlePrimaryTap() }
        }
        .contextMenu {
            Button("Open Settings") {
                NotificationCenter.default.post(name: .notchOpenSettings, object: nil)
            }
            Divider()
            Button("Reset to Idle") {
                withAnimation(ND.Motion.expand) { state.reset() }
            }
            Button("Cycle Demo Stage") {
                withAnimation(ND.Motion.expand) { state.cycleDemoStage() }
            }
        }
        .gesture(swipeGesture)
        .animation(ND.Motion.expand, value: state.currentStage)
        .animation(ND.Motion.fast,   value: state.continuityMessage)
    }

    // MARK: - Stage Views

    @ViewBuilder
    private var stageView: some View {
        switch state.currentStage {

        case .s0Idle:
            Stage0View(
                dimensions:    state.dimensions,
                hasPendingAlert: state.hasPendingAlert,
                hasActiveTask:   state.hasActiveTask,
                isPlaying:       state.isPlayingMusic
            )

        case .s1Notification:
            Stage1NotificationView(
                dimensions:   state.dimensions,
                message:      state.currentMessage,
                leftAction:   state.leftAction,
                rightAction:  state.rightAction,
                showsButtons: state.showsInlineButtons,
                swipeOffset:  state.swipeOffset,
                alertType:    state.currentAlertType
            )

        case .s1Timer:
            Stage1TimerView(
                dimensions:   state.dimensions,
                title:        state.activeTask?.title ?? state.currentMessage,
                timerLabel:   state.currentTimerLabel,
                progress:     state.timerProgress,
                leftAction:   state.leftAction,
                rightAction:  state.rightAction,
                showsButtons: state.showsInlineButtons,
                swipeOffset:  state.swipeOffset,
                onTimerTap:   state.toggleTimerPause
            )

        case .s1Volume:
            Stage1VolumeView(
                dimensions: state.dimensions,
                volume:     state.volumeLevel,
                muted:      state.volumeMuted
            )

        case .s15Hover:
            Stage15HoverView(
                dimensions:      state.dimensions,
                message:         state.currentMessage,
                nowPlaying:      state.nowPlaying,
                bluetoothDevice: state.bluetoothDevice,
                activeTask:      state.activeTask
            )

        case .s2Card:
            Stage2CardView(
                dimensions:   state.dimensions,
                title:        state.activeTask?.title ?? state.currentMessage,
                subtitle:     state.activeTask?.project ?? state.secondaryMessage,
                leftAction:   state.leftAction,
                centerAction: state.centerAction,
                rightAction:  state.rightAction,
                swipeOffset:  state.swipeOffset
            )

        case .s3Dashboard:
            Stage3DashboardView(
                dimensions:      state.dimensions,
                currentEvent:    state.currentCalEvent,
                nextEvent:       state.nextCalEvent,
                missedCount:     state.missedCalCount,
                nowPlaying:      state.nowPlaying,
                bluetoothDevice: state.bluetoothDevice,
                activeTask:      state.activeTask,
                pendingTasks:    state.pendingTasks,
                notionTasks:     state.notionTasks,
                memory:          state.workingMemory
            )

        case .s4Chat:
            Stage4ChatView(dimensions: state.dimensions)
        }
    }

    // MARK: - Swipe

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard state.leftAction != nil || state.rightAction != nil else { return }
                state.applySwipeOffset(value.translation.width)
            }
            .onEnded { value in
                guard state.leftAction != nil || state.rightAction != nil else { return }
                withAnimation(ND.Motion.spring) {
                    state.commitSwipeIfNeeded(predictedEnd: value.predictedEndTranslation.width)
                }
            }
    }
}
