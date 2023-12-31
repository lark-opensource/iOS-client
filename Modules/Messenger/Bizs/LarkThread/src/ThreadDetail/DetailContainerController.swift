//
//  DetailContainerController.swift
//  LarkThread
//
//  Created by lizhiqiang on 2020/3/29.
//

import Foundation
import LarkUIKit
import LarkModel
import UniverseDesignToast
import EENavigator
import LarkMessageCore
import LKCommonsLogging
import LarkSDKInterface
import LarkSplitViewController
import LarkFeatureGating
import LarkSuspendable
import LarkContainer
import LarkMessengerInterface
import UIKit

typealias GetDetailController = (UIViewController, ThreadMessage, Chat, TopicGroup) throws -> UIViewController

/// 该类用来保存thread的跳转信息，兜底reply in thread使用
struct ThreadDetailPushInfo {
    public let loadType: ThreadDetailLoadType
    public let position: Int32?
    public weak var fromVC: UIViewController?
}

final class DetailContainerController: BaseUIViewController {
    var pushInfo: ThreadDetailPushInfo?
    var sourceID: String = UUID().uuidString

    lazy var lynxcardRenderFG: Bool = {
        return self.viewModel.userResolver.fg.staticFeatureGatingValue(with: "lynxcard.client.render.enable")
    }()

    init(
        viewModel: DetailContainerViewModel,
        intermediateStateControl: InitialDataAndViewControl<DetailBlockData, Void>,
        getDetailController: @escaping GetDetailController
    ) {
        self.viewModel = viewModel
        self.intermediateStateControl = intermediateStateControl
        self.getDetailController = getDetailController
        super.init(nibName: nil, bundle: nil)
        self.startIntermediateStateControl()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        self.supportSecondaryOnly = true
        self.supportSecondaryPanGesture = true
        self.keyCommandToFullScreen = true
        self.fullScreenSceneBlock = { "channel" }
        super.viewDidLoad()
        self.isNavigationBarHidden = true
        self.intermediateStateControl.viewDidLoad()
    }

    private static let logger = Logger.log(DetailContainerController.self, category: "LarkThread")
    private let viewModel: DetailContainerViewModel
    private let getDetailController: GetDetailController
    private let intermediateStateControl: InitialDataAndViewControl<DetailBlockData, Void>
    private var loadingView: DetailIntermediateView?

    private func startIntermediateStateControl() {
        self.intermediateStateControl.start { [weak self] (result) in
            switch result {
            case .success(let status):
                DetailContainerController.logger.info("ProcessStatus is \(status)")
                switch status {
                case .blockDataFetched(data: let data):
                    self?.viewModel.ready(threadMessage: data.0, chat: data.1, topicGroup: data.2)
                case .inNormalStatus:
                    guard let chat = self?.viewModel.chat,
                        let threadMessage = self?.viewModel.threadMessage,
                        let topicGroup = self?.viewModel.topicGroup else {
                            DetailContainerController.logger.error("block data is empty error \(self?.viewModel.threadID ?? "")")
                            return
                    }
                    /// 这里有个历史逻辑 端上会拦截进入threadMessage.position < chat.firstMessagePostion提示话题被撤回
                    if threadMessage.isNoTraceDeleted || !threadMessage.isVisible {
                        self?.showLoadingView()
                        self?.viewModel.removeFeedCard()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                            if let window = self?.view.window {
                                UDToast.showFailure(with: BundleI18n.LarkThread.Lark_Chat_TopicWasRecalledToast, on: window)
                            }
                            self?.popSelf()
                        }
                        DetailContainerController.logger.error("topic had deleted \(self?.viewModel.threadID ?? "") \(chat.firstMessagePostion) - \(chat.bannerSetting?.chatThreadPosition)")
                        return
                    }

                    ThreadTracker.trackEnterChat(chat: chat, threadID: self?.viewModel.threadID)
                    self?.setupUI(with: threadMessage, chat: chat, topicGroup: topicGroup)
                    self?.hideLoadingView()
                case .inInstantStatus:
                    self?.showLoadingView()
                }
            case .failure(let error):
                if let error = error.underlyingError as? APIError {
                    switch error.type {
                    case .noPullMessagePermission(let message):
                        self?.viewModel.removeFeedCard()
                        DispatchQueue.main.async {
                            self?.showLoadingView()
                            if let window = self?.view.window {
                                UDToast.showFailure(with: message, on: window)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self?.popSelf()
                            }
                        }
                    default: break
                    }
                }
                DetailContainerController.logger.error("fetch thread error \(self?.viewModel.threadID ?? "")", error: error)
            }
        }
    }

    private func setupUI(with threadMessage: ThreadMessage, chat: Chat, topicGroup: TopicGroup) {
        /// 这里加这个判断的原因如下，因为reply in thread的存在，导致原来话题会出现在chat和换题群中
        /// 由于业务上跳转话题的详情页的逻辑很多，为防止有些场景遗漏，导致应该跳转reply in thread详情页的情况
        /// 跳转至话题详情页，加一个兜底，正常逻辑不会触发
        if chat.chatMode != .threadV2,
           threadMessage.rootMessage.threadMessageType == .threadRootMessage,
           let info = self.pushInfo,
           let fromVC = info.fromVC {
            assertionFailure("keep scene")
            self.popSelf(animated: false)
            let body = ReplyInThreadByModelBody(message: threadMessage.message,
                                                chat: chat,
                                                loadType: info.loadType,
                                                position: info.position)
            self.viewModel.navigator.push(body: body, from: fromVC, animated: false)
            Self.logger.info("error router to thread detail chat.id: \(chat.id) threadId: \(threadMessage.id)")
            return
        }
        guard let detailVC = try? self.getDetailController(self, threadMessage, chat, topicGroup) else { return }
        self.addChild(detailVC)
        self.view.addSubview(detailVC.view)
        detailVC.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Helper
    private func hideLoadingView() {
        self.loadingView?.stopLoading()
        self.loadingView?.removeFromSuperview()
    }

    private func showLoadingView() {
        let loadingView = DetailIntermediateView(showKeyboard: true, backButtonClickedBlock: { [weak self] in
            guard let `self` = self else {
                assertionFailure("缺少 From VC")
                return
            }
            self.viewModel.navigator.pop(from: self)
        })
        self.view.addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        loadingView.startLoading()
        self.loadingView = loadingView
    }
}

// MARK: - 页面支持收入多任务浮窗

extension DetailContainerController: ViewControllerSuspendable {

    var suspendID: String {
        return viewModel.threadID
    }

    var suspendSourceID: String {
        return sourceID
    }

    var suspendTitle: String {
        guard let message = viewModel.threadMessage?.rootMessage else {
            return viewModel.chat?.displayName ?? viewModel.threadID
        }
        let content = MessageSummarizeUtil.getSummarize(message: message, lynxcardRenderFG: self.lynxcardRenderFG)
        if let name = message.fromChatter?.displayName {
           return content + " - " + name
        } else {
            return content
        }
    }

    var suspendIcon: UIImage? {
        return Resources.suspend_icon_topic
    }

    var suspendIconKey: String? {
        return viewModel.chat?.avatarKey
    }

    var suspendIconEntityID: String? {
        return viewModel.chat?.id
    }

    var suspendURL: String {
        return "//client/chat/thread/detail/\(viewModel.threadID)"
    }

    var suspendParams: [String: AnyCodable] {
        return [:]
    }

    var suspendGroup: SuspendGroup {
        return .thread
    }

    var isWarmStartEnabled: Bool {
        return false
    }

    var analyticsTypeName: String {
        return "topic"
    }
}
