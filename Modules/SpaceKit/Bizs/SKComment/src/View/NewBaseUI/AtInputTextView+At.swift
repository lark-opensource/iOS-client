//
//  AtInputTextView+At.swift
//  SKCommon
//
//  Created by chenhuaguan on 2021/2/8.
//
// swiftlint:disable cyclomatic_complexity

import Foundation
import SKFoundation
import SKResource
import RxSwift
import RxCocoa
import SnapKit
import SKUIKit
import UniverseDesignToast
import CoreGraphics
import LarkEMM
import SpaceInterface
import SKCommon
import SKInfra

extension AtInputTextView {

    func setupAtBind() {
        guard let inputTextView = inputTextView else { return }
        atListView.selectAction = { [weak self] atInfo, _, _ in
            if let atInfo = atInfo {
                // 1. 处理@信息
                self?.onAtListViewSelected(atInfo)
                // 2. 隐藏@列表
                self?.hideAtListView()
            }
        }

        // 监听 TextView 内容变化
        inputTextView.textObservale.asDriver().drive(onNext: { [weak self] text in
            guard let self = self else { return }

            if text.isEmpty { // 1. 内容为空隐藏 @
                self.hideAtListView()
                inputTextView.textView.invalidateIntrinsicContentSize() // Fix: 文本为空时，不会 layoutSubviews
                return
            }

            if self.innerIsShowingAtListView.value { // 2. 假设正在显示@列表就拼接 keyword
                self.setKeyword(text, selectRange: inputTextView.textView.selectedRange)
            }
        }).disposed(by: disposeBag)

        let isShowingAtListViewSkipFirst = innerIsShowingAtListView.skip(1)

        // @列表关闭，清空 keyword
        // 第一次进入肯定@列表是隐藏的，忽略第一次无用的信号
        isShowingAtListViewSkipFirst.subscribe(onNext: { [weak self] isShowing in
            if !isShowing {
                self?.keyword.accept("")
            }
        }).disposed(by: disposeBag)

        // 正在展示列表的时候，如果 keyword 发生了改变，则去请求新的@数据
        // 跳过前两次的初始化
        let debounceKeyword = keyword.skip(2).debounce(DispatchQueueConst.MilliSeconds_250, scheduler: MainScheduler.instance).distinctUntilChanged()
        Observable
            .combineLatest(debounceKeyword, isShowingAtListViewSkipFirst)
            .filter({ !$0.isEmpty && $1 }) // keyword 非空 & 正在展示列表
            .subscribe(onNext: { [weak self] (kw, _) in
                self?.refreshAtListView(kw)
                DocsLogger.info("刷新keyword")
            }).disposed(by: disposeBag)

        isShowingAtListViewSkipFirst.subscribe(onNext: { [weak self] (isShowing) in
                self?.toolBar.setAtButton(select: isShowing)
            }).disposed(by: disposeBag)

        inputTextView.isRecordingObservable
            .observeOn(MainScheduler.instance)
            .bind { [weak self] (isOn) in
                guard let self = self else { return }
                self.toolBar.setVoiceButton(select: isOn)
                if isOn {
                    if self.dependency?.textViewInToolView == true, !inputTextView.isLongPressVoicing {
                        if !UIApplication.shared.statusBarOrientation.isLandscape {
                            self.toolBar.isHidden = true
                            // 组件不支持，横屏下暂时禁用语音输入
                            self.updateTextViewStatus(isRecord: isOn)
                            inputTextView.stretchTextView()
                            self.isRecording = true
                        }
                    }
                } else {
                    if self.dependency?.textViewInToolView == true, !inputTextView.isLongPressVoicing {
                        if !UIApplication.shared.statusBarOrientation.isLandscape {
                            self.toolBar.isHidden = false
                            // 组件不支持，横屏下暂时禁用语音输入
                            self.updateTextViewStatus(isRecord: isOn)
                            inputTextView.shrinkTextView()
                            self.isRecording = false
                        }
                    }
                }
            }.disposed(by: disposeBag)

        inputTextView.textView.pasteOperation = { [weak self] sender in
            guard let self = self else { return }
            guard let text = SKPasteboard.string(psdaToken: PSDATokens.Pasteboard.docs_comment_input_do_paste) else { return }
            let candidateUrl = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let item = self.disableSendButtonTemporary()
            InternalDocAPI().getAtInfoByURL(candidateUrl)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] res in
                    item.cancel()
                    self?.recoverSendButtonStatus()
                    switch res {
                    case .success(let atInfo):
                        // 使用原始URL，后台返回的URL可能会出错以及漏掉参数
                        atInfo.href = candidateUrl
                        self?.replaceStringToAttachment(text, with: atInfo)
                    case .failure(let error):
                        DocsLogger.error("get atInfo by url failure", error: error)
                    }
                })
                .disposed(by: self.disposeBag)
        }
    }

    private func disableSendButtonTemporary() -> Dispatch.DispatchWorkItem {
        guard UserScopeNoChangeFG.HYF.disableSendWhenParsingUrl else {
            return .init {}
        }
        self.toolBar.setSendBtnEnable(enable: false)
        self.toolBar.requestingURLInfo = true
        let item = Dispatch.DispatchWorkItem {
            [weak self] in
           self?.recoverSendButtonStatus()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_2500, execute: item)
        return item
    }
    
    func recoverSendButtonStatus() {
        guard UserScopeNoChangeFG.HYF.disableSendWhenParsingUrl else { return }
        self.toolBar.requestingURLInfo = false
        guard let inputTextView = inputTextView else { return }
        if !inputTextView.textView.text.isEmpty {
            self.toolBar.setSendBtnEnable(enable: true)
        }
    }

    private func setKeyword(_ text: String, selectRange: NSRange) {
        guard let inputTextView = inputTextView else { return }

        // 1. 获取当前光标前的内容
        let index = AtInfo.removeEmojiLocation(with: inputTextView.textView, location: selectRange.location)
        let textBeforeSelectLocation = text.mySubString(to: index)
        // 2. 获取当前光标前@后面的内容
        let sign = dependency?.responseSign ?? "@"
        if let lastAtIndex = textBeforeSelectLocation.lastIndex(of: sign) {
            let keyword = String(textBeforeSelectLocation[lastAtIndex...])

            // 最后一个是空格或者回车，取消@操作
            if keyword.last == " " || keyword.last == "\n" {
                hideAtListView()
                self.keyword.accept("")
            } else {
                self.keyword.accept(keyword)
            }
        } else { // 找不到 @
            hideAtListView()
        }
    }

    // 生成 At 列表
    func setupAtListView() -> AtListView {
        let atConfig = AtDataSource.Config(chatID: nil,
                                           sourceFileType: dependency?.fileType ?? .doc,
                                           location: dependency?.atViewType ?? .docs,
                                                token: dependency?.fileToken ?? "")
        let dataSource = AtDataSource(config: atConfig)
        let atListView = AtListView(dataSource, type: dependency?.atViewType ?? .docs)
        atListView.clipsToBounds = false
        atListView.backgroundColor = .clear
        atListView.cancelAction = { [weak self] in
            self?.didClickAtIcon(select: false)
        }
        return atListView
    }

    // 隐藏@列表
    func hideAtListView() {
        self.toolBar.setAtButton(select: false)
        innerIsShowingAtListView.accept(false)
        if dependency?.atListViewInToolView == true {
            atListView.isHidden = true
            atListView.snp.updateConstraints { (make) in
                make.height.equalTo(0)
            }
        } else {
            textChangeDelegate?.hideAtListView()
        }

    }
    
    // 计算@列表的高度
    func calculateAtListViewHeight() -> CGFloat {
        // 在iPad上显示atListView高度会高一点
        var atListViewHeight: CGFloat = SKDisplay.pad ? 364 : 220
        
        if DocsType.commentSupportLandscapaeFg {
            if let containerView = dependency?.commentConentView {
                let frame = self.toolContentView.convert(toolContentView.bounds, to: containerView)
                let remainHeight = frame.origin.y
                DocsLogger.info("calculate atList height-- origin.Y: \(remainHeight), landscape: \(self.isChangeLandscape) containerViewSize:\(containerView.bounds.size)")
                atListViewHeight = min(atListViewHeight, remainHeight)
            }
        } else {
            if let keyboardDidShowHeight = dependency?.keyboardDidShowHeight, let window = self.window {
                let remainHeight = window.bounds.height - self.toolContentView.bounds.height - keyboardDidShowHeight
                atListViewHeight = min(atListViewHeight, remainHeight)
            }
        }
        DocsLogger.info("calculate atList height-- final height: \(atListViewHeight), landscape: \(self.isChangeLandscape)")
        return atListViewHeight
    }

    // 展示@列表
    func showAtListView() {
        self.inviteTipsView?.isHidden = true
        self.toolBar.setAtButton(select: true)
        innerIsShowingAtListView.accept(true)
        let atListViewHeight = self.calculateAtListViewHeight()
        if dependency?.atListViewInToolView == true {
            atListView.isHidden = false
            atListView.snp.updateConstraints { (make) in
                make.height.equalTo(atListViewHeight)
            }
        } else {
            if let textView = inputTextView?.textView {
                let rect = textView.caretRect(for: textView.selectedTextRange?.end ?? .init())
                textChangeDelegate?.textViewDidTriggerAtAction(self, at: rect)
            }
        }
        AtTracker.expose(parameter: [:], docsInfo: docsInfo)
    }

    // 刷新列表
    func refreshAtListView(_ keyword: String?) {
        // Keyword 的开头必须是 @
        guard let dependency = dependency else { return }
        let sign = dependency.responseSign
        if let char = keyword?.first, sign == char,
           var keyword = keyword, !(keyword.isEmpty) {
            keyword.removeFirst()
            if dependency.atListViewInToolView {
                var filter = AtDataSource.RequestType.atViewFilter
                if dependency.atViewType == .gadget {
                    filter = [.user]
                } else if dependency.atViewType == .minutes, keyword.isEmpty {
                    // minutes首次只展示人
                    filter = [.user]
                }
                atListView.refresh(with: keyword, filter: filter, animated: false)
            } else {
                textChangeDelegate?.atListViewShouldRefresh(keyword)
            }
        }
    }

    // 处理列表点击事件
    func onAtListViewSelected(_ atInfo: AtInfo) {
        replaceStringToAttachment(keyword.value, with: atInfo)
        if let textView = self.inputTextView?.textView {
            self.textChangeDelegate?.commentTextView(textView: textView, didMention: atInfo)
            saveCommentDraftManually()
        }
        var mentionId = atInfo.id ?? ""
        if atInfo.type != .user {
            mentionId = atInfo.token
        }
        var domain: AtTracker.Zone = isWhole ? .fullComment : .partComment
        if let type = docsInfo?.type, type == .file {
            // 对drive文件的全局评论, 上报的domain应该是fullComment
            // https://bytedance.feishu.cn/sheets/shtcnf70A3JLwKwoQbD9EWICw6g?sheet=65WpGw&table=tbl7qjrFt9Pf5vJD&view=vewVjnbAKC
            domain = .fullComment
        }
        AtTracker.mentionReport(type: atInfo.type.strForMentionType, mentionId: mentionId, isSendNotice: false, domain: domain, docsInfo: docsInfo, extra: CommentTracker.commonParams)
    }

    // 替换输入框的文字为 attachment
    private func replaceStringToAttachment(_ replacement: String, with atInfo: AtInfo) {
        guard let inputTextView = inputTextView, let dependency = self.dependency else { return }
        if dependency.supportAtSubtypeTag == false {
            atInfo.subType = nil
        }
        // 1. 获取 At Attriutes String
        if atInfo.type == .user, dependency.canSupportInviteUser == true, dependency.canShowDraftDarkName {
            let docsKey = AtUserDocsKey(token: dependency.fileToken, type: dependency.fileType)
            atInfo.hasPermission = AtPermissionManager.shared.hasPermission(atInfo.token, docsKey: docsKey) ?? true
        }
        let atAttrString = atInfo.attributedString(attributes: AtInfo.TextFormat.defaultAttributes(font: textFont, textColor: nil), lineBreakMode: .byWordWrapping)
        atInfo.iconInfo?.image.subscribe(onNext: { (_) in
            let range = NSRange(location: 0, length: inputTextView.textView.attributedText.length)
            inputTextView.textView.layoutManager.invalidateDisplay(forCharacterRange: range)
        }).disposed(by: disposeBag)

        // 2. 获取原文
        let textAttrString = NSMutableAttributedString(attributedString: inputTextView.textView.attributedText)

        // 3. 获取当前光标的位置
        let selectedRange = inputTextView.textView.selectedRange

        // 4. 查找光标前的字符创的最后一个需要替换的 keyword 的位置
        let location = selectedRange.location - replacement.count
        let replacementRange = NSRange(location: location, length: replacement.count)

        // 5. 替换 keyword
        guard
            replacementRange.location >= 0,
            replacementRange.location < textAttrString.length,
            replacementRange.location + replacementRange.length <= textAttrString.length
            else {
                DocsLogger.error("at location error - \(textAttrString) -\(replacementRange)", component: LogComponents.comment)
                return
        }
        textAttrString.replaceCharacters(in: replacementRange, with: atAttrString)

        // 6. 还原原本内容
        inputTextView.textView.attributedText = textAttrString

        // 7. 还原光标位置 & 默认样式
        let newLocation = atAttrString.length + location
        inputTextView.textView.selectedRange = NSRange(location: newLocation, length: 0)

        // 8. 插入一个空格
        inputTextView.textView.insertText(" ")

        // 9. 拉取权限，更新高亮状态
        if dependency.canSupportInviteUser, dependency.canShowDraftDarkName {
            requestPermissionForAt(atInfo)
        }
    }

    private func requestPermissionForAt(_ at: AtInfo) {
        guard let dependency = dependency else { return }
        let docsKey = AtUserDocsKey(token: dependency.fileToken, type: dependency.fileType)
        AtPermissionManager.shared.fetchAtUserPermission(ids: [at.token], docsKey: docsKey, handler: self) { _ in
            DispatchQueue.main.async {
                if self.refreshAtUserTextPermission(needToastFor: at), let textView = self.inputTextView?.textView {
                    let rect = textView.getSelectionRect().insetBy(dx: -10, dy: -10)
                    self.showInviteTips(at: at, rect: rect, inView: textView)
                }
            }
        }
    }

    @discardableResult
    func refreshAtUserTextPermission(needToastFor target: AtInfo?) -> Bool {
        var needToast: Bool = false
        guard let dependency = self.dependency, let text = self.inputTextView?.textView.attributedText else { return false }
        let docsKey = AtUserDocsKey(token: dependency.fileToken, type: dependency.fileType)
        // 查找更新at权限
        let attributedText = NSMutableAttributedString(attributedString: text)
        var needUpdateArray: [(AtInfo, NSRange)] = []
        let totalRange = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttribute(AtInfo.attributedStringAtInfoKey, in: totalRange, options: .reverse) { (attrs, attrsRange, _) in
            if attrs != nil, let tAttrs = attrs as? AtInfo, tAttrs.type == .user {
                needUpdateArray.append((tAttrs, attrsRange))
            }
        }
        let hasInvitePermission = AtPermissionManager.shared.canInvite(for: docsKey.token)
        for (atInfo, range) in needUpdateArray {
            if let hasPermission = AtPermissionManager.shared.hasPermission(atInfo.token, docsKey: docsKey), hasPermission != atInfo.hasPermission {
                atInfo.hasPermission = hasPermission
                let atAttrString = atInfo.attributedString(attributes: AtInfo.TextFormat.defaultAttributes(font: self.textFont, textColor: nil), lineBreakMode: .byWordWrapping)
                attributedText.replaceCharacters(in: range, with: atAttrString)
            }
            if hasInvitePermission, let target = target, target.token == atInfo.token,
               atInfo.hasPermission == false {
                needToast = true
            }
        }

        // 更新内容
        self.inputTextView?.textView.attributedText = attributedText
        return needToast
    }

    private func showInviteTips(at: AtInfo, rect: CGRect, inView: UIView) {
        if dependency?.atListViewInToolView ?? false {
            if self.inviteTipsView == nil {
                self.inviteTipsView = AtUserInviteView(frame: .zero)
                self.addSubview(self.inviteTipsView!)
                // 横屏下不要超出安全区域
                self.inviteTipsView?.snp.makeConstraints({ make in
                    inviteTipsView?.portraitScreenConstraints.append(make.left.right.equalToSuperview().constraint)
//                    make.left.right.equalToSuperview()
                    inviteTipsView?.landscapeScreenConstraints.append(make.left.equalTo(safeAreaLayoutGuide.snp.left).constraint)
                    inviteTipsView?.landscapeScreenConstraints.append(make.right.equalTo(safeAreaLayoutGuide.snp.right).constraint)
                    make.bottom.equalTo(self.toolContentView.snp.top)
                })
                self.inviteTipsView?.updateConstraintsWhenOrientationChangeIfNeed(isChangeLandscape: isChangeLandscape)
                self.inviteTipsView?.addCornerStyle()
            }
            self.inviteTipsView?.atUserInfo = at
            let atInviteConfig = AtUserInviteViewConfig.congfigWithAt(at, docsInfo: docsInfo)
            self.inviteTipsView?.showWithConfig(atInviteConfig, delegte: self)
            self.inviteTipsView?.isHidden = false
            cancelOvertimeRemoveInviteTip()
            self.perform(#selector(type(of: self).becomeOverTime), with: nil, afterDelay: 4.0)
        } else {
            //iPad宽屏下的场景
            dependency?.showInvitePopoverTips(at: at, rect: rect, inView: inView)
        }
    }

    private func cancelOvertimeRemoveInviteTip() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(becomeOverTime), object: nil)
    }

    @objc
    func becomeOverTime() {
        self.inviteTipsView?.isHidden = true
    }
}

extension AtInputTextView: AtUserInviteViewDelegate {
    public func clickConfirmButton(_ view: AtUserInviteView) {
        view.isHidden = true
        guard let dependency = self.dependency, let atInfo = view.atUserInfo, let window = self.window else { return }
        let docsKey = AtUserDocsKey(token: dependency.fileToken, type: dependency.fileType)
        AtPermissionManager.shared.inviteUserRequest(atInfo: atInfo, docsKey: docsKey, sendLark: false) { errMsg in
            if let errMsg {
                UDToast.docs.showMessage(errMsg, on: window, msgType: .success)
                return
            }
            if let result = AtPermissionManager.shared.hasPermission(atInfo.token, docsKey: docsKey), result == true {
                UDToast.docs.showMessage(BundleI18n.SKResource.CreationMobile_mention_sharing_success, on: window, msgType: .success)
                self.refreshAtUserTextPermission(needToastFor: nil)
                NotificationCenter.default.post(name: Notification.Name.FeatchAtUserPermissionResult, object: nil)
            }
        }
    }
}


extension AtInputTextView {
    /// 标记隐藏AtListView
    func markAtListViewHide() {
        innerIsShowingAtListView.accept(false)
        self.toolBar.setAtButton(select: false)
    }
}
