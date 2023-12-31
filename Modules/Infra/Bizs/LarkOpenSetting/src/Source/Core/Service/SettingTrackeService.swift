//
//  SettingTrackeService.swift
//  LarkOpenSetting
//
//  Created by panbinghua on 2022/8/3.
//

import Foundation

public final class SettingTrackeService {
    public enum ActionType {
        case get
        case set
        case custom(String)

        var description: String {
            switch self {
            case .get: return "get"
            case .set: return "set"
            case .custom(let str): return str
            }
        }
    }

    public struct TrackInfo: CustomStringConvertible {
        public let settingName: String
        public let action: String
        public let duration: TimeInterval
        public let module: String
        public let errorCode: Int
        public let errorMsg: String
        public let from: String

        public init(settingName: String, action: ActionType, fromRemote: Bool = true,
                    duration: TimeInterval,
                    module: String,
                    errorCode: Int = 0, errorMsg: String = "") {
            self.settingName = settingName
            self.action = action.description
            self.module = module
            self.duration = duration
            self.errorCode = errorCode
            self.errorMsg = errorMsg
            self.from = fromRemote ? "remote" : "local"
        }

        public var description: String {
            "Setting TrackInfo: \(module) \(action) \(settingName) from \(from) duration: \(duration * 1_000)ms error: \(errorCode) \(errorMsg)"
        }
    }

    static let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "SettingKVStore.track"
        queue.qualityOfService = .background
        return queue
    }()

    static private var _track: (_ info: TrackInfo) -> Void = { _ in }

    static public func registerTrackHandler(handler: @escaping (_ info: TrackInfo) -> Void) {
        Self._track = handler
    }

    static public func track(settingName: String, action: ActionType, fromRemote: Bool = true,
                             duration: TimeInterval,
                             module: String,
                             errorCode: Int = 0, errorMsg: String = "") { // 给外部调用
        let info = TrackInfo(settingName: settingName, action: action, fromRemote: fromRemote,
                             duration: duration, module: module, errorCode: errorCode, errorMsg: errorMsg)
        SettingTrackeService.queue.addOperation {
            SettingTrackeService._track(info)
        }
    }
}
