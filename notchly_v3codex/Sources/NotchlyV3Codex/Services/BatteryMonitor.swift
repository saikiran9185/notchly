import Foundation
import IOBluetooth

struct BTDeviceInfo: Equatable {
    let name: String
    let batteryPercent: Int?
}

final class BatteryMonitor: NSObject, @unchecked Sendable {
    var onUpdate: ((BTDeviceInfo?) -> Void)?
    private(set) var current: BTDeviceInfo?
    private var timer: Timer?

    func start() {
        check()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.check()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func check() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            let info = Self.findAudioDevice()
            DispatchQueue.main.async {
                self?.current = info
                self?.onUpdate?(info)
            }
        }
    }

    private static func findAudioDevice() -> BTDeviceInfo? {
        guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else { return nil }

        for device in devices {
            guard device.isConnected() else { continue }
            let name = device.name ?? ""
            // Major class 4 = Audio/Video
            let isAudio = Int(device.deviceClassMajor) == 4
            let isAirPods = name.lowercased().contains("airpod")
            let isHeadphone = name.lowercased().contains("headphone") || name.lowercased().contains("beats") || name.lowercased().contains("bose") || name.lowercased().contains("sony")

            if isAudio || isAirPods || isHeadphone {
                let battery = getBatteryFromRegistry(address: device.addressString ?? "")
                return BTDeviceInfo(name: name, batteryPercent: battery)
            }
        }
        return nil
    }

    // Try to get battery level via ioreg
    private static func getBatteryFromRegistry(address: String) -> Int? {
        let task = Process()
        task.launchPath = "/usr/sbin/ioreg"
        task.arguments = ["-r", "-k", "BatteryPercent"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do {
            try task.run()
        } catch {
            return nil
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        guard let output = String(data: data, encoding: .utf8) else { return nil }

        // Parse "BatteryPercent" = 85
        for line in output.components(separatedBy: "\n") {
            if line.contains("BatteryPercent"),
               let eqRange = line.range(of: "="),
               let val = Int(line[eqRange.upperBound...].trimmingCharacters(in: .whitespaces)) {
                return val
            }
        }
        return nil
    }
}
