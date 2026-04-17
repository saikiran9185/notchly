import Carbon
import AppKit

// Registers Shift+Space as a system-wide hotkey using Carbon RegisterEventHotKey.
// Does NOT require Accessibility permission.
final class HotkeyManager: @unchecked Sendable {
    static let shared = HotkeyManager()
    var onTrigger: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    func register() {
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind:  OSType(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, _, userData) -> OSStatus in
                guard let ptr = userData else { return OSStatus(eventNotHandledErr) }
                let mgr = Unmanaged<HotkeyManager>.fromOpaque(ptr).takeUnretainedValue()
                DispatchQueue.main.async { mgr.onTrigger?() }
                return noErr
            },
            1, &spec, selfPtr, &eventHandlerRef
        )
        var keyID = EventHotKeyID(signature: OSType(0x4E544C59), id: 1) // 'NTLY'
        RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(shiftKey),
            keyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let r = hotKeyRef      { UnregisterEventHotKey(r);  hotKeyRef = nil }
        if let r = eventHandlerRef { RemoveEventHandler(r);    eventHandlerRef = nil }
    }
}
