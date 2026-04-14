import SwiftUI

struct NotchRootView: View {
    @ObservedObject var state: NotchState

    var body: some View {
        ZStack(alignment: .top) {
            stageView
                .frame(
                    width: state.size(for: state.currentStage).width,
                    height: state.size(for: state.currentStage).height,
                    alignment: .top
                )

            if let continuityMessage = state.continuityMessage {
                ContinuityBanner(text: continuityMessage)
                    .padding(.top, state.size(for: state.currentStage).height + 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(
            width: state.size(for: state.currentStage).width,
            height: state.size(for: state.currentStage).height,
            alignment: .top
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            state.setHover(hovering)
        }
        .onTapGesture(count: 2) {
            state.setStage(.s4Chat)
        }
        .onTapGesture {
            state.handlePrimaryTap()
        }
        .contextMenu {
            Button("Open Calibration") {
                NotificationCenter.default.post(name: .notchOpenSettings, object: nil)
            }
            Divider()
            Button("Reset to Idle") {
                state.reset()
            }
        }
        .gesture(swipeGesture)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.78, blendDuration: 0),
            value: state.currentStage
        )
    }

    @ViewBuilder
    private var stageView: some View {
        switch state.currentStage {
        case .s0Idle:
            Stage0View(dimensions: state.dimensions)
        case .s1Notification:
            Stage1NotificationView(
                dimensions: state.dimensions,
                message: state.currentMessage,
                leftAction: state.leftAction,
                rightAction: state.rightAction,
                showsButtons: state.showsInlineButtons,
                swipeOffset: state.swipeOffset
            )
        case .s1Timer:
            Stage1TimerView(
                dimensions: state.dimensions,
                title: "Typography draft",
                timerLabel: state.currentTimerLabel,
                leftAction: state.leftAction,
                rightAction: state.rightAction,
                showsButtons: state.showsInlineButtons,
                swipeOffset: state.swipeOffset,
                onTimerTap: state.toggleTimerPause
            )
        case .s1Volume:
            Stage1VolumeView(
                dimensions: state.dimensions,
                volume: state.volumeLevel,
                muted: state.volumeMuted
            )
        case .s15Hover:
            Stage15HoverView(
                dimensions: state.dimensions,
                message: state.currentMessage,
                nowPlaying: state.nowPlaying,
                bluetoothDevice: state.bluetoothDevice
            )
        case .s2Card:
            Stage2CardView(
                dimensions: state.dimensions,
                title: "Breakfast reminder",
                subtitle: state.secondaryMessage,
                leftAction: state.leftAction,
                centerAction: state.centerAction,
                rightAction: state.rightAction,
                swipeOffset: state.swipeOffset
            )
        case .s3Dashboard:
            Stage3DashboardView(
                dimensions: state.dimensions,
                currentEvent: state.currentCalEvent,
                nextEvent: state.nextCalEvent,
                missedCount: state.missedCalCount,
                nowPlaying: state.nowPlaying,
                bluetoothDevice: state.bluetoothDevice
            )
        case .s4Chat:
            Stage4ChatView(dimensions: state.dimensions)
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard state.leftAction != nil || state.rightAction != nil else { return }
                state.applySwipeOffset(value.translation.width)
            }
            .onEnded { value in
                guard state.leftAction != nil || state.rightAction != nil else { return }
                state.commitSwipeIfNeeded(predictedEnd: value.predictedEndTranslation.width)
            }
    }
}
