//
//  AtInputTextView+TextViewDelegate.swift
//  SKCommon
//
//  Created by chenhuaguan on 2021/2/8.
//

import SKFoundation
import SpaceInterface
import SKCommon
import SKInfra

extension AtInputTextView: InputTextViewDependency {

    var docsInfo: DocsInfo? {
        return dependency?.commentDocsInfo as? DocsInfo
    }

    var keyboardDidShowHeight: CGFloat? {
        return dependency?.keyboardDidShowHeight
    }

    var canSupportPic: Bool {
        return dependency?.canSupportPic ?? false
    }

    var iPadNewStyle: Bool {
        return dependency?.textViewInToolView == false
    }

    func customSelectBoxButton() -> UIButton? {
        return dependency?.customSelectBoxButton()
    }

    func textViewDidClickVoiceButton(_ textView: UITextView, isTap: Bool) {
        guard !UIApplication.shared.statusBarOrientation.isLandscape else { return }
        toolBar.setImageButton(select: false)
        toolBar.setAtButton(select: false)
        hideAtListView()

        dependency?.didClickRecord(self)

        let mode = isTap ? "click" : "press"
        CommentTracker.log(.create_audiocomment, atInputTextView: self, extraInfo: ["mode": mode])
    }

    func textViewDidClickVoiceCancelButton(_ textView: UITextView) {
        // 取消发送逻辑，清空数据
        dependency?.didCancelVoiceCommentInput(self)
    }

    func imagePreviewDidChange() {
        textChangeDelegate?.imagePreviewDidChange()
        toolBar.setImageButton(enable: true)
        let key = commentDraftKey
        let imageInfos = inputTextView?.inputImageInfos ?? []
        let images = imageInfos.map { CommentDraftImage(from: $0) }
        CommentDraftManager.shared.updateCommentImages(images, for: key)
    }

    func textViewDidChange(_ textView: UITextView) {
        textChangeDelegate?.textViewDidChange(textView)
        saveCommentDraftManually() // 语音评论产生的文字变化, 手动保存下
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        guard let attributedString = textView.attributedText else {
            return
        }

        let currentRange = textView.selectedRange

        if currentRange.length > 0 { // 选择文本的时候不限制
            return
        }

        let totalRange = NSRange(location: 0, length: attributedString.length)
        attributedString.enumerateAttribute(AtInfo.attributedStringAtInfoKey, in: totalRange, options: .reverse) { (attrs, atRange, _) in
            if currentRange.location >= atRange.location + atRange.length
                || currentRange.location <= atRange.location
                || attrs == nil { // 不在范围不做处理
                return
            }

            if lastTextViewSelectedRange.location < currentRange.location {
                textView.selectedRange = NSRange(location: atRange.location + atRange.length, length: 0)
            } else {
                textView.selectedRange = NSRange(location: atRange.location, length: 0)
            }
        }

        lastTextViewSelectedRange = textView.selectedRange
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let dependency = dependency else { return true }
        let responseSign = String(dependency.responseSign)
        // 1. 处理@相关逻辑
        if text == responseSign {
            // 1.1 是否响应@
            let shouldRespond = AtInputProcessor.shouldRespondToAt(text, replaceRange: range)

            if shouldRespond {
                keyword.accept(String(dependency.responseSign))

                if innerIsShowingAtListView.value == false,
                   dependency.atListViewInToolView == false {
                    self.atRange = range
                }
                // 1.2 展示@面板
                showAtListView()
            }
        }

        // 2. 处理删除逻辑
        if text.isEmpty, range.length != 0 {
            let hasDelete = AtInfo.deleteAtInfoIfNeeded(textView, range)
            if hasDelete { // 执行了删除atinfo
                saveCommentDraftManually()
            } else if innerIsShowingAtListView.value,
                      atRange?.location == range.location {
                let deletedCharacter = (textView.text as NSString).substring(with: range)
                if deletedCharacter == responseSign {
                    hideAtListView()
                }
            }
            return !hasDelete
        }

        return true
    }

    func didClickInsertImageIcon(show: Bool) {
        if show {
            CommentTracker.log(.click_image_icon, atInputTextView: self)
            // 如果正在展示 @列表, 则关闭它
            if innerIsShowingAtListView.value == true {
                hideAtListView()
            }
            inputTextView?.dismissVoiceViewIfNeed()
            toolBar.setVoiceButton(select: false)
        }
    }
    
    func updateContentStatus(hasContent: Bool) {
        toolBar.setSendBtnEnable(enable: hasContent)
    }

    func updateImageSelectStatus(select: Bool) {
        toolBar.setImageButton(select: select)
    }

    func updateVoiceSelectStatus(select: Bool) {
        toolBar.setVoiceButton(select: select)
    }

    func keyBoardEnterHandler() {
        doSend()
    }

    func voiceSendBtnHandler() {
        doSend(from: .voiceCommentView)
    }
    
    func willTransformImageInfo() {
        DispatchQueue.main.async {
           self.toolBar.setImageButton(enable: false)
        }
    }
    
    func finishTransformImageInfo() {
        DispatchQueue.main.async {
            self.toolBar.setImageButton(enable: true)
        }
    }
    
    var diableTextMultiLine: Bool {
        return dependency?.diableTextMultiLine ?? false
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        textChangeDelegate?.textViewDidBeginEditing(self)
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        textChangeDelegate?.textViewDidEndEditing(self)
    }
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return textChangeDelegate?.textViewShouldBeginEditing(self) ?? true
    }
    
    public func showMutexDialog(withTitle str: String) {
        dependency?.showMutexDialog(withTitle: str)
    }
    
    public var mediaMutex: SKMediaMutexDependency? {
        DocsContainer.shared.resolve(SKMediaMutexDependency.self)
    }
    
    func textViewDidCopyContent() {
        dependency?.didCopyCommentContent()
    }
    
    func clearVoiceText() {
        saveCommentDraftManually()
    }
}
