//
//  FileLogHandler.swift
//  LarkExtensionServices
//
//  Created by 王元洵 on 2021/3/23.
//

import UIKit
import Foundation
import LarkStorageCore

/// 日志的路径
public func logBasePath() -> IsoPath? {
    let domain = Domain.biz.infra.child("Log")
    guard let path = IsoPath.in(space: .global, domain: domain).buildShared(relativePart: "logs") else {
        return nil
    }
    // 迁移旧路径
    if let oldPath = AbsPath.sharedRoot.map { $0 + "logs" }, oldPath.exists, !path.exists {
        try? path.notStrictly.moveItem(from: oldPath)
    }
    return path
}

/// 默认的文件日志输出类
final class FileLogHandler: NSObject, LogHandler {
    private let maxBufferSize = AppConfig.logBufferSize
    private var currentBufferCount = 0
    private let logDirPath: IsoPath? = logBasePath()

    private var _currentSimpleLogger: SimpleLog?
    private var currentSimpleLooger: SimpleLog? {
        guard AppConfig.logEnable else { return nil }
        if _currentSimpleLogger != nil {
            return _currentSimpleLogger
        }
        let logger = getSimpleLoggerByDay()
        _currentSimpleLogger = logger
        return logger
    }

    var presentedItemOperationQueue = OperationQueue()

    override init() {
        super.init()
        self.presentedItemOperationQueue.maxConcurrentOperationCount = 1
        createLogDirIfNeeded()
        registerAppStateChangeNotification()
    }

    func log(eventMessage: Logger.Message) {
        guard AppConfig.logEnable else { return }
        self.writeInfoToSimpleLogger("\(eventMessage)")
    }

    private func createLogDirIfNeeded() {
        do {
            try logDirPath?.createDirectoryIfNeeded()
        } catch {
            assertionFailure("Log path is illegally, error \(error)")
        }
    }

    private func writeInfoToSimpleLogger(_ info: String) {
        self.presentedItemOperationQueue.addOperation { [weak self] in
            guard let `self` = self else { return }
            self.currentSimpleLooger?.write(msg: info)
            self.currentBufferCount += 1
            if self.currentBufferCount >= self.maxBufferSize {
                self.currentSimpleLooger?.flush()
                self.currentBufferCount = 0
            }
        }
    }

    private func getSimpleLoggerByDay() -> SimpleLog? {
        guard let dirPath = self.logDirPath else { return nil }

        let name = "extension-\(ProcessInfo.processInfo.processIdentifier)"
        return SimpleLog(path: dirPath.absoluteString, name: name, version: "1")
    }

    private func registerAppStateChangeNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(
                                                applicationEnterBackgroundOrTerminate(notification:)),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(
                                                applicationEnterBackgroundOrTerminate(notification:)),
                                               name: UIApplication.willTerminateNotification,
                                               object: nil)
    }

    @objc
    private func applicationEnterBackgroundOrTerminate(notification: NSNotification) {
        guard AppConfig.logEnable else { return }
        self.presentedItemOperationQueue.addOperation { [weak self] in
            guard let `self` = self else { return }
            self.currentSimpleLooger?.flush()
            self.currentBufferCount = 0
        }
    }
}
