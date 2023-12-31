//
//  MyAIInteractView.swift
//  LarkChat
//
//  Created by 李勇 on 2023/4/17.
//

import UIKit
import RxCocoa
import RxSwift
import LarkCore
import FigmaKit
import ServerPB
import LarkAIInfra
import LarkSDKInterface
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignToast
import LarkMessengerInterface

/// My AI场景，展示new topic、快捷指令
final class MyAIInteractView: UIScrollView {

    private let disposeBag = DisposeBag()
    private let viewModel: MyAIInteractViewModel
    weak var targetVC: UIViewController?

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.spacing = Cons.buttonSpacing
        // 左右侧边距对齐输入框
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(horizontal: Cons.hMargin, vertical: 0)
        return stack
    }()

    /// new topic按钮，type需要使用custom，否则icon的颜色为蓝色，点击后有默认的点击态，不符合UX需求
    public let newTopicButton = NewTopicButton(type: .custom)

    public lazy var sceneSwitchButton = MyAISwitchSceneButton(tapAction: { [weak self] in
        self?.handleClickingSwitchScene()
    })

    private var quickActionButtons: [UIButton] = []

    private func updateQuickActions(_ quickActions: [AIQuickAction]) {
        quickActionButtons.forEach { $0.removeFromSuperview() }
        quickActionButtons.removeAll()
        for quickAction in quickActions {
            let button = QuickActionButton(with: quickAction)
            button.addTarget(self, action: #selector(didTapQuickActionButton), for: .touchUpInside)
            quickActionButtons.append(button)
            contentStack.addArrangedSubview(button)
        }
    }

    private func setQuickActionsHidden(_ isHidden: Bool) {
        for quickActionButton in quickActionButtons {
            quickActionButton.isHidden = isHidden
        }
    }

    init(viewModel: MyAIInteractViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        self.bounces = true
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        // 点了UIScrollView上的Button马上松手不会有背景色变化，解决方案：https://www.jianshu.com/p/66ab6171508f
        self.delaysContentTouches = false

        addSubview(contentStack)
        self.snp.makeConstraints { make in
            make.height.equalTo(Cons.buttonHeight)
        }
        contentStack.snp.makeConstraints { make in
            make.top.bottom.left.right.equalTo(self.contentLayoutGuide)
            make.height.equalTo(self.safeAreaLayoutGuide)
        }
        // 添加「新话题」
        contentStack.addArrangedSubview(newTopicButton)
        /// 主会场的新话题按钮状态跟随onboard卡片展示状态
        if let myAIPageService = viewModel.myAIPageService, !myAIPageService.chatMode {
            myAIPageService.myAIMainChatConfig.onBoardInfoSubject
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] status in
                    switch status {
                    case .notShow:
                        self?.newTopicButton.changeNewTopicButtonStatus(.normal)
                    case .loading:
                        self?.newTopicButton.changeNewTopicButtonStatus(.loading)
                    case .success, .willDismiss:
                        self?.newTopicButton.changeNewTopicButtonStatus(.disable)
                    }
                })
        }
        newTopicButton.addTarget(self, action: #selector(startNewTopic), for: .touchUpInside)
        // 添加「场景对话」
        if self.viewModel.shouldAddModeButton {
            contentStack.addArrangedSubview(sceneSwitchButton)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(toolStartNewTopic(notification:)), name: MyAIToolsSelectedViewController.Notification.StartNewTopic, object: nil)

        // 添加「快捷指令」
        viewModel.myAIPageService?.aiQuickActions.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] quickActions in
                guard let self = self else { return }
                self.updateQuickActions(quickActions)
                // 场景需求FG开时，不需要单独显示/隐藏快捷指令，因为整体都显示/隐藏了
                if !self.viewModel.shouldAddModeButton { self.setQuickActionsHidden(self.viewModel.stopGeneratingIsShown?.value ?? false) }
                // 上报 QuickAction 展示埋点
                self.viewModel.reportQuickActionShownEvent(quickActions)
            }).disposed(by: disposeBag)
        // 「停止生成」出现时，隐藏快捷指令等按钮
        viewModel.stopGeneratingIsShown?
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isStopGeneratingShown in
                guard let self = self else { return }
                // 场景需求开启时，因为固定有新话题 + 场景对话两个入口，渲染时容易和停止生成重合，所以改为直接把整体都显示/隐藏了
                if self.viewModel.shouldAddModeButton { self.contentStack.isHidden = isStopGeneratingShown } else {
                    // 否则只显示/隐藏快捷指令部分
                    self.setQuickActionsHidden(isStopGeneratingShown)
                }
            }).disposed(by: disposeBag)
    }

    // 点了UIScrollView上的Button马上松手不会有背景色变化，解决方案：https://www.jianshu.com/p/66ab6171508f
    override func touchesShouldCancel(in view: UIView) -> Bool {
        return true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func toolStartNewTopic(notification: NSNotification) {
        guard let myAIPageService = self.viewModel.myAIPageService else {
            MyAITopExtendSubModule.logger.info("notification my ai click new topic error, service is none")
            return
        }
        guard let aiChatModeId = notification.userInfo?["aiChatModeId"] as? Int64 else { return }
        // 处理当前只会在主会场或某分会场新建话题
        guard aiChatModeId == myAIPageService.chatModeConfig.aiChatModeId else {
            return
        }
        startNewTopic()
    }

    @objc
    private func startNewTopic() {
        if viewModel.myAIPageService?.chatMode == true || !viewModel.useNewOnboard {
            startTopicInChatMode()
        } else {
            startTopicInMainChat()
        }
    }

    func startTopicInMainChat() {
        guard let myAIPageService = self.viewModel.myAIPageService else {
            MyAITopExtendSubModule.logger.info("start TopicInMainChat new topic error, service is none")
            return
        }
        myAIPageService.showOnboardCard(byUser: true) { [weak self] error in
            guard let self = self else { return }
            let toast = {
                guard let window = self.window else { return }
                UDToast.showFailure(
                    with: BundleI18n.LarkAI.Lark_Legacy_ErrorMessageTip,
                    on: window,
                    error: error
                )
            }
            if Thread.isMainThread {
                toast()
            } else {
                DispatchQueue.main.async {
                    toast()
                }
            }
        }
    }

    func startTopicInChatMode() {
        self.viewModel.handleClickingNewTopic { [weak self] in
            // 请求完成时，恢复状态
            self?.newTopicButton.changeNewTopicButtonToNormal()
            // 跳转到会话最后
            self?.viewModel.chatMessagesOpenService?.pageAPI?.jumpToChatLastMessage(tableScrollPosition: .bottom, needDuration: true)
        } onError: { [weak self] error in
            // 请求出错时，恢复状态
            self?.newTopicButton.changeNewTopicButtonToNormal()
            guard let view = self?.targetVC?.view else { return }
            if let apiError = error.transformToAPIError().metaErrorStack.first(where: { $0 is APIError }) as? APIError {
                if case .myAiAlreadyNewTopic(let message) = apiError.type {
                    UDToast.showTips(with: message, on: view)
                } else {
                    UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: view, error: apiError)
                }
            } else {
                UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: view, error: error)
            }
        }
        // 开始请求时，进入loading态
        self.newTopicButton.changeNewTopicButtonToLoading()
    }

    @objc
    private func handleClickingSwitchScene() {
        guard let targetVC = self.targetVC else { return }

        IMTracker.Chat.Main.Click.sceneList(self.viewModel.chat, self.viewModel.myAIPageService?.chatFromWhere ?? ChatFromWhere.default())
        self.viewModel.myAISceneService?.openSceneList(from: targetVC, chat: self.viewModel.chat, selected: { [weak self] sceneId in
            guard let `self` = self else { return }
            IMTracker.Scene.Click.session(
                self.viewModel.chat,
                params: ["session_id": self.viewModel.myAIPageService?.aiRoundInfo.value.sessionID ?? "", "scene_trigger_type": "click_my_scene", "scene_id": "[\(sceneId)]"]
            )
            self.viewModel.handleClickingNewScene(sceneId: sceneId) {} onError: { [weak self] error in
                guard let view = self?.targetVC?.view else { return }
                if let apiError = error.transformToAPIError().metaErrorStack.first(where: { $0 is APIError }) as? APIError {
                    UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: view, error: apiError)
                } else {
                    UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: view, error: error)
                }
            }
        })
    }

    @objc
    private func didTapQuickActionButton(_ button: UIButton) {
        guard let quickActionButton = button as? QuickActionButton else { return }
        viewModel.handleSelectingQuickAction(quickActionButton.quickAction)
    }
}

extension MyAIInteractView {

    enum Cons {
        static var hMargin: CGFloat { 8 }
        static var buttonSpacing: CGFloat { 6 }
        static var buttonHeight: CGFloat { 28.auto() }
        static var sceneSwitchButtonHInset: CGFloat { 6 }
        static var quickActionButtonHInset: CGFloat { 8 }
        static var quickActionButtonMinWidth: CGFloat { 200 }
        static var quickActionButtonMaxWidth: CGFloat { 580 }
        static var newTopicIconSize: CGSize { .square(16.auto()) }
        static var buttonCornerRadius: CGFloat { QuickActionListButton.Cons.cornerRadius }
    }
}
