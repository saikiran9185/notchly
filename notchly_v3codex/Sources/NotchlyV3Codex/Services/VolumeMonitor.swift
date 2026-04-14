import CoreAudio
import Foundation

final class VolumeMonitor: NSObject, @unchecked Sendable {
    var onVolumeChange: ((Float, Bool) -> Void)?
    private var timer: Timer?
    private var lastVolume: Float = -1
    private var lastMuted: Bool = false

    func start() {
        let (vol, muted) = readVolume()
        lastVolume = vol
        lastMuted = muted

        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.checkVolume()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkVolume() {
        let (vol, muted) = readVolume()
        if abs(vol - lastVolume) > 0.01 || muted != lastMuted {
            lastVolume = vol
            lastMuted = muted
            onVolumeChange?(vol, muted)
        }
    }

    private func readVolume() -> (Float, Bool) {
        var deviceID = AudioDeviceID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var hwAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &hwAddr, 0, nil, &size, &deviceID
        )
        guard deviceID != kAudioObjectUnknown else { return (0.5, false) }

        // Read volume scalar
        var vol: Float32 = 0.5
        var volSize = UInt32(MemoryLayout<Float32>.size)
        var volAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectGetPropertyData(deviceID, &volAddr, 0, nil, &volSize, &vol)

        // Read mute state
        var muteVal: UInt32 = 0
        var muteSize = UInt32(MemoryLayout<UInt32>.size)
        var muteAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectGetPropertyData(deviceID, &muteAddr, 0, nil, &muteSize, &muteVal)

        return (vol, muteVal == 1)
    }
}
