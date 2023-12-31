//
//  AtInputTextView+Public.swift
//  SKCommon
//
//  Created by chenhuaguan on 2021/2/8.
//

import SKFoundation
import SKResource
import SpaceInterface

extension AtInputTextView {

    public func textviewBecomeFirstResponder(_ focusType: AtInputFocusType = .new) {
        guard let inputTextView = inputTextView else { return }

        textViewShouldLogInputAction(focusType)

        self.focusType = focusType
        inputTextView.textView.becomeFirstResponder()
        DocsLogger.info("textview BecomeFirstResponder", component: LogComponents.comment)
    }

    public func textViewResignFirstResponder(_ focusType: AtInputFocusType = .new) {
        guard let inputTextView = inputTextView else { return }

        if self.focusType == .edit {
            inputTextView.textView.text = ""
            inputTextView.updatePreviewWithImageInfos([])
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500) {
            self.focusType = focusType
        }
        toolBar.setAtButton(select: false)
        toolBar.setImageButton(select: false)
        toolBar.setVoiceButton(select: false)
        inputTextView.textView.resignFirstResponder()
        inputTextView.dismissVoiceViewIfNeed(reload: false)
        inputTextView.dismissSelectImageView(reload: false)
        if self.dependency?.textViewInToolView == true {
            self.toolBar.isHidden = false
        }
        NotificationCenter.default.post(name: Notification.Name.commentCancelForcePotraint, object: nil)
        DocsLogger.info("textView resignFirstResponder", component: LogComponents.comment)
    }

    public func textViewIsFirstResponder() -> Bool {
        guard let inputTextView = inputTextView else { return false }

        return inputTextView.textView.isFirstResponder
    }

    public func textViewSet(attributedText: NSAttributedString) {
        guard let inputTextView = inputTextView else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        inputTextView.textView.attributedText = attributedText
        CATransaction.commit()
    }

    public func textViewSet(text: String) {
        guard let inputTextView = inputTextView else { return }
        inputTextView.textView.text = text
    }
    
    public func clearAllContent() {
        inputTextView?.textView.text = ""
        inputTextView?.textView.attributedText = nil
        inputTextView?.clearPreviewImage()
        refreshPlaceholder(nil)
        inputTextView?.textView.dingOut()
        toolBar.setSendBtnEnable(enable: false)
        inputTextView?.textView.touchPlaceholder()
        inputTextView?.shrinkTextView()
    }


    func refreshPlaceholder(_ placeHolder: String?) {
        guard let inputTextView = inputTextView else { return }

        if let placeHolder = placeHolder {
            inputTextView.placeholder = placeHolder
        } else {
            guard let dependency = dependency else { return }
            switch dependency.atInputTextType {
            case .none, .docs, .photo, .add: // @某人 与他讨论
                inputTextView.placeholder = BundleI18n.SKResource.Doc_Doc_CommentDot
            case .cards, .reply: // 回复评论
                inputTextView.placeholder = BundleI18n.SKResource.Doc_Doc_ReplyCommentDot
            case .global: // @某人 与他讨论
                inputTextView.placeholder = BundleI18n.SKResource.Doc_Doc_GlobalCommentDot
            }
        }
    }

    // 仅上报评论框可输入的事件
    public func textViewShouldLogInputAction(_ focusType: AtInputFocusType = .new) {
        guard let inputTextView = inputTextView else { return }

        if inputTextView.textView.isFirstResponder == false {
            // 埋点
            CommentTracker.log(.input_comment, atInputTextView: self)

            if focusType == .edit {
                // 埋点
                CommentTracker.log(.re_edit_comment, atInputTextView: self)
            }
        }
    }
    
    public func hideImagePickerView() {
        if self.isSelectingImage {
            inputTextView?.selectImgView?.presentVC?.dismiss(animated: false)
        }
    }
}
