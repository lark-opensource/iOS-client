//
//  AudioQueue.swift
//  LarkMedia
//
//  Created by kiri on 2022/11/30.
//

import Foundation
import AVFoundation

struct AudioQueue {
    static let execute = AudioQueue(tag: "execute", queue: DispatchQueue(label: "larkmedia.audio.execute"))
    static let callback = AudioQueue(tag: "callback", queue: DispatchQueue(label: "larkmedia.audio.callback"))

    private let tag: String
    let queue: DispatchQueue
    private init(tag: String, queue: DispatchQueue) {
        self.tag = tag
        self.queue = queue
    }

    func async(_ taskName: String,
               file: String = #fileID, function: String = #function, line: Int = #line,
               execute block: @escaping () -> Void) {
        queue.async(execute: taskItem(taskName, file: file, function: function, line: line, block: block))
    }

    func async(_ taskName: String, delay: DispatchTimeInterval,
               file: String = #fileID, function: String = #function, line: Int = #line,
               execute block: @escaping () -> Void) {
        queue.asyncAfter(deadline: .now() + delay, execute: taskItem(taskName, file: file, function: function, line: line, block: block))
    }

    private func taskItem(_ taskName: String, file: String, function: String, line: Int, block: @escaping () -> Void) -> DispatchWorkItem {
        return DispatchWorkItem {
            let t0 = CACurrentMediaTime()
            block()
            let duration = round((CACurrentMediaTime() - t0) * 1e6) / 1e3
            if duration > 1000 {
                LarkAudioSession.logger.warn("[\(tag)] AudioSession timeout: \(taskName), duration = \(duration)ms",
                                             file: file, function: function, line: line)
            }
        }
    }
}
