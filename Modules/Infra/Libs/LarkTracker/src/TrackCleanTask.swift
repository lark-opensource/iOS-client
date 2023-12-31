//
//  TrackCleanTask.swift
//  LarkTracker
//
//  Created by 王元洵 on 2022/09/08.
//

// swiftlint:disable no_space_in_method_call

import UIKit
import Foundation
import LarkCache
import LKCommonsLogging
import LarkReleaseConfig
import LarkStorage

/// 埋点数据清理任务，仅用于极端情况下RangersAppLog自己的清理任务失败导致埋点数据文件过大的情况
struct TrackCleanTask: CleanTask {
    private static let logger = Logger.log(TrackCleanTask.self, category: "TrackCleanTask")

    private let trackerDataDir = AbsPath.library + "._tob_applog_docu/\(ReleaseConfig.appId)"

    let name = "TrackCleanTask"

    private func fileSize(of path: String) -> Int {
        (try? FileManager.default.attributesOfItem(atPath: path)[.size] as? Int) ?? 0
    }

    // 只清理极端情况的文件（埋点数据库文件大于500M）
    private func calculateBytesForCleaning(needsClean: Bool) throws -> Int {
        let children: [AbsPath] = try trackerDataDir.childrenOfDirectory(recursive: false)
        var totalBytes = 0
        for path in children {
            guard let fileSize = path.fileSize, fileSize > 500 * 1_024 * 1_024 else { continue }
            if needsClean {
                do {
                    try path.notStrictly.removeItem()
                    totalBytes += Int(fileSize)
                } catch {
                    Self.logger.error("clean track data failed at: \(path.absoluteString)", error: error)
                }
            } else {
                totalBytes += Int(fileSize)
            }
        }
        return totalBytes
    }

    func clean(config: CleanConfig, completion: @escaping Completion) {
        let startTime = CACurrentMediaTime()
        DispatchQueue.global().async {
            do {
                let bytesSize = try calculateBytesForCleaning(needsClean: true)
                completion(
                    .init(
                        completed: true,
                        costTime: Int((CACurrentMediaTime() - startTime) * 1_000),
                        size: .bytes(bytesSize)
                    )
                )
            } catch {
                Self.logger.error("\(trackerDataDir) clean track data failed! ", error: error)
                completion(
                    .init(
                        completed: true,
                        costTime: Int((CACurrentMediaTime() - startTime) * 1_000),
                        size: .bytes(0)
                    )
                )
            }
        }
    }

    func size(config: CleanConfig, completion: @escaping Completion) {
        let startTime = CACurrentMediaTime()
        DispatchQueue.global().async {
            do {
                let bytesSize = try calculateBytesForCleaning(needsClean: false)
                completion(
                    .init(
                        completed: true,
                        costTime: Int((CACurrentMediaTime() - startTime) * 1_000),
                        size: .bytes(bytesSize)
                    )
                )
            } catch {
                Self.logger.error("\(trackerDataDir) calculate track data size failed! ", error: error)
                completion(
                    .init(
                        completed: true,
                        costTime: Int((CACurrentMediaTime() - startTime) * 1_000),
                        size: .bytes(0)
                    )
                )
            }
        }
    }
}
