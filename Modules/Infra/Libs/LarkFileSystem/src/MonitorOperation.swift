//
//  MonitorOperation.swift
//  CryptoSwift
//
//  Created by PGB on 2020/3/17.
//

import Foundation
import LKCommonsTracker
import LKCommonsLogging
import Heimdallr

public protocol MonitorOperation {
    func operate(files: [FileItem]) -> Void
}

public class LogFiles: MonitorOperation {
    public func operate(files: [FileItem]) {
        var lines: [(level: Int, log: String)] = []
        for item in files {
            let parts = item.path.split(separator: "/")
            var path = item.path
            if !item.isDir, let last = parts.last {
                // 替换文件名
                var filename = String(last)
                if let pointIndex = filename.lastIndex(of: ".") {
                    filename = "File" + filename[pointIndex ..< filename.endIndex]
                } else {
                    filename = "File"
                }

                if let slashIndex = path.lastIndex(of: "/") {
                    path = path[path.startIndex ... slashIndex] + filename
                }
            }
            let type = item.isDir ? "Folder" : "File"
            let line = item.size.formattedSize + "\t" + type + "\t" + path
            lines.append((parts.count, line))
        }

        var log = "Log files result:\n"
        for (_, line) in lines.sorted(by: { $0.level < $1.level }) {
            log += line + "\n"
        }
        LarkDiskMonitor.logger.info(log)
    }
}

public class TrackEvent: MonitorOperation {
    public func operate(files: [FileItem]) {
        var matrix: [String: Double] = [:]
        for file in files {
            matrix[file.trackName] = matrix[file.trackName, default: 0] + file.size.megaByteFormat
        }
        Tracker.post(SlardarEvent(
            name: LarkDiskMonitor.eventName,
            metric: matrix,
            category: [:],
            extra: [:])
        )
    }
}

public class RaiseCustomException: MonitorOperation {
    public func operate(files: [FileItem]) {
        for file in files {
            HMDUserExceptionTracker.shared().trackUserException(withExceptionType: "DiskAbnormalFile", title: file.trackName, subTitle: "", customParams: nil, filters: nil, callback: { _ in })
        }
    }
}
