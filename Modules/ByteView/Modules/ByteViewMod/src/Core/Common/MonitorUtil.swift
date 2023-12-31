//
//  MonitorUtil.swift
//  ByteViewMod
//
//  Created by kiri on 2023/2/3.
//

import Foundation
import ByteViewCommon

final class MonitorUtil {
    @discardableResult
    static func run<T>(_ taskName: String, file: String = #fileID, function: String = #function, line: Int = #line,
                       execute block: () throws -> T) -> T? {
        let startTime = CACurrentMediaTime()
        do {
            let obj = try block()
            let duration = CACurrentMediaTime() - startTime
            Queue.logger.async {
                Logger.monitor.info("execute task success: \(taskName), duration = \(Util.formatTime(duration))",
                                    file: file, function: function, line: line)
            }
            return obj
        } catch {
            let duration = CACurrentMediaTime() - startTime
            Queue.logger.async {
                Logger.monitor.error("execute task failed: \(taskName), duration = \(Util.formatTime(duration)), error = \(error)", file: file, function: function, line: line)
            }
            return nil
        }
    }
}
