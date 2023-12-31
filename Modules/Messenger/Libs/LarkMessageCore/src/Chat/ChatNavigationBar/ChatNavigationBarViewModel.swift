//
//  ChatNavigationBarViewModel.swift
//  Pods
//
//  Created by lizhiqiang on 2019/4/10.
//
import UIKit
import Foundation
import LarkModel
import LarkCore
import RxSwift
import RxCocoa
import LarkTag
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkUIKit
import LarkFeatureSwitch
import AnimatedTabBar
import LarkTab
import UniverseDesignColor
import LarkEmotion
import LarkOpenChat
import LarkBadge
import RustPB
import LarkLocalizations
import SwiftProtobuf
import LarkSetting
import LKCommonsLogging
import LarkBizTag

public final class ChatNavigationBarViewModel {
    private static let logger = Logger.log(ChatNavigationBarViewModel.self, category: "ChatNavigationBarViewModel")

    private let chatWrapper: ChatPushWrapper
    private let disposeBag = DisposeBag()

    private(set) var countColor: UIColor = UIColor.ud.N600

    /// 是否正在多选，如果正在多选，rightItems 只会返回 [.cancelItem]
    var multiSelecting: Bool = false {
        didSet {
            if oldValue != multiSelecting {
                self.module.createRigthItems(metaModel: ChatNavigationBarMetaModel(chat: self.chat))
                self.module.context.refreshRightItems()
            }
        }
    }

    var rightItems: [ChatNavigationExtendItem] {
        return self.module.rightItems()
    }

    var leftItems: [ChatNavigationExtendItem] {
        return self.module.leftItems()
    }

    var titleView: UIView? {
        return self.module.contentView()
    }

    public var chat: Chat {
        return self.chatWrapper.chat.value
    }
    public let isDark: Bool
    public var barStyle: OpenChatNavigationBarStyle

    private(set) lazy var focusStatus: Chatter.FocusStatus? = {
        // FG is handled in SDK
        guard chat.type == .p2P else { return nil }
        return chat.chatter?.focusStatusList.topActive
    }()

    var moduleAleadySetup: Bool = false

    /// 当前所在的VC开始渲染subView
    private var viewRealRenderedSubView: Bool = false

    private let module: BaseChatNavigationBarModule

    var showLeftStyle: Bool {
        (try? module.userResolver.resolve(type: ChatNavigationBarConfigService.self).showLeftStyle) ?? false
    }

    // MARK: - Life Cycle
    public init(
        chatWrapper: ChatPushWrapper,
        module: BaseChatNavigationBarModule,
        isDark: Bool = false) {
        self.chatWrapper = chatWrapper
        self.module = module
        self.isDark = isDark
        self.barStyle = isDark ? .darkContent : .lightContent
    }

    func setupModule() {
        guard !moduleAleadySetup else {
            return
        }
        moduleAleadySetup = true
        let metaModel = ChatNavigationBarMetaModel(chat: self.chat)
        self.module.handler(model: metaModel)
        if !chat.isTeamVisitorMode {
            self.module.createRigthItems(metaModel: metaModel)
        }
        self.module.createContentView(metaModel: metaModel)
        self.module.createLeftItems(metaModel: metaModel)
        self.chatWrapper.chat
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] chat in
                self?.module.modelDidChange(model: ChatNavigationBarMetaModel(chat: chat))
            }.disposed(by: self.disposeBag)
    }

    func getRightItem(type: ChatNavigationExtendItemType) -> ChatNavigationExtendItem? {
        return self.module.rightItems().first(where: { item in
            return item.type == type
        })
    }

    func getLeftItem(type: ChatNavigationExtendItemType) -> ChatNavigationExtendItem? {
        return self.module.leftItems().first(where: { item in
            return item.type == type
        })
    }

    public func viewWillAppear() {
        self.module.viewWillAppear()
    }

    public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.module.viewWillTransition(to: size, with: coordinator)
    }

    /// VC viewDidAppear
    public func viewDidAppear() {
        self.module.viewDidAppear()
    }

    public func viewWillRealRenderSubView() {
        if self.viewRealRenderedSubView {
            assertionFailure("viewWillRealRenderSubView should only once")
            Self.logger.error("viewWillRealRenderSubView should only once")
        }
        self.module.viewWillRealRenderSubView()
        self.viewRealRenderedSubView = true
    }

    public func viewFinishedMessageRender() {
        self.module.viewFinishedMessageRender()
    }

    public func splitDisplayModeChange() {
        self.module.splitDisplayModeChange()
    }

    public func splitSplitModeChange() {
        self.module.splitSplitModeChange()
    }

    public func barStyleDidChange() {
        self.module.barStyleDidChange()
    }
}
