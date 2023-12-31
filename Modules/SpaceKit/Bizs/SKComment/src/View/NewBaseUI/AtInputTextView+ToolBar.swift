//
//  AtInputTextView+ToolBar.swift
//  SKCommon
//
//  Created by chenhuaguan on 2021/2/8.
//

import Foundation
import SpaceInterface
import SKFoundation

extension AtInputTextView {

    func setupToolBarView() -> CommentToolBar {
        let barView = CommentToolBar(delegate: self)
        return barView
    }
    
    public var isSelectingImage: Bool {
        return toolBar.isSelectingImage
    }
}

extension AtInputTextView: CommentToolBarDelegate {

    var supportPic: Bool {
        return dependency?.canSupportPic ?? false
    }
    func selectBoxButton() -> UIButton? {
        return dependency?.customSelectBoxButton()
    }
    
    var supportVoice: Bool? {
        return dependency?.canSupportVoice
    }

    func didClickInsertImageIcon(select: Bool) {
        inputTextView?.stopRecordingIfNeed()
        var isSelectingVoice = false
        if let _ = inputTextView?.textView.inputView as? VoiceCommentViewV2 {
            isSelectingVoice = true
        }
        let willShowImagePicker = { [weak self] () -> Bool in
            guard let self = self else { return false }
            // toolbar不在AtInputTextView中显示时，插入图片事件传给外面
            guard self.dependency?.textViewInToolView == true else {
                let leftImageCount = CommentImageInfo.commentImageMaxCount - (self.inputTextView?.inputImageInfos.count ?? 0)
                if isSelectingVoice {
                    let delayTime: TimeInterval = 0.1
                    DispatchQueue.main.asyncAfter(wallDeadline: .now() + delayTime) { [weak self] in
                        guard let self = self else { return }
                        self.textChangeDelegate?.textViewDidTriggerInsertImageAction(maxCount: leftImageCount, { [weak self] (result) in
                            self?.inputTextView?.handleImagePickerResult(result: result)
                        })
                    }
                } else {
                    self.textChangeDelegate?.textViewDidTriggerInsertImageAction(maxCount: leftImageCount, { [weak self] (result) in
                        self?.inputTextView?.handleImagePickerResult(result: result)
                    })
                }
                return false
            }
            return true
        }
        if self.inputTextView?.didClickSelectImgBtn(willShowImagePicker: willShowImagePicker) == true {
            CommentTracker.log(.click_image_icon, atInputTextView: self)
            // 如果正在展示 @列表, 则关闭它
            hideAtListView()
        }
        toolBar.setAtButton(select: false)
        toolBar.setVoiceButton(select: false)
    }

    func didClickSendIcon(select: Bool) {
        DocsLogger.info("clickSendIcon", component: LogComponents.comment)
        if textChangeDelegate?.textViewShouldBeginEditing(self) == false {
            DocsLogger.error("textView can not edit by permission denied", component: LogComponents.comment)
            return
        }
        doSend()
    }
    
    func didClickAtIcon(select: Bool) {
        // 如果正在展示 @列表 则不处理
        guard !innerIsShowingAtListView.value else {
            hideAtListView()
            return
        }

        toolBar.setVoiceButton(select: false)
        toolBar.setImageButton(select: false)
        //如果在展示imageSelectingView,关闭它
        inputTextView?.stopRecordingIfNeed()
        inputTextView?.closeInsertPicViewIfNeed()
        let sign = String(dependency?.responseSign ?? "@")
        inputTextView?.textView.insertText(sign)
        keyword.accept(sign)
        showAtListView()
    }

    func didClickVoiceIcon(_ gesture: UITapGestureRecognizer) {
        inputTextView?.voiceTap(gesture)
        hideAtListView()
        toolBar.setAtButton(select: false)
        toolBar.setImageButton(select: false)
    }
    
    func didLongPressVoiceBtn(_ gesture: UILongPressGestureRecognizer) {
        inputTextView?.voiceLongPress(gesture)
        hideAtListView()
    }
    
    func didClickResignKeyboardBtn(select: Bool) {
        dependency?.resignInputView()
    }
     
    func willResignActive() {
        if let voiceView = inputTextView?.textView.inputView as? VoiceCommentViewV2 {
            if voiceView.isVoiceButtonOn.value == true {
                // 长按语音同时又退到后台，直接下掉键盘吧，太多badcase了
                textViewResignFirstResponder()
            } else {
                inputTextView?.stopRecordingIfNeed(changeValue: false)
            }
        } else if toolBar.isSelectingVoice {
            textViewResignFirstResponder()
        }
    }

}
