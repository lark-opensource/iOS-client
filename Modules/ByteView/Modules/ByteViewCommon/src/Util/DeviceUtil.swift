//
//  DeviceUtil.swift
//  ByteViewCommon
//
//  Created by kiri on 2023/2/28.
//

import Foundation

public struct DeviceModelNumber: Codable, Comparable, CustomStringConvertible {
    public private(set) var major: Int
    public private(set) var minor: Int

    public init(major: Int, minor: Int) {
        self.major = major
        self.minor = minor
    }

    public static func < (lhs: DeviceModelNumber, rhs: DeviceModelNumber) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        return lhs.minor < rhs.minor
    }

    public var description: String {
        "DeviceModelNumber(\(major),\(minor))"
    }
}

public final class DeviceUtil {
    /// iPhone12,1
    public static let modelIdentifier: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? CChar, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        if simulatorNames.contains(identifier), let name = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return name
        }
        return identifier
    }()

    public static let modelNumber: DeviceModelNumber = {
        let identifier = modelIdentifier
        var majorNum = 1
        var minorNum = 1
        let numbers = identifier.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }
        if let first = numbers.first, let major = Int(first) {
            majorNum = major
        }
        if let last = numbers.last, let minor = Int(last) {
            minorNum = minor
        }
        return DeviceModelNumber(major: majorNum, minor: minorNum)
    }()

    private static let simulatorNames: Set<String> = ["i386", "x86_64", "arm64"]
}
