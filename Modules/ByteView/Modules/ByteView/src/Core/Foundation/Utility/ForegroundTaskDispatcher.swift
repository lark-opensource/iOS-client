//
//  ForegroundTaskDispatcher.swift
//  ByteView
//
//  Created by fakegourmet on 2023/5/16.
//

import Foundation

final class ForegroundTaskDispatcher {

    typealias Task = (() -> Void)?

    private static var _shared: ForegroundTaskDispatcher?

    static var shared: ForegroundTaskDispatcher {
        guard let shared = _shared else {
            let new = ForegroundTaskDispatcher()
            _shared = new
            return new
        }
        return shared
    }

    private var tasks: [Task] = []

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        Logger.util.info("\(#function)")
    }

    deinit {
        Logger.util.info("\(#function)")
    }

    func execute(_ task: Task) {
        Util.runInMainThread { [weak self] in
            if UIApplication.shared.applicationState == .background {
                self?.tasks.append(task)
            } else {
                task?()
            }
        }
    }

    @objc
    private func willEnterForeground() {
        tasks.forEach {
            $0?()
        }
        Self.destory()
    }

    private static func destory() {
        _shared = nil
    }
}
