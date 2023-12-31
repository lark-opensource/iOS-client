//
// Created by duanxiaochen.7 on 2019/8/12.
// Affiliated with SpaceKit.
//
// Description:

import SKFoundation
import SKCommon
import SKBrowser
import SKUIKit
import SKResource

extension SheetShowInputService: SheetToolbarDelegate {

    var width: CGFloat {
        return ui?.hostView.bounds.width ?? .zero
    }

    func didRequestHideKeyboard() {
        sheetInputView?.onEndEditing(byUser: true)
        cachedDateValue = nil
        cachedPickerType = .none
        selectionFeedbackGenerator.selectionChanged()
        logKeyboardEditStatus()
    }

    func didRequestSwitchKeyboard(type: BarButtonIdentifier) {
        model?.jsEngine.callFunction(
            .sheetOnClickToolbarItem,
            params: ["id": type.rawValue] as [String: Any],
            completion: { (_, error) in
                if let error = error {
                    DocsLogger.error("sheet toolbar insert item failure:", error: error, component: LogComponents.toolbar)
                }
            }
        )
        var info: SheetInputKeyboardDetails = SheetInputKeyboardDetails(mainType: .systemText, subType: .none)
        var caretShouldHide = false
        var newlineButtonShouldDisable = false
        switch type {
        case .systemText:
            sheetInputView?.resetReturnKeyTypeIfNeed(willMode: nil)
            switchKeyboardView(nil)
        case .customNumber:
            info = SheetInputKeyboardDetails(mainType: .customNumber, subType: .none)
            numberKeyboardView.frame.size = CGSize(width: keyboardContainerWidth,
                                                   height: preferredCustomKeyboardHeight + windowSafeAreaBottomHeight)
            switchKeyboardView(numberKeyboardView)
        case .customDate:
            caretShouldHide = true
            newlineButtonShouldDisable = true
            info = SheetInputKeyboardDetails(mainType: .customDate, subType: cachedPickerType)
            dateTimeKeyboardView.frame.size = CGSize(width: keyboardContainerWidth,
                                                     height: preferredCustomKeyboardHeight + windowSafeAreaBottomHeight)
            switchKeyboardView(dateTimeKeyboardView)
        case .insertImage:
            caretShouldHide = true
            newlineButtonShouldDisable = true
            info = SheetInputKeyboardDetails(mainType: .insertImage, subType: .none)
            imagePickerKeyboardView.frame.size = CGSize(width: keyboardContainerWidth,
                                                        height: preferredCustomKeyboardHeight + windowSafeAreaBottomHeight)
            switchKeyboardView(imagePickerKeyboardView)
        case .at:
            toolbar?.switchSelectedItem(to: .systemText)
            sheetInputView?.atButtonAction()
        default: ()
        }
        selectionFeedbackGenerator.selectionChanged()
        sheetInputView?.setCaretHidden(caretShouldHide)
        sheetInputView?.disableNewline(newlineButtonShouldDisable)
        sheetInputView?.keyboardInfo = info
        logSwitchKeyboard(type: type)
    }
    
    func checkUploadPermission(_ showTips: Bool) -> Bool {
        guard let docsInfo = self.docsInfo else { return false }
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            let response = DocPermissionHelper.validate(objToken: docsInfo.token, objType: docsInfo.inherentType, operation: .uploadAttachment)
            if showTips {
                response.didTriggerOperation(controller: navigator?.currentBrowserVC ?? UIViewController())
            }
            return response.allow
        } else {
            return DocPermissionHelper.checkPermission(.ccmAttachmentUpload,
                                                       docsInfo: docsInfo,
                                                       showTips: showTips,
                                                       securityAuditTips: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast,
                                                       hostView: navigator?.currentBrowserVC?.view.window)
        }

    }

    func switchKeyboardView(_ keyboardView: UIView?) {
        var needResetInputView = false
        var needResetTextKeyboard = false
        if keyboardView == nil {
            needResetTextKeyboard = sheetInputView?.inputView != nil
            numberKeyboardView.removeFromSuperview()
            dateTimeKeyboardView.removeFromSuperview()
            imagePickerKeyboardView.removeFromSuperview()
        } else {
            //从文本（inputView为空）切换至数字、图片、日期输入时才需要reset
            needResetInputView = sheetInputView?.inputView == nil
        }
        // 123键盘隐藏时会将alpha设为0 但是从其他键盘切回 123键盘不会将alpha设为1导致看不见123键盘
        // 需要手动设置一下alpha为1
        keyboardView?.alpha = 1
        sheetInputView?.inputView = keyboardView
        if #available(iOS 16.0, *), UserScopeNoChangeFG.LJW.sheetInputViewFix, needResetInputView {
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) { [weak self] in
                //iPadOS 16上将妙控键盘最小化拖到屏幕左侧再拖回来会导致textView的inputView设置后无法展示出来
                //用最小化demo测试确定为系统bug，原因是superView的位置偏移到了屏幕左侧，其minX<0
                //需要resgin后重新becomeFirstResponder才能恢复正常
                guard let self, self.sheetInputView?.isFirstResponder == true else { return }
                if self.sheetInputView?.inputView?.superview?.frame.minX ?? -1 < 0 {
                    if var inputData = self.sheetInputView?.inputData {
                        self.sheetInputView?.ignoreInputViewResign = true
                        self.sheetInputView?.inputTextView.resignFirstResponder()
                        inputData.format = "undefined"
                        self.sheetInputView?.keyboardInfo = SheetInputKeyboardDetails(mainType: .insertImage, subType: .none)
                        if let selectedItemId = self.toolbar?.toolbarItems.first(where: { $0.isSelected == true })?.id {
                            self.updateInputView(inputData,
                                                 textToEdit: self.sheetInputView?.currentAttText,
                                                 hideFAB: self.toolkitButtonShouldHide,
                                                 toolbarItems: self.toolbar?.toolbarItems ?? [],
                                                 badges: self.toolbar?.badgedItems,
                                                 keyboardType: selectedItemId)
                        }
                        self.sheetInputView?.ignoreInputViewResign = false
                    }
                }
            }
        }
        if keyboardView != nil {
            refreshCustomKeyboardFrame()
            if SKDisplay.isInSplitScreen {
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_2500) { [weak self] in
                    //分屏+外接键盘场景，左右A、B两scene，A scene中文档唤起键盘输入框输入，双击B文档纯数字/日期单元格，调用becomeFirstResponder并且同时设置inputView
                    //系统键盘工具条的高度有异常，需要调一次reloadInputViews刷新
                    if self?.sheetInputView?.frame.maxY ?? .zero < SKDisplay.mainScreenBounds.height {
                        self?.sheetInputView?.inputTextView.reloadInputViews()
                    }
                }
            }
        }

        if needResetTextKeyboard, SKDisplay.pad, #available(iOS 16.0, *), UserScopeNoChangeFG.LJY.fixSheetSwitchKeyobardInIOS16,
           var inputData = sheetInputView?.inputData {
            //从其它键盘切换回文字键盘，在iPad妙控+台前调度会导致键盘下掉，需要重新弹出来
            inputData.format = BarButtonIdentifier.systemText.rawValue
            DocsLogger.info("reset SheetText Keyboard", component: LogComponents.toolbar)
            DispatchQueue.main.async {
                self.updateInputView(inputData,
                                     textToEdit: self.sheetInputView?.currentAttText,
                                     hideFAB: self.toolkitButtonShouldHide,
                                     toolbarItems: self.toolbar?.toolbarItems ?? [],
                                     badges: self.toolbar?.badgedItems)
            }
        }
    }
}

extension SheetShowInputService: SKPickMediaDelegate {
    func didFinishPickingMedia(params: [String: Any]) {
        model?.jsEngine.simulateJSMessage(DocsJSService.simulateFinishPickFile.rawValue, params: params)
        stopEditing()
    }
}
