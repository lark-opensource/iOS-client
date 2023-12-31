//
//  MyAIDependency.swift
//  ByteView
//
//  Created by 陈乐辉 on 2023/8/3.
//

import Foundation
import RxSwift
import ByteViewNetwork

final class MeetingMyAI {
    private let dependency: MyAIDependency
    init(dependency: MyAIDependency) {
        self.dependency = dependency
    }

    /// 打开MyAI
    func openMyAIChat(with config: MyAIChatConfig, from: UIViewController) {
        dependency.openMyAIChat(with: config, from: from)
    }

    /// 检测MyAI是否onboarding
    func isMyAINeedOnboarding() -> Bool {
        dependency.isMyAINeedOnboarding()
    }

    /// 打开MyAI Onboarding
    func openMyAIOnboarding(from: UIViewController, completion: @escaping ((Bool) -> Void)) {
        dependency.openMyAIOnboarding(from: from, completion: completion)
    }

    /// MyAI是否可用
    func isMyAIEnabled() -> Bool {
        dependency.isMyAIEnabled()
    }

    func observeName(with disposeBag: DisposeBag, observer: @escaping ((String) -> Void)) {
        dependency.observeName(with: disposeBag, observer: observer)
    }
}

public protocol MyAIDependency {
    /// 打开MyAI
    func openMyAIChat(with config: MyAIChatConfig, from: UIViewController)

    /// 检测MyAI是否onboarding
    func isMyAINeedOnboarding() -> Bool

    /// 打开MyAI Onboarding
    func openMyAIOnboarding(from: UIViewController, completion: @escaping ((Bool) -> Void))

    /// MyAI是否可用
    func isMyAIEnabled() -> Bool

    /// 监听MyAI昵称变化
    func observeName(with disposeBag: DisposeBag, observer: @escaping ((String) -> Void))
}

public final class MyAIChatConfig {
    /// AI 主会话 ID. 当且仅当需要onboarding的时候，chatID会为nil
    public var chatId: Int64?
    /// AI 分会话 ID
    public var aiChatModeId: Int64
    /// 当前场景操作的对象ID
    public var objectId: String
    /// 插件id
    public var toolIds: [String]
    /// 本次 AI 分会话期间，MyAI 向业务实时获取上下文信息（如当前选区内容）
    public var appContextDataProvider: (() -> [String: String])?
    /// 获取分会场业务执行快捷指令携带的额外参数
    public var quickActionsParamsProvider: (() -> [String: String])?

    public var pageService: AnyObject?

    public var closeBlock: (() -> Void)?

    public var activeBlock: ((Bool) -> Void)?

    public var disposeBag: DisposeBag = DisposeBag()

    public init(chatId: Int64, aiChatModeId: Int64, objectId: String, toolIds: [String]) {
        self.chatId = chatId
        self.aiChatModeId = aiChatModeId
        self.objectId = objectId
        self.toolIds = toolIds
    }

    public func closeMyAI() {
        closeBlock?()
    }

    public func clear() {
        pageService = nil
        closeBlock = nil
        activeBlock = nil
        disposeBag = DisposeBag()
    }
}
