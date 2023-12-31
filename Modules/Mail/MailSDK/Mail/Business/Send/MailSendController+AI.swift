//
//  MailSendController+AI.swift
//  MailSDK
//
//  Created by tanghaojin on 2022/6/18.
//

import Foundation
import LarkAlertController
import EENavigator

extension MailSendController: MailAIServiceDelegate {
    func openAIFG() -> Bool {
        if self.baseInfo.statInfo.from == .outOfOffice {
            return false
        }
        let enable = accountContext.provider.myAIServiceProvider?.isAIEnable ?? false
        return accountContext.featureManager.open(FeatureKey(fgKey: .larkAI, openInMailClient: false)) && accountContext.featureManager.open(FeatureKey(fgKey: .mailAI, openInMailClient: false)) && enable
    }
    func getShowAIPanelViewController() -> UIViewController {
        return self
    }
    
    func aiItemClick() {
        guard openAIFG() else { return }
        self.aiMaskView.isHidden = false
        self.view.bringSubviewToFront(self.aiMaskView)
        let title = self.scrollContainer.getSubjectText() ?? ""
        self.togglePlaceholder(flag: false)
        self.getContentAndInit(title: title,
                               needReport: true,
                               draftMail: false)
    }
    func genDraftIdAndNames() -> (String, String) {
        var names = ""
        for send in self.viewModel.sendToArray {
            if !send.displayName.isEmpty {
                names = names + send.displayName + ","
            } else if !send.name.isEmpty {
                names = names + send.name + ","
            } else if !send.address.isEmpty {
                names = names + send.address + ","
            }
        }
        if names.count > 0 {
            names = names.substring(to: names.count - 1)
        }
        let id = self.draft?.id ?? ""
        return (id, names)
    }
    func editorAIClick() {
        self.aiMaskView.isHidden = false
        self.view.bringSubviewToFront(self.aiMaskView)
        let event = NewCoreEvent(event: .email_email_edit_myai_click)
        event.params = ["target": "none",
                        "click":"open_myai",
                        "label_item": baseInfo.statInfo.newCoreEventLabelItem,
                        "open_type": "blank_mail",
                        "mail_account_type": Store.settingData.getMailAccountType()]
        event.post()
        // 隐藏placeholder
        self.togglePlaceholder(flag: false)
        //requestHideKeyBoard()
        let title = self.scrollContainer.getSubjectText() ?? ""
        self.getContentAndInit(title: title,
                               needReport: false,
                               draftMail: true)
    }
    func getContentAndInit(title: String, needReport: Bool, draftMail: Bool) {
        self.getEditorContent(needSelect: true) { [weak self] info in
            guard let `self` = self else { return }
            let content = info[MailAIService.ContentKey] as? String ?? ""
            var hasContent = !content.isEmpty
            var hasHistory = false
            var userSelect = false
            if let aiEmpty = info[MailAIService.AIEmptyKey], let flag = aiEmpty as? Bool {
                hasContent = !flag
            }
            if let selectFlag = info[MailAIService.AIUserSelect], let flag = selectFlag as? Bool {
                userSelect = flag
            }
            if self.accountContext.featureManager.open(FeatureKey(fgKey: .mailAISmartReply, openInMailClient: false)),
               let history = info[MailAIService.AIHasHistoryKey],
                let hisFlag = history as? Bool{
                hasHistory = hisFlag
            }
            if needReport {
                let select = content.isEmpty ? "false" : "true"
                let event = NewCoreEvent(event: .email_editor_right_menu_click)
                event.params = ["target":"none",
                                "click":"open_myai",
                                "select_content":select,
                                "label_item": self.baseInfo.statInfo.newCoreEventLabelItem,
                                "mail_account_type": Store.settingData.getMailAccountType()]
                event.post()
            }
            self.requestHideKeyBoard()
            DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.ultraShort) { [weak self] in
                guard let `self` = self else { return }
                let idAndName = self.genDraftIdAndNames()
                self.aiService.initAITask(draftMail: draftMail,
                                           title: title,
                                           hasContent: hasContent,
                                           hasHistory: hasHistory,
                                           userSelect: userSelect,
                                           draftId: idAndName.0,
                                           toNames: idAndName.1)
            }
        }
    }
    func adjustPosition(selectionTop: CGFloat) {
        let y = scrollContainer.webView.frame.minY + selectionTop
        let currentY = scrollContainer.contentOffset.y
        if y >= scrollContainer.webView.frame.minY && y != currentY {
            //aiService.myAIContext.frozenFrame = true
            //aiService.myAIContext.contentOffset = CGPoint(x: 0, y: y)
            self.aiModeUpdateContentOffset(y: y, animated: true)
            startScrollViewObserve()
        }
        
    }
    func startScrollViewObserve() {
        if let ob = self.aiService.myAIContext.observation {
            ob.invalidate()
        }
        self.aiService.myAIContext.observation = self.scrollContainer.observe(\.contentOffset, options: NSKeyValueObservingOptions.init(rawValue: 3)) { [weak self] (scrollView, change) in
            guard let `self` = self else { return }
            if self.aiService.weakModeScrollByUser {
                return
            }
            if let new = change.newValue,
               let old = change.oldValue,
               new.y != old.y {
                if let y = self.aiService.myAIContext.aiModeOffsetY {
                    scrollView.setContentOffset(CGPoint(x: 0, y: y), animated: false)
                }
            }
        }
    }
    func endScrollViewObserve() {
        if let ob = self.aiService.myAIContext.observation {
            //DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) {
                ob.invalidate()
            //}
        }
    }
    
    func updateMyAIPanelHeight(height: CGFloat) {
        aiService.myAIContext.viewHeight = height
        updateContentSize()
    }
    func updateContentSize() {
        if self.scrollContainer.frame.size.height > 0, self.aiService.myAIContext.viewHeight > 0, self.aiService.myAIContext.inWeakAIMode {
            var containerHeight = self.scrollContainer.frame.size.height
            let viewOffset = 20.0
            let aiHeight = self.scrollContainer.frame.size.height - self.aiService.myAIContext.viewHeight - viewOffset
            if aiHeight > 0 {
                containerHeight = aiHeight
            }
            self.updateAiOffset(containerHeight: containerHeight)
        }
    }
    func toOriginPositionIfNeed() {
        aiService.myAIContext.viewHeight = 0
        //updateContentSize()
        let threshold = 50.0
        if let y = aiService.myAIContext.aiModeOffsetY,
           self.scrollContainer.contentSize.height - y < self.view.bounds.size.height,
           y < self.view.bounds.size.height - threshold {
             //need scroll to top
            UIView.animate(withDuration: timeIntvl.short) {
                //self.aiService.myAIContext.contentOffset = nil
                self.aiService.myAIContext.aiModeOffsetY = nil
                self.scrollContainer.contentOffset = CGPointZero
            }
        }
        self.aiService.myAIContext.aiModeOffsetY = nil
        //aiService.myAIContext.contentOffset = nil
    }
    /// 打开myAI浮窗
    func openQuickActionPanel() {
        self.getEditorContent(needSelect: false) { [weak self] info in
            let content = info[MailAIService.ContentKey] as? String ?? ""
            let sceneType = content.isEmpty ? "unselect_content" : "selected_content"
            let hasContent = content.isEmpty ? "false" : "true"
            self?.aiService.myAIContext.sceneType = sceneType
            self?.myAiReport(event: .email_myai_window_view)
        }
    }
    func quiteAI(insertContent: Bool) {
        self.aiMaskView.isHidden = true
        self.aiService.myAIContext.selectionTopOffset = nil
        self.aiService.myAIContext.selectionBottomOffset = nil
        self.aiService.myAIContext.bgNeedToTop = false
        //self.aiService.myAIContext.aiModeOffsetY = nil
        self.togglePlaceholder(flag: true)
        endScrollViewObserve()
        toOriginPositionIfNeed()
        clearSelectionMock()
        if !insertContent {
            selectionReFocus()
        }
    }
    func aiFocusEditor() {
//        guard let responder = self.firstResponder else {
//            return
//        }
//        if responder == scrollContainer.webView {
//            scrollContainer.webView.focusAtEditorBegin()
//        }
    }
    func clearContent() {
        let clearStr = "window.command.clearContent()"
        self.requestEvaluateJavaScript(clearStr) {(_, err) in
            if let err = err {
                MailLogger.error("[MailAI] clear editor Content err \(err)")
            }
        }
    }
    func myAiReport(event: NewCoreEvent.EventName) {
        let mailAccountType = Store.settingData.getMailAccountType()
        let labelItem = baseInfo.statInfo.newCoreEventLabelItem
        let event = NewCoreEvent(event: event)
        event.params = ["target": "none",
                       "label_item": labelItem,
                        "scene_type": self.aiService.myAIContext.sceneType,
                        "mail_account_type": mailAccountType,
                        "mail_content": self.aiService.myAIContext.mailContent]
        event.post()
    }
    func clickAiPanel(click: String, commandType: String) {
        let mailAccountType = Store.settingData.getMailAccountType()
        let labelItem = baseInfo.statInfo.newCoreEventLabelItem
        let event = NewCoreEvent(event: .email_myai_window_click)
        event.params = ["target": "none",
                        "click": click,
                        "is_shortcut":"false",
                        "label_item": labelItem,
                        "scene_type": self.aiService.myAIContext.sceneType,
                        "mail_account_type": mailAccountType,
                        "mail_content": self.aiService.myAIContext.mailContent]
        if !commandType.isEmpty {
            event.params["command_type"] = commandType
        }
        event.post()
    }
    func showAIStopAlert(quiteBlock: @escaping (() -> Void)) {
        self.myAiReport(event: .email_quit_myai_window_view)
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_MyAI_DiscardAndLeave_Title)
        let aiBrandName = self.accountContext.provider.myAIServiceProvider?.aiDefaultName ?? ""
        var desc = BundleI18n.MailSDK.Mail_MyAI_DiscardAndLeave_aiName_Desc(aiBrandName)
        if let nickName = self.accountContext.provider.myAIServiceProvider?.aiNickName, !nickName.isEmpty {
            desc = BundleI18n.MailSDK.Mail_MyAINickname_DiscardAndLeave_Desc(nickName)
        }
        alert.setContent(text: desc,
                             alignment: .center)
        let mailAccountType = Store.settingData.getMailAccountType()
        let labelItem = baseInfo.statInfo.newCoreEventLabelItem
        let event = NewCoreEvent(event: .email_quit_myai_window_click)
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_MyAI_DiscardAndLeave_Leave_Bttn, dismissCompletion:  {
            event.params = ["target": "none",
                           "label_item": labelItem,
                           "click": "confirm",
                            "mail_account_type": mailAccountType]
            event.post()
            quiteBlock()
        })
        alert.addButton(text: BundleI18n.MailSDK.Mail_MyAI_DiscardAndLeave_Cancel_Bttn, dismissCompletion: {
            event.params = ["target": "none",
                           "label_item": labelItem,
                           "click": "cancel",
                            "mail_account_type": mailAccountType]
            event.post()
        })
        if let vc = self.presentedViewController {
            accountContext.navigator.present(alert, from: vc)
        } else {
            accountContext.navigator.present(alert, from: self)
        }
    }
    /// 获取当前编辑器内容
    func getEditorContent(needSelect: Bool,
                          processContent: @escaping (([String: Any]) -> Void)) {
        let title = self.scrollContainer.getSubjectText()
        let jsStr = "window.command.getEmailMdContent()"
        self.requestEvaluateJavaScript(jsStr) { [weak self] (data, err) in
            if let content = data, let contentDic = content as? [String: Any] {
                var info:[String: Any] = [:]
                info[MailAIService.TitleKey] = title
                info[MailAIService.ContentKey] = contentDic["content"]
                info[MailAIService.SelectionKey] = contentDic["selection"]
                //let isCollapsed = contentDic["isCollapsed"] as? Bool ?? true
                var isCollapsed = true
                var selectionBegin = false
                if let originSel = contentDic["originSelection"] as? [String: Any], let start = originSel["start"] as? [String: Any],
                   let end = originSel["end"] as? [String: Any],
                    let startZone = start["zoneId"] as? String,
                    let endZone = end["zoneId"] as? String,
                    let startOffset = start["offset"] as? NSNumber,
                    let endOffset = end["offset"] as? NSNumber,
                    let startLine = start["line"] as? NSNumber,
                    let endLine = end["line"] as? NSNumber {
                    if startZone == endZone && startOffset == endOffset && startLine == endLine {
                        isCollapsed = true
                    } else {
                        isCollapsed = false
                    }
                    if startLine == 0 && startOffset == 0 {
                        selectionBegin = true
                    }
                }
                if needSelect {
                    self?.requestEvaluateJavaScript("window.command.isEditorEmptyForAI()") { [weak self] (res,_) in
                        self?.requestEvaluateJavaScript("window.command.hasHistoryQuote()") { [weak self] (hasHistory,_) in
                            if !isCollapsed {
                                info[MailAIService.AIEmptyKey] = false
                            } else if let res = res, let flag = res as? Bool {
                                info[MailAIService.AIEmptyKey] = flag
                            }
                            let jsonObj = (selectionBegin && isCollapsed) ? contentDic["originSelection"] : contentDic["selection"]
                            guard let data = try? JSONSerialization.data(withJSONObject: jsonObj ?? [:], options: []),
                                  let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
                                return
                            }
                            if let history = hasHistory, let hisFlag = history as? Bool {
                                info[MailAIService.AIHasHistoryKey] = hisFlag
                            }
                            info[MailAIService.AIUserSelect] = !isCollapsed
                            self?.aiService.myAIContext.selection = JSONString
                            self?.aiService.myAIContext.alreadyMockSelection = false
                            self?.aiService.myAIContext.isCollapsed = isCollapsed
                            self?.aiService.myAIContext.isCollapsedBegin = selectionBegin
                            self?.requestEvaluateJavaScript("window.command.blur()") { [weak self] (_,_) in
                                self?.getSelectionRect(json: JSONString)
                                //self?.requestHideKeyBoard()
                                processContent(info)
                            }
                            if !isCollapsed {
                                self?.setMockSelection(isMock: true)
                            }
                        }
                    }
                } else {
                    processContent(info)
                }
            }
            if let err = err {
                MailLogger.error("[MailAI] getEmailMdContent err \(err)")
            }
        }
    }
    func getEditorHisoryContent(processContent: @escaping ((String) -> Void)) {
        self.requestEvaluateJavaScript("window.command.fetchHistoryQuoteText()") { (res,_) in
            if let info = res as? String {
                processContent(info)
            }
        }
    }
    /// 编辑器插入弱确认内容
    func insertEditorContent(content: String, preview: Bool, toTop: Bool) {
        if content.isEmpty {
            return
        }
        let json: [String: Any] = ["markdown": content,
                    "isPreview": preview]
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: []),
              let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
            return
        }
        self.requestHideKeyBoard()
        self.aiService.myAIContext.bgNeedToTop = toTop
        let jsStr = "window.command.insertMDContentWrap(\(JSONString))"
        self.requestEvaluateJavaScript(jsStr) { [weak self] (_, err) in
            guard let `self` = self else { return }
            if let err = err {
                MailLogger.error("[MailAI] insertEditorContent err \(err)")
            } else {
                self.requestHideKeyBoard()
                self.updateContentSize()
            }
        }
        clearSelectionMock()
    }
    func updateAiOffset(containerHeight: CGFloat) {
        if self.aiService.myAIContext.inWeakAIMode {
            let jsStr = "window.command.getAIRect()"
            self.requestEvaluateJavaScript(jsStr) { [weak self] (data, err) in
                guard let `self` = self else { return }
                if let err = err {
                    MailLogger.error("[MailAI] updateAiOffset err \(err)")
                } else if let res = data as? [String: Any] {
                    guard let top = res["top"] as? CGFloat ,
                            let height = res["height"] as? CGFloat else { return }
                    let threshold = 8.0
                    let bottomOffset = top + height + threshold
                    let topOffset = top
                    var toTop = false
                    if self.aiService.myAIContext.bgNeedToTop {
                        if topOffset + self.scrollContainer.webView.frame.minY <= self.scrollContainer.contentOffset.y {
                            // 说明内容的头部在上面看不到
                            toTop = true
                        } else if topOffset + self.scrollContainer.webView.frame.minY - self.scrollContainer.contentOffset.y > containerHeight {
                            // 说明内容的头部在下面看不到
                            toTop = true
                        }
                    }
                    if toTop {
                        let point = CGPoint(x: 0,
                                            y: topOffset + self.scrollContainer.webView.frame.minY)
                        if point.y > 0 {
                            self.aiModeUpdateContentOffset(y: point.y)
                        }
                    } else {
                        let bottomPoint = CGPoint(x: 0, y: bottomOffset + self.scrollContainer.webView.frame.minY)
                        let topPoint = CGPoint(x: 0, y: topOffset + self.scrollContainer.webView.frame.minY)
                        if bottomPoint.y - self.scrollContainer.contentOffset.y > containerHeight {
                            self.aiModeUpdateContentOffset(y: bottomPoint.y - containerHeight)
                        } else if topPoint.y < self.scrollContainer.contentOffset.y &&
                                    (bottomPoint.y - topPoint.y) < (containerHeight) &&
                                    topPoint.y > 0 {
                            // 头部在上面，做调整
                            self.aiModeUpdateContentOffset(y: topPoint.y)
                        }
                    }
                }
            }
        }
    }
    
    func aiModeUpdateContentOffset(y: CGFloat, animated: Bool = false) {
        self.aiService.myAIContext.aiModeOffsetY = y
        UIView.animate(withDuration: timeIntvl.short) {
            self.scrollContainer.contentOffset = CGPoint(x: 0,
                                                         y: y)
        }
    }
    
    func adjuestWebViewInset(inset: UIEdgeInsets) {
        self.scrollContainer.contentInset = inset
    }

    func adjuestOffset(operate: String,
                       bottomOffset: CGFloat?,
                       topOffset: CGFloat?,
                       aiHeight: CGFloat) {
        // 调整一下位置
        var offsety: CGFloat = -1
        var containerHeight = self.scrollContainer.bounds.size.height
        if self.view.bounds.size.height - aiHeight < containerHeight {
            containerHeight = self.view.bounds.size.height - aiHeight
        }
        if operate == MailAIService.PreviewInsertKey {
            // 往后插入,检查selectionBottom是否在可视区域
            if let offset = bottomOffset {
                let bottom = offset + self.scrollContainer.webView.frame.minY
                if bottom < self.scrollContainer.contentOffset.y {
                    offsety = bottom
                } else if bottom - self.scrollContainer.contentOffset.y > containerHeight {
                    offsety = bottom
                }
            }
        } else if operate == MailAIService.PreviewReplaceKey {
            // 替换，检查selectionTop是否在可视区域
            if let offset = topOffset {
                let top = offset + self.scrollContainer.webView.frame.minY
                if top < self.scrollContainer.contentOffset.y {
                    offsety = top
                } else if top - self.scrollContainer.contentOffset.y > containerHeight {
                    offsety = top
                }
            }
        }
        if offsety > 0 {
            self.aiService.myAIContext.forceScroll = true
            //self.aiService.myAIContext.contentOffset = nil
            self.aiModeUpdateContentOffset(y: offsety)
        }
    }
    /// 强确认内容插入编辑器
    func applyEditorContent(dataSet: [String: Any],
                            operate: String,
                            bottomOffset: CGFloat?,
                            topOffset: CGFloat?,
                            aiHeight: CGFloat) {
        //移动逻辑
       // self.adjuestOffset(operate: operate, bottomOffset: bottomOffset, topOffset: topOffset, aiHeight: aiHeight)

//        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) {
            var param:[String: Any] = [:]
            param["operate"] = operate
            guard let set = try? JSONSerialization.data(withJSONObject: dataSet, options: []),
                  let setString = NSString(data: set, encoding: String.Encoding.utf8.rawValue) else {
                return
            }
            param["deltaSet"] = setString
            guard let data = try? JSONSerialization.data(withJSONObject: param, options: []),
                  let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
                return
            }
            self.aiService.myAIContext.selection = nil
            let jsStr = "window.command.applyContent(\(JSONString))"
            self.requestEvaluateJavaScript(jsStr) { [weak self] (_, err) in
                if let err = err {
                    MailLogger.error("[MailAI] applyEditorContent err \(err)")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) { [weak self] in
                    self?.clearAIBg(needSelect: false)
                }
            }
    }
    /// 清除AI背景
    func clearAIBg(needSelect: Bool) {
        var jsStr = "window.command.clearAIGB()"
        if needSelect {
            jsStr = "window.command.clearAIGB(\(needSelect))"
        }
        self.requestEvaluateJavaScript(jsStr) { (_, err) in
            if let err = err {
                MailLogger.error("[MailAI] clearAIBg err \(err)")
            } else {
//                if needBlur {
//                    let blur = "window.command.blur()"
//                    self?.requestEvaluateJavaScript(blur) { [weak self] (_, _) in
//                        self?.requestHideKeyBoard()
//                    }
//                }
            }
        }
        if needSelect {
            self.scrollContainer.webView.becomeFirstResponder()
            //reFocus()
        }
    }
    /// 清除AI生成的内容
    func clearAIContent() {
        let jsStr = "window.command.clearAIContent()"
        self.requestEvaluateJavaScript(jsStr) { (_, err) in
            if let err = err {
                MailLogger.error("[MailAI] clearAIContent err \(err)")
            }
        }
    }
    // 设置selection mock背景色
    func setMockSelection(isMock: Bool) {
        if let jsonString = self.aiService.myAIContext.selection, !self.aiService.myAIContext.alreadyMockSelection {
            if isMock {
                self.aiService.myAIContext.alreadyMockSelection = true
            }
            //let isMock = true
            let isReal = false
            let js = "window.command.setSelection(`\(jsonString)`,\(isMock),\(isReal))"
            self.requestEvaluateJavaScript(js) { (_, err) in
                if let err = err {
                    MailLogger.info("[MailAI] setSelection err \(err)")
                }
            }
        }
    }
    /// 清除selection mock 背景色
    func clearSelectionMock() {
        let jsStr = "window.command.clearMockSelectionRect()"
        self.requestEvaluateJavaScript(jsStr) { (_, err) in
            if let err = err {
                MailLogger.error("[MailAI] clearMockSelectionRect err \(err)")
            }
        }
    }
    
    func selectionReFocus() {
        if let selection = self.aiService.myAIContext.selection {
            if self.aiService.myAIContext.isCollapsed {
                //let isMock = false
                var js = "window.command.focusAtSelectionEnd()"
                if self.aiService.myAIContext.isCollapsedBegin {
                    js = "window.command.focusAtEditorBegin()"
                }
                //let js = "window.command.setSelection(`\(selection)`,\(isMock))"
                self.requestEvaluateJavaScript(js) {(_, err) in
                    if let err = err {
                        MailLogger.info("[MailAI] resetSelection err \(err)")
                    }
                }
            }
            self.aiService.myAIContext.selection = nil
            self.reFocus()
        }
        self.aiService.myAIContext.isCollapsed = false
        self.aiService.myAIContext.isCollapsedBegin = false
    }
    func getSelectionRect(json: NSString) {
        let jsStr = "window.command.getSelectionRect(`\(json)`)"
        self.requestEvaluateJavaScript(jsStr) { [weak self] (data, err) in
            if let err = err {
                MailLogger.error("[MailAI] getSelectionRect err \(err)")
            } else if let res = data as? [String: Any] {
                guard let top = res["top"] as? CGFloat,
                        let height = res["height"] as? CGFloat else { return }
                let threshold = 8.0
                self?.aiService.myAIContext.selectionBottomOffset = top + height + threshold
                self?.aiService.myAIContext.selectionTopOffset = top
                self?.adjustPosition(selectionTop: top)
            } else {
                self?.adjustPosition(selectionTop: 0)
            }
        }
    }
    
    /// 隐藏或显示placeholder
    func togglePlaceholder(flag: Bool) {
        let jsStr = "window.command.togglePlaceholder(\(flag))"
        self.requestEvaluateJavaScript(jsStr) { (_, err) in
            if let err = err {
                MailLogger.error("[MailAI] togglePlaceholder err \(err)")
            }
        }
    }
    func updateAIName(name: String) {
        let jsStr = "window.command.updateAiName(`\(name)`)"
        self.requestEvaluateJavaScript(jsStr) { (_, err) in
            if let err = err {
                MailLogger.error("[MailAI] updateAIName err \(err)")
            }
        }
    }
}
