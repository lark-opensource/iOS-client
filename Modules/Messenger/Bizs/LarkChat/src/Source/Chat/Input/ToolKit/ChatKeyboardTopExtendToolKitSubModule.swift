//
//  ChatKeyboardTopExtendToolKitSubModule.swift
//  LarkChat
//
//  Created by JackZhao on 2022/6/20.
//

import Foundation
import UIKit
import RxSwift
import Swinject
import LarkModel
import EENavigator
import LarkOpenChat
import LarkOpenIM
import LarkContainer
import LarkFoundation
import LarkRustClient
import LarkSDKInterface
import LKCommonsLogging
import LarkSetting
import UniverseDesignToast
import UniverseDesignColor
import LarkAccountInterface

public final class ChatKeyboardTopExtendToolKitSubModule: ChatKeyboardTopExtendSubModule {
    static let logger = Logger.log(ChatKeyboardTopExtendToolKitSubModule.self, category: "Module.LarkChat")

    private var innerContentView: ChatKeyboardTopExtendToolKitView?
    private var display: Bool = false
    private let disposeBag = DisposeBag()
    private var chatId: String?
    private lazy var pushChatToolKits: Observable<PushChatToolKits> = {
        (try? context.resolver.userPushCenter.observable(for: PushChatToolKits.self)) ?? .empty()
    }()
    private var currentUserId: String { userResolver.userID }
    @ScopedInjectedLazy private var toolKitAPI: ToolKitAPI?

    public override func contentView() -> UIView? {
        return display ? self.innerContentView : nil
    }

    public override class func canInitialize(context: ChatKeyboardTopExtendContext) -> Bool {
        true // "im.chat.open_toolkit" 已经全量
    }

    public override var type: ChatKeyboardTopExtendType {
        return .toolKit
    }

    public override func modelDidChange(model: ChatKeyboardTopExtendMetaModel) {
    }

    public override func handler(model: ChatKeyboardTopExtendMetaModel) -> [Module<ChatKeyboardTopExtendContext, ChatKeyboardTopExtendMetaModel>] {
        return [self]
    }

    public override func canHandle(model: ChatKeyboardTopExtendMetaModel) -> Bool {
        return true
    }

    public override func createContentView(model: ChatKeyboardTopExtendMetaModel) {
        self.chatId = model.chat.id
        self.display = false
        let toolKitView = ChatKeyboardTopExtendToolKitView()
        toolKitView.snp.makeConstraints { make in
            make.height.equalTo(0)
        }
        innerContentView = toolKitView
        let chatId = Int64(self.chatId ?? "") ?? 0
        // 拉取远端数据, 显示组件
        toolKitAPI?.pullChatToolKitsRequest(chatId: "\(model.chat.id)")
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (res) in
                guard let `self` = self, res.toolkits.isEmpty == false else { return }
                self.display = true
                let items = self.transfromItemsFrom(toolKits: res.toolkits)
                self.innerContentView?.updateItemViews(items)
                toolKitView.snp.remakeConstraints { make in
                    make.height.equalTo(ToolKitConfig.height)
                }
                self.context.refresh()
            }, onError: { error in
                Self.logger.error("pullToolKitsRequest error \(error)")
            }).disposed(by: disposeBag)

        // 监听数据变更
        pushChatToolKits
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (res) in
                guard let `self` = self else { return }
                self.display = !res.toolKits.isEmpty
                let items = self.transfromItemsFrom(toolKits: res.toolKits)
                self.innerContentView?.updateItemViews(items)
                self.context.refresh()
            }, onError: { error in
                Self.logger.error("pushChatToolKits error \(error)")
            }).disposed(by: disposeBag)
    }
}

// MARK: 处理接口数据
extension ChatKeyboardTopExtendToolKitSubModule {
    private func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let str = String((0 ..< length).map { _ in (letters.randomElement() ?? "a") })
        return str
    }

    private func transfromItemsFrom(toolKits: [ToolKit]) -> [KeyBoardToolKitItem] {
        return toolKits.map { toolKit in
            KeyBoardToolKitEntity(identify: toolKit.id,
                                  title: toolKit.name,
                                  // 产品规定只有callback形式的按钮才需要展示loading
                                  canShowLoading: toolKit.type == .callback,
                                  icon: !toolKit.hasImageKey ? nil : .identify(key: toolKit.imageKey)) { [weak self] (_, successCallback, failureCallback) in
                guard let `self` = self else { return }
                switch toolKit.type {
                case .unknown:
                    assertionFailure("toolKit.actionType is unknown")
                    Self.logger.info("toolKit.actionType is unknown")
                // 跳转到另一个页面
                case .redirectUrl(let iosUrl, let commonUrl):
                    jump(iosUrl, commonUrl: commonUrl)
                // 回调到 开放平台
                case .callback:
                    action()
                case .none:
                    Self.logger.info("toolKit.actionType is none")
                case .some(_):
                    Self.logger.info("toolKit.actionType is some")
                }

                // 发起请求
                func action() {
                    let cid = self.randomString(length: 10)
                    let chatId = Int64(self.chatId ?? "") ?? 0
                    let extra: [String: String] = ["actionTime": "\(CACurrentMediaTime())"]
                    Self.logger.info("toolKitActionRequest cid: \(cid), toolKitId: \(toolKit.id) appTenantID:\(toolKit.appTenantID), extra: \(extra)")
                    self.toolKitAPI?.toolKitActionRequest(cid: cid,
                                                         userId: Int64(self.currentUserId) ?? 0,
                                                         appTenantID: toolKit.appTenantID,
                                                         chatId: chatId,
                                                         toolKitId: toolKit.id,
                                                         extra: extra)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { _ in
                            successCallback()
                        }, onError: { [weak self] error in
                            guard let `self` = self else { return }
                            failureCallback(error)
                            guard let vc = try? self.context.resolver.resolve(assert: ChatOpenService.self).chatVC() else { return }
                            // TODO @jack: 目前所有的透传接口没有走transformToAPIError，导致这里的error都不是APIError类型，应该在RustClient层统一进行处理 => 错误专项
                            if let wrappedError = error.transformToAPIError() as? WrappedError,
                               let rcError = wrappedError.metaErrorStack.first(where: { $0 is RCError }) as? RCError,
                               case .businessFailure(let buzErrorInfo) = rcError {
                                UDToast.showFailure(with: buzErrorInfo.serverMessage,
                                                    on: vc.view)
                            } else {
                                UDToast.showFailure(with: BundleI18n.LarkChat.Lark_IM_ActionFailedPleaseTryAgainLater_ErrorMessage,
                                                    on: vc.view)
                            }
                            Self.logger.error("toolKitActionRequest \(error)")
                        }).disposed(by: self.disposeBag)
                }
                // 跳转到另一个页面
                func jump(_ iosUrl: String, commonUrl: String) {
                    Self.logger.info("toolKit redirectLink")
                    guard let vc = try? self.context.resolver.resolve(assert: ChatOpenService.self).chatVC() else { return }
                    if let url = URL(string: iosUrl) {
                        self.navigator.push(url, from: vc)
                    } else if let url = URL(string: commonUrl) {
                        self.navigator.push(url, from: vc)
                    } else {
                        assertionFailure("toolKit redirectLink fail, url unvaild")
                        Self.logger.error("toolKit redirectLink fail, url unvaild")
                    }
                }
            }
        }
    }
}
