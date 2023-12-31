//
//  BTURLField.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/4/8.
//

import SKUIKit
import SKResource
import SKFoundation
import SKBrowser
import UniverseDesignColor
import UniverseDesignIcon
import Foundation
import UIKit
import SKCommon
import SpaceInterface

// 接受到的类型只有两种情况：SKBitable.BTSegmentType.mention 或者 SKBitable.BTSegmentType.url
final class BTFieldV2URL: BTFieldV2BaseText, BTFieldURLCellProtocol {
    
    enum EditBoardState {
        case prepareForShow
        case showed
        case close
    }
    
    var urlTipManager = URlTipFirstOpenManager()
    
    var editAgent: BTURLEditAgent?
    /// 当前是否展示超链接编辑面板
    private var editBoardState: EditBoardState = .close
    
    private var lastTapCursorRect: CGRect?
    
    private lazy var editBoardManagerView: BTURLEditBoardManagerView = {
        let view = BTURLEditBoardManagerView(frame: .zero, baseContext: baseContext)
        view.editBoardView.delegate = self
        view.delegate = self
        return view
    }()
    
    /// 注意点：这里要在 interceptUpdateWhileEditing 进行类型过滤，要不然编辑过程中会一直调用 loadModel 方法。
    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        debugPrint("BTURLField loadModel \(model.textValue)")
        textView.editPermission = model.editable
        if !model.editable, model.textValue.count > 1 {
            // 非编辑场景，需要支持多链接点击，开启 shouldUseTextAsLinkForURLSegment = true
            textView.attributedText = BTUtil.convert(model.textValue,
                                                     font: BTFV2Const.Font.fieldValue,
                                                     plainTextColor: UDColor.textLinkNormal,
                                                     shouldUseTextAsLinkForURLSegment: true,
                                                     forTextView: textView)
        } else {
            // 编辑 URL 场景不支持多URL，所以不需要支持多链接点击
            textView.attributedText = BTUtil.convert(model.textValue,
                                                     font: BTFV2Const.Font.fieldValue,
                                                     plainTextColor: UDColor.textLinkNormal,
                                                     shouldUseTextAsLinkForURLSegment: false,
                                                     forTextView: textView)
        }
    }
    
    override func subviewsInit() {
        super.subviewsInit()
        addMenuNotification()
    }
    
    @objc
    override func onFieldEditBtnClick(_ sender: UIButton) {
        editBoardBtnPressed()
    }
    
    @objc
    override func onFieldValueEnlargeAreaClick(_ sender: UITapGestureRecognizer) {
        if textViewShouldBeginEditing(textView), textView.canBecomeFirstResponder {
            textView.becomeFirstResponder()
            editAgent?.scrollTillFieldVisible()
        }
    }
    
    override func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        debugPrint("BTURLField textViewShouldBeginEditing")
        let editable = fieldModel.editable
        if editable {
            let newEditAgent = BTURLEditAgent(fieldID: fieldID, recordID: fieldModel.recordID)
            self.textView.pasteOperation = { [weak newEditAgent] in
                newEditAgent?.doPaste()
            }
            editAgent = newEditAgent
            setInputAccesssoryView(isSetNil: false)
            delegate?.startEditing(inField: self, newEditAgent: newEditAgent)
        }
        return editable
    }
    
    override func textViewDidBeginEditing(_ textView: UITextView) {
        super.textViewDidBeginEditing(textView)
        debugPrint("BTURLField textViewDidBeginEditing")
        urlTipManager.textViewDidBeginEditing()
        editAgent?.scrollTillFieldVisible()
    }
    
    override func btTextView(_ textView: BTTextView, didSigleTapped sender: UITapGestureRecognizer) {
        let pointOfTextView = sender.location(in: textView)
        if fieldModel.editable {
            let isTapOnTrailBlank = BTUtil.isTapOnTrailBlank(in: textView, at: pointOfTextView)
            if isTapOnTrailBlank {
                debugPrint("BTURLField tapOnBlank")
                hideOpenURLTipView()
            } else {
                if isTapOnCursor(tapGR: sender) {
                    debugPrint("BTURLField tapOnCursor")
                    showMenu()
                } else {
                    showOpenURLTipView()
                }
                debugPrint("BTURLField tapOnContent")
            }
            lastTapCursorRect = getCursorRect()
            setCursorBootomOffset()
            editAgent?.scrollTillFieldVisible()
            urlTipManager.textViewDidSingleTap(isNeedShow: !isTapOnTrailBlank)
        } else {
            if BTUtil.isTapOnTrailBlank(in: textView, at: pointOfTextView) {
                showUneditableToast()
            } else {
                openUrlWitchGetFromFieldModel(didSigleTapped: sender)
            }
        }
    }

    override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return editAgent?.textView(textView, shouldChangeTextIn: range, replacementText: text) ?? false
    }

    override func textViewDidChange(_ textView: UITextView) {
        editAgent?.textViewDidChange(textView)
        hideOpenURLTipView()
    }

    override func textViewDidChangeSelection(_ textView: UITextView) {
        editAgent?.textViewDidChangeSelection(textView)
    }

    override func textViewDidEndEditing(_ textView: UITextView) {
        super.textViewDidEndEditing(textView)
        editAgent?.didEndEditingText()
        fieldModel.update(isEditing: false)
        setInputAccesssoryView(isSetNil: true)
    }
    
    override func btTextViewDidOpenUrl() {
        self.openUrlWitchGetFromFieldModel()
    }
    
    override func stopEditing() {
        textView.resignFirstResponder()
        hideEditBoardView()
        hideOpenURLTipView()
        delegate?.stopEditingField(self, scrollPosition: nil)
    }
    
    private func openUrlWitchGetFromFieldModel(didSigleTapped sender: UITapGestureRecognizer? = nil) {
        
        if let sender = sender,
            fieldModel.textValue.count > 1 {
            // 显示多个链接时，需要找到精确的链接打开
            let attributes = BTUtil.getAttributes(in: textView, sender: sender)
            var urlStr: String?
            if let urlInfo = attributes[AtInfo.attributedStringURLKey] as? URL {
                urlStr = urlInfo.url.absoluteString
            } else if let atInfo = attributes[AtInfo.attributedStringAtInfoKey] as? AtInfo {
                urlStr = atInfo.href
            } else if let atInfo = attributes[BTRichTextSegmentModel.attrStringBTAtInfoKey] as? BTAtModel {
                urlStr = atInfo.link
            }
            guard let urlStr = urlStr else {
                // 可能是点击了逗号，属于预期内的情况
                DocsLogger.info("[DATA] BTURLField get url nil")
                return
            }
            self.textView.resignFirstResponder()
            let url = BTUtil.addHttpScheme(to: urlStr)
            guard let delegate = delegate else {
                DocsLogger.btError("[DATA] BTURLField open url but delegate is nil")
                return
            }
            delegate.openUrl(url, inFieldModel: fieldModel)
            return
        }
        guard let segment = fieldModel.textValue.first else {
            DocsLogger.btError("[DATA] BTURLField get segment fail")
            return
        }
        self.textView.resignFirstResponder()
        let url = getURLLink(from: segment)
        delegate?.openUrl(url, inFieldModel: fieldModel)
    }
    
    override func startKeyboardObserver() {
        keyboard = Keyboard()
        keyboard.on(events: [.willShow, .willHide, .didShow]) { [weak self] options in
            guard let self = self else { return }
            self.handleKeyboardEvent(options: options)
        }
        keyboard.start()
    }
}

extension BTFieldV2URL {
    
    func setInputAccesssoryView(isSetNil: Bool) {
        if isSetNil {
            self.textView.inputAccessoryView = nil
            return
        }
        if let window = window {
            let rect = CGRect(origin: .zero, size: CGSize(width: window.bounds.width, height: 40))
            let accView = BTKeyboardInputAccessoryView(frame: rect)
            accView.delegate = editAgent
            self.textView.inputAccessoryView = accView
        }
    }
}

// MARK: handle keyboard
extension BTFieldV2URL {
    private func handleKeyboardEvent(options: Keyboard.KeyboardOptions) {
        switch options.event {
        case .willShow:
            if editBoardState == .prepareForShow {
                /// 处理打开超链接编辑面板
                editBoardState = .showed
                self.editBoardManagerView.setEditBoardBottom(options.endFrame.height)
                heightOfContentAboveKeyBoard = BTFieldLayout.Const.urlEditBoardHeight
                self.editAgent?.scrollTillFieldVisible(needAddCursorOffset: false)
            }
        case .willHide:
            /// 这里是为了防止其他异常情况导致键盘下去，但是编辑面板没有消失进行处理。
            /// https://meego.feishu.cn/larksuite/issue/detail/4822622
            if editBoardState != .close {
                urlEditBoardDidCancel(isByClose: false)
            }
        case .didShow:
            if editBoardState == .close, textView.isFirstResponder {
                //长按进入编辑态时，光标被键盘遮挡
                setCursorBootomOffset()
                editAgent?.scrollTillFieldVisible()
            }
        default: break
        }
    }
}

// MARK: 键盘事件
extension BTFieldV2URL: BTFieldCollectionScrollEventObserver {

    func fieldCollectionDidEndScrollingAnimation() {
        if urlTipManager.isNeedToShow {
            showOpenURLTipView()
        }
        urlTipManager.fieldCollectionDidEndScroll()
    }
}


// MARK: 超链接编辑面板逻辑
extension BTFieldV2URL {
   
    private func showEditBoardView() {
        guard let window = window else {
            DocsLogger.btError("[ACTION] BTURLField showEditBoardView without window")
            return
        }
        var text: String = ""
        var link: String = ""
        if let segment = fieldModel.textValue.first {
            text = segment.text
            link = getURLLink(from: segment)
        }
        editBoardState = .prepareForShow
        updateBorderMode(.editing)
        editBoardManagerView.show(data: BTURLEditBoardViewModel(text: text, link: link), superView: window)
    }
    
    private func hideEditBoardView() {
        editBoardState = .close
        updateBorderMode(.normal)
        editBoardManagerView.hide()
        heightOfContentAboveKeyBoard = 0
    }
    
    @objc
    private func editBoardBtnPressed() {
        guard fieldModel.editable else {
            showUneditableToast()
            return
        }
        let newEditAgent = BTURLEditAgent(fieldID: fieldID, recordID: fieldModel.recordID)
        editAgent = newEditAgent
        delegate?.startEditing(inField: self, newEditAgent: newEditAgent)
        showEditBoardView()
    }
    
    // 获取显示的 Link
    private func getURLLink(from segment: BTRichTextSegmentModel) -> String {
        if !segment.link.isEmpty {
            return segment.link
        } else {
            return BTUtil.addHttpScheme(to: segment.text)
        }
    }
}

// MARK: BTURLEditBoardManagerViewDelegate
extension BTFieldV2URL: BTURLEditBoardManagerViewDelegate {
    
    func getHandlerWhenTapAtLocationToWindow(_ location: CGPoint) -> (() -> Void) {
        guard let window = window else {
            return {}
        }
        let rect = self.convert(self.bounds, to: window)
        if rect.contains(location) {
            return { [weak self] in
                self?.textView.becomeFirstResponder()
            }
        } else {
            return {}
        }
    }
}

// MARK: BTURLEditBoardViewDelegate
extension BTFieldV2URL: BTURLEditBoardViewDelegate {
    
    /// 超链接编辑菜单完成回调
    func urlEditBoardDidFinish(contentType: BTURLEditBoardFinishContentType) {
        hideEditBoardView()
        switch contentType {
        case let .normal(data, changeType):
            switch changeType {
            case .none:
                editAgent?.didEndEditBoard(nil)
            default:
                editAgent?.didEndEditBoard(data)
            }
        case .atInfo(let atInfo):
            editAgent?.didEndEditBoard(nil, atInfo)
        }
    }
    
    func urlEditBoardDidCancel(isByClose: Bool) {
        hideEditBoardView()
        editAgent?.didEndEditBoard(nil)
    }
}

// MARK: 气泡菜单
extension BTFieldV2URL {
    
    private var openURLTip: String {
        BundleI18n.SKResource.Bitable_Form_OpenLinkMobileVer
    }
    /// 展示打开链接气泡菜单
    private func showOpenURLTipView() {
        let menuVC = UIMenuController.shared
        self.textView.isEnableOpenURLAction = true
        menuVC.menuItems = [UIMenuItem(title: openURLTip, action: #selector(BTTextView.openURL))]
        let showRect = getCursorRect() ?? textView.bounds
        menuVC.docs.showMenu(from: textView, rect: showRect)
    }
    
    /// 隐藏打开链接气泡菜单
    private func hideOpenURLTipView() {
        if (UIMenuController.shared.menuItems?.contains(where: { $0.title == openURLTip }) ?? false) {
            UIMenuController.shared.docs.hideMenu()
        }
    }
    
    /// 展示非打开链接气泡菜单
    func showMenu() {
        hideOpenURLTipView()
        clearMenuItems()
        let showRect = getCursorRect() ?? textView.bounds
        UIMenuController.shared.docs.showMenu(from: textView, rect: showRect)
    }
    
    /// 判断当前点击是否是之前的光标里。
    private func isTapOnCursor(tapGR: UITapGestureRecognizer) -> Bool {
        debugPrint("BTURLField tapOn cursorRect: \(String(describing: getCursorRect())), " +
                   "lastRect: \(String(describing: lastTapCursorRect)), " +
                   "location: \(tapGR.location(in: textView))")
        let tapLocation = tapGR.location(in: textView)
        if let cursorRect = getCursorRect(), let lastCursorRect = self.lastTapCursorRect, cursorRect.contains(lastCursorRect) {
            let judgeRect = CGRect(x: cursorRect.minX - 10, y: cursorRect.minY, width: cursorRect.width + 20, height: cursorRect.height)
            if judgeRect.contains(tapLocation) {
                return true
            }
        }
        return false
    }
    
    private func addMenuNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(clearMenuItems), name: UIMenuController.didHideMenuNotification, object: nil)
    }
    
    @objc
    private func clearMenuItems() {
        UIMenuController.shared.menuItems = []
        self.textView.isEnableOpenURLAction = false
        lastTapCursorRect = nil
    }
}
