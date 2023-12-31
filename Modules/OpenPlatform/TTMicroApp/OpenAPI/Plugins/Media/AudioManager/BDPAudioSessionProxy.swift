//
//  BDPAudioSessionProxy.swift
//  Timor
//
//  Created by zhysan on 2020/12/30.
//

// 问题背景：https://bytedance.feishu.cn/docs/doccnYPUufoktWu08yKbcbVbXbO#
// 相关文档一：https://bytedance.feishu.cn/docs/doccne8SLJpqcLG1oImhBshxhNe
// 相关文档二：https://bytedance.feishu.cn/docs/doccnRztUGWQNJsPCRb9sOuU9cd
// 预期将开放平台 Audio Session 的模式切换收敛到此类中，统一使用飞书音频框架 AudioSessionScenario 来管理

import Foundation
import LarkMedia
import LKCommonsLogging
import LarkSetting

/// AudioSessionScenario 的 Objc 桥接类
@objcMembers 
public final class BDPScenarioObj: NSObject {
    /// scenario 的唯一标识，同一个场景保持唯一
    public let name: String
    public let category: AVAudioSession.Category
    public let mode: AVAudioSession.Mode
    public let options: AVAudioSession.CategoryOptions
    
    public init(name: String,
                category: AVAudioSession.Category,
                mode: AVAudioSession.Mode = .default,
                options: AVAudioSession.CategoryOptions = []) {
        self.name = name
        self.category = category
        self.mode = mode
        self.options = options
        super.init()
    }
    
    override public var description: String {
        "\(name)"
    }
}

private extension BDPScenarioObj {
    func scenario() -> AudioSessionScenario {
        return AudioSessionScenario(self.name,
                                    category: self.category,
                                    mode: self.mode,
                                    options: self.options)
    }
}

@objcMembers
public final class BDPAudioSessionProxy: NSObject {
    
    /// logger
    private static let logger = Logger.oplog(BDPAudioSessionProxy.self, category: "BDPAudioSessionProxy")
    
    @RealTimeFeatureGating(key: "openplatform.api.fix_audio_session_async_operation_enabled") private static var fixAudioSessionAsyncOperationEnabled: Bool
    
    private static let semaphore = DispatchSemaphore(value: 0)
    private static let queue = DispatchQueue(label: "com.openplatform.BDPAudioSessionProxy", qos: .userInteractive)

    /// 激活指定的音频场景
    public static func entry(obj: BDPScenarioObj, scene: OPMediaMutexScene, observer: OPMediaResourceInterruptionObserver? = nil) {
        logger.info("BDPAudioSessionProxy entry: \(obj)")
        if fixAudioSessionAsyncOperationEnabled {
            OPMediaMutex.enter(scenario: obj.scenario(), scene: scene, observer: observer)
            LarkAudioSession.shared.waitAudioSession("BDPAudioSessionProxy.entry") {
                queue.async { semaphore.signal() }
            }
            semaphore.wait()
        } else {
            OPMediaMutex.enter(scenario: obj.scenario(), scene: scene, observer: observer)
        }
    }
    
    /// 离开指定的音频场景
    public static func leave(obj: BDPScenarioObj, scene: OPMediaMutexScene, wrapper: OPMediaMutexObserveWrapper? = nil) {
        logger.info("BDPAudioSessionProxy leave: \(obj)")
        if fixAudioSessionAsyncOperationEnabled {
            OPMediaMutex.leave(scenario: obj.scenario(), scene: scene, wrapper: wrapper)
            LarkAudioSession.shared.waitAudioSession("BDPAudioSessionProxy.leave") {
                queue.async { semaphore.signal() }
            }
            semaphore.wait()
        } else {
            OPMediaMutex.leave(scenario: obj.scenario(), scene: scene, wrapper: wrapper)
        }
    }
}
