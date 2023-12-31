//
//  InMeetAsyncActionHolder.swift
//  ByteView
//
//  Created by kiri on 2021/5/11.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 在异步操作完成前持有action对象，以保证action可以独立完成，而不需要依附于除InMeetAsyncActionHolder以外的其它对象。
/// - 请使用InMeetAsyncActionHolder.current 
final class InMeetAsyncActionHolder {
    private let lock = NSLock()
    private var objects: [ObjectIdentifier: AnyObject] = [:]
    let meetingId: String
    init(meetingId: String) {
        self.meetingId = meetingId
    }

    func hold(_ object: AnyObject) {
        lock.lock()
        defer { lock.unlock() }
        let key = ObjectIdentifier(object)
        self.objects[key] = object
        #if DEBUG
        Util.observeDeinit(object)
        #endif
    }

    func remove(_ object: AnyObject) {
        lock.lock()
        defer { lock.unlock() }
        self.objects.removeValue(forKey: ObjectIdentifier(object))
    }

    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        self.objects.removeAll()
    }
}
