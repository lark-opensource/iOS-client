//
//  WebViewController+KeyBoard.swift
//  DocsSDKDemo
//
//  Created by Webster on 2019/5/31.
//

import Foundation

//  键盘监听和操作
extension MailSendController {
    /// 开始键盘监听
    func listenKeyBoard() {
        let events: [Keyboard.KeyboardEvent] = [.willShow, .didShow, .willHide, .didHide, .willChangeFrame, .didChangeFrame]
        self.keyBoard.on(events: events) { [weak self] (opt) in
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                MailLogger.debug("keyboard events \(opt.event)")
                self.handleKeyBoardOptions(opt)
            }
        }
        self.keyBoard.start()
    }

    /// 停止键盘监听
    func stopListenKeyBoard() {
        self.keyBoard.stop()
    }

    // 根据键盘变化，更新工具条位置
    func handleKeyBoardOptions(_ options: Keyboard.KeyboardOptions) {
        guard options.event == .willChangeFrame ||
                (options.event == .willHide && options.trigger == "byCode")  else {
            return
        }
        self.scrollContainer.webView.inputAssistantItem.trailingBarButtonGroups = []
        self.scrollContainer.webView.inputAssistantItem.leadingBarButtonGroups = []
        /// 差值
        let dy = UIScreen.main.bounds.height - view.bounds.size.height
        /// 键盘
        var keyBoardHeight = options.endFrame.height
        var keyBoardOffsetY = options.endFrame.minY
        if mainToolBar?.isDisplaySubPanel ?? false && keyBoardHeight < toolbarConfig.keyboardLockHeight {
            keyBoardHeight = toolbarConfig.subPanelDefaultHeight
            keyBoardOffsetY = UIScreen.main.bounds.height - keyBoardHeight
        }
        /// 工具条
        let toolbarHeight = toolbarConfig.toolBarHeight
        let toolbarWidth = UIScreen.main.bounds.width
        var toolBarOffsetY = keyBoardOffsetY - toolbarHeight - dy + Display.bottomSafeAreaHeight
        let willHideFlag = options.endFrame.maxY > UIScreen.main.bounds.height + 10 ||
            options.event == .willHide
        if  willHideFlag {
            toolBarOffsetY = toolBarOffsetY - Display.bottomSafeAreaHeight
        }
        /// 子面板
        let subPanelHeight = keyBoardHeight
        let subPanelOffsetY = keyBoardOffsetY
        /// fix 在M1上，键盘没有的情况下主面板消失的bug，做一个兜底
        let toolBarMaxY = UIScreen.main.bounds.height - toolbarHeight - dy
        if toolBarOffsetY > toolBarMaxY {
            toolBarOffsetY = toolBarMaxY
        } else if toolBarOffsetY < 0 {
            toolBarOffsetY = toolBarMaxY
        }
        /// 更新设置数据
        toolbarConfig.keyboardOffsetY = keyBoardOffsetY
        toolbarConfig.keyboardHeight = keyBoardHeight
        toolbarConfig.toolBarHeight = toolbarHeight
        toolbarConfig.toolBarOffsetY = toolBarOffsetY
        toolbarConfig.subPanelHeight = subPanelHeight
        toolbarConfig.subPanelOffsetY = subPanelOffsetY

        /// 更新滚动区域高度
        let contentHeight = toolBarOffsetY
        var contentFrame = scrollContainer.frame
        if willHideFlag {
            //hide
            contentFrame.size.height = view.bounds.height
        } else {
            // show
            contentFrame.size.height = contentHeight
            let heightChange: CGFloat = 44
            scrollContainer.updateCurrentKeyboardHeight(keyBoardHeight + heightChange)
        }
        
        /// 更新工具条位置
        let toolBarFrame = CGRect(x: 0, y: toolBarOffsetY, width: toolbarWidth, height: toolbarHeight)
        /// 更新搜索推荐列表的高度
        var suggestFrame = suggestTableView.frame
        let needChangeSuggestFrame = !suggestTableView.isHidden
        suggestFrame.size.height = toolBarOffsetY - suggestFrame.origin.y
//        if self.toolBarSubPanel?.superview != nil {
//            self.toolBarSubPanel?.snp.remakeConstraints({ (make) in
//                make.leading.trailing.bottom.equalToSuperview()
//                make.height.equalTo(toolbarConfig.subPanelHeight)
//            })
//        }
        let shift: UInt = 16
        UIView.animate(withDuration: options.animationDuration,
                       delay: 0,
                       options: UIView.AnimationOptions.init(rawValue: UInt( options.animationCurve.rawValue << shift)),
                       animations: { [weak self] in
            guard let `self` = self else { return }
            self.scrollContainer.frame = contentFrame
            self.mainToolBar?.frame = toolBarFrame
            if Display.pad && self.firstResponder == self.scrollContainer.webView {
                self.mainToolBar?.isHidden = false
            } else {
                self.mainToolBar?.isHidden = willHideFlag
            }
            
            if let originY = self.popoverOriginY,
                self.presentedViewController != nil,
               let popVC = self.presentedViewController as? PopupMenuPoverViewController {
                let scrollHeight: CGFloat = self.scrollContainer.contentOffset.y
                let webviewOffsetY: CGFloat = self.scrollContainer.webView.frame.origin.y
                let y = originY + webviewOffsetY - scrollHeight
                popVC.resetSourceRect(offsetY: y)
                
            }
        }, completion: nil)

        if needChangeSuggestFrame &&
            !self.suggestTableView.isHidden &&
            self.suggestTableView.frame != suggestFrame {
            self.suggestTableView.frame = suggestFrame
        }
        if willHideFlag {
            self.view.subviews.filter({ $0 is EditorSubToolBarPanel }).forEach({ $0.removeFromSuperview() })
        }
        if self.scrollContainer.webView == self.firstResponder &&
            !self.aiService.myAIContext.inAIMode {
            /// 滚动光标到可视范围
            requestEvaluateJavaScript("window.command.getCursorPosition()") { (res, err) in
                if let err = err {
                    MailLogger.error("getCursorPosition err \(err)")
                } else if let res = res as? [String: Any] {
                    guard let top = res["top"] as? CGFloat, let left = res["left"] as? CGFloat, let height = res["height"] as? CGFloat else { return }
                    let position = EditorSelectionPosition(top: top, left: left, height: height)
                    self.didUpdateSelection(position)
                }
            }
        }
        self.view.layoutIfNeeded()
    }

    func updateKeyboardRelatedViews() {
        // 旋转屏幕时，隐藏键盘和sub面板
        requestHideKeyBoard()
        scrollContainer.webView.endEditing(true)
        // 键盘隐藏的情况下，需要更新相关view的frame
        let option = Keyboard.KeyboardOptions(event: .willHide,
                                              beginFrame: .zero,
                                              endFrame:
                                                CGRect(x: 0,
                                                       y: UIScreen.main.bounds.size.height,
                                                       width: UIScreen.main.bounds.size.width,
                                                       height: 0),
                                              animationCurve: self.keyBoard.options?.animationCurve ?? UIView.AnimationCurve.linear,
                                              animationDuration: self.keyBoard.options?.animationDuration ?? 0,
                                              isShow: false,
                                              trigger: "byCode")
        self.handleKeyBoardOptions(option)
    }
}
