//
//  SheetShowInputService.swift
//  SpaceKit
//
//  Created by Webster on 2019/7/11.
//

// swiftlint:disable file_length
import Foundation
import SKCommon
import SKBrowser
import SKFoundation
import SKUIKit
import SKResource
import HandyJSON
import UniverseDesignIcon
import UniverseDesignColor
import LarkAssetsBrowser
import SpaceInterface

// MARK: Input View 是键盘上方的 输入框 inputTextView + 工具栏 toolbar，Toolkit Button 是 Input View 右上方的圆形按钮

class SheetShowInputService: BaseJSService {
    var inputManager: SheetInputManager?
    let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
    var currentInputMode: SheetInputView.SheetInputMode = .basic

    var inputViewIsHidden: Bool { sheetInputView?.isHidden ?? true }
    var displayingKeyboard: Bool { sheetInputView?.inputTextView.isFirstResponder ?? false }
    // 处理sheet卡片模式不显示FAB按钮的逻辑
    var toolkitButtonShouldHide = false

    var cachedPickerType = SheetDateTimeKeyboardSubtype.none
    var cachedDateValue: Date?
    var deletedTimer: Timer?
    var everEditKeyboard: [SheetInputKeyboardDetails] = [SheetInputKeyboardDetails]() //统计相关的
    
    let cameraType: CameraType = UserScopeNoChangeFG.LJW.cameraStoragePermission ? .systemAutoSave(true) : .system
    lazy var uploadImageManager = SKPickMediaManager(delegate: self,
                                                     assetType: .imageOnly(maxCount: 1),
                                                     cameraType: cameraType,
                                                     rootVC: ui?.editorView.window?.rootViewController)

    weak var toolbar: SheetToolbar? {
        didSet {
            guard let sbvc = registeredVC as? SheetBrowserViewController else { return }
            sbvc.toolbar = toolbar
        }
    }
    weak var sheetInputView: SheetInputView? {
        didSet {
            guard let sbvc = registeredVC as? SheetBrowserViewController else { return }
            sbvc.sheetInputView = sheetInputView
        }
    }
    weak var keyWindow: UIWindow?
    weak var toolkitButton: UIButton?
    lazy var numberKeyboardView: SheetNumKeyboardView = {
        let frame = CGRect(x: 0, y: 0, width: keyboardContainerWidth, height: preferredCustomKeyboardHeight)
        let view = SheetNumKeyboardView(frame: frame)
        view.delegate = self
        return view
    }()
    lazy var dateTimeKeyboardView = SheetDateTimeKeyboardView(subtype: .dateTime, date: Date())
    lazy var imagePickerKeyboardView: UIView = {
        let view = uploadImageManager.suiteView
        view.frame = CGRect(x: 0, y: 0, width: keyboardContainerWidth, height: preferredCustomKeyboardHeight)
        return view
    }()

    // 使用 window 是因为 Magic Share 的场景下 hostView 并不和屏幕底部接触，但是键盘确实是接触底部的
    var windowSafeAreaBottomHeight: CGFloat {
        sheetInputView?.inputView?.window?.safeAreaInsets.bottom ?? ui?.hostView.window?.safeAreaInsets.bottom ?? 0.0
    }
    static let inputViewHeight: CGFloat = 94
    let toolbarHeight: CGFloat = SheetInputView.LayoutInfo.toolbarHeight
    var realInputViewHeight: CGFloat = 94 //非全屏模式下的编辑框高度
    var keyboardHeightInWindow: CGFloat = 200
    var keyboardContainerWidth: CGFloat {
        sheetInputView?.inputView?.superview?.frame.width ?? SKDisplay.mainScreenBounds.width
    }
    lazy var preferredCustomKeyboardHeight: CGFloat = {
        let validWidth = SheetNumKeyboardView.preferredKeyboardWidth(for: keyboardContainerWidth)
        let height = validWidth * 258 / 375
        return height
    }()

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
        dateTimeKeyboardView.delegate = self
        selectionFeedbackGenerator.prepare()
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveModalViewControllerWillAppear), name: Notification.Name.Docs.modalViewControllerWillAppear, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveModalViewControllerWillDismiss), name: Notification.Name.Docs.modalViewControllerWillDismiss, object: nil)
        if SKDisplay.pad {
            NotificationCenter.default.addObserver(self, selector: #selector(didReceiveOrientatioDidChange), name: UIApplication.willChangeStatusBarOrientationNotification, object: nil)
        }
    }

    deinit {
        stopTimer()
    }

    @objc
    func didReceiveModalViewControllerWillAppear() {
        toolkitButton?.removeFromSuperview()
        sheetInputView?.removeFromSuperview()
        sheetInputView = nil
    }

    @objc
    func didReceiveModalViewControllerWillDismiss() {
        ui?.uiResponder.becomeFirst()
        restoreEditBaseIfNeed()
    }

    @objc
    func didReceiveOrientatioDidChange() {
        browserWillTransition(from: .zero, to: .zero)
    }

    private func restoreEditBaseIfNeed() {
        attachInputViewIfNeeded()
        attachToolkitButtonIfNeeded()
        hideInputView(true)
        toolkitButton?.isHidden = true
        if let view = self.sheetInputView {
            self.sheetInputView?.superview?.sendSubviewToBack(view)
        }
    }
}

extension SheetShowInputService: BrowserViewLifeCycleEvent {
    func browserDidAppear() {
        inputManager = SheetInputManager(model)
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) { [weak self] in
            self?.attachInputViewIfNeeded()
            self?.attachToolkitButtonIfNeeded()
            self?.hideInputView(true)
            self?.toolkitButton?.isHidden = true
        }
    }

    func browserWillClear() {
        sheetInputView?.removeFromSuperview()
        sheetInputView = nil
        toolkitButton?.removeFromSuperview()
        NotificationCenter.default.removeObserver(self)
    }

    func browserWillTransition(from: CGSize, to: CGSize) {
        stopEditing()
        toolkitButton?.removeFromSuperview()
        sheetInputView?.removeFromSuperview()
        sheetInputView = nil
    }

    func browserDidTransition(from: CGSize, to: CGSize) {
        restoreEditBaseIfNeed()
    }
    
    func browserDidSplitModeChange() {
        restoreEditBaseIfNeed()
    }
}

extension SheetShowInputService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.sheetShowInput]
    }

    func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.sheetShowInput.rawValue:
            DocsLogger.info("web call sheetShowInput, hide:\(params.isEmpty)", component: LogComponents.toolbar)
            updateInputView(params)
        default:
            ()
        }
    }

    struct ShowInputParams: HandyJSON {
        var data: SheetInputData?
        var hideFAB: Bool = false
        var toolbarItems: [SheetToolbarItemInfo] = []
    }
    
    private func updateInputView(_ params: [String: Any]) {
        guard let sbvc = registeredVC as? SheetBrowserViewController, sbvc.view != nil else { return }
        guard let json = ShowInputParams.deserialize(from: params), let data = json.data else {
            stopEditing()
            return
        }
        
        for item in json.toolbarItems {
            if item.id == .insertImage {
                let canUpload = self.checkUploadPermission(false)
                item.isEnabled = canUpload //上层增加条件访问管控
            }
        }
        
        let badges = params["badges"] as? [String]
        let textToEdit = SheetFieldDataConvert.convertSegmentToAttString(from: data.realValue, cellStyle: SheetCustomCellStyle(data.style)) // 当前单元格内容以及样式
        updateInputView(data,
                        textToEdit: textToEdit,
                        hideFAB: json.hideFAB,
                        toolbarItems: json.toolbarItems,
                        badges: badges)
    }
    
    func updateInputView(_ data: SheetInputData,
                         textToEdit: NSMutableAttributedString?,
                         hideFAB: Bool,
                         toolbarItems: [SheetToolbarItemInfo],
                         badges: [String]?,
                         keyboardType: BarButtonIdentifier = .systemText) {
        hideInputView(false)
        ui?.uiResponder.stopMonitorKeyboard()
        attachInputViewIfNeeded()
        attachToolkitButtonIfNeeded()
        if let view = sheetInputView {
            hideInputView(false)
            sheetInputView?.superview?.bringSubviewToFront(view)
        }
        toolkitButtonShouldHide = hideFAB
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let inputViewHidden = self.sheetInputView?.isHidden ?? true
            self.toolkitButton?.isHidden = self.toolkitButtonShouldHide ? true : inputViewHidden
        }
       
        let inputType = data.format // 希望打开时选中的键盘格式：只会有 abc、123 和日期三种
        let dateTimeType = data.dateType // 日期键盘的格式

        var keyboardType: BarButtonIdentifier = keyboardType
        sheetInputView?.keyboardInfo = SheetInputKeyboardDetails(mainType: .systemText, subType: .none)
        var caretShouldHide = false
        var newlineButtonShouldDisable = false
        switch inputType {
        case BarButtonIdentifier.systemText.rawValue:
            keyboardType = .systemText
            sheetInputView?.keyboardInfo = SheetInputKeyboardDetails(mainType: keyboardType, subType: .none)
            caretShouldHide = false
            switchKeyboardView(nil)
        case BarButtonIdentifier.customNumber.rawValue:
            keyboardType = .customNumber
            sheetInputView?.keyboardInfo = SheetInputKeyboardDetails(mainType: keyboardType, subType: .none)
            caretShouldHide = false
            numberKeyboardView.frame.size = CGSize(width: keyboardContainerWidth,
                                                   height: preferredCustomKeyboardHeight + windowSafeAreaBottomHeight)
            switchKeyboardView(numberKeyboardView)
        case BarButtonIdentifier.customDate.rawValue:
            keyboardType = .customDate
            let shouldUsePickerType = parse(dateTimeType)
            var shouldDisplayDate: Date
            if let textToEdit = textToEdit, textToEdit.string.isEmpty, let cachedDateValue = cachedDateValue {
                shouldDisplayDate = cachedDateValue
            } else if let textToEdit = textToEdit {
                shouldDisplayDate = format(textToEdit.string, to: shouldUsePickerType) ?? Date()
                cachedDateValue = shouldDisplayDate
            } else {
                shouldDisplayDate = Date()
            }
            dateTimeKeyboardView.frame.size = CGSize(width: keyboardContainerWidth,
                                                     height: preferredCustomKeyboardHeight + windowSafeAreaBottomHeight)
            switchKeyboardView(dateTimeKeyboardView)
            dateTimeKeyboardView.updatePicker(subtype: shouldUsePickerType, date: shouldDisplayDate)
            sheetInputView?.keyboardInfo = SheetInputKeyboardDetails(mainType: keyboardType, subType: shouldUsePickerType)
            caretShouldHide = true
            newlineButtonShouldDisable = true
        default:
            DocsLogger.error("前端传过来的 toolbar 类型不对，应该只有 ABC 123 日期 三个")
            //return
        }
        let initialBarItems = toolbarItems
        initialBarItems.forEach { (item) in
            item.updateValue(toSelected: item.id == keyboardType)
        }
        if let badgedItemsArray = badges {
            let badgedItemsID = badgedItemsArray.compactMap { BarButtonIdentifier(rawValue: $0) }
            initialBarItems.forEach { (item) in
                item.updateValue(toBadged: badgedItemsID.contains(item.id))
            }
        }
        DocsLogger.info("start edit sheet cell: \(data.cellInfo)")
        if !SKDisplay.isInSplitScreen, sheetInputView?.keyboardLayoutGuideEnable == true {
            //先取消webview的焦点
            ui?.uiResponder.resign()
        }
        updateToolbar(withItems: initialBarItems)
        sheetInputView?.setCaretHidden(caretShouldHide)
        sheetInputView?.disableNewline(newlineButtonShouldDisable)
        sheetInputView?.attributeArray = data.realValue
        sheetInputView?.cellStyle = data.style
        sheetInputView?.editCellID = data.cellInfo
        sheetInputView?.inputData = data
        sheetInputView?.beginEditWith(textToEdit)
    }
    
    private func attachInputViewIfNeeded() {
        guard let container = registeredVC?.view else { return }
        guard let docsInfo = self.docsInfo, docsInfo.isSheet else { return }
        if let view = sheetInputView, view.superview != nil { return }
        let inputView = makeInputView()
        var keyboardLayoutGuide: SKKeyboardLayoutGuide?
        if inputView.keyboardLayoutGuideEnable {
            keyboardLayoutGuide = container.skKeyboardLayoutGuide
        }
        container.addSubview(inputView)
        inputView.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalTo(SheetShowInputService.inputViewHeight)
            make.left.right.equalToSuperview()
            if let layoutGuide = keyboardLayoutGuide {
                make.bottom.equalTo(layoutGuide.snp.top)
            } else {
                make.bottom.equalToSuperview().offset(SheetShowInputService.inputViewHeight)
            }
        }
        sheetInputView = inputView
        keyboardLayoutGuide?.on(identifier: DocsKeyboardTrigger.sheetEditor.rawValue) { [weak self] (isShow, height, options) in
            guard let self, let container = self.registeredVC?.view else { return }
            let currentKeyWindow = UIApplication.shared.keyWindow
            if self.keyWindow != currentKeyWindow {
                //判断当前输入框是否在keyWindow，不在应当隐藏
                self.keyWindow = currentKeyWindow
                guard self.sheetInputView?.window == currentKeyWindow else {
                    self.inputViewWillHide(self.sheetInputView)
                    return
                }
            }
            if self.sheetInputView?.isHidden == true {
                DocsLogger.info("input view is Hidden, no more need keyboard action", component: LogComponents.toolbar)
                return
            }
            self.sheetInputView?.performActionWhenKeyboard(isShow: isShow, keyboardHeight: height, options: options)
            self.keyboardHeightInWindow = height
            let pointInContainer = container.frame.height - height - self.realInputViewHeight
            let pointInEditor = container.convert(CGPoint(x: 0, y: pointInContainer), to: self.ui?.editorView)
            let viewportHeight = pointInEditor.y
            let info = SimulateKeyboardInfo()
            info.height = viewportHeight
            info.trigger = DocsKeyboardTrigger.sheetEditor.rawValue
            info.isShow = true
            let params: [String: Any] = [SimulateKeyboardInfo.key: info]
            DocsLogger.info("sheetInput dispatchKeyboardHeight,\(params)", component: LogComponents.toolbar)
            self.model?.jsEngine.simulateJSMessage(DocsJSService.simulateKeyboardChange.rawValue, params: params)
        }
    }

    private func attachToolkitButtonIfNeeded() {
        guard let container = registeredVC?.view else { return }
        guard let inputView = sheetInputView, inputView.superview != nil else { return }
        if let toolkitButton = toolkitButton, toolkitButton.superview != nil { return }

        let button = FloatPrimaryButton(id: .toolkit)
        container.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.width.height.equalTo(40)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(inputView.snp.top).offset(-16)
        }
        _ = button.rx.tap.subscribe(onNext: { [weak self] _ in self?.didPressToolkitButton() })
        toolkitButton = button
    }

    private func makeInputView() -> SheetInputView {
        let inputView = SheetInputView(bottomSafeAreaHeight: windowSafeAreaBottomHeight, from: .sheet)
        inputView.uiDelegate = self
        inputView.delegate = self
        inputView.backgroundColor = UIColor.ud.N00
        inputView.layer.shadowColor = UIColor.ud.N900.cgColor
        inputView.layer.shadowOffset = CGSize(width: 0, height: -6)
        inputView.layer.shadowOpacity = 0.08
        inputView.layer.shadowRadius = 24
        inputView.hideAtButton() // 独立 sheets 需要隐藏 at 按钮，因为工具栏里面也有一个
        let bar = SheetToolbar(delegate: self)
        inputView.contentView.addSubview(bar)
        bar.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalTo(toolbarHeight)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        toolbar = bar
        return inputView
    }

    private func updateToolbar(withItems items: [SheetToolbarItemInfo]) {
        toolbar?.toolbarItems = items
    }

    private func hideInputView(_ hides: Bool) {
        sheetInputView?.isHidden = hides
        if let view = sheetInputView {
            if hides {
                view.superview?.sendSubviewToBack(view)
            } else {
                view.superview?.bringSubviewToFront(view)
            }
        }
    }

    private func clearToolbarBadges() {
        guard let badgedItems: [String] = toolbar?.badgedItems else {
            DocsLogger.info("toolbar 不存在，或是 toolbar 上不存在红点，不需要调用 clear badges", component: LogComponents.toolbar)
            return
        }
        model?.jsEngine.callFunction(
            .sheetClearBadges,
            params: [
                "panelName": BadgedItemIdentifier.sheetToolbar.rawValue,
                "badges": badgedItems
            ] as [String: Any],
            completion: { (_, error) in
                if let error = error {
                    DocsLogger.error("sheet toolbar clear badges failure:", error: error, component: LogComponents.toolbar)
                }
            }
        )
    }

    func stopEditing() {
        DocsLogger.info("sheet stopEditing", component: LogComponents.toolbar)
        sheetInputView?.endEdit()
        hideInputView(true)
        clearToolbarBadges()
        toolkitButtonShouldHide = false
        toolkitButton?.isHidden = true
        cachedDateValue = nil
        cachedPickerType = .none
        sheetInputView?.cleanText()
        logKeyboardEditStatus()
        ui?.uiResponder.becomeFirst()
        if sheetInputView?.isHidden == false, sheetInputView?.isFirstResponder == true {
            dispatchKeyboardHeightIfHidden()
        }
    }

    func didPressToolkitButton() {
        logKeyboardToolkitSwitchToFAB()
        stopEditing()
        jsEngine?.simulateJSMessage(DocsJSService.simulateOpenSheetToolkit.rawValue, params: ["id": FABIdentifier.toolkit.rawValue])
    }
}

extension SheetShowInputService: SheetInputViewUIDelegate {
    func inputView(_ inputView: SheetInputView, changeMode mode: SheetInputView.SheetInputMode) {
        currentInputMode = mode
        let inputViewHidden = sheetInputView?.isHidden ?? true
        if currentInputMode == .full {
            disableCellSwitch(disable: true)
            dateTimeKeyboardView.isInFullScreenInputMode = true
            toolkitButton?.isHidden = true
        } else {
            disableCellSwitch(disable: false)
            dateTimeKeyboardView.isInFullScreenInputMode = false
            toolkitButton?.isHidden = toolkitButtonShouldHide ? true : inputViewHidden
        }
    }

    func refreshCustomKeyboardFrame() {
        // 在切换到系统键盘的 window 之后，重新适应宽度和安全区
        DispatchQueue.main.async { [weak self] in
            defer {
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) { [weak self] in
                    self?.sheetInputView?.inputTextView.reloadInputViews()
                }
            }
            guard let currentKeyboardView = self?.sheetInputView?.inputView else { return }
            guard let containerWidth = self?.keyboardContainerWidth,
                  let keyboardPreferredHeight = self?.preferredCustomKeyboardHeight,
                  let keyboardWindow = currentKeyboardView.window else { return }
            switch currentKeyboardView {
            case let numberKeyboardView as SheetNumKeyboardView:
                numberKeyboardView.frame = CGRect(origin: .zero,
                                                  size: CGSize(width: containerWidth,
                                                         height: keyboardPreferredHeight + keyboardWindow.safeAreaInsets.bottom))
                numberKeyboardView.update(containerWidth: containerWidth)
            default:
                currentKeyboardView.frame = CGRect(origin: .zero,
                                                   size: CGSize(width: containerWidth,
                                                          height: keyboardPreferredHeight + keyboardWindow.safeAreaInsets.bottom))
            }
            self?.sheetInputView?.inputView = currentKeyboardView
        }
    }

    func inputView(_ inputView: SheetInputView, updateHeight height: CGFloat, layoutNow: Bool) {
        sheetInputView?.snp.updateConstraints { (make) in
            make.height.equalTo(height)
        }
        if layoutNow {
            sheetInputView?.layoutIfNeeded()
            registeredVC?.view.layoutIfNeeded()
        }
        //输入文字触发调整输入框高度
        if currentInputMode != .full && height != realInputViewHeight && !inputViewIsHidden {
            dispatchKeyboardHeightIfEditing(inputHeight: height)
        }
        if currentInputMode != .full {
            realInputViewHeight = height
        }
    }
    
    func inputViewWillHide(_ inputView: SheetInputView?) {
        if inputView?.isHidden == false {
            self.tellFEExitEdit()
            dispatchKeyboardHeightIfHidden()
        }
        inputView?.cleanText()
        self.hideInputView(true)
        self.toolkitButton?.isHidden = true
    }

    func inputViewReceive(_ keyboardEvent: Keyboard.KeyboardEvent, options: Keyboard.KeyboardOptions) {
        guard let sheetInputView = self.sheetInputView else { return }
        if sheetInputView.isHidden {
            DocsLogger.info("input view 已经不见了，不需要响应键盘事件", component: LogComponents.toolbar)
            return
        }
        guard let sbvc = registeredVC as? BrowserViewController, let window = sbvc.view.window else { return } // 不可能会失败
        // iPadOS 15 在拖动键盘小方块结束的时候会发送 willShow / willChangeFrame，其中的 start/end 都是 .zero，这个会导致工具栏飞上去，屏蔽掉
        // 长期的做法应该是在 iPadOS 15 上面使用 UIKeyboardLayoutGuide 来布局，或者把 iPad 工具栏的按钮集成到系统的 inputAssistant 里
        if options.beginFrame == .zero && options.endFrame == .zero { return }
        if options.endFrame.size == .zero, options.fixedEndFrameForSheet.origin.y == 0, options.event == .didChangeFrame {
            //在iOS16拖动妙控小键盘后，didChangeFrame收到的endFrame和hostViewFrame的origin为0的异常事件，键盘y值不可能为0的，忽略之
            DocsLogger.info("sheetInput ignore invalid keyboard event", component: LogComponents.toolbar)
            return
        }
        let beginY = options.beginFrame.minY
        let endY = options.fixedEndFrameForSheet.minY
        let screenMaxY = window.bounds.height
        var realEvent = Keyboard.KeyboardEvent.willChangeFrame
        var changeEvent = true
       
        //willShow不应该被改变,为了适配浮动键盘，需要改变willHide和didChangeFrame
        changeEvent = keyboardEvent != .willShow
        
        if changeEvent {
            var changeToHide = endY >= screenMaxY
            if keyboardEvent != .willHide {
                //iOS16.1妙控willShow或didChangeFrame时，endFrame.size为0,此时endY == screenMaxY
                changeToHide = (endY - screenMaxY) > 4 //在分屏下Y值有时会超出一点点，暂时认为是合理的,等重构吧
            }
            if changeToHide {
                realEvent = .willHide
                dispatchKeyboardHeight(event: realEvent, options: options)
                guard sheetInputView.superview != nil else { return }
                sheetInputView.snp.updateConstraints { (make) in
                    make.bottom.equalToSuperview().offset(200)
                }
                if sheetInputView.isHidden == false {
                    self.tellFEExitEdit()
                }
                sheetInputView.cleanText()
                self.hideInputView(true)
                self.toolkitButton?.isHidden = true
                DocsLogger.info("sheetInput changeToHide from \(keyboardEvent),endY:\(endY),screenMaxY:\(screenMaxY) ", component: LogComponents.toolbar)
                return
            } else if beginY >= screenMaxY {
                realEvent = .willShow
            }
        }
        dispatchKeyboardHeight(event: realEvent, options: options)
        let keyboardTopInBrowserView = sbvc.view.convert(options.fixedEndFrameForSheet, from: nil).top
        let toolbarBottomOffset = max(0, sbvc.view.frame.bottom - keyboardTopInBrowserView)
        DocsLogger.info("sheetInput change \(keyboardEvent) to \(realEvent), toolbarBottomOffset:\(toolbarBottomOffset), keyboardTop:\(keyboardTopInBrowserView)", component: LogComponents.toolbar)
        guard sheetInputView.superview != nil else { return }
        let animationCurve = UIView.AnimationOptions(rawValue: UInt(options.animationCurve.rawValue))
        UIView.animate(withDuration: options.animationDuration, delay: 0, options: animationCurve) {
            sheetInputView.snp.updateConstraints { (make) in
                make.bottom.equalToSuperview().offset(-toolbarBottomOffset)
            }
            sheetInputView.superview?.layoutIfNeeded()
        }
    }

    /// 收到系统键盘事件，通知前端视窗尺寸更新
    func dispatchKeyboardHeight(event: Keyboard.KeyboardEvent, options: Keyboard.KeyboardOptions) {
        guard let sbvc = registeredVC as? BrowserViewController else { return }
        let webviewHeight = sbvc.view.frame.height - sbvc.statusBar.frame.height - sbvc.topContainer.frame.height
        let info = SimulateKeyboardInfo()
        switch event {
        case .willShow, .willChangeFrame:
            let keyboardTopInBrowserView = sbvc.view.convert(options.fixedEndFrameForSheet, from: nil).top
            let toolbarBottomOffset = max(0, sbvc.view.frame.bottom - keyboardTopInBrowserView)
            let viewportHeight = webviewHeight - toolbarBottomOffset - realInputViewHeight
            info.height = viewportHeight
            info.isShow = true
            keyboardHeightInWindow = sbvc.view.convert(options.fixedEndFrameForSheet, from: nil).height
        case .willHide:
            info.height = webviewHeight
            info.isShow = false
            keyboardHeightInWindow = 0
        default: return
        }
        info.trigger = options.trigger
        let params: [String: Any] = [SimulateKeyboardInfo.key: info]
        DocsLogger.info("sheetInput dispatchKeyboardHeight,\(params)", component: LogComponents.toolbar)
        model?.jsEngine.simulateJSMessage(DocsJSService.simulateKeyboardChange.rawValue, params: params)
    }

    /// 输入框编辑模式切换时通知前端视窗尺寸更新，这个方法由于拿不到键盘的 endframe，所以采用另一种计算 viewport 高度的方法
    func dispatchKeyboardHeightIfEditing(inputHeight: CGFloat) {
        guard let sbvc = registeredVC as? BrowserViewController else { return }
        let statusBarHeight: CGFloat = sbvc.statusBar.bounds.height
        let topContainerHeight: CGFloat = sbvc.topContainer.bounds.height
        let browserViewDistanceToWindowBottom = sbvc.browserViewDistanceToWindowBottom
        let maxHeight = sbvc.view.frame.height + browserViewDistanceToWindowBottom
        var info: SimulateKeyboardInfo = SimulateKeyboardInfo()
        let viewportHeight = maxHeight - max(keyboardHeightInWindow, browserViewDistanceToWindowBottom) - statusBarHeight - topContainerHeight - inputHeight
        info = SimulateKeyboardInfo()
        info.height = viewportHeight
        info.isShow = true
        info.trigger = DocsKeyboardTrigger.sheetEditor.rawValue
        let params: [String: Any] = [SimulateKeyboardInfo.key: info]
        DocsLogger.info("sheetInput dispatchKeyboardHeightIfEditing,\(params)", component: LogComponents.toolbar)
        model?.jsEngine.simulateJSMessage(DocsJSService.simulateKeyboardChange.rawValue, params: params)
    }

    /// 结束编辑时通知前端视窗尺寸更新
    func dispatchKeyboardHeightIfHidden() {
        guard let sbvc = registeredVC as? BrowserViewController else { return }
        // BrowserView 在 VC Follow 的时候，是 VC Window 的 subview。这个时候底端有视频会议的工具栏，它的高度也是要考虑进去的
        let maxHeight = sbvc.view.frame.height
        let statusBarHeight: CGFloat = sbvc.statusBar.bounds.height
        let topContainerHeight: CGFloat = sbvc.topContainer.bounds.height
        let innerHeight = maxHeight - statusBarHeight - topContainerHeight
        let info = SimulateKeyboardInfo()
        info.height = innerHeight
        info.isShow = false
        info.trigger = DocsKeyboardTrigger.sheetEditor.rawValue
        let params: [String: Any] = [SimulateKeyboardInfo.key: info]
        DocsLogger.info("sheetInput dispatchKeyboardHeightIfHidden,\(params)", component: LogComponents.toolbar)
        model?.jsEngine.simulateJSMessage(DocsJSService.simulateKeyboardChange.rawValue, params: params)
    }


    func inputViewIsEditing(_ inputView: SheetInputView, in keyboard: SheetInputKeyboardDetails) {
        everEditKeyboard.append(keyboard)
    }

    func inputViewGoDownItemInSystemKeyboard(_ inputView: SheetInputView) {
        logPressSystemKeyboardNextItem()
    }
}

extension SheetShowInputService: SheetInputViewDelegate {
    
    var browserVC: BrowserViewController? { registeredVC as? BrowserViewController }

    func inputView(_ inputview: SheetInputView, didChangeInput segmentArr: [[String: Any]]?, editState: SheetInputView.SheetEditMode, keyboard: SheetInputKeyboardDetails) {
        inputManager?.inputView(didChangeInput: inputview.editCellID,
                                segmentArr: segmentArr,
                                editState: editState,
                                keyboard: keyboard)
    }
    
    func inputView(_ inputView: SheetInputView, open url: URL) {
        self.navigator?.requiresOpen(url: url)
    }

    func atViewController(type: AtViewType) -> AtListView? {
        return inputManager?.atListView(type: type)
    }

    func hideInputView(_ inputView: SheetInputView) {
        DocsTracker.log(enumEvent: .sheetCloseKeyboard, parameters: nil)
    }

    func inputView(_ inputView: SheetInputView, switchTo mode: SheetInputView.SheetInputMode) {}

    func doStatisticsForAction(enumEvent: DocsTracker.EventType, extraParameters: [SheetInputView.StatisticParams: SheetInputView.SheetAction]) {
        inputManager?.doStatisticsForAction(enumEvent: enumEvent, extraParameters: extraParameters)
    }

    func logEditMode(infos: [String: String]) {}

    func fileIdForStatistics() -> String? {
        return inputManager?.fileIdForStatistics()
    }
    
    func enterFullMode() {}

    func exitFullMode() {}
}

extension SheetShowInputService: SheetDateTimeKeyboardDelegate {

    var jsEngine: BrowserJSEngine? {
        return model?.jsEngine
    }

    var cachedValue: Date? {
        get { return cachedDateValue }
        set { cachedDateValue = newValue }
    }

    var cachedSubtype: SheetDateTimeKeyboardSubtype {
        get { return cachedPickerType }
        set { cachedPickerType = newValue }
    }

    func didSwitchDatetimeInputSubtype(to subtype: SheetDateTimeKeyboardSubtype) {
        let keyboardInfo = SheetInputKeyboardDetails(mainType: .customDate, subType: subtype)
        sheetInputView?.keyboardInfo = keyboardInfo
        sheetInputView?.callJSForTextChanged(text: sheetInputView?.attributedText ?? NSAttributedString(), editState: .editing)
    }

    func logCompletion(type: SheetDateTimeKeyboardSubtype) {
        logCompleteDateTimeKeyboardSelection(type: type)
    }

    private func parse(_ str: String) -> SheetDateTimeKeyboardSubtype {
        switch str {
        case "datetime":
            return .dateTime
        case "date":
            return .date
        case "time":
            return .time
        default:
            return cachedPickerType
        }
    }

    private func format(_ str: String, to type: SheetDateTimeKeyboardSubtype) -> Date? {
        let formatter = DateFormatter()
        if type == .time {
            let today = Date()
            formatter.dateFormat = "yyyy-MM-dd"
            let newStr = "\(formatter.string(from: today)) \(str)"
            for format in type.formats {
                formatter.dateFormat = "yyyy-MM-dd \(format)"
                if let date = formatter.date(from: newStr) {
                    return date
                }
            }
        } else {
            for format in type.formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: str) {
                    return date
                }
            }
        }
        return nil
    }
}
