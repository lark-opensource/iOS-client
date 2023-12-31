//
//  CommentTextPlugin.swift
//  SKCommon
//
//  Created by huayufan on 2022/7/28.
// swiftlint:disable file_length identifier_name line_length trailing_whitespace
// 输入框和键盘事件处理

import UIKit
import SKResource
import SKFoundation
import SKUIKit
import SpaceInterface
import UniverseDesignDialog
import SKCommon

class CommentTextPlugin: CommentPluginType {
    
    var keyboardDidShowHeight: CGFloat?
    
    weak var context: CommentServiceContext?
    
    static let identifier: String = "TextPlugin"
    
    func apply(context: CommentServiceContext) {
        self.context = context
    }
    
    func mutate(action: CommentAction) {
        switch action {
        case let .interaction(uiAction):
            handleUIAction(action: uiAction)
        default:
            break
        }
    }
    
    init() {}
    
    func handleUIAction(action: CommentAction.UI) {
        switch action {
        case let .asideKeyboardChange(options, item):
            handleAsideKeyBoardChange(options: options, item: item)
        case let .keyboardChange(option):
            if context?.pattern == .float {
                handleFloatKeyBoardChange(options: option)
            } else if context?.pattern == .drive {
                handleDriveKeyBoardChange(options: option)
            }
        case .tapBlank:
            handleTapBlank()

        case .clickInputBarView:
            handleClickInputBarView()

        case let .clickInputBarSendBtn(textView, attributedText, imageList):
            handleClickInputBarSendBtn(textView, attributedText, imageList)
            
        case let .textViewDidEndEditing(atInputTextView):
            if context?.pattern == .aside {
                handleAsideTextViewDidEndEditing(atInputTextView)
            } else if context?.pattern == .float {
                handleFloatTextViewDidEndEditing(atInputTextView)
            }
            context?.scheduler?.dispatch(action: .tea(.cancelClick))
        default:
            break
        }
    }
    
    var scheduler: CommentSchedulerType? { context?.scheduler }
}

extension CommentTextPlugin {
    
    private func handleFloatTextViewDidEndEditing(_ atInputTextView: AtInputViewType) {
        guard let fastState = context?.scheduler?.fastState else {
            DocsLogger.error("fastState is nil", component: LogComponents.comment)
            return
        }
        switch fastState.mode {
        case let .newInput(model):
            if let vc = context?.commentVC?.presentedViewController {
               DocsLogger.info("commentVC is presenting vc:\(vc.self)", component: LogComponents.comment)
               return
            }
            if !atInputTextView.isSelectingImage {
                atInputTextView.textViewResignFirstResponder()
                if !model.sended {
                    self.scheduler?.dispatch(action: .interaction(.clickClose))
                }
            }
        default:
            scheduler?.dispatch(action: .ipc(.setFloatCommentMode(mode: .browseMode), nil))
        }
    }
    
    private func handleAsideTextViewDidEndEditing(_ atInputTextView: AtInputViewType) {
        guard let commentWrapper = atInputTextView.commentWrapper else {
            DocsLogger.error("didEndEditing fail", component: LogComponents.comment)
            return
        }
        let commentId = commentWrapper.comment.commentID
        let replyId = commentWrapper.commentItem.replyID
        scheduler?.dispatch(action: .ipc(.resignKeyboard(commentId: commentId, replyId: replyId), nil))
        if commentWrapper.commentItem.viewStatus.isEdit {
            scheduler?.dispatch(action: .ipc(.setReplyMode(commentId: commentId, becomeResponser: false), nil))
            scheduler?.dispatch(action: .ipc(.refresh(commentId: commentId, replyId: nil), nil))
        }
    }
    
    func handleClickInputBarView() {
        guard let comment = context?.scheduler?.fastState.activeComment,
              let item = comment.commentList.last else {
            DocsLogger.error("fastState item is nil", component: LogComponents.comment)
            return
        }
        scheduler?.dispatch(action: .ipc(.setFloatCommentMode(mode: .reply(item)), nil))
        context?.scheduler?.dispatch(action: .tea(.beginEdit))
    }
    
    
    func handleClickInputBarSendBtn(_ textView: AtInputTextView, _ attributedText: NSAttributedString, _ imageList: [CommentImageInfo]) {
        guard let innerTextView = textView.inputTextView else { return }
        textView.textViewSet(attributedText: attributedText)
        textView.inputTextView?.updatePreviewWithImageInfos(imageList)

        if innerTextView.textView.text.isEmpty == false ||
            innerTextView.inputImageInfos.count > 0 {
            textView.didClickSendButtonFromeSideCar()
        } else {
            DocsLogger.info("content is nil", component: LogComponents.comment)
        }
    }

    func handleDriveKeyBoardChange(options: Keyboard.KeyboardOptions) {
        guard let fastState = context?.scheduler?.fastState else {
            DocsLogger.error("fastState is nil", component: LogComponents.comment)
            return
        }
        if options.event == .willHide || options.event == .didHide {
            // 设置成浏览模式
            scheduler?.dispatch(action: .ipc(.setDriveCommentMode(mode: .browseMode), nil))
            
        } else if options.event == .didShow || options.event == .willShow {
            saveKeyBoardHeightIfNeed(options)
            if fastState.mode == .browseMode {
                // 设置成回复模式
                guard let comment = context?.scheduler?.fastState.activeComment,
                      let item = comment.commentList.last else {
                    DocsLogger.error("fastState item is nil", component: LogComponents.comment)
                    return
                }
                scheduler?.dispatch(action: .ipc(.setDriveCommentMode(mode: .reply(item)), nil))
            } else {
                // 已经是replyMode 或者 editMode
            }
            if options.event == .didShow {
                if case .newInput = fastState.mode {
                    context?.scheduler?.dispatch(action: .tea(.beginEdit))
                }
            }
        }
    }
    
    func handleFloatKeyBoardChange(options: Keyboard.KeyboardOptions) {
        guard let fastState = context?.scheduler?.fastState else {
            DocsLogger.error("fastState is nil", component: LogComponents.comment)
            return
        }
        if options.event == .willHide || options.event == .didHide {
            // do nothing
            
        } else if options.event == .didShow || options.event == .willShow {
            saveKeyBoardHeightIfNeed(options)
            
            /// 如果是新建评论，不需要处理键盘起来的操作
            if case .newInput = fastState.mode {
                return
            }
            // 如果当前不是reply/edit mode，说明键盘可能是被系统中断又恢复，因为一般是先设置mode
            // 再激活/下掉键盘
            // 这时直接重制到browseMode下掉键盘（不能确定之前的item是否被删除，兼容太多场景易出bug）
            if fastState.mode == .browseMode {
                DocsLogger.warning("reset to preMode", component: LogComponents.comment)
                scheduler?.dispatch(action: .ipc(.setFloatCommentMode(mode: fastState.preMode ?? .browseMode), nil))
            } else {
                // TODO: - hyf 这里实现的效果不好
                // scroll to bottom
                let count = fastState.activeComment?.commentList.count ?? 1
                let dest = IndexPath(row: count - 1, section: 0)
                scheduler?.reduce(state: .foucus(indexPath: dest, position: .bottom, highlight: false))
            }
            
            if options.event == .didShow {
                if case .newInput = fastState.mode {
                    context?.scheduler?.dispatch(action: .tea(.beginEdit))
                }
            }
        }
    }

    func saveKeyBoardHeightIfNeed(_ options: Keyboard.KeyboardOptions) {
        if options.event == .didShow {
            let height = options.endFrame.height
            let minimumHeight: CGFloat = 180
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            let newHeight = height - (isPad ? SKDisplay.keyboardAssistantBarHeight : 0)
            // 系统键盘通知经常会有一些100-200左右高度的奇怪参数，过滤掉
            if newHeight > minimumHeight || newHeight == 0 {
                keyboardDidShowHeight = newHeight
            }
        }
    }

    func handleAsideKeyBoardChange(options: Keyboard.KeyboardOptions, item: CommentItem) {
        let event = options.event
        saveKeyBoardHeightIfNeed(options)
        // 设置table bottom inset
        let vcToolbarHeight = self.context?.vcToolbarHeight ?? 0
        let height = options.endFrame.height
        var bottom = height - vcToolbarHeight
        if event == .willHide || event == .didHide {
            bottom = 0
        }
        guard let scheduler = scheduler else { return }
        if context?.docsInfo?.isInVideoConference == true,
           scheduler.fastState.followRole == .follower {
            DocsLogger.error("follower should not response to keyBoardChange", component: LogComponents.comment)
            return
        }
        
        // 确保textView滚动到键盘顶部
        if options.endFrame != .zero, options.event == .willShow || options.event == .didShow || options.event == .willHide {
            let commentId = item.commentId ?? ""
            scheduler.dispatch(action: .ipc(.fetchIndexPath(commentId: commentId, replyId: item.replyID), { indexPath, error in
                if let idx = indexPath as? IndexPath {
                    scheduler.reduce(state: .scrollAboveKeyboard(toIndexPath: idx, keyboardFrame: options.endFrame, bottomInset: bottom, duration: options.animationDuration / 2.0))
                } else {
                    DocsLogger.error("fetch cId:\(commentId) rId:\(item.replyID) indexPath error", error: error, component: LogComponents.comment)
                }
            }))
        }
    }
}


// MARK: - AtInputTextViewDependency

// MARK: - text config
extension CommentTextPlugin: AtInputTextViewDependency {

    var commentDocsInfo: CommentDocsInfo? { docsInfo }

    var commentConentView: UIView? {
        return context?.commentPluginView
    }
    
    var fileType: DocsType {
        return docsInfo?.inherentType ?? .doc
    }
    
    var fileToken: String {
        return docsInfo?.token ?? ""
    }
    
    var docsInfo: DocsInfo? {
        if let docsInfo = context?.docsInfo {
            return docsInfo
        } else {
            return context?.businessDependency?.commentDocsInfo as? DocsInfo
        }
    }

    /// 确定mention时返回的内容有哪些
    var atViewType: AtViewType {
        let isInDocs = docsInfo?.isInCCMDocs ?? true
        if docsInfo?.type == .minutes {
            return .minutes
        } else if isInDocs == false {
            return .gadget
        } else {
            return .comment
        }
    }
    
    var atInputTextType: AtInputTextType {
        guard let pattern = context?.pattern else {
            return .add
        }
        if pattern == .float {
            if case .newInput = context?.scheduler?.fastState.mode {
                return .add
            } else {
                return .reply
            }
        } else if pattern == .aside {
            if context?.scheduler?.fastState.activeComment?.isNewInput == true {
                return .add
            } else {
                return .reply
            }
        }
        return .reply
    }
    
    var canSupportPic: Bool {
        // 小程序不支持
        if let docsInfo = self.docsInfo,
           docsInfo.isInCCMDocs == false {
            return false
        }
        if context?.pattern == .drive {
            return false
        } else {
            return true
        }
    }
    
    var textViewInToolView: Bool {
        guard let pattern = context?.pattern else {
            return false
        }
        switch pattern {
        case .aside:
            return false
        case .drive, .float:
            return true
        }
    }
    
    var atListViewInToolView: Bool {
        guard let pattern = context?.pattern else {
            return false
        }
        switch pattern {
        case .aside:
            return false
        case .drive:
            return true
        case .float:
            if SKDisplay.pad, case .newInput = context?.scheduler?.fastState.mode {
                // iPad窄屏模式使用popver
                let isRegularSize = context?.commentPluginView.isMyWindowRegularSize() ?? false
                let inVC = docsInfo?.isInVideoConference ?? false
                return !(isRegularSize && inVC)
            }
            return true
        }
    }
    
    var commentDraftScene: CommentDraftKeyScene? {
        guard let pattern = context?.pattern else {
            return nil
        }
        if let fastState = scheduler?.fastState,
           let mode = fastState.mode {
            if pattern == .float {
                switch mode {
                case let .newInput(model):
                    return model.draftKey.sceneType
                case .browseMode, .reply:
                    return .newReply(commentId: fastState.activeCommentId ?? "")
                case let .edit(item):
                    return .editExisting(commentId: item.commentId ?? "", replyId: item.replyID)
                }
            } else if pattern == .drive {
                switch mode {
                case .browseMode, .reply:
                    return .newReply(commentId: fastState.activeCommentId ?? "")
                case let .edit(item):
                    return .editExisting(commentId: item.commentId ?? "", replyId: item.replyID)
                default:
                    break
                }
            }
        }
        return nil
    }
    
    var needMagicLayout: Bool {
        guard let pattern = context?.pattern else {
            return false
        }
        return pattern != .aside
    }
    
    var canSupportVoice: Bool? {
        let isInVC = docsInfo?.isInVideoConference == true
        let isInDocs = docsInfo?.isInCCMDocs == true
        let canSupportVoice = !isInVC && isInDocs
        if !canSupportVoice {
            DocsLogger.error("canSupportVoice is false, isInVC:\(isInVC) isInDocs:\(isInDocs)", component: LogComponents.comment)
        }
        return canSupportVoice
    }
    
    public func showMutexDialog(withTitle str: String) {
        let dialog = UDDialog()
        dialog.setTitle(text: str)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Ok)
        context?.topMost?.present(dialog, animated: true)
        let identifier = context?.scheduler?.fastState.activeComment?.menuKey ?? "MutexDialog"
        let wrapper = MenuWeakWrapper(menuVC: dialog, identifier: identifier)
        context?.scheduler?.dispatch(action: .ipc(.setMenu(wrapper), nil))
    }
    
    public var supportAtSubtypeTag: Bool {
        var isWholeComment = false
        if case let .newInput(model) = context?.scheduler?.fastState.mode {
            isWholeComment = model.isWhole
        }
        // 全文评论前端历史代码不兼容Subtype解析，发送全文评论时不加Subtype
        return UserScopeNoChangeFG.HYF.commentWikiIcon && !isWholeComment
    }
    
    var canShowDraftDarkName: Bool {
        return context?.businessDependency?.businessConfig.canShowDarkName ?? true
    }
}

// MARK: - text action

extension CommentTextPlugin {
    
    func willSendCommentContent(_ atInputTextView: AtInputViewType, content: CommentContent) -> Bool {
        if !DocsNetStateMonitor.shared.isReachable {
            DocsLogger.error("newwork is is not reachable", component: LogComponents.comment)
            scheduler?.reduce(state: .toast(.failure(BundleI18n.SKResource.Doc_Doc_CommentSendFailed)))
            return false
        }
        return true
    }
    
    func didSendCommentContent(_ atInputTextView: AtInputViewType, content: CommentContent) {
        guard let pattern = context?.pattern else { return }
        switch pattern {
        case .aside:
            handleSendAsideComment(atInputTextView, content: content)
        case .float:
            handleSendCardComment(atInputTextView, content: content)
        case .drive:
            handleSendCardComment(atInputTextView, content: content)
        }
    }
    

    func handleSendCardComment(_ atInputTextView: AtInputViewType, content: CommentContent) {
        guard let fastState = context?.scheduler?.fastState,
        let comment = fastState.activeComment else {
            DocsLogger.error("fastState is nil", component: LogComponents.comment)
            return
        }
        guard let mode = fastState.mode else {
            DocsLogger.error("comment mode nil", component: LogComponents.comment)
            return
        }
        switch mode {
        case let .newInput(model):
            switch model.type {
            case .new:
                scheduler?.dispatch(action: .api(.addComment(content, model.toCommentWrapper()), nil))
            case .edit:
                // 目前暂时只有编辑评论场景 
                scheduler?.dispatch(action: .api(.editComment(content, model.toCommentWrapper()), nil))
            }
            var sendModel = model
            sendModel.markSended()
            scheduler?.dispatch(action: .ipc(.setFloatCommentMode(mode: .newInput(sendModel)), nil))
            atInputTextView.clearAllContent()
            scheduler?.dispatch(action: .ipc(.clearDraft(draftKey: model.draftKey),
                                             nil))
            scheduler?.reduce(state: .dismiss) // 主动关掉
        case .browseMode: // 点击的floatBar的send按钮
            let item = comment.commentList.first ?? CommentItem() // 其实没有使用到
            scheduler?.dispatch(action: .api(.addComment(content, CommentWrapper(commentItem: item, comment: comment)), nil))
            scheduler?.dispatch(action: .ipc(.clearDraft(draftKey: item.newReplyKey),
                                             nil))
        case let .reply(item):
            scheduler?.dispatch(action: .api(.addComment(content, CommentWrapper(commentItem: item, comment: comment)), nil))
            scheduler?.dispatch(action: .ipc(.clearDraft(draftKey: item.newReplyKey),
                                             nil))
            if context?.pattern == .float {
                scheduler?.dispatch(action: .ipc(.setFloatCommentMode(mode: .browseMode), nil))
            } else {
                scheduler?.dispatch(action: .ipc(.setDriveCommentMode(mode: .browseMode), nil))
            }

        case let .edit(item):
            scheduler?.dispatch(action: .api(.editComment(content, CommentWrapper(commentItem: item, comment: comment)), nil))
            scheduler?.dispatch(action: .ipc(.clearDraft(draftKey: item.editDraftKey),
                                             nil))
            if context?.pattern == .float {
                scheduler?.dispatch(action: .ipc(.setFloatCommentMode(mode: .browseMode), nil))
            } else {
                scheduler?.dispatch(action: .ipc(.setDriveCommentMode(mode: .browseMode), nil))
            }
        }
    }

    func handleSendAsideComment(_ atInputTextView: AtInputViewType, content: CommentContent) {
        guard let wrapper = atInputTextView.commentWrapper else {
            return
        }

        let item = wrapper.commentItem
        let commentId = wrapper.comment.commentID
        
        // 还原输入框状态
        atInputTextView.shrinkTextView(maxHeight: 74)
        atInputTextView.clearAllContent()
        
        // atInputTextView.textViewResignFirstResponder()
        // 标记下掉键盘 & 清空草稿
        scheduler?.dispatch(action: .ipc(.resignKeyboard(commentId: commentId, replyId: item.replyID), nil))
        scheduler?.dispatch(action: .ipc(.clearDraft(draftKey: wrapper.commentItem.commentDraftKey),
                                         nil))

        if case .reply = item.viewStatus {
            scheduler?.dispatch(action: .ipc(.refresh(commentId: commentId,
                                                              replyId: item.replyID),
                                                     nil))
            // 开始发送回复/新增评论
            scheduler?.dispatch(action: .api(.addComment(content, wrapper), nil))
        } else {
            scheduler?.dispatch(action: .ipc(.setReplyMode(commentId: nil,
                                                                   becomeResponser: false),
                                                     nil))
            scheduler?.dispatch(action: .ipc(.refresh(commentId: commentId,
                                                              replyId: nil),
                                                     nil))
            // 开始发送编辑评论
            scheduler?.dispatch(action: .api(.editComment(content, wrapper), nil))
        }
    }
    
    /// 取消语音输入
    func didCancelVoiceCommentInput(_ atInputTextView: AtInputViewType) {
        didTapBlankView(atInputTextView)
    }
    
    /// 点击空白处
    func didTapBlankView(_ atInputTextView: AtInputViewType) {
        // 不会走这里
    }
    
    func handleTapBlank() {
        // TODO: - hyf埋点
        let action = CommentAction.ipc(.fetchSnapshoot, { [weak self] (result, error) in
            guard let snapshoot = result as? CommentSnapshootType else {
                DocsLogger.error("tap blank fetch error", error: error, component: LogComponents.comment)
                return
            }
            self?._handleTapBlank(snapshoot)
        })
        scheduler?.dispatch(action: action)
    }
    
    func _handleTapBlank(_ snapshoot: CommentSnapshootType) {
        guard let pattern = context?.pattern else { return }
        switch pattern {
        case .aside:
            if snapshoot.viewStatus.isFirstResponser {
                if snapshoot.viewStatus.isEdit { // 编辑模式
                    // 设置编辑态
                    self.scheduler?.dispatch(action: .ipc(.setReplyMode(commentId: nil, becomeResponser: false), nil))
                    self.scheduler?.dispatch(action: .ipc(.refresh(commentId: snapshoot.commentId, replyId: nil), nil))
                } else {
                    // 标记下掉键盘
                    scheduler?.dispatch(action: .ipc(.resignKeyboard(commentId: snapshoot.commentId, replyId: snapshoot.replyId), nil))
                    
                    // 更新UI
                    scheduler?.reduce(state: .updateItems([snapshoot.indexPath]))
                }
            }
            // 如果是新建评论，需要向前端发起取消新建评论交互
            scheduler?.dispatch(action: .api(.cancelPartialNewInput, nil))
        case .float:
           // 局部评论不会走这里了
           break
        case .drive:
            break
        }
        
    }
    
    func resignInputView() {
        guard context?.pattern == .float else { return }
        context?.scheduler?.dispatch(action: .interaction(.tapBlank))
    }
    
    func didCopyCommentContent() {
        context?.businessDependency?.didCopyCommentContent()
    }
}


// MARK: - showInvite
extension CommentTextPlugin {
    var canSupportInviteUser: Bool {
        return self.canSupportInviteUser(docsInfo)
    }
    
    public func showInvitePopoverTips(at: AtInfo, rect: CGRect, inView: UIView) {
        scheduler?.dispatch(action: .ipc(.showTextInvite(at: at, rect: rect, inView: inView), nil))
    }
}
