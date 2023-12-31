//
//  CallKitQueue.swift
//  ByteView
//
//  Created by kiri on 2023/6/14.
//

import Foundation

final class CallKitQueue {
    private static let testQueueKey = DispatchSpecificKey<Void>()
    static let queue: DispatchQueue = {
        let queue = DispatchQueue(label: "lark.byteview.callkit", qos: .userInteractive)
        queue.setSpecific(key: testQueueKey, value: ())
        return queue
    }()

    static func assertCallKitQueue() {
        assert(DispatchQueue.getSpecific(key: testQueueKey) != nil)
    }
}
