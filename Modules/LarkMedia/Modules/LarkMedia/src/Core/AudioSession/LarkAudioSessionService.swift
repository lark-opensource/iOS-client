//
//  LarkAudioSessionService.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/8/2.
//

import Foundation

public typealias AudioSessionScenarioCompletion = () -> Void

/// LarkMedia 对外提供 AudioSessionScenario 方法
public protocol LarkAudioSessionService {

    /// 获取当前激活中的 AudioSessionScenario
    var activeScenario: [AudioSessionScenario] { get }

    /// 激活指定的音频场景
    /// - parameter scenario: 音频场景
    /// - parameter options: 音频场景选项
    /// - parameter completion: 执行结束回调，并发子线程回调
    func enter(_ scenario: AudioSessionScenario,
               options: ScenarioEntryOptions,
               completion: AudioSessionScenarioCompletion?)

    /// 离开指定的音频场景
    /// - parameter scenario: 音频场景
    /// - parameter options: 音频场景选项
    ///
    /// - warning: 执行leave后AVAudioSession并不一定会被deactive，根据1s后是否还存在音频场景来判断
    func leave(_ scenario: AudioSessionScenario, options: ScenarioEntryOptions)

    func leave(_ scenario: AudioSessionScenario)
}

public extension LarkAudioSessionService {
    func enter(_ scenario: AudioSessionScenario) {
        enter(scenario, options: [], completion: nil)
    }

    func enter(_ scenario: AudioSessionScenario, options: ScenarioEntryOptions) {
        enter(scenario, options: options, completion: nil)
    }

    func enter(_ scenario: AudioSessionScenario, completion: AudioSessionScenarioCompletion?) {
        enter(scenario, options: [], completion: completion)
    }

    func leave(_ scenario: AudioSessionScenario) {
        leave(scenario, options: [])
    }
}
