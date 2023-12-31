//
//  DetailBottomCommentModule.swift
//  Todo
//
//  Created by 张威 on 2021/5/11.
//

import RxSwift
import RxCocoa
import LarkContainer
import CoreGraphics

/// Detail - Bottom - Comment - Module
/// 管理评论输入：输入窗、输入草稿

// nolint: magic number
class DetailBottomCommentModule: DetailBottomSubmodule, HasViewModel {
    let viewModel: DetailBottomCommentViewModel
    private var entryView = DetailBottomCommentButton()
    private let disposeBag = DisposeBag()
    // 是否展示评论入口
    private var shouldShowEntry = false
    // 当前的 scene
    private var currentScene: CommentInputScene?
    // 正在 send 评论
    private var isSendingComment = false

    private var inputController: CommentInputViewController?

    private var rxBottomInset = BehaviorRelay<CGFloat>(value: 0)

    override init(resolver: UserResolver, context: DetailModuleContext) {
        viewModel = ViewModel(resolver: resolver, store: context.store)
        super.init(resolver: resolver, context: context)
    }

    deinit {
        if let inputChild = inputController,
           let scene = currentScene {
            let draftContent = inputChild.inputContent()
            viewModel.setDraftInputContentForDeinit(draftContent, for: scene)
        }
    }

    override func setup() {
        entryView.onClick = { [weak self] in self?.handleEntryClick() }
        context.bus.subscribe { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .activeCommentInput(let content, let scene):
                self.activeInput(with: content, for: scene)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                    self?.inputController?.focusInputTextViewIfNeeded()
                }
            default:
                break
            }
        }.disposed(by: disposeBag)

        viewModel.rxShowBadge.distinctUntilChanged()
            .subscribe(onNext: { [weak self] shouldShow in
                self?.entryView.showBadge = shouldShow
            })
            .disposed(by: disposeBag)

        viewModel.setup()
            .drive(onNext: { [weak self] isAvailable in
                guard let self = self else { return }
                self.shouldShowEntry = isAvailable
                if isAvailable {
                    self.setupInput()
                }
                self.containerModule?.setNeedsReload()
            })
            .disposed(by: disposeBag)
        context.registerBottomInsetRelay(self.rxBottomInset, forKey: "comment.input")
    }

    override func bottomItems() -> [DetailBottomItem] {
        guard shouldShowEntry else { return [] }
        return [.init(view: entryView, widthMode: .fixed(36))]
    }
}

extension DetailBottomCommentModule {

    // MARK: Active/Inactive Input

    private func setupInput() {
        let scene = viewModel.preferredScene()
        let activeSucceed = activeInput(with: nil, for: scene)
        guard activeSucceed else { return }
        viewModel.rxRealDraft.skip(1)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (scene, content) in
                guard let self = self else { return }
                self.updateInputContent(with: content, for: scene)

            }).disposed(by: disposeBag)
        inputController?.rxKeyboardVisibleRect
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] keyBoardRect in
                guard let self = self else { return }
                self.updateTableContentOffset(keyBoardRect)
            }).disposed(by: disposeBag)
    }

    private func updateInputContent(with content: CommentInputContent?, for scene: CommentInputScene) {
        guard let inputChild = inputController else { return }
        var content = content
        if let draftContent = viewModel.draftInputContent(for: scene) {
            content = draftContent
        }
        var insertWhiteSpace = false
        if case .reply = scene {
            insertWhiteSpace = true
        }
        inputChild.resetContent(content, insertWhiteSpace: insertWhiteSpace)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.rxBottomInset.accept(self.inputController?.keyboardView.frame.height ?? 0)
        }
    }

    private func updateTableContentOffset(_ keyBoardRect: CGRect?) {
        let keboardAttachHeight = inputController?.attachmentView.frame.height ?? 0
        guard let tableView = context.tableView,
              let rect = inputController?.keyboardView.frame,
              rect.minY > 0,
              rect.height >= Detail.commentKeyboardEstimateHeight + keboardAttachHeight else {
            return
        }

        rxBottomInset.accept(rect.height)
        // 将 tableView 滑到底部；delay 0.1s，确保 tableView 的 inset 已经设置 ok
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let offsetY = max(
                -tableView.adjustedContentInset.top,
                 tableView.contentSize.height - tableView.bounds.height + tableView.adjustedContentInset.bottom
            )
            if offsetY > 0 {
                tableView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: true)
            }
        }
    }

    // 点击 entry。根据草稿判断 scene (reply/create) -> 激活 inputChild
    private func handleEntryClick() {
        Detail.Track.clickComment(with: viewModel.todoId)
        let scene = viewModel.preferredScene()
        let activeSucceed = activeInput(with: nil, for: scene)
        guard activeSucceed else { return }
        // 将 tableView 滑到底部；delay 0.1s，确保 tableView 的 inset 已经设置 ok
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let tableView = self.context.tableView else { return }
            let offsetY = max(
                -tableView.adjustedContentInset.top,
                tableView.contentSize.height - tableView.bounds.height + tableView.adjustedContentInset.bottom
            )
            if offsetY > 0 {
                tableView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: true)
            }
        }
    }

    @discardableResult
    private func activeInput(with content: CommentInputContent?, for scene: CommentInputScene) -> Bool {
        viewModel.trackAction("input_comment")

        guard !isSendingComment else {
            Detail.logger.info("is sending comment now")
            if let view = context.viewController?.view {
                Utils.Toast.showWarning(with: I18N.Todo_common_ActionFailedTryAgainLater, on: view)
            }
            return false
        }
        let inputChild: CommentInputViewController?
        if let controller = inputController {
            inputChild = controller
            currentScene = scene
        } else {
            inputChild = activeInputChild(forScene: scene)
        }
        guard let inputChild = inputChild, let curScene = currentScene else { return false }
        inputController = inputChild
        if let content = content {
            updateInputContent(with: content, for: curScene)
        }
        inputChild.onSend.delegate(on: self) { [unowned inputChild] (self, _) in
            self.viewModel.trackAction("submit_comment")
            let inputContent = inputChild.inputContent()
            self.isSendingComment = true
            let sendEvent = DetailModuleEvent.sendCommentInput(content: inputContent, scene: self.currentScene ?? .create) { [weak self] err in
                if err != nil {
                    // 发送失败，存草稿
                    self?.viewModel.setDraftInputContent(inputContent, for: scene)
                }
                self?.isSendingComment = false
            }
            self.context.bus.post(sendEvent)
            self.inactiveInputChild(inputChild, fromSend: true)
        }
        return true
    }

    private func activeInputChild(forScene scene: CommentInputScene) -> CommentInputViewController? {
        if let oldScene = currentScene {
            context.bus.post(.commentInputStatusChanged(isActive: false, scene: oldScene))
        }
        currentScene = scene
        context.bus.post(.commentInputStatusChanged(isActive: true, scene: scene))

        guard let container = context.viewController else { return nil }

        let vc = CommentInputViewController(
            resolver: userResolver,
            inputController: viewModel.makeInputController(forScene: scene),
            todoId: viewModel.todoId,
            chatId: viewModel.chatId
        )
        vc.onHidden.delegate(on: self) { [unowned vc] (self, _) in
            self.inactiveInputChild(vc, fromSend: false)
        }

        container.addChild(vc)
        container.view.addSubview(vc.view)
        vc.view.snp.remakeConstraints { $0.edges.equalToSuperview() }
        vc.didMove(toParent: container)
        return vc
    }

    /// 退出输入场景
    private func inactiveInputChild(_ inputChild: CommentInputViewController, fromSend: Bool) {
        inputChild.keyboardView.observeKeyboard = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.rxBottomInset.accept(inputChild.keyboardView.frame.height)
        }

        if let scene = currentScene {
            if fromSend {
                viewModel.clearDraftInputContent(for: scene)
                currentScene = .create
            } else {
                let draftContent = inputChild.inputContent()
                viewModel.setDraftInputContent(draftContent, for: scene)
            }
            context.bus.post(.commentInputStatusChanged(isActive: false, scene: scene))
        }
    }

}
