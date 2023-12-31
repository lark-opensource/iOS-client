//
//  GrootPushNotifier.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/15.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewTracker

public protocol GrootCellNotifierProtocol: GrootCellHandler {
    associatedtype CellType
    associatedtype Observer

    init(channel: GrootChannel)

    var channel: GrootChannel { get }
    func addObserver(_ observer: Observer)
    func removeObserver(_ observer: Observer)
}

public class GrootCellNotifier<CellType: NetworkDecodable, Observer>: GrootCellNotifierProtocol {
    private let logger = Logger.groot
    private let observers = Listeners<Observer>()
    public let channel: GrootChannel
    public required init(channel: GrootChannel) {
        self.channel = channel
    }

    public func processGrootCells(_ cells: [GrootCell]) {
        let startTime = CACurrentMediaTime()
        Queue.groot.async { [weak self] in
            guard let self = self else {
                return
            }

            let t0 = CACurrentMediaTime()
            let logId = "[groot][\(self.channel.type)]"

            if self.observers.isEmpty {
                self.logger.info("\(logId) ignored. observers isEmpty")
                return
            }
            let latency = t0 - startTime
            if latency > 2 {
                self.logger.warn("\(logId) wait too long, latency = \(Util.formatTime(latency))")
            }

            do {
                self.logger.info("\(logId) start, latency = \(Util.formatTime(latency))")
                let message = try cells.map({ try CellType.init(serializedData: $0.payload) })
                let senders = cells.map( { $0.sender })
                if self.channel.type == .sketch, !senders.isEmpty {
                    self.observers.forEach {
                        self.dispatch(message: message, sender: senders, to: $0)
                    }
                } else {
                    self.observers.forEach {
                        self.dispatch(message: message, to: $0)
                    }
                }
                let duration = CACurrentMediaTime() - t0
                if duration > 2 {
                    self.logger.warn("\(logId) process too long, duration = \(Util.formatTime(duration)), message = \(message)")
                } else {
                    self.logger.info("\(logId) process finished, duration = \(Util.formatTime(duration)), message = \(message)")
                }
            } catch {
                let duration = CACurrentMediaTime() - t0
                self.logger.error("\(logId) process failed: deserialization failed, duration = \(Util.formatTime(duration)), error = \(error)")
            }
        }
    }

    /// for implement
    func dispatch(message: [CellType], to observer: Observer) {
        assertionFailure("methodNotImplemented!")
    }

    // optional
    func dispatch(message: [CellType], sender: [ByteviewUser?], to observer: Observer) {}
}

public extension GrootCellNotifier {
    func addObserver(_ observer: Observer) {
        observers.addListener(observer)
    }

    func removeObserver(_ observer: Observer) {
        observers.removeListener(observer)
    }
}

private extension Queue {
    /// 推送，qos = userInitiated
    static let groot = DispatchQueue(label: "ByteView.PushQueue.Groot", qos: .userInitiated)
}
