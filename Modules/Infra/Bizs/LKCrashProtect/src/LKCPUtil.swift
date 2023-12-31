//
//  LKCPUtil.swift
//  LKCrashProtect
//
//  Created by sniperj on 2020/7/27.
//

import Foundation
import MMKV

let fatalSignals: [Int32] = [SIGABRT, SIGBUS, SIGFPE, SIGILL, SIGPIPE, SIGSEGV, SIGSYS, SIGTRAP]
/// when app crash recive signal
/// - Parameter signal: signal
func signalExceptionHandler(signal: Int32) {
    LKCPProxy.sharedInterface.utilArray.forEach { (util) in
        util.onSignalCrash(signal: signal)
    }
    exit(1)
}

class LKCPProxy {
    static let sharedInterface = LKCPProxy()
    var utilArray: [LKCPUtil] = []
    init() {
        monitorExcepitonSignal()
    }

    /// monitor excepiton signal
    func monitorExcepitonSignal() {
        fatalSignals.forEach { (sigNum) in
            signal(sigNum, signalExceptionHandler)
        }
    }

    func registCPUtil(by typeKey: String) -> LKCPUtil {
        let util = LKCPUtil(with: typeKey)
        utilArray.append(util)
        return util
    }
}

struct LKCPInfo {
    let key: String
    let threadID: UInt64
}

/// crash protect base util
class LKCPUtil {
    let typeKey: String
    var hasCrashKV: MMKV?
    var mayHasCrashKV: MMKV?
    var isLastTimeCrashed: Bool?
    var runloopsCPKeys: [LKCPInfo]
    var whiteList: [String: Bool]
    var currIncreaseCPKeys: [String: Int]
    var lock: os_unfair_lock = os_unfair_lock_s()

    var singleMark: Int32 = 0x64
    var mayCrashMark: Int32 = 0x96

    init(with typeKey: String) {
        MMKV.initialize(rootDir: nil)
        runloopsCPKeys = []
        whiteList = [:]
        currIncreaseCPKeys = [:]
        self.typeKey = typeKey
        checkKVIsValid()
        checkMayCrashAndMarkAsHasCrash()
    }

    /// setup custom config
    /// - Parameter type: CPType is String
    func setup() {
        //拉取白名单配置

    }

    /// Determine whether the string is safe
    /// For external use
    /// - Parameter key: key
    func isUnSafeKey(key: String) -> Bool {
        if !key.isEmpty {
            return getHasCrashKV()?.bool(forKey: key) ?? false
        }
        return false
    }

    /// Mark this string when rendering starts
    /// For external use
    /// - Parameter key: key
    func increaseCrashCountWithKey(key: String) {
        if key.isEmpty != true {
            os_unfair_lock_lock(&lock)
            if !checkKeyIsValid(key: key) {
                os_unfair_lock_unlock(&lock)
                return
            }
            let info = LKCPInfo(key: key, threadID: UInt64(mach_thread_self()))
            let num = currIncreaseCPKeys[key]
            if let num = num,
                num >= 1 {
                currIncreaseCPKeys[key] = num + 1
            } else {
                currIncreaseCPKeys[key] = 1
                let kv = getMayCrashKV()
                let value = kv?.int32(forKey: key) ?? 0
                kv?.set(value + singleMark, forKey: key)
            }
            runloopsCPKeys.append(info)
            os_unfair_lock_unlock(&lock)
        }
    }

    /// Mark this string when rendering end
    /// For external use
    /// - Parameter key: key
    func decreaseCrashCountWithKey(key: String) {
        if key.isEmpty != true {
            os_unfair_lock_lock(&lock)
            if !checkKeyIsValid(key: key) {
                os_unfair_lock_unlock(&lock)
                return
            }
            removeInfo(with: key, threadID: UInt64(mach_thread_self()))
            let num = currIncreaseCPKeys[key] ?? 0
            if num < 2 {
                if num == 1 {
                    currIncreaseCPKeys.removeValue(forKey: key)
                    let value = getMayCrashKV()?.int32(forKey: key) ?? 0
                    if value > 0 {
                        getMayCrashKV()?.set(value - singleMark, forKey: key)
                        if value - singleMark == 0 {
                            whiteList[key] = true
                        }
                    }
                }
            } else {
                currIncreaseCPKeys[key] = (currIncreaseCPKeys[key] ?? 0) + 1
            }
            os_unfair_lock_unlock(&lock)
        }
    }

    /// remove info with key and threadID
    /// - Parameters:
    ///   - key: key
    ///   - threadID: threadID
    func removeInfo(with key: String, threadID: CUnsignedLongLong) {
        runloopsCPKeys = runloopsCPKeys.filter { (info) -> Bool in
            if info.key == key {
                if threadID == info.threadID {
                    return false
                }
            }
            return true
        }
    }

    /// decrease current increaseCPKeys
    /// - Parameter keys: not decrease keys
    func decreaseCurrIncreaseCPKeys(without keys: [String]?) {
        os_unfair_lock_lock(&lock)
        currIncreaseCPKeys.keys.forEach { (key) in
            if let keys = keys,
                !keys.contains(key) {
            } else {
                getMayCrashKV()?.removeValue(forKey: key)
            }
        }
        os_unfair_lock_unlock(&lock)
    }

    /// check KV is valid
    func checkKVIsValid() {
        let defaultKV = MMKV.default()
        let recordTime = defaultKV?.double(forKey: "CPDataRecordTime\(typeKey)")
        let date = Date().timeIntervalSince1970
        if let time = recordTime,
            date - time >= 60 * 60 * 24 * 7 {
            getHasCrashKV()?.clearAll()
            getMayCrashKV()?.clearAll()
        }
        defaultKV?.set(date, forKey: "CPDataRecordTime\(typeKey)")
    }

    /// Mark what can become hasCrash in MayCrashList as hasCash
    func checkMayCrashAndMarkAsHasCrash() {
        var needRemoveList: [String] = []
        let hasCrashKV = getHasCrashKV()
        let mayCrashKV = getMayCrashKV()
        mayCrashKV?.enumerateKeys({ (key, _) in
            let value = mayCrashKV?.int32(forKey: key)
            if let temp = value,
                temp >= self.mayCrashMark {
                hasCrashKV?.set(true, forKey: key)
                needRemoveList.append(key)
            }
        })
    }

    /// check key is valid key
    /// - Parameter key: key
    func checkKeyIsValid(key: String) -> Bool {
        if whiteList[key] != nil || getHasCrashKV()?.bool(forKey: key) ?? false {
            return false
        }
        return true
    }

    /// check memory mapkv is valid
    func isMemoryMappedKVValid() -> Bool {
        if MMKV.isFileValid(for: "hasCrashKV\(typeKey)"),
            MMKV.isFileValid(for: "mayHasCrashKV\(typeKey)") {
            return true
        }
        return false
    }

    /// crash callback
    /// - Parameter info: siginfo
    func onSignalCrash(signal: Int32) {
        os_unfair_lock_lock(&lock)
        let lastKey = getLastKey(from: UInt64(mach_thread_self()))
        os_unfair_lock_unlock(&lock)
        if let tempKey = lastKey,
            signal != 4 {
            if isLastTimeCrashedBySpecial() {
                getHasCrashKV()?.set(true, forKey: tempKey)
                getMayCrashKV()?.removeValue(forKey: tempKey)
                decreaseCurrIncreaseCPKeys(without: nil)
            } else {
                decreaseCurrIncreaseCPKeys(without: [tempKey])
            }
            //此处使用userdefault的原因是因为不确定MMKV的稳定性，并且wx内部也是这样使用的
            UserDefaults.standard.set(true, forKey: "CrashBySpecial\(typeKey)")
            UserDefaults.standard.synchronize()
        } else {
            UserDefaults.standard.removeObject(forKey: "CrashBySpecial\(typeKey)")
        }
    }

    /// when user force kill app callback
    func onExit() {
        decreaseCurrIncreaseCPKeys(without: nil)
    }

    /// get last key from runloopCPKeys with threadID
    /// - Parameter threadID: threadID
    func getLastKey(from threadID: CUnsignedLongLong) -> String? {
        if runloopsCPKeys.count >= 1 {
            for info in runloopsCPKeys where info.threadID == threadID {
                return info.key
            }
        }
        return nil
    }

    func isLastTimeCrashedBySpecial() -> Bool {
        if isLastTimeCrashed != nil {
            return isLastTimeCrashed ?? false
        }
        let res = UserDefaults.standard.bool(forKey: "CrashBySpecial\(typeKey)")
        if false == res {
            isLastTimeCrashed = false
        } else {
            isLastTimeCrashed = self.isMemoryMappedKVValid()
        }
        return isLastTimeCrashed ?? false
    }

    /// get hasCrash KV
    func getHasCrashKV() -> MMKV? {
        if hasCrashKV == nil {
            hasCrashKV = MMKV(mmapID: "hasCrashKV\(typeKey)")
        }
        return hasCrashKV
    }

    /// get may crash KV
    func getMayCrashKV() -> MMKV? {
        if mayHasCrashKV == nil {
            mayHasCrashKV = MMKV(mmapID: "getMayCrashKV\(typeKey)")
        }
        return mayHasCrashKV
    }
}
