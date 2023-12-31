//
//  SheetInputView.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/7/30.
//  当选中单元格时，屏幕下方的 input accessory view，里面有个输入框充当 PC 端 Fx 栏的作用，还包含一个 toolbar（在外面注入）
//  监听了键盘事件，将事件分发给 SheetShowInputService 处理
//  swiftlint:disable file_length cyclomatic_complexity line_length function_body_length

import UIKit
import SnapKit
import RxSwift
import SKCommon
import SKFoundation
import SKUIKit
import SKResource
import LarkAssetsBrowser
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignFont
import SKResource
import SpaceInterface
import SKInfra

public protocol SheetInputViewDelegate: AnyObject {
    var browserVC: BrowserViewController? { get }
    func atViewController(type: AtViewType) -> AtListView?
    func hideInputView(_ inputView: SheetInputView)
    func inputView(_ inputview: SheetInputView, didChangeInput segmentArr: [[String: Any]]?, editState: SheetInputView.SheetEditMode, keyboard: SheetInputKeyboardDetails)
    func inputView(_ inputView: SheetInputView, switchTo mode: SheetInputView.SheetInputMode)
    func inputView(_ inputView: SheetInputView, open url: URL)
    func doStatisticsForAction(enumEvent: DocsTracker.EventType, extraParameters: [SheetInputView.StatisticParams: SheetInputView.SheetAction])
    func logEditMode(infos: [String: String])
    func fileIdForStatistics() -> String?
    func enterFullMode()
    func exitFullMode()
}

public protocol SheetInputViewUIDelegate: AnyObject {
    func inputView(_ inputView: SheetInputView, changeMode mode: SheetInputView.SheetInputMode)
    func inputView(_ inputView: SheetInputView, updateHeight height: CGFloat, layoutNow: Bool)
    func inputViewReceive(_ keyboardEvent: Keyboard.KeyboardEvent, options: Keyboard.KeyboardOptions)
    func inputViewIsEditing(_ inputView: SheetInputView, in keyboard: SheetInputKeyboardDetails)
    func inputViewGoDownItemInSystemKeyboard(_ inputView: SheetInputView)
    func inputViewWillHide(_ inputView: SheetInputView?)
}

extension SheetInputViewDelegate {
    func atViewController(type: AtViewType) -> AtListView? { return nil }
}

extension SheetInputViewUIDelegate {
    public func inputViewIsEditing(_ inputView: SheetInputView, in keyboard: SheetInputKeyboardDetails) {}
    public func inputViewGoDownItemInSystemKeyboard(_ inputView: SheetInputView) {}
}

public final class SheetInputView: UIView {
    public var attributeArray: [SheetSegmentBase] = [] // 表格中的局部样式数组
    public var cellStyle: SheetStyleJSON? { //表格整体样式
        didSet {
            if let style = cellStyle {
                cellAttributes = SheetFieldDataConvert.convertFromStyleToAttributes(from: style, isSpecial: false)
            } else {
                cellAttributes = nil
            }
        }
    }
    public private(set) var cellAttributes: [NSAttributedString.Key: Any]?
    public var editCellID: String? //当前编辑的cellID
    
    public var inputData: SheetInputData?
    
    public enum SheetInputMode: Int {
        case basic /*文字不足的单行模式*/
        case multi /*多行模式*/
        case full  /*全屏*/
        //上报的名字
        public func logName() -> String {
            switch self {
            case .basic, .multi:
                return "default"
            default:
                return "cell_expand"
            }
        }
    }

    public enum SheetEditMode: Int {
        case endCellEdit = 1 //跳到下一个单元格
        case endSheetEdit = 2
        case editing = 3
        case jumpRightItem = 4 //跳到右边的单元格
    }

    public struct LayoutInfo {
        static public let basicInputHeight: CGFloat = 22
        static public let maxInputHeight: CGFloat = 66
        static public let buttonHeight: CGFloat = 32
        static public let baseFxHeight: CGFloat = 49
        static public let toolbarHeight: CGFloat = 44
        static public let baseModeHeightOneLine = LayoutInfo.baseFxHeight + LayoutInfo.toolbarHeight
        static public let fullModeHeight = 300
        static public let baseInputRightPadding: CGFloat = 100
        static public let txtLeftPadding: CGFloat = 16
        static public let txtTopPadding: CGFloat = 14
        static public let multiTxtTopPadding: CGFloat = 9
        static public let fullInputTopPadding: CGFloat = 47
        static public let buttonBottomPadding: CGFloat = 8.5
        static public let buttonLeftPadding: CGFloat = 12
    }

    let disposeBag = DisposeBag()
    /// 高度的Inset，指定影响全屏高度的控件高度，如工具栏高度
    var heightInset: CGFloat = 0
    public var keyboardInfo: SheetInputKeyboardDetails = SheetInputKeyboardDetails(mainType: .systemText, subType: .none)
    var bottomSafeAreaHeight: CGFloat
    public var ignoreInputViewResign: Bool = false
    private var caretNormalColor = UIColor.clear
    private var dynamicInputHeight: CGFloat = 66
    override public var isFirstResponder: Bool {
        return inputTextView.isFirstResponder
    }
    /// 当前 keyboard view
    override public var inputView: UIView? {
        get { return inputTextView.inputView }
        set {
            inputTextView.inputView = newValue
            inputTextView.reloadInputViews()
        }
    }

    public var attributedText: NSAttributedString {
        return inputTextView.attributedText
    }

    //进入全屏模式
    private lazy var expandButton: UIButton = {
        let button = UIButton()
        let image = UDIcon.richtextOutlined
        button.setImage(image.ud.withTintColor(UDColor.iconN1), for: .normal)
        button.setImage(image.ud.withTintColor(UDColor.iconN2), for: .highlighted)
        button.addTarget(self, action: #selector(enterFullMode), for: .touchUpInside)
        return button
    }()

    // 退出全屏模式
    private lazy var narrowButton: UIButton = {
        let button = UIButton()
        let image = UDIcon.richtextQuitOutlined
        button.setImage(image.ud.withTintColor(UDColor.iconN1), for: .normal)
        button.setImage(image.ud.withTintColor(UDColor.iconN2), for: .highlighted)
        button.addTarget(self, action: #selector(exitFullMode), for: .touchUpInside)
        return button
    }()

    private lazy var atButton: UIButton = {
        let b = UIButton()
        let image = UDIcon.atOutlined
        b.setImage(image.ud.withTintColor(UDColor.iconN1), for: .normal)
        b.setImage(image.ud.withTintColor(UDColor.iconN2), for: .highlighted)
        b.addTarget(self, action: #selector(atButtonAction), for: UIControl.Event.touchUpInside)
        b.backgroundColor = .clear
        return b
    }()

    private lazy var newlineButton: UIButton = {
        let b = UIButton()
        let image = UDIcon.lineFeedOutlined
        b.setImage(image.ud.withTintColor(UDColor.iconN1), for: .normal)
        b.setImage(image.ud.withTintColor(UDColor.iconN2), for: .highlighted)
        b.setImage(image.ud.withTintColor(UDColor.iconDisabled), for: .disabled)
        b.setImage(image.ud.withTintColor(UDColor.iconDisabled), for: UIControl.State.disabled.union(.highlighted))
        b.addTarget(self, action: #selector(newlineButtonAction), for: UIControl.Event.touchUpInside)
        b.backgroundColor = .clear
        return b
    }()

    private(set) var atListView: AtListView?

    public private(set) lazy var inputTextView: SheetTextView = {
        let t = SheetTextView()
        t.font = self.inputFont
        t.textColor = UDColor.textTitle
        t.backgroundColor = UDColor.bgBody
        t.showsHorizontalScrollIndicator = false
        t.textContainer.lineBreakMode = .byWordWrapping
        t.returnKeyType = .next
        t.layoutManager.allowsNonContiguousLayout = false
        t.pasteOperation = { [weak self] in
            self?._doPaste()
        }
        caretNormalColor = t.tintColor
        t.textViewDelegate = self
        return t
    }()

    private lazy var buttonContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()

    public private(set) lazy var contentView: UIView = {
        let v = UIView()
        v.backgroundColor = UDColor.bgBody
        v.layer.masksToBounds = true
        v.clipsToBounds = true
        v.layer.ud.setShadowColor(UDColor.N900)
        v.layer.shadowOffset = CGSize(width: 0, height: -6)
        v.layer.shadowOpacity = 0.08
        v.layer.shadowRadius = 24
        return v
    }()

    private lazy var bottomSeparateLine: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.N400
        return view
    }()

    private lazy var inputFont: UIFont = {
        let font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        return font
    }()

    lazy var normalAttribution: [NSAttributedString.Key: Any] = {
        let leftAlign = NSMutableParagraphStyle()
        leftAlign.alignment = .left
        leftAlign.lineSpacing = 2
        leftAlign.lineBreakMode = .byWordWrapping
        let style = SheetStyleJSON()
        let attribution: [NSAttributedString.Key: Any] = [
                           NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle,
                           NSAttributedString.Key.paragraphStyle: leftAlign,
                           NSAttributedString.Key.font: self.inputFont,
                           SheetInputView.attributedStringStyleKey: style]
        return attribution
    }()

    private lazy var safeAreaButtomMask: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        view.isUserInteractionEnabled = false
        return view
    }()

    public var currentText: String = ""
    public var currentAttText: NSMutableAttributedString = NSMutableAttributedString()
    private var fullModeHideToolBar: Bool {
        // sheet at docs 全屏模式下会隐藏 toolbar，独立 sheets 不会
        source == .docs
    }
    private var keyboard: Keyboard?
    private let kAniamteDuration: TimeInterval = 0.25
    private var currentKeyboardY: CGFloat = 0
    static public let attributedStringFontSizeKey = NSAttributedString.Key(rawValue: "fontSize")
    static public let attributedStringFontFamilyKey = NSAttributedString.Key(rawValue: "fontFamily")
    static public let attributedStringFontStyleKey = NSAttributedString.Key(rawValue: "fontStyle")
    static public let attributedStringSegmentKey = NSAttributedString.Key(rawValue: "Segment")
    static public let attributedStringHyperLinkIdKey = NSAttributedString.Key(rawValue: "HyperLinkId")  //同一个url可能有多个属性，最终转换的时候为了区分用id判断
    static public let attributedStringSpecialKey = NSAttributedString.Key(rawValue: "special")
    static public let attributedStringStyleKey = NSAttributedString.Key("SheetInputStyle")
    
    public weak var delegate: SheetInputViewDelegate?
    public weak var uiDelegate: SheetInputViewUIDelegate?

    public var sheetDocsInfo: DocsInfo? //适配SyncBlock，如果有sheet独立block DocsInfo优先使用
    public var docsInfo: DocsInfo? {
        if sheetDocsInfo != nil {
            return sheetDocsInfo
        }
        return delegate?.browserVC?.docsInfo
    }
    
    let keyboardLayoutGuideFG = UserScopeNoChangeFG.LJW.sheetInputViewFix
    public private(set) var keyboardLayoutGuideEnable = false
    
    var browserStatusBarHeight: CGFloat {
        guard let dbvc = delegate?.browserVC else { return 0 }
        return dbvc.statusBar.bounds.height
    }

    var fullInputFieldMinY: CGFloat {
        var height = browserStatusBarHeight
        if !keyboardLayoutGuideEnable {
            height += primaryBrowserViewDistanceToWindowTop
        }
        return height
    }

    var primaryBrowserViewDistanceToWindowTop: CGFloat {
        guard let dbvc = delegate?.browserVC else { return 0 }
        return dbvc.browserViewDistanceToWindowTop
    }

    /// 插入 @ 时是用键盘还是按钮
    var atSource: AtSource?
    private var isShowingAt: Bool {
        if let at = currentAtListView() {
            return subviews.contains(at)
        } else { return false }
    }
    private var lastTextViewSelectedRange: NSRange = NSRange(location: 0, length: 0)
    var atContext: (str: String, location: Int)? {
        didSet {
            // 3.29 fix：使用键盘输入@没有弹出@功能的联想面板问题
            var keyword = atContext?.str
            if let str = atContext?.str, str == "@" {
                keyword = ""
            }
            
            if let first = keyword?.first, first == "@" {
                keyword?.removeFirst()
            }
            refreshAtView(with: keyword)
        }
    }

    private(set) var mode: SheetInputMode = .basic
    private(set) var currentInputHeight: CGFloat = LayoutInfo.basicInputHeight
    private let source: SheetInputSource
    
    public enum SheetInputSource {
        case docs
        case sheet
    }

    public init(bottomSafeAreaHeight: CGFloat?, from source: SheetInputSource) {
        self.bottomSafeAreaHeight = bottomSafeAreaHeight ?? .zero
        self.source = source
        self.keyboardLayoutGuideEnable = source == .sheet && keyboardLayoutGuideFG
        super.init(frame: .zero)
        self.backgroundColor = .clear
        addSubview(contentView)
        contentView.addSubview(inputTextView)
        contentView.addSubview(expandButton)
        contentView.addSubview(narrowButton)
        contentView.addSubview(bottomSeparateLine)

        buttonContainer.addSubview(atButton)
        buttonContainer.addSubview(newlineButton)
        contentView.addSubview(buttonContainer)


        addSubview(safeAreaButtomMask)
        safeAreaButtomMask.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.snp.bottom)
            //iOS15.1系统外接键盘时的悬浮小键盘后面没有遮罩
            //需要加高safeAreaButtomMask的高度，避免后面的内容被透出来
            make.height.equalTo(74)
        }

        inputTextView.delegate = self
        configureTextView(for: mode)
        updateContentView(for: mode)
        self.inputTextView.textContainerInset = UIEdgeInsets.zero
        makeConstraints()
        if !keyboardLayoutGuideEnable {
            self.keyboard = Keyboard(listenTo: nil, trigger: DocsKeyboardTrigger.sheetEditor.rawValue)
        }
        // 警告：不要随意修改下面的监听事件数组，若修改请在 iPad 上彻查以下情况：
        // 1. 点击虚拟键盘右下角的收起按钮，工具栏是否收起（此乃巨坑）
        // 2. 从完整键盘双指捏合进入浮动键盘模式，工具栏位置是否正确
        // 3. 从浮动键盘双指展开进入完整键盘模式，工具栏位置是否正确
        // ...
        keyboard?.on(events: [.willShow, // 键盘起来
                              .didChangeFrame, // 浮动键盘位置变化
                              .willHide] // 虚拟键盘收起按钮
        ) { [weak self] (options) in
            let isFocus = self?.inputTextView.isFirstResponder ?? false
            if isFocus || options.event == .willHide {
                DocsLogger.info("sheetInput Keyboard:\(options), isFocus:\(isFocus)", component: LogComponents.toolbar)
                self?.performActionWhenKeyboard(didTrigger: options.event, options: options)
            }
        }
        keyboard?.start()
        // 切换键盘逻辑的处理在 SheetShowInputService.switchKeyboardView(_ keyboardView: UIView?, listenNotify: Bool) 中
    }

    public override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        expandButton.docs.removeAllPointer()
        expandButton.docs.addHighlight(with: UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10), radius: 8)
        narrowButton.docs.removeAllPointer()
        narrowButton.docs.addHighlight(with: UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10), radius: 8)
        newlineButton.docs.removeAllPointer()
        newlineButton.docs.addHighlight(with: UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10), radius: 8)
        atButton.docs.removeAllPointer()
        atButton.docs.addHighlight(with: UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10), radius: 8)
    }

    deinit {
        keyboard?.stop()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Internal Supporting Method
extension SheetInputView {
    // MARK: - Constraints
    private func makeConstraints() {
        //初始化的时候按照basic模式进行布局
        contentView.snp.makeConstraints { (make) in
            make.leading.trailing.top.bottom.equalToSuperview()
        }
        bottomSeparateLine.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-LayoutInfo.toolbarHeight)
            make.height.equalTo(0.5)
        }
        expandButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(LayoutInfo.buttonHeight)
            make.bottom.equalToSuperview().offset(-(LayoutInfo.buttonBottomPadding + LayoutInfo.toolbarHeight))
            make.trailing.equalToSuperview().offset(-LayoutInfo.buttonLeftPadding)
        }

        narrowButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(LayoutInfo.buttonHeight)
            make.top.equalToSuperview().offset(LayoutInfo.buttonBottomPadding)
            make.trailing.equalToSuperview().offset(-LayoutInfo.buttonLeftPadding)
        }

        expandButton.alpha = 0.0
        narrowButton.alpha = 0.0

        buttonContainer.snp.makeConstraints { (make) in
            make.width.equalTo(100)
            make.height.equalTo(LayoutInfo.buttonHeight)
            make.bottom.equalToSuperview().offset(-(LayoutInfo.buttonBottomPadding + LayoutInfo.toolbarHeight))
            make.trailing.equalToSuperview()
        }

        atButton.snp.makeConstraints { (make) in
            make.height.width.equalTo(LayoutInfo.buttonHeight)
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(LayoutInfo.buttonLeftPadding)
        }

        newlineButton.snp.makeConstraints { (make) in
            make.height.width.equalTo(LayoutInfo.buttonHeight)
            make.top.equalToSuperview()
            make.trailing.equalToSuperview().offset(-LayoutInfo.buttonLeftPadding)
        }

        inputTextView.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(LayoutInfo.txtLeftPadding)
            make.trailing.equalToSuperview().offset(-LayoutInfo.baseInputRightPadding)
            make.top.equalToSuperview().offset(LayoutInfo.txtTopPadding)
            make.height.equalTo(LayoutInfo.basicInputHeight)
        }
    }

    /// 点击结束编辑时的行为
    public func onEndEditing(byUser: Bool) {
        UIView.performWithoutAnimation { inputView = nil }
        if byUser {
            hideKeyboard()
            callJSForTextChanged(text: inputTextView.attributedText, editState: .endSheetEdit)
        } else {
            endEdit()
        }
    }

    /// 当Sheet输入框隐藏时(进入其他面板也属于隐藏)，通知前端
    func onKeyboardHide() {
        hideAtView()
    }

    func resetCurrentInputHeight() {
        currentInputHeight = LayoutInfo.basicInputHeight
    }

    // MARK: Internal Interface
    private func configureTextView(for mode: SheetInputMode) {
        switch mode {
        case .multi, .full:
            inputTextView.showsVerticalScrollIndicator = true
        case .basic:
            inputTextView.showsVerticalScrollIndicator = false
        }
    }

    func currentAtListView() -> AtListView? {
        if let view = atListView { return view }
        let newAt = makeAtView()
        atListView = newAt
        return atListView
    }

    func updateConstraintFor(_ mode: SheetInputMode) {
        switch mode {
        case .basic:
            remakeBasicModeLayout()
            backgroundColor = .clear
        case .multi:
            remakeMultiModeLayout()
            backgroundColor = .clear
        case .full:
            remakeFullModeLayout()
            backgroundColor = UDColor.bgMask
        }
    }

    func enterFullAtMode() {
        guard self.mode == .full else { return }
        currentInputHeight += LayoutInfo.baseFxHeight
        currentInputHeight += AtListView.shadowHeight
        currentInputHeight -= currentAtListHeight()
        currentInputHeight -= 5 //跟阴影重叠，减去一些
        if currentInputHeight < LayoutInfo.basicInputHeight {
            currentInputHeight = LayoutInfo.basicInputHeight
        }
        changeTo(.full, animated: false)
    }

    func exitFullAtMode() {
        guard self.mode == .full else { return }
        reCalcInputHeightAtFullMode()
        changeTo(.full, animated: false)
    }

    public func hideAtButton() {
        atButton.isHidden = true
    }

    public func disableNewline(_ shouldDisable: Bool) {
        newlineButton.isEnabled = !shouldDisable
    }

    private func updateContentView(for mode: SheetInputMode) {
        switch mode {
        case .basic, .multi:
            contentView.layer.cornerRadius = 0
        case .full:
            contentView.layer.cornerRadius = 6
            contentView.layer.maskedCorners = .top
        }
    }

    /// 收到系统键盘事件，通知前端视窗尺寸更新
    private func performActionWhenKeyboard(didTrigger event: Keyboard.KeyboardEvent, options: Keyboard.KeyboardOptions) {
        guard let window = self.window else { return }
        let additionalAccessoryHeight = inputTextView.inputAccessoryView?.frame.height ?? 0
        let oldKeyboardY = self.currentKeyboardY
        let realKeyboardMinY = options.fixedEndFrameForSheet.minY
        self.currentKeyboardY = min(realKeyboardMinY + additionalAccessoryHeight, window.bounds.height - bottomSafeAreaHeight)
        DocsLogger.info("sheetInput KeyboardChange: minY:\(realKeyboardMinY), currentKeyboardY:\(self.currentKeyboardY)")
        
        uiDelegate?.inputViewReceive(event, options: options)
        let hasChange = options.beginFrame != options.fixedEndFrameForSheet || oldKeyboardY != self.currentKeyboardY
        if mode == .full && hasChange {
            reCalcInputHeightAtFullMode()
            let animationCurve = UIView.AnimationOptions(rawValue: UInt(options.animationCurve.rawValue))
            UIView.animate(withDuration: options.animationDuration, delay: 0, options: animationCurve, animations: {
                self.hideAtView()
                self.layoutIfNeeded()
            }, completion: { [weak self] (_) in
                self?.changeTo(.full, animated: true)
            })
        } else {
            self.relayoutAtView()
        }
    }
    
    public func performActionWhenKeyboard(isShow: Bool, keyboardHeight: CGFloat, options: Keyboard.KeyboardOptions) {
        guard let superview = self.superview else { return }
        let oldKeyboardY = self.currentKeyboardY
        self.currentKeyboardY = superview.bounds.height - keyboardHeight
        let hasChange = oldKeyboardY != self.currentKeyboardY
        if mode == .full && hasChange {
            reCalcInputHeightAtFullMode()
            let animationCurve = UIView.AnimationOptions(rawValue: UInt(options.animationCurve.rawValue))
            UIView.animate(withDuration: options.animationDuration, delay: 0, options: animationCurve, animations: {
                self.layoutIfNeeded()
            }, completion: { [weak self] (_) in
                self?.changeTo(.full, animated: true)
            })
        } else {
            self.relayoutAtView()
        }
    }

    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if #available(iOS 13.4, *) {
            if event?.type == .hover || event == nil {
                // iPad 外接键盘触控板上的接触、移动会导致频繁调用到这里，event?.type 是 hover 的类型。
                // 这种情况下不应该有 at 面板的控制逻辑，直接返回系统默认实现就好。
                // 如果后面要对 hover event 做特殊处理，则写在这个控制块中。
                return super.hitTest(point, with: event)
            }
        }
        let pointInAt = self.convert(point, to: currentAtListView())
        if let view = currentAtListView()?.hitTest(pointInAt, with: event), isShowingAt {
            return view
        }
        let needUpdate = (isShowingAt) && (mode == .full)
        hideAtView()
        if needUpdate {
            updateConstraintFor(.full)
        }
        let pointInContentView = self.convert(point, to: self.contentView)
        return self.contentView.hitTest(pointInContentView, with: event)
    }

    // MARK: - inner actions
    @objc
    private func hideKeyboard() {
        inputTextView.resignFirstResponder()
        delegate?.doStatisticsForAction(enumEvent: .sheetEditAction, extraParameters: [.sheetEditAction: .clickHideKeyboard])
    }

    /// 进入全屏模式
    @objc
    private func enterFullMode() {
        guard self.mode != .full else { return }
        self.mode = .full
        reCalcInputHeightAtFullMode()
        delegate?.doStatisticsForAction(enumEvent: .sheetEditAction, extraParameters: [.fullScreenAction: .clickExpand])
        changeTo(.full, animated: true)
        if keyboardInfo.mainKeyboard == .systemText {
            resetReturnKeyTypeIfNeed(willMode: .full)
        }
        //统计
        let params: [String: String] = ["action": "enter_cell_expand", "mode": "cell_expand"]
        delegate?.logEditMode(infos: params)
        delegate?.enterFullMode()
    }

    public func resetReturnKeyTypeIfNeed(willMode: SheetInputMode?) {
        let nextMode = willMode ?? self.mode
        let returnType: UIReturnKeyType = (nextMode == .full) ? .default : .next
        if inputTextView.returnKeyType == returnType { return }
        ignoreInputViewResign = true
        let oldRange = inputTextView.selectedRange
        let fake = makeFakeInputViewWithReturnKeyType(returnType)
        contentView.addSubview(fake)
        fake.becomeFirstResponder()
        fake.reloadInputViews()

        inputTextView.returnKeyType = returnType
        inputTextView.becomeFirstResponder()
        inputTextView.scrollRangeToVisible(oldRange)
        inputTextView.reloadInputViews()
        fake.resignFirstResponder()
        fake.removeFromSuperview()
        ignoreInputViewResign = false

        if inputTextView.inputView is SheetDateTimeKeyboardView ||
            inputTextView.inputView is AssetPickerSuiteView {
            disableNewline(true)
        } else {
            disableNewline(false)
        }

        //统计
        let params: [String: String] = ["action": "enter_cell_expand", "mode": "cell_expand"]
        delegate?.logEditMode(infos: params)
    }

    private func makeFakeInputViewWithReturnKeyType(_ type: UIReturnKeyType) -> UITextView {
        let view = UITextView()
        view.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        view.alpha = 0.0
        view.returnKeyType = type
        return view
    }

    /// 退出全屏模式
    @objc
    private func exitFullMode() {
        let newModeInfo = dynamicCalcuInputMode()
        self.mode = newModeInfo.mode
        currentInputHeight = newModeInfo.height
        changeTo(newModeInfo.mode, animated: true)
        if keyboardInfo.mainKeyboard == .systemText {
            resetReturnKeyTypeIfNeed(willMode: newModeInfo.mode)
        }
        //统计
        let params: [String: String] = ["action": "enter_cell_expand", "mode": "full_screen"]
        delegate?.logEditMode(infos: params)
        delegate?.exitFullMode()
    }

    private func reCalcInputHeightAtFullMode() {
        currentInputHeight = self.currentKeyboardY - fullInputFieldMinY
        currentInputHeight -= LayoutInfo.fullInputTopPadding
        currentInputHeight -= LayoutInfo.baseFxHeight
        if !fullModeHideToolBar {
            currentInputHeight -= LayoutInfo.buttonBottomPadding * 2
            currentInputHeight -= LayoutInfo.buttonHeight
        }
    }

    @objc
    public func atButtonAction() {
        // insert @
        let location = AtInfo.insertAt(for: inputTextView, attri: self.inputTextView.typingAttributes)
        callJSForTextChanged(text: inputTextView.attributedText, editState: .editing)
        currentAttText = NSMutableAttributedString(attributedString: inputTextView.attributedText)
        currentText = inputTextView.attributedText.string
        // at view
        showAtView()
        atContext = ("", location)
        modifyNonFullModeIfNeed()
    }

    @objc
    func newlineButtonAction() {
        addTextAtDefaultRange(txt: "\n")
        //统计
        var pMode = "default"
        if mode == .full { pMode = "cell_expand" }
        let params: [String: String] = ["action": "line_feed", "mode": pMode]
        delegate?.logEditMode(infos: params)
    }

/*
    private func transferPureTextToAttribute(pureText: String) -> NSMutableAttributedString {
        return AtInfo.translateAtFormat(from: pureText, font: 16.0, textColor: UDColor.textTitle, lineBreakMode: .byWordWrapping)
    }
*/

    private func markedTextRange() -> NSRange? {
        let beginPoz = inputTextView.beginningOfDocument
        let range = inputTextView.markedTextRange
        if let start = range?.start, let end = range?.end {
            let location = inputTextView.offset(from: beginPoz, to: start)
            let length = inputTextView.offset(from: start, to: end)
            return NSRange(location: location, length: length)
        }

        return nil
    }
}

// MARK: Interface functions
extension SheetInputView {
    public func beginEditWith(_ text: NSMutableAttributedString?) {
        if let realText = text,
           realText.isEqual(to: inputTextView.attributedText),
           !realText.string.elementsEqual("") {
            self.inputTextView.becomeFirstResponder()
            return
        }
        currentText = text?.string ?? ""
        currentAttText = text ?? NSMutableAttributedString()
        
        if inputTextView.attributedText != currentAttText {
            inputTextView.attributedText = currentAttText
        }
        
        if currentAttText.string.isEmpty {
            resetTypingAttributes() //如果文本为空需要重置一下typing样式
        }
        
        modifyNonFullModeIfNeed()
        self.inputTextView.becomeFirstResponder()
        
        if SKDisplay.isInSplitScreen,
           !self.inputTextView.isHidden,
           self.inputTextView.window?.isHidden == false
        {
            //分屏时左右A、B两个scenes，在A scene文档进行输入时双击B scene单元格调用becomeFirstResponder不会生效，没有焦点和键盘
            //原因此时B scene的window还不是keyWindow
            self.inputTextView.window?.makeKeyAndVisible()
            DispatchQueue.main.async {
                self.inputTextView.becomeFirstResponder()
            }
        }
    }

    public func endEdit() {
        mode = .basic
        inputTextView.resignFirstResponder()
        hideAtView()
        editCellID = nil
        OnboardingManager.shared.targetView(for: [.sheetToolbarIntro, .sheetCardModeToolbar], updatedExistence: false)
    }

    public func cleanText() {
        currentText = ""
        currentAttText = NSMutableAttributedString()
        inputTextView.attributedText = currentAttText
        mode = .basic
        changeTo(.basic, animated: false)
    }

    func contentShowTopShadow(show: Bool) {
        contentView.clipsToBounds = !show
        contentView.layer.masksToBounds = !show
    }
    
    func addTextAtDefaultRange(txt: String) {
        currentAttText = NSMutableAttributedString(attributedString: inputTextView.attributedText)
        let range = inputTextView.selectedRange
        var newLineAttTxt = SheetFieldDataConvert.convertFromStyleAndText(style: cellStyle ?? SheetStyleJSON(), text: txt, isSpecial: false)  //换行跟随单元格样式
        if txt != "\n" && !currentAttText.string.isEmpty {
            let attr = getAttributesFromLocation(from: range.location)//正常在后面插入文本（注释的注释：不一定是在后面插入文本，也可能在中间，所以应该获取selectedRange处的富文本属性）
            newLineAttTxt = NSMutableAttributedString(string: txt, attributes: attr)
        }
        if range.length > 0 {
            currentAttText.replaceCharacters(in: range, with: newLineAttTxt) //有选区则替换文本
        } else {
            currentAttText.insert(newLineAttTxt, at: range.location)
        }
        let newRange = NSRange(location: range.location + txt.count, length: 0)
        inputTextView.attributedText = currentAttText
        inputTextView.selectedRange = newRange
        inputTextView.scrollRangeToVisible(newRange)
        updateAtContextIfNeed()
        modifyNonFullModeIfNeed()
        callJSForTextChanged(text: inputTextView.attributedText, editState: .editing)
        currentText = currentAttText.string
    }
}
//.AppleColorEmojiUI
private let emojiFont = "LkFwcGxlQ29sb3JFbW9qaVVJ".fromBase64()
extension SheetInputView: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        spaceAssert(textView == inputTextView)
        if let last = textView.text.last, last == "@" {
            if let range = textView.text.range(of: "@", options: .backwards) {
                let location = textView.text.distance(from: textView.text.startIndex, to: range.lowerBound)
                atContext = ("", location + 1)
            }
        }
        handleTextViewChanged(textView)
        currentAttText = NSMutableAttributedString(attributedString: textView.attributedText)
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        guard let attributedString = textView.attributedText else {
            return
        }
        let currentRange = textView.selectedRange
        if lastTextViewSelectedRange.location == currentRange.location { // 相同位置不做处理
            return
        }
        attributedString.enumerateAttribute(AtInfo.attributedStringAtInfoKey, in: NSRange(location: 0, length: attributedString.length), options: .reverse) { (attrs, atRange, _) in
            if currentRange.location >= atRange.location + atRange.length || currentRange.location <= atRange.location || attrs == nil { // 不在范围不做处理
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
    
    @available(iOS 16.0, *)
    public func textView(_ textView: UITextView, editMenuForTextIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
        
        var hasUrl = false
        if range.location < self.attributedText.length, let url =  self.attributedText.attribute(AtInfo.attributedStringURLKey, at: range.location, effectiveRange: nil) as? URL {
            debugPrint("editMenuForTextInUrl:\(url.absoluteString)")
            hasUrl = true
        }
        let ignoreIds = [UIMenu.Identifier.lookup, UIMenu.Identifier.share]
        var newActions = suggestedActions.filter { item in
            if let menu = item as? UIMenu {
                if ignoreIds.contains(menu.identifier)  {
                    return false
                }
            }
            return true
        }
        if hasUrl {
            //替换成自定义的打开链接
            let title = BundleI18n.SKResource.Bitable_Form_OpenLinkMobileVer
            let command = UICommand(title: title, action: #selector(onOpenUrl))
            newActions.append(command)
        }
        debugPrint("sheet actions: \(suggestedActions.count), \(newActions.count)....")
        return UIMenu(children: newActions)
    }
    
    @objc
    private func onOpenUrl() {
        guard self.inputTextView.selectedRange.length > 0,
              self.inputTextView.selectedRange.location < self.attributedText.length,
              let url =  self.attributedText.attribute(AtInfo.attributedStringURLKey, at: self.inputTextView.selectedRange.location, effectiveRange: nil) as? URL,
              let modifiedUrl = url.docs.avoidNoDefaultScheme else {
            return
        }
        DocsLogger.info("sheet onOpenUrl:\(modifiedUrl.absoluteString.encryptToShort)")
        self.delegate?.inputView(self, open: modifiedUrl)
    }
    
    private func resetTypingAttributes() {
        if let newAttrs = cellAttributes {
            self.inputTextView.typingAttributes = newAttrs
            DocsLogger.info("sheetInput resetTypingAttributes")
        }
    }
    
    private func getAttributesFromOneSide(from attrs: [NSAttributedString.Key: Any]?) -> [NSAttributedString.Key: Any] {
        var typingAttrs = [NSAttributedString.Key: Any]()
        if let attrs = attrs {
            if attrs[SheetInputView.attributedStringSpecialKey] != nil {
                let seg = attrs[SheetInputView.attributedStringSegmentKey] as? SheetSegmentBase ?? SheetSegmentBase()
                // 取不到seg的style说明是附件类型，直接取cell的格式
                if let style = seg.style {
                    typingAttrs = SheetFieldDataConvert.convertFromStyleToAttributes(from: style, isSpecial: false)
                } else {
                    typingAttrs = SheetFieldDataConvert.convertFromStyleToAttributes(from: cellStyle ?? SheetStyleJSON(), isSpecial: false)
                }
            } else {
                typingAttrs = attrs
            }
        }
        
        return typingAttrs
    }
    
    private func getTypingAttributes(fromLeft leftAttrs: [NSAttributedString.Key: Any]?, fromRight rightAttrs: [NSAttributedString.Key: Any]?) -> [NSAttributedString.Key: Any] {
        var typingAttrs = [NSAttributedString.Key: Any]()
        
        if leftAttrs == nil && rightAttrs == nil {
            typingAttrs = SheetFieldDataConvert.convertFromStyleToAttributes(from: cellStyle ?? SheetStyleJSON(), isSpecial: false)   //左右两边没有样式 默认单元格
        } else if leftAttrs == nil {
            typingAttrs = getAttributesFromOneSide(from: rightAttrs)    //左边没有样式 跟随右边
        } else if rightAttrs == nil {
            typingAttrs = getAttributesFromOneSide(from: leftAttrs)     //右边没有样式 跟随左边
        } else if let left = leftAttrs, left[SheetInputView.attributedStringSegmentKey] as? SheetHyperLinkSegment != nil,
                    let right = rightAttrs, right[SheetInputView.attributedStringSegmentKey] as? SheetHyperLinkSegment != nil {
            typingAttrs = left     //处于url中间 需要保留segment
        } else {
            typingAttrs = getAttributesFromOneSide(from: leftAttrs)     //左右都有样式 默认跟随左边
        }
        
        return typingAttrs
    }
    
    private func getAttributesFromLocation(from index: Int) -> [NSAttributedString.Key: Any] {
        let length = inputTextView.attributedText.length
        var leftAttrs: [NSAttributedString.Key: Any]?
        var rightAttrs: [NSAttributedString.Key: Any]?
       
        if index - 1 >= 0 {
            leftAttrs = inputTextView.attributedText.attributes(at: index - 1, effectiveRange: nil)
            if (leftAttrs?[.font] as? UIFont)?.fontName == emojiFont {
                //UITextView键入emoji后系统会自动为其设置默认的emoji字体，后续输入的文字或数字不应跟随这个样式
                //Meego:https://meego.feishu.cn/larksuite/issue/detail/9849447
                //https://stackoverflow.com/questions/36899193/nstextstorage-subclass-cant-handle-emoji-characters-and-changes-font-in-some-ca/39456258#39456258
                leftAttrs = SheetFieldDataConvert.convertFromStyleToAttributes(from: cellStyle ?? SheetStyleJSON(), isSpecial: false)
            }
        }
        if length > index && index >= 0 {
            rightAttrs = inputTextView.attributedText.attributes(at: index, effectiveRange: nil)
            if (rightAttrs?[.font] as? UIFont)?.fontName == emojiFont {
                rightAttrs = SheetFieldDataConvert.convertFromStyleToAttributes(from: cellStyle ?? SheetStyleJSON(), isSpecial: false)
            }
        }
        
        return getTypingAttributes(fromLeft: leftAttrs, fromRight: rightAttrs)
    }
    
    private func urlTextChange(index: Int, currentId: UInt64) {
        //url编辑的时候需要判断编辑后是否仍是合法链接 若合法更新link 否则保存旧值
        var leftPointer = index - 1
        var rightPointer = index
        var leftAttrs = [NSAttributedString.Key: Any]()
        var rightAttrs = [NSAttributedString.Key: Any]()
        var isLeftValid = true
        var isRightValid = true
        var isFinished = false
        var totalURL = ""
        let str = inputTextView.attributedText.string
        
        if inputTextView.attributedText.length != str.count {
            return //不处理中间插入表情 每插入一个表情length比count多1 遍历时数组越界
        }
        
        if leftPointer < 0 || leftPointer >= str.count {
            isLeftValid = false
        }
        if rightPointer >= str.count || rightPointer < 0 {
            isRightValid = false
        }
        
        if isLeftValid {
            leftAttrs = inputTextView.attributedText.attributes(at: leftPointer, effectiveRange: nil)
        }
        if isRightValid {
            rightAttrs = inputTextView.attributedText.attributes(at: rightPointer, effectiveRange: nil)
        }
        
        //从当前光标位置向前/后遍历 一直到linkId不同/不是urlSeg为止 得到全部url
        while !isFinished {
            if !isLeftValid
                || leftAttrs[SheetInputView.attributedStringSegmentKey] as? SheetHyperLinkSegment == nil
                || (leftAttrs[SheetInputView.attributedStringHyperLinkIdKey] as? UInt64) != currentId {
                isLeftValid = false
            }
            if !isRightValid
                || rightAttrs[SheetInputView.attributedStringSegmentKey] as? SheetHyperLinkSegment == nil
                || (rightAttrs[SheetInputView.attributedStringHyperLinkIdKey] as? UInt64) != currentId {
                isRightValid = false
            }   //判断双指针左右两边是否是相同的hyperlink
            
            if isLeftValid {
                let currentChar = str[str.index(str.startIndex, offsetBy: leftPointer)]
                totalURL.insert(currentChar, at: totalURL.startIndex)
                leftPointer -= 1
            }
            if isRightValid {
                let currentChar = str[str.index(str.startIndex, offsetBy: rightPointer)]
                totalURL.insert(currentChar, at: totalURL.endIndex)
                rightPointer += 1
            }
            if leftPointer < 0 || leftPointer >= str.count {
                isLeftValid = false
            }
            if rightPointer >= str.count || rightPointer < 0 {
                isRightValid = false
            }   //指针越界，遍历已经完成
            if isLeftValid {
                leftAttrs = inputTextView.attributedText.attributes(at: leftPointer, effectiveRange: nil)
            }
            if isRightValid {
                rightAttrs = inputTextView.attributedText.attributes(at: rightPointer, effectiveRange: nil)
            }
            if !isLeftValid && !isRightValid {
                isFinished = true
            }
        }
        let ranges = totalURL.docs.regularUrlRanges
        if ranges.count == 1 {
            let segmentVal = inputTextView.attributedText.attributes(at: leftPointer + 1, effectiveRange: nil)[SheetInputView.attributedStringSegmentKey] as? SheetHyperLinkSegment
            segmentVal?.link = totalURL
            let att = NSMutableAttributedString(attributedString: inputTextView.attributedText)
            let range = NSRange(location: leftPointer + 1, length: totalURL.count)
            att.removeAttribute(SheetInputView.attributedStringSegmentKey, range: range)
            att.removeAttribute(AtInfo.attributedStringURLKey, range: range)
            att.removeAttribute(.link, range: range)
            att.addAttribute(SheetInputView.attributedStringSegmentKey, value: segmentVal ?? SheetHyperLinkSegment(), range: range)
            att.addAttribute(AtInfo.attributedStringURLKey, value: URL(string: totalURL) as Any, range: range)
            att.addAttribute(.link, value: totalURL, range: range)
            let originalRange = inputTextView.selectedRange
            inputTextView.attributedText = att
            inputTextView.selectedRange = originalRange
        }   //text是合法的url链接，更新link
        
        inputTextView.selectedRange = lastTextViewSelectedRange
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        spaceAssert(textView == inputTextView)
        inputTextView.typingAttributes = getAttributesFromLocation(from: range.location)
        // delete
        if text.isEmpty && range.length != 0 {
            // 删除【@人名】时，把【@人名】整个删除
            let deleteSpecial = AtInfo.removeAtString(from: textView)
            currentAttText = NSMutableAttributedString(attributedString: inputTextView.attributedText)
            if let range = markedTextRange() {
                currentAttText.replaceCharacters(in: range, with: "")
            }
            currentText = currentAttText.string
            callJSForTextChanged(text: currentAttText, editState: .editing)
            if deleteSpecial {
                return false
            }
        }
        // insert
        if text.hasSuffix("@") {
            // 3.31bugfix 在九宫格模式下，点击三次才输入@，range.location有问题，改成在textViewDidChange里面重新设置atContext
            atContext = ("x", range.location + text.count )
            showAtView(from: .input)
        } else if let context = atContext, range.location <= context.location - 1 {
            hideAtView()
            exitFullAtMode()
            atContext = nil
        }

        guard text == "\n" else {
            return true
        }
        textView.typingAttributes = SheetFieldDataConvert.convertFromStyleToAttributes(from: cellStyle ?? SheetStyleJSON(), isSpecial: false)   //当换行的时候默认单元格整体样式
        uiDelegate?.inputViewGoDownItemInSystemKeyboard(self)
        switch mode {
        case .basic, .multi:
            callJSForTextChanged(text: textView.attributedText, editState: .endCellEdit)
            let params: [String: String] = ["action": "next_row", "mode": "full_screen"]
            delegate?.logEditMode(infos: params)
            return false
        case .full:
            delegate?.doStatisticsForAction(enumEvent: .sheetEditAction, extraParameters: [.fullScreenAction: .clickNewLine])
            let params: [String: String] = ["action": "line_feed", "mode": "cell_expand"]
            delegate?.logEditMode(infos: params)
            return true
        }
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        guard ignoreInputViewResign == false else { return }
        if mode == .basic || mode == .multi {
            self.delegate?.hideInputView(self)
        }
        currentText = ""
        currentAttText = NSMutableAttributedString()
    }

}

extension SheetInputView {
    public func handleTextViewChanged(_ textView: UITextView) {
        //过滤掉还没真正输入的字符
        
        currentAttText = NSMutableAttributedString(attributedString: inputTextView.attributedText)
        if let markedTextRange = markedTextRange() {
            currentAttText.replaceCharacters(in: markedTextRange, with: "")
        }
        let index = inputTextView.selectedRange.location
        if index > 0 {
            let attrs = inputTextView.attributedText.attributes(at: index - 1, effectiveRange: nil)
            if attrs[SheetInputView.attributedStringSegmentKey] as? SheetHyperLinkSegment != nil {
                urlTextChange(index: inputTextView.selectedRange.location, currentId: attrs[SheetInputView.attributedStringHyperLinkIdKey] as? UInt64 ?? 0)
                currentAttText = NSMutableAttributedString(attributedString: inputTextView.attributedText)
                callJSForTextChanged(text: currentAttText, editState: .editing)
            }
        }   //在url中间进行编辑，判断url合法性并更新link
        // 如果在url开头进行删除 判断右边的属性
        updateAtContextIfNeed()
        
        //把NSTextAttachment已经转化成回车的string传给前端
        if !inputTextView.attributedText.string.elementsEqual(currentText) {
            currentText = inputTextView.attributedText.string
            callJSForTextChanged(text: inputTextView.attributedText, editState: .editing)
        }
        modifyNonFullModeIfNeed()
    }
    
//    private func convertToPanoSegment(from attText: NSAttributedString, range: NSRange) -> SheetPanoSegment {
//        let index = range.location
//        let attributes = attText.attributes(at: index, effectiveRange: nil)
//        let panoSegment = attributes[SheetInputView.attributedStringSegmentKey] as? SheetPanoSegment ?? SheetPanoSegment()
//        panoSegment.text = attText.attributedSubstring(from: range).string
//        
//        return panoSegment
//    }
    
    private func convertToURLSegment(from urlStr: String, index: Int) -> [String: Any] {
        let attrs = inputTextView.attributedText.attributes(at: index, effectiveRange: nil)
        let attSegment = attrs[SheetInputView.attributedStringSegmentKey] as? SheetHyperLinkSegment ?? SheetHyperLinkSegment()
        var textsJson: [[String: Any]] = []
        let type = SheetSegmentType(rawValue: "url")
        let style = cellStyle ?? SheetStyleJSON()
        
        var params: [String: Any] = [
            "type": type?.rawValue as Any,
            "text": urlStr,
            "link": attSegment.link ?? "",
            "cellPosition": attSegment.cellPosition?.toJSON() as Any,
            "visited": attSegment.visited ?? false,
            "style": convertFromAttributesToStyle(from: attrs).toJSON() ?? style.toJSON() as Any,
            "texts": textsJson
        ]
        
        inputTextView.attributedText.enumerateAttributes(in: NSRange(location: index, length: urlStr.count), options: []) { _, range, _ in
            let currentTextSeg = convertToTextSegment(from: inputTextView.attributedText, range: range)
            if let textJson = currentTextSeg.toJSON() {
                textsJson.append(textJson)
            }   //根据样式对url划分
        }
        if textsJson.count > 1 {
            params["texts"] = textsJson //如果url有不同属性子段，在texts字段中回传给前端
        }
        
        return params
    }
//    private func convertToAttachSegment(from attText: NSAttributedString, range: NSRange) -> SheetAttachmentSegment {
//        let index = range.location
//        let attributes = attText.attributes(at: index, effectiveRange: nil)
//
//        return attributes[SheetInputView.attributedStringSegmentKey] as? SheetAttachmentSegment ?? SheetAttachmentSegment()
//    }
//
//    private func convertToMentionSegment(from attText: NSAttributedString, range: NSRange) -> SheetMentionSegment {
//        let index = range.location
//        let attributes = attText.attributes(at: index, effectiveRange: nil)
//
//        return attributes[SheetInputView.attributedStringSegmentKey] as? SheetMentionSegment ?? SheetMentionSegment()
//    }
    
    private func convertToTextSegment(from attText: NSAttributedString, range: NSRange) -> SheetTextSegment {
        let textSegment = SheetTextSegment()
        textSegment.text = attText.attributedSubstring(from: range).string
        textSegment.style = convertFromAttributesToStyle(from: attText.attributes(at: range.location, effectiveRange: nil))
        
        return textSegment
    }
    
    private func convertFromAttStringToSegmentArr(from attText: NSAttributedString) -> [[String: Any]]? {
        var segmentArrJSONStr = [[String: Any]]()

        if attText.string.isEmpty && !attributeArray.isEmpty {
            //考虑embed-image 输入文本会消失
            if let image = attributeArray[0] as? SheetEmbedImageSegment, let imageJson = image.toJSON() {
                segmentArrJSONStr.append(imageJson)
            }
            return segmentArrJSONStr
        }
        if attText.string.isEmpty {
            return nil
        }
        
        var mentionRange = NSRange()
        var currentMentionSeg = SheetMentionSegment()
        var currentAtInfo: AtInfo?
        var attachRange = NSRange()
        var currentAttachSeg = SheetAttachmentSegment()
        var panoRange = NSRange()
        var currentPanoSeg = SheetPanoSegment() //同一个mention/attach/pano会分成多个不同attributes的串，遍历的时候要注意合并
        var totalURL = ""
        var leftPointer = 0
        var isURL = false
        var currentHyperLinkId: UInt64 = 0
        
        attText.enumerateAttributes(in: NSRange(location: 0, length: attText.length), options: NSAttributedString.EnumerationOptions(rawValue: 1)) { attrs, range, _ in
            if attrs[AtInfo.attributedStringPanoKey] as? String != nil {
                //处理panoSeg
                isURL = false
                if !totalURL.isEmpty {
                    let urlJson = convertToURLSegment(from: totalURL, index: leftPointer)
                    segmentArrJSONStr.append(urlJson)   //保证顺序，其他segment处理先判断是否有url需要转换
                }
                totalURL = ""
                if attrs[AtInfo.attributedStringAtInfoKeyStart] != nil {
                    panoRange.location = range.location
                    panoRange.length = range.length
                    currentPanoSeg = attrs[SheetInputView.attributedStringSegmentKey] as? SheetPanoSegment ?? SheetPanoSegment()//更新pano起始信息并且拿到当前panoSegment
                } else {
                    let nextIndex = range.location + range.length
                    if nextIndex < attText.length &&
                        attText.attributes(at: nextIndex, effectiveRange: nil)[SheetInputView.attributedStringSegmentKey] as? SheetPanoSegment == currentPanoSeg {
                        panoRange.length += range.length    //更新下标
                    } else {
                        if let panoJson = currentPanoSeg.toJSON() {
                            segmentArrJSONStr.append(panoJson)
                        }
                    }
                }
            } else if attrs[AtInfo.attributedStringAttachmentKey] as? String != nil,
                      attrs[SheetInputView.attributedStringSegmentKey] is SheetAttachmentSegment {
                //处理attachSeg
                isURL = false
                if !totalURL.isEmpty {
                    let urlJson = convertToURLSegment(from: totalURL, index: leftPointer)
                    segmentArrJSONStr.append(urlJson)   //保证顺序，其他segment处理先判断是否有url需要转换
                }
                totalURL = ""
                if attrs[AtInfo.attributedStringAtInfoKeyStart] != nil {
                    attachRange.location = range.location
                    attachRange.length = range.length
                    currentAttachSeg = attrs[SheetInputView.attributedStringSegmentKey] as? SheetAttachmentSegment ?? SheetAttachmentSegment()  //更新attach起始信息
                } else {
                    let nextIndex = range.location + range.length
                    if nextIndex < attText.length &&
                        attText.attributes(at: nextIndex, effectiveRange: nil)[SheetInputView.attributedStringSegmentKey] as? SheetAttachmentSegment == currentAttachSeg {
                        attachRange.length += range.length  //更新下标
                    } else {
                        if let attachJson = currentAttachSeg.toJSON() {
                            segmentArrJSONStr.append(attachJson)
                        }
                    }
                }
            } else if attrs[AtInfo.attributedStringAtInfoKey] != nil {
                //处理mentionSeg
                isURL = false
                if !totalURL.isEmpty {
                    let urlJson = convertToURLSegment(from: totalURL, index: leftPointer)
                    segmentArrJSONStr.append(urlJson)   //保证顺序，其他segment处理先判断是否有url需要转换
                }
                totalURL = ""
                if attrs[AtInfo.attributedStringAtInfoKeyStart] != nil {
                    mentionRange.location = range.location
                    mentionRange.length = 1
                    currentMentionSeg = attrs[SheetInputView.attributedStringSegmentKey] as? SheetMentionSegment ?? SheetMentionSegment() //更新mention起始信息
                    currentAtInfo = attrs[AtInfo.attributedStringAtInfoKey] as? AtInfo
                } else {
                    let nextIndex = range.location + range.length
                    if nextIndex < attText.length &&
                        attText.attributes(at: nextIndex, effectiveRange: nil)[SheetInputView.attributedStringSegmentKey] as? SheetMentionSegment == currentMentionSeg &&
                        attText.attributes(at: nextIndex, effectiveRange: nil)[AtInfo.attributedStringAtInfoKey] as? AtInfo == currentAtInfo {
                        mentionRange.length += range.length //更新下标
                    } else {
                        if let mentionJson = currentMentionSeg.toJSON() {
                            segmentArrJSONStr.append(mentionJson)
                        }
                    }
                }
                
            } else if attrs[SheetInputView.attributedStringHyperLinkIdKey] != nil {
                //更新urlSeg
                if !isURL {
                    leftPointer = range.location
                    currentHyperLinkId = attrs[SheetInputView.attributedStringHyperLinkIdKey] as? UInt64 ?? 0
                    isURL = true
                }   //设置url起始信息
                if isURL {
                    if currentHyperLinkId != attrs[SheetInputView.attributedStringHyperLinkIdKey] as? UInt64 ?? 0 {
                        let urlJson = convertToURLSegment(from: totalURL, index: leftPointer)
                        segmentArrJSONStr.append(urlJson)   //先将当前保存的相同url转换
                        totalURL = ""
                        currentHyperLinkId = attrs[SheetInputView.attributedStringHyperLinkIdKey] as? UInt64 ?? 0
                        totalURL.append(attText.attributedSubstring(from: range).string)
                        leftPointer = range.location    //再更新newSeg的起始信息
                    } else {
                        totalURL.append(attText.attributedSubstring(from: range).string)
                    }
                }   //上一个也是url，分为两种情况（id是否相同）
            } else {
                isURL = false
                if !totalURL.isEmpty {
                    let urlJson = convertToURLSegment(from: totalURL, index: leftPointer)
                    segmentArrJSONStr.append(urlJson)   //保证顺序，其他segment处理先判断是否有url需要转换
                }
                totalURL = ""
                let currentTextSeg = convertToTextSegment(from: attText, range: range)
                if let textJson = currentTextSeg.toJSON() {
                    segmentArrJSONStr.append(textJson)
                }
            }
        }
        
        if !totalURL.isEmpty {
            let urlJson = convertToURLSegment(from: totalURL, index: leftPointer)
            segmentArrJSONStr.append(urlJson)   //保证顺序，其他segment处理先判断是否有url需要转换
        }
        totalURL = ""   //当最后一个segment是url
        
        //注：如果先全部转为segment arr再toJson会出错，因此单独转json再合起来
        
        return segmentArrJSONStr
    }
    
    public func callJSForTextChanged(text: NSAttributedString, editState: SheetEditMode) {
        let segmentArr = convertFromAttStringToSegmentArr(from: text)
        self.delegate?.inputView(self, didChangeInput: segmentArr ?? [], editState: editState, keyboard: keyboardInfo)
        self.uiDelegate?.inputViewIsEditing(self, in: keyboardInfo)
    }

    public func setCaretHidden(_ toHide: Bool) {
        inputTextView.tintColor = toHide ? .clear : caretNormalColor
    }
}

// MARK: - statistics
extension SheetInputView {
    public enum SheetAction: String {
        case clickHideKeyboard = "click_quit_keyboard"
        case clickExpand       = "click_expand_enter_full_screen"
        case clickNewLine      = "switch_row_under_full_screen"
    }

    public enum StatisticParams: String {
        case sheetEditAction  = "sheet_edit_action_type"
        case fullScreenAction = "full_screen_edit_action"
    }
}

// layout相关
extension SheetInputView {

    func modifyNonFullModeIfNeed() {
        //在full模式下只能用户自己切换回 basic、multi模式
        guard self.mode != .full else { return }
        let newModeInfo = dynamicCalcuInputMode()
        if newModeInfo.mode != self.mode || newModeInfo.height != currentInputHeight {
            self.mode = newModeInfo.mode
            currentInputHeight = newModeInfo.height
            changeTo(self.mode, animated: true)
        }
    }

    private func changeTo(_ mode: SheetInputMode, animated: Bool, duration: TimeInterval? = 0.3) {
        uiDelegate?.inputView(self, changeMode: mode)
        uiDelegate?.inputView(self, updateHeight: currentMaxHeight(), layoutNow: false)
        updateConstraintFor(mode)
        let expandHidden = (mode != .multi)
        let narrowHidden = (mode != .full)
        inputTextView.isScrollEnabled = false
        var customDuration: TimeInterval = duration ?? 0.3
        customDuration = animated ? customDuration : 0.0
        UIView.animate(withDuration: customDuration, animations: { [weak self] in
            self?.superview?.layoutIfNeeded()
            self?.layoutIfNeeded()
            self?.expandButton.alpha = expandHidden ? 0.0 : 1.0
            self?.narrowButton.alpha = narrowHidden ? 0.0 : 1.0
            }, completion: { [weak self] (_) in
                self?.updateContentView(for: mode)
                self?.configureTextView(for: mode)
                self?.inputTextView.isScrollEnabled = true
                if let range = self?.inputTextView.selectedRange {
                    self?.inputTextView.scrollRangeToVisible(range)
                }
        })
    }

    private func currentMaxHeight() -> CGFloat {
        var height = LayoutInfo.toolbarHeight
        switch self.mode {
        case .basic:
            height += LayoutInfo.basicInputHeight
            height += (LayoutInfo.txtTopPadding * 2)
        case .multi:
            height += LayoutInfo.multiTxtTopPadding
            height += LayoutInfo.baseFxHeight
            height += currentInputHeight
        case .full:
            height = self.currentKeyboardY - fullInputFieldMinY
        }
        return height
    }

    func currentAtListHeight() -> CGFloat {
        var emptyHeight: CGFloat = self.currentKeyboardY - fullInputFieldMinY
        let defaultHeight: CGFloat = 265
        switch self.mode {
        case .basic, .multi:
            emptyHeight -= currentMaxHeight()
            emptyHeight += AtListView.shadowHeight
            if emptyHeight >= defaultHeight {
                emptyHeight = defaultHeight
            }
        case .full:
            //最少应该给输入留这么多空间
            let stayHeight = LayoutInfo.fullInputTopPadding + LayoutInfo.basicInputHeight
            if (emptyHeight - defaultHeight) > stayHeight {
                emptyHeight = defaultHeight
            } else {
                emptyHeight -= stayHeight
                if emptyHeight < 136 { emptyHeight = 136 }
            }
        }
        return emptyHeight
    }

    private func dynamicCalcuInputMode() -> (mode: SheetInputMode, height: CGFloat) {
        let containerWidth = self.frame.width
        let minHeight = LayoutInfo.basicInputHeight
        let maxHeight = LayoutInfo.maxInputHeight
        let basicWidth = containerWidth - LayoutInfo.txtLeftPadding - LayoutInfo.baseInputRightPadding
        let basicFitSize = CGSize(width: basicWidth, height: CGFloat.greatestFiniteMagnitude)
        let multiWidth = containerWidth - LayoutInfo.txtLeftPadding - LayoutInfo.txtLeftPadding
        let multiFitSize = CGSize(width: multiWidth, height: CGFloat.greatestFiniteMagnitude)

        var fitedSize = inputTextView.sizeThatFits(basicFitSize)
        if fitedSize.height <= minHeight {
            return (.basic, minHeight)
        } else {
            fitedSize = inputTextView.sizeThatFits(multiFitSize)
            var nextHeight = fitedSize.height
            if nextHeight < minHeight {
                nextHeight = minHeight
            }
            return (.multi, min(nextHeight, maxHeight))
        }
    }

    private func remakeBasicModeLayout() {
        inputTextView.snp.remakeConstraints { (make) in
            make.leading.equalToSuperview().offset(LayoutInfo.txtLeftPadding)
            make.trailing.equalToSuperview().offset(-LayoutInfo.baseInputRightPadding)
            make.top.equalToSuperview().offset(LayoutInfo.txtTopPadding)
            make.height.equalTo(LayoutInfo.basicInputHeight)

        }

        buttonContainer.snp.updateConstraints { (make) in
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-(LayoutInfo.buttonBottomPadding + LayoutInfo.toolbarHeight))
        }

        expandButton.snp.updateConstraints { (make) in
            make.bottom.equalToSuperview().offset(-(LayoutInfo.buttonBottomPadding + LayoutInfo.toolbarHeight))
        }

        bottomSeparateLine.snp.updateConstraints { (make) in
            make.bottom.equalToSuperview().offset(-LayoutInfo.toolbarHeight)
        }
    }

    private func remakeMultiModeLayout() {
        inputTextView.snp.updateConstraints { (make) in
            make.leading.equalToSuperview().offset(LayoutInfo.txtLeftPadding)
            make.trailing.equalToSuperview().offset(-LayoutInfo.txtLeftPadding)
            make.top.equalToSuperview().offset(LayoutInfo.multiTxtTopPadding)
            make.height.equalTo(currentInputHeight)
        }

        buttonContainer.snp.updateConstraints { (make) in
            make.trailing.equalToSuperview().offset(-(LayoutInfo.buttonHeight + LayoutInfo.buttonLeftPadding))
            make.bottom.equalToSuperview().offset(-(LayoutInfo.buttonBottomPadding + LayoutInfo.toolbarHeight))
        }

        expandButton.snp.updateConstraints { (make) in
            make.bottom.equalToSuperview().offset(-(LayoutInfo.buttonBottomPadding + LayoutInfo.toolbarHeight))
        }

        bottomSeparateLine.snp.updateConstraints { (make) in
            make.bottom.equalToSuperview().offset(-LayoutInfo.toolbarHeight)
        }
    }

    private func remakeFullModeLayout() {
        // basic模式下的约束
        inputTextView.snp.updateConstraints { (make) in
            make.leading.equalToSuperview().offset(LayoutInfo.txtLeftPadding)
            make.trailing.equalToSuperview().offset(-LayoutInfo.txtLeftPadding)
            make.top.equalToSuperview().offset(LayoutInfo.fullInputTopPadding)
            make.height.equalTo(currentInputHeight)
        }

        let padding = fullModeHideToolBar ? LayoutInfo.buttonBottomPadding : (LayoutInfo.buttonBottomPadding + LayoutInfo.toolbarHeight)
        buttonContainer.snp.updateConstraints { (make) in
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-padding)
        }

        expandButton.snp.updateConstraints { (make) in
            make.bottom.equalToSuperview().offset(-padding)
        }

        let offset: CGFloat = fullModeHideToolBar ? 0.0 : LayoutInfo.toolbarHeight
        bottomSeparateLine.snp.updateConstraints { (make) in
            make.bottom.equalToSuperview().offset(-offset)
        }
    }
}

extension SheetInputView {
    func convertFromAttributesToStyle(from attrs: [NSAttributedString.Key: Any]) -> SheetStyleJSON {
        let styleJSON = SheetStyleJSON()
        if let style = attrs[SheetInputView.attributedStringStyleKey] as? SheetStyleJSON {
            styleJSON.color = style.color
        } else if let color = attrs[.foregroundColor] as? UIColor, let strColor = UIColor.ud.hex(color, withAlphaPrefix: false), attrs[SheetInputView.attributedStringSpecialKey] == nil, attrs[.paragraphStyle] == nil {
            if let showColor = styleJSON.showColor, let showColorStr = UIColor.ud.hex(showColor, withAlphaPrefix: false), showColorStr.lowercased() == strColor.lowercased() {
                // bugfix: 暗黑模式下，foregroundColor 默认色是白色的，不应当把这个默认色提交到文档数据中。因此与默认 showColor 做对比，如果与 showColor 相同，那就保持其默认值就可以了，不需要强制覆盖。https://bytedance.feishu.cn/docx/QWYkd4Stjopr4vxUYW3caQF8nKe
            } else {
                styleJSON.color = strColor.lowercased()
            }
        }
        let font = attrs[.font] as? UIFont
        let descriptor = font?.fontDescriptor

        
        styleJSON.fontWeight = 400
        styleJSON.fontStyle = "normal"
        if let symbolicTraits = descriptor?.symbolicTraits {
            if symbolicTraits.contains(.traitBold) {
                styleJSON.fontWeight = 700
            }
            if symbolicTraits.contains(.traitItalic) {
                styleJSON.fontStyle = "italic"
            }
        }
        
        //UDFont
        if font?.isBold == true {
            styleJSON.fontWeight = 700
        }
        if font?.isItalic == true {
            styleJSON.fontStyle = "italic"
        }
            
        if attrs[SheetInputView.attributedStringFontStyleKey] != nil {
            styleJSON.fontStyle = "italic"
        }
        let style = cellStyle ?? SheetStyleJSON()
        styleJSON.fontSize = attrs[SheetInputView.attributedStringFontSizeKey] as? Double ?? style.fontSize
        styleJSON.fontFamily = attrs[SheetInputView.attributedStringFontFamilyKey] as? String ?? style.fontFamily
        if attrs[.underlineStyle] != nil && attrs[.strikethroughStyle] != nil {
            styleJSON.textDecoration = "line-through underline"
        } else if attrs[.underlineStyle] != nil {
            styleJSON.textDecoration = "underline"
        } else if attrs[.strikethroughStyle] != nil {
            styleJSON.textDecoration = "line-through"
        }
        
        return styleJSON
    }
    private func convertToHyperLinkSegment(from attText: NSAttributedString) -> SheetHyperLinkSegment {
        let hyperLinkSegment = SheetHyperLinkSegment()
        //复制粘贴生成的hyperlinkSegment，此时整个link的属性都相同
        hyperLinkSegment.type = .url
        hyperLinkSegment.text = attText.string
        hyperLinkSegment.link = attText.string  //合法，link属性与text属性相同
        hyperLinkSegment.visited = false
        hyperLinkSegment.style = convertFromAttributesToStyle(from: attText.attributes(at: 0, effectiveRange: nil))
        hyperLinkSegment.cellPosition = nil
        hyperLinkSegment.texts = []
        let textSegment = SheetTextSegment()
        textSegment.style = hyperLinkSegment.style
        textSegment.text = hyperLinkSegment.text
        hyperLinkSegment.texts?.append(textSegment)
        
        return hyperLinkSegment
    }
    
    private func convertToDocMentionSegment(from attText: NSAttributedString, atinfo: AtInfo) -> SheetMentionSegment {
        let mentionSeg = SheetMentionSegment()
        
        mentionSeg.type = .mention
        mentionSeg.blockNotify = nil
        mentionSeg.notNotify = nil
        mentionSeg.notNotify = nil
        mentionSeg.category = "undefined"
        mentionSeg.name = atinfo.name
        mentionSeg.text = atinfo.at
        mentionSeg.enName = atinfo.enName
        mentionSeg.link = attText.string
        mentionSeg.token = atinfo.token
        mentionSeg.mentionType = atinfo.inherentType.rawValue   //转成int
        mentionSeg.icon = nil   //用iconinfo
        mentionSeg.mentionNotify = nil
        mentionSeg.mentionId = ""
        if UserScopeNoChangeFG.HZK.sheetCustomIconPart {
            mentionSeg.iconInfo = atinfo.iconInfoMeta
        }
        
        mentionSeg.style = convertFromAttributesToStyle(from: attText.attributes(at: 0, effectiveRange: nil))
        
        return mentionSeg
    }
    
    private func _doPaste() {
        guard let url = SKPasteboard.string(psdaToken: PSDATokens.Pasteboard.sheet_inputview_do_paste) else { return }
        let index = inputTextView.selectedRange.location    //此时光标处url还没加上
        currentAttText = NSMutableAttributedString(attributedString: inputTextView.attributedText)
        let attributes = index == 0 ? SheetFieldDataConvert.convertFromStyleToAttributes(from: cellStyle ?? SheetStyleJSON(), isSpecial: true) : currentAttText.attributes(at: index - 1, effectiveRange: nil) // 判断粘贴的url跟随的样式
        let attUrl = NSMutableAttributedString(string: url, attributes: attributes)
        attUrl.addAttribute(AtInfo.attributedStringURLKey, value: URL(string: url) as Any, range: NSRange(location: 0, length: attUrl.length))
        //还要加上font的size和family
        
        InternalDocAPI().getAtInfoByURL(url)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] res in
                switch res {
                case .success(let atInfo):
                    guard let inputTextView = self?.inputTextView else { return }
                    let rawUrlBeginPosition = inputTextView.selectedRange.location - attUrl.length
                    //此时url已经加上
                    if atInfo.type == .unknown {
                        //外部链接 转换为linkSeg
                        let hyperLinkSegment = self?.convertToHyperLinkSegment(from: attUrl)
                        attUrl.addAttribute(SheetInputView.attributedStringSegmentKey, value: hyperLinkSegment ?? SheetHyperLinkSegment(), range: NSRange(location: 0, length: attUrl.length))
                        attUrl.addAttribute(SheetInputView.attributedStringSpecialKey, value: "special", range: NSRange(location: 0, length: attUrl.length))
                        self?.replaceStringToAttachment(attUrl, with: atInfo, range: NSRange(location: rawUrlBeginPosition, length: attUrl.length))
                    } else {
                        //内部文档 转换为mentionSeg
                        let mentionSeg = self?.convertToDocMentionSegment(from: attUrl, atinfo: atInfo)
                        attUrl.addAttribute(SheetInputView.attributedStringSegmentKey, value: mentionSeg as Any, range: NSRange(location: 0, length: attUrl.length))
                        attUrl.addAttribute(SheetInputView.attributedStringSpecialKey, value: "special", range: NSRange(location: 0, length: attUrl.length))
                        self?.replaceStringToAttachment(attUrl, with: atInfo, range: NSRange(location: rawUrlBeginPosition, length: attUrl.length))
                        
                    }
                case .failure(let error):
                    DocsLogger.info("sheet pasting: get atInfo by url failure \(error)")
                }
            })
            .disposed(by: self.disposeBag)
        
    }
}
extension SheetInputView: SheetTextViewDelegate {
    public func textViewWillResign(_ textView: SheetTextView) {
        if !keyboardLayoutGuideEnable || ignoreInputViewResign { return }
        uiDelegate?.inputViewWillHide(self)
    }
    public func textViewCanCopy(_ textView: SheetTextView, showTips: Bool) -> Bool {
        guard _canCopy(showTips) else {
            DocsLogger.info("sheetInput has no copy permission")
            return false
        }
        return true
    }
    public func textViewCanCut(_ textView: SheetTextView, showTips: Bool) -> Bool {
        guard _canCopy(showTips) else {
            DocsLogger.info("sheetInput has no cut permission")
            return false
        }
        return true
    }

    public func textViewOnCopy(_ textView: SheetTextView) {
        
    }
    
    private func _canCopy(_ showTips: Bool = false) -> Bool {
        guard UserScopeNoChangeFG.WWJ.permissionSDKEnable else {
            return legacyCheckCanCopy(showTips: showTips)
        }
        guard let docsInfo = self.docsInfo else { return false }
        guard let service = delegate?.browserVC?.editor?.permissionConfig.getPermissionService(for: .referenceDocument(objToken: docsInfo.token)) else { return false }
        let response = service.validate(operation: .copyContent)
        if case let .forbidden(denyType, _) = response.result,
           case let .blockByUserPermission(reason) = denyType {
            switch reason {
            case .blockByServer, .userPermissionNotReady, .unknown, .blockByAudit:
                if let encryptId = ClipboardManager.shared.getEncryptId(token: docsInfo.token), !encryptId.isEmpty {
                    // 非 CAC、DLP 的无复制权限，允许通过单文档复制
                    return true
                }
            case .blockByCAC, .cacheNotSupport:
                break
            }
        }
        if showTips {
            response.didTriggerOperation(controller: affiliatedViewController ?? UIViewController())
        }
        return response.allow
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func legacyCheckCanCopy(showTips: Bool) -> Bool {
        guard let docsInfo = self.docsInfo else { return false }
        if !DocPermissionHelper.checkPermission(.ccmCopy,
                                                docsInfo: docsInfo,
                                                showTips: showTips) {
            DocsLogger.info("admin control, can not copy")
            return false
        }
        // TODO: 权限模型改造 - 需要通过其他方式指明 sheet Block 所在的文档 token
        var userCanCopy = delegate?.browserVC?.editor?.permissionConfig.userPermissions?.canCopy() ?? false
        //判断是否单一文档可复制
        if let encryptId = ClipboardManager.shared.getEncryptId(token: docsInfo.token), !encryptId.isEmpty {
            userCanCopy = true
        }
        guard userCanCopy else {
            DocsLogger.info("has no user permission")
            return false
        }
        let dlpStatus = DlpManager.status(with: docsInfo.token, type: docsInfo.inherentType, action: .COPY)
        if dlpStatus != .Safe {
            DocsLogger.info("dlp control, can not copy dlp \(dlpStatus.rawValue)")
            return false
        }
        return true
    }
}


extension Keyboard.KeyboardOptions {
    public var fixedEndFrameForSheet: CGRect {
        return self.endFrame
    }
}
