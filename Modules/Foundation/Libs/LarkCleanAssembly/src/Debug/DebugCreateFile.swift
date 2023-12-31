//
//  DebugCreateFile.swift
//  LarkCleanAssembly
//
//  Created by 7Up on 2023/7/27.
//

#if !LARK_NO_DEBUG
import Foundation

public enum FileSizeUnit: String {
    case B, KB, MB, GB

    public var count: Int {
        switch self {
        case .B: return 0x1
        case .KB: return 0x400
        case .MB: return 0x100000
        case .GB: return 0x40000000
        }
    }
}

public struct FileSize: CustomStringConvertible {
    public let count: Int
    public let unit: FileSizeUnit

    struct ParseFailed: Swift.Error, CustomStringConvertible {
        var description: String
        init(_ desc: String) {
            description = desc
        }
    }

    public init(_ count: Int, _ unit: FileSizeUnit) {
        self.count = count
        self.unit = unit
    }

    public static func parse(from str: String) throws -> Self {
        let arr = str.components(separatedBy: CharacterSet.whitespaces).filter { !$0.isEmpty }
        guard arr.count == 2 else {
            throw ParseFailed(str)
        }
        let countStr = arr[0]
        let unitStr = arr[1]
        guard
            let count = Int(countStr), count > 0,
            let unit = FileSizeUnit(rawValue: unitStr)
        else {
            throw ParseFailed(str)
        }

        return .init(count, unit)
    }

    public var description: String {
        return "\(count)\(unit)"
    }
}


public func createCustomFile(atPath path: String, size: FileSize, completon: @escaping () -> Void) throws {
    let times, bufferCount: Int

    switch size.unit {
    case .B, .KB, .MB:
        times = size.count
        bufferCount = size.unit.count
    case .GB:
        times = size.count * 1024
        bufferCount = FileSizeUnit.MB.count
    }

    if !FileManager.default.fileExists(atPath: path) {
        FileManager.default.createFile(atPath: path, contents: nil)
    }
    let pathUrl = URL(fileURLWithPath: path, isDirectory: false)
    let handle = try FileHandle(forUpdating: pathUrl)
    DispatchQueue.global().async {
        let buffer = Data(repeating: 0, count: bufferCount)
        for _ in 0..<times {
            handle.seekToEndOfFile()
            handle.write(buffer)
        }
        handle.closeFile()
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            completon()
        }
    }
}

#endif
