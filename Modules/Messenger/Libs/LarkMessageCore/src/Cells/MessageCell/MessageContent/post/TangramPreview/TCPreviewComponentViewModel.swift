//
//  TCPreviewComponentViewModel.swift
//  LarkMessageCore
//
//  Created by 袁平 on 2021/4/23.
//

import UIKit
import Foundation
import RustPB
import RxSwift
import LarkCore
import LarkModel
import EENavigator
import LarkContainer
import TangramService
import LKCommonsLogging
import TangramUIComponent
import TangramComponent
import LarkMessageBase
import AsyncComponent
import DynamicURLComponent
import LarkMessengerInterface

internal let tcLogger = Logger.log(NSObject(), category: "LarkMessageCore.URLPreview")

protocol TCPreviewComponentDependency: AnyObject, URLCardDependency {
    var hostMessage: Message? { get }
    var hostChat: Chat? { get }
    var cornerRadius: CGFloat { get }
    var border: Border? { get }
    var backgroundColor: UIColor { get }
    // 卡片点击需携带的额外参数
    var cardRouterContext: [String: Any] { get }
    var fileUtilService: FileUtilService? { get }
    func auditEvent(event: ChatSecurityAuditEventType) //上报审计埋点
}

final class TCPreviewComponentViewModel<C: TCPreviewContainerContext & PageContext> {
    // 弱持有
    weak var dependency: TCPreviewComponentDependency?
    let context: C
    let component: TCPreviewComponent<C>
    // 记录渲染时间，内部为基础类型，可不用加锁
    var renderInfo: TCPreviewRenderInfo?
    private var _cardViewModel = Atomic<URLCardViewModel>()
    var cardViewModel: URLCardViewModel? {
        get { return _cardViewModel.wrappedValue }
        set { _cardViewModel.wrappedValue = newValue }
    }
    var onTap: TCPreviewWrapperView.OnTap?
    // 会话场景不允许根节点border自定义
    let urlCardConfig = URLCardConfig(hideRootBorder: true)

    init(entity: URLPreviewEntity,
         dependency: TCPreviewComponentDependency,
         context: C,
         renderInfo: TCPreviewRenderInfo?) {
        self.dependency = dependency
        self.context = context
        self.renderInfo = renderInfo
        let props = TCPreviewComponent<C>.Props(renderer: nil)
        let style = ASComponentStyle()
        component = TCPreviewComponent(props: props, style: style, context: context)
        let startTime = CACurrentMediaTime()
        let cardViewModel = context.urlCardService.createCard(entity: entity, cardDependency: dependency, config: urlCardConfig)
        trackRender(entity: entity, startTime: startTime)
        self.cardViewModel = cardViewModel
        props.renderer = cardViewModel?.renderer
        // 不变的属性只同步一次
        props.onTap = self.onTap
        props.renderCallback = self
        style.cornerRadius = dependency.cornerRadius
        style.border = dependency.border
        style.backgroundColor = dependency.backgroundColor
        setOnTap()
        TCPreviewTracker.trackUrlRender(entity: entity, extraParams: dependency.extraTrackParams)
    }

    private func trackRender(entity: URLPreviewEntity, startTime: CFTimeInterval) {
        // 只记录初始state的卡片构建耗时
        guard (renderInfo?.renderNeedTrack ?? false),
              (renderInfo?.componentTreeBuildCost ?? 0) <= 0,
              let body = entity.previewBody,
              let state = body.states[body.currentStateID],
              let template = dependency?.templateService?.getTemplate(id: state.templateID) else { return }
        self.renderInfo?.componentTreeBuildCost = CACurrentMediaTime() - startTime
        self.renderInfo?.componentsCount = template.elements.count
        self.renderInfo?.templateID = template.templateID
        self.renderInfo?.totalCostEndTime = CACurrentMediaTime()
    }

    private func setOnTap() {
        self.onTap = { [weak self] in
            guard let self = self else { return }
            if self.dependency?.hostMessage?.type == .file {
                self.onFileTapped()
            } else {
                self.onCardTapped(cardURL: self.cardViewModel?.getCardURL())
            }
        }
        self.component.props.onTap = self.onTap
    }

    private func onFileTapped() {
        guard let message = self.dependency?.hostMessage,
              let chat = self.dependency?.hostChat,
              let window = self.dependency?.targetVC?.view.window else { return }
        self.dependency?.fileUtilService?.onFileMessageClicked(message: message,
                                                               chat: chat,
                                                               window: window,
                                                               downloadFileScene: nil) { [weak self] in
            self?.openFile()
        }
    }

    private func onCardTapped(cardURL: Basic_V1_URL?) {
        guard let urlStr = cardURL?.tcURL, let targetVC = self.dependency?.targetVC else { return }
        guard !urlStr.isEmpty, let url = try? URL.forceCreateURL(string: urlStr) else {
            tcLogger.error("[URLPreview] url create failed: \(urlStr)")
            return
        }
        let context = dependency?.cardRouterContext ?? [:]
        func openVC() {
            self.context.navigator.open(url, context: context, from: targetVC)
        }
        if let myAiPageService = try? self.context.userResolver.resolve(type: MyAIPageService.self) {
            myAiPageService.onMessageURLTapped(fromVC: targetVC,
                                               url: url,
                                               context: context) {
                openVC()
            }
        } else {
            openVC()
        }
        if let entity = self.cardViewModel?.entity {
            TCPreviewTracker.trackRenderClick(entity: entity,
                                              extraParams: self.dependency?.extraTrackParams ?? [:],
                                              clickType: .openPage,
                                              componentID: "none")
        }
    }

    private func openFile() {
        guard let targetVC = self.dependency?.targetVC,
              let chat = self.dependency?.hostChat,
              let message = self.dependency?.hostMessage,
              let fileContent = (message.content as? FileContent) else { return }
        guard !chat.isCrypto else {
            assertionFailure("crypto do not support tcPreview for FileMessage")
            return
        }

        self.dependency?.auditEvent(event: .chatPreviewfile(chatId: chat.id,
                                                            chatType: chat.type,
                                                            fileId: fileContent.key,
                                                            fileName: fileContent.name,
                                                            fileType: (fileContent.name as NSString).pathExtension))
        func pushVC() {
            let fileBrowseScene: FileSourceScene = .chat
                 let body = MessageFileBrowseBody(message: message, scene: fileBrowseScene, downloadFileScene: .chat, chatFromTodo: nil)
            self.context.navigator.push(body: body, from: targetVC)
        }
        if let myAiPageService = try? self.context.userResolver.resolve(type: MyAIPageService.self) {
            myAiPageService.onMessageFileTapped(fromVC: targetVC,
                                                message: message,
                                                scene: .chat,
                                                downloadFileScene: .chat) {
                pushVC()
            }
        } else {
            pushVC()
        }
    }

    func update(entity: URLPreviewEntity) {
        let startTime = CACurrentMediaTime()
        if self.cardViewModel == nil, let dependency = dependency {
            self.cardViewModel = context.urlCardService.createCard(entity: entity, cardDependency: dependency, config: urlCardConfig)
            component.props.renderer = cardViewModel?.renderer
        } else {
            cardViewModel?.update(entity: entity)
        }
        trackRender(entity: entity, startTime: startTime)
        setOnTap()
    }

    func willDisplay() {
        cardViewModel?.willDisplay()
    }

    func didEndDisplay() {
        cardViewModel?.didEndDisplay()
    }

    func onResize() {
        cardViewModel?.onResize()
    }
}

extension TCPreviewComponentViewModel: TCPreviewRenderCallback {
    func beforeRender() {
        guard renderInfo?.renderNeedTrack ?? false else { return }
        if (renderInfo?.uiRenderStartTime ?? 0) <= 0 {
            renderInfo?.uiRenderStartTime = CACurrentMediaTime()
        }
    }

    func afterRender() {
        guard renderInfo?.renderNeedTrack ?? false else { return }
        if (renderInfo?.uiRenderEndTime ?? 0) <= 0 {
            renderInfo?.uiRenderEndTime = CACurrentMediaTime()
        }
        renderInfo?.renderNeedTrack = false
        if let entity = self.cardViewModel?.entity {
            TCPreviewRenderTracker.trackRender(previewID: entity.previewID, info: renderInfo)
        }
    }
}
