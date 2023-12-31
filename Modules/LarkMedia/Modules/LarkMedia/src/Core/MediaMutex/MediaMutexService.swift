//
//  MediaMutexService.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/8/3.
//

import Foundation

public protocol MediaMutexService {
    /// 获取音视频资源
    /// - Parameter scene: 媒体业务场景
    /// - Returns: `LarkMediaResource`
    /// 若当前未获取资源锁，返回 nil
    func getMediaResource(for scene: MediaMutexScene) -> LarkMediaResource?

    /// 请求使用音视频资源
    /// - Parameter scene: 媒体业务场景
    /// - Parameter options: 进阶选项，可选
    /// - Parameter observer: 注册打断观察者，可选
    /// - Parameter completion: 回调
    /// - 成功，回调 `success`。若当前为低优先级 scene，则先打断当前 scene
    /// - 失败，回调 `failure`。错误类型为 `MediaMutexError`
    /// - 如果当前 scene 已经激活中，会直接返回 `success`，配置遵从第一次 tryLock 的配置
    /// - 如果 scene 相同，observer 相同，trylock 跳过，直接返回成功
    /// - 如果 scene 相同，observer 不同，也会执行打断逻辑
    /// - 回调线程为 Global 线程
    func tryLock(scene: MediaMutexScene, options: MediaMutexOptions, observer: MediaResourceInterruptionObserver?, completion: @escaping (MediaMutexCompletion) -> Void)

    /// 同步请求使用音视频资源
    /// - Parameter scene: 媒体业务场景
    /// - Parameter options: 进阶选项，可选
    /// - Parameter observer: 注册打断观察者，可选
    /// - Returns: `MediaMutexCompletion`
    /// - 成功，回调 `success`。若当前为低优先级 scene，则先打断当前 scene
    /// - 失败，回调 `failure`。错误类型为 `MediaMutexError`
    /// - 如果当前 scene 已经激活中，会直接返回 `success`，配置遵从第一次 tryLock 的配置
    /// - 如果 scene 相同，observer 相同，trylock 跳过，直接返回成功
    /// - 如果 scene 相同，observer 不同，也会执行打断逻辑
    func tryLock(scene: MediaMutexScene, options: MediaMutexOptions, observer: MediaResourceInterruptionObserver?) -> MediaMutexCompletion

    /// 请求释放音视频资源
    /// - Parameter scene: 媒体业务场景
    /// 如果同一个 scene 在当前队列存在多个实例，会根据 observer 进行 unlock
    /// 如果 observer 传 nil，会将当前 scene 关联的所有 observer 移除
    func unlock(scene: MediaMutexScene, options: MediaMutexOptions)

    /// 更新权限状态
    /// - priority 传 nil 时表示取消对应权限
    /// - 该方法只会影响当前使用中的 scene，如果不在使用中则调用无效
    /// - 如果无法取得更高权限也会无效
    /// - record、play 当前不支持 update
    /// - ⚠️注意！调用该方法之前需要找相关负责人评估
    func update(scene: MediaMutexScene, mediaType: MediaMutexType, priority: MediaMutexPriority?)
}

public protocol MediaResourceInterruptionObserver: AnyObject {
    /// 开始打断
    /// 只对占用中并被打断的业务发送
    /// - Scene: 打断者
    /// - type: 具体被打断的媒体类型
    /// - msg: 打断通用文案
    func mediaResourceWasInterrupted(by scene: MediaMutexScene, type: MediaMutexType, msg: String?)

    /// 打断结束
    /// 只对被打断的业务发送
    /// - Scene: 打断结束者
    /// - type: 具体被释放的媒体类型
    func mediaResourceInterruptionEnd(from scene: MediaMutexScene, type: MediaMutexType)
}

public struct MediaMutexScene: Hashable, CustomStringConvertible {
    public private(set) var rawValue: String
    /// 唯一标识符
    /// 用于单 scene 多实例的情况
    /// 标识符由使用方定义
    public private(set) var id: String

    public init(rawValue: String, id: String = "") {
        self.rawValue = rawValue
        self.id = id
    }

    public var description: String {
        if id.isEmpty {
            return rawValue
        } else {
            return "\(rawValue)_\(id)"
        }
    }
}

public struct MediaMutexType: RawRepresentable, Hashable, CustomStringConvertible {
    public var rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let record = MediaMutexType(rawValue: "record")
    public static let camera = MediaMutexType(rawValue: "camera")
    public static let play = MediaMutexType(rawValue: "play")

    public var description: String {
        rawValue
    }
}

public enum MediaMutexError: Error {
    case unknown
    /// 媒体资源被其他 scene 占用
    /// - scene: 当前占用的场景
    /// - msg: 通用错误文案
    case occupiedByOther(MediaMutexScene, String?)
    /// scene 未配置
    case sceneNotFound
}

public enum MediaMutexPriority: UInt, Comparable, CustomStringConvertible {
    case low
    case `default`
    case medium
    case high

    public static func < (lhs: MediaMutexPriority, rhs: MediaMutexPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var description: String {
        switch self {
        case .low:      return "low"
        case .default:  return "default"
        case .medium:   return "medium"
        case .high:     return "high"
        }
    }
}

public struct MediaMutexOptions: OptionSet {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// 用于让播放共存
    /// 当且仅当播放池中所有 scene 都开启该选项时才能共存
    public static let mixWithOthers = MediaMutexOptions(rawValue: 1 << 0)

    /// `tryLock` 时带上该选项会自动关闭摄像头权限
    /// 适用于摄像头权限动态变化的 scene
    public static let onlyAudio = MediaMutexOptions(rawValue: 1 << 1)

    /// `unLock` 时带上该选项会自动释放对应 `MediaMutexScene` 的所有 `AudioSessionScenario`
    public static let leaveScenarios = MediaMutexOptions(rawValue: 1 << 2)
}

public typealias MediaMutexCompletion = Result<LarkMediaResource, MediaMutexError>
