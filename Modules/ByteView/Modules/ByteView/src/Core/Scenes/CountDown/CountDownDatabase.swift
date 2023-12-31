//
//  CountDownDatabase.swift
//  ByteView
//
//  Created by wulv on 2022/5/5.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

final class CountDownDatabase {
    let storage: UserStorage
    init(storage: UserStorage) {
        self.storage = storage
    }

    var foldBoard: Bool {
        get {
            let local = storage.bool(forKey: .dbFoldBoard)
            Logger.countDown.info("is fold: \(local), key: dbFoldBoard")
            return local
        }
        set {
            Logger.countDown.info("is fold update: \(newValue), key: dbFoldBoard")
            storage.set(newValue, forKey: .dbFoldBoard)
        }
    }

    /// If the specified key doesn‘t exist, this method returns 0.
    var lastSetMinute: Int {
        get {
            let local = storage.int(forKey: .dbLastSetMinute)
            Logger.countDown.info("last set minute: \(local)")
            return local
        }
        set {
            Logger.countDown.info("save set minute: \(newValue)")
            storage.set(newValue, forKey: .dbLastSetMinute)
        }
    }

    /// 用-1标记不启用，1标记启用，0表示未设置
    var isEndAudioEnabled: Int {
        get {
            let local = storage.int(forKey: .dbEndAudio)
            Logger.countDown.info("end audio enabled: \(local)")
            return local
        }
        set {
            Logger.countDown.info("save end audio enabled: \(newValue)")
            storage.set(newValue, forKey: .dbEndAudio)
        }
    }

    /// 用-1标记不启用，非0标记启用值
    var lastRemindMinute: Int {
        get {
            let local = storage.int(forKey: .dbLastRemind)
            Logger.countDown.info("last remind minute: \(local)")
            return local
        }
        set {
            Logger.countDown.info("save remind minute: \(newValue)")
            storage.set(newValue, forKey: .dbLastRemind)
        }
    }
}
