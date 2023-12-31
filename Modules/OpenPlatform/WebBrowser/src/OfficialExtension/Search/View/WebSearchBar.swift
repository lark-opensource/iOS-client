//
//  WebSearchBar.swift
//  WebBrowser
//
//  Created by baojianjun on 2023/10/25.
//

import UIKit
import RxSwift
import RxCocoa
import LKCommonsLogging
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignInput
import UniverseDesignFont
import UniverseDesignShadow
import OPFoundation

// MARK: -

fileprivate
final class WebSearchTextField: UITextField {
    
    weak var keyPressDelegate: WebSearchBarKeyPressDelegate?
    
    /// 键盘事件
    ///
    /// 处理物理键盘的enter及shift enter，和软键盘上“搜索”键按下时的差异
    ///
    /// 差异表现:
    /// - 物理键盘的enter及shift enter按下时，会调用`pressesBegan`, `textFieldShouldReturn`
    /// - 软键盘的搜索键按下时，仅调用`textFieldShouldReturn`
    /// 
    /// ps. 其中`textFieldShouldReturn`是在super.pressesBegan()中触发的
    ///
    /// when `self.pressesBegan` has been called，`doNotHandleTextFieldShouldReturn = true`
    ///
    /// when `super.pressesBegan` -> `textFieldShouldReturn`, `if doNotHandleTextFieldShouldReturn { do nothing }`
    ///
    /// after `super.pressesBegan` has been called, `doNotHandleTextFieldShouldReturn = false`
    var doNotHandleTextFieldShouldReturn = false
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let key = presses.first?.key else {
            return
        }
        switch key.keyCode {
        case .keyboardReturnOrEnter:
            doNotHandleTextFieldShouldReturn = true
            if key.modifierFlags == .shift {
                // shift enter
                keyPressDelegate?.pressShiftEnterSubject.onNext(())
            } else {
                // just enter
                keyPressDelegate?.pressEnterSubject.onNext(())
            }
        case .keyboardEscape:
            keyPressDelegate?.pressEscapeSubject.onNext(())
        default: break
        }
        
        super.pressesBegan(presses, with: event)
        doNotHandleTextFieldShouldReturn = false
    }
}

fileprivate
protocol WebSearchBarKeyPressDelegate: AnyObject {
    var pressEnterSubject: PublishSubject<Void> { get }
    var pressShiftEnterSubject: PublishSubject<Void> { get }
    var pressEscapeSubject: PublishSubject<Void> { get }
}

// MARK: -

// 设计思路:
// 进入搜索模式时创建, 退出搜索模式时销毁
// 搜索状态暴露在ViewModel内
final class WebSearchBar: UIView, WebSearchBarKeyPressDelegate {
    
    // MARK: Private Property
    
    private static let logger = Logger.webBrowserLog(WebSearchBar.self, category: "WebSearchBar")
    
    private let keyboardHelper: OPComponentKeyboardHelper
    
    fileprivate let pressEnterSubject = PublishSubject<Void>()
    fileprivate let pressShiftEnterSubject = PublishSubject<Void>()
    fileprivate let pressEscapeSubject = PublishSubject<Void>()
    
    fileprivate var cacheBottomMargin: CGFloat?
    
    // MARK: Internal Property
    
    let disposeBag = DisposeBag()
    
    lazy private(set) var upArrowSignal = {
        upArrow.rx.tap.asSignal()
    }()
    
    lazy private(set) var downArrowSignal = {
        downArrow.rx.tap.asSignal()
    }()
    
    lazy private(set) var finishSignal = {
        finishButton.rx.tap.asSignal()
    }()
    
    lazy private(set) var pressEnterSignal = {
        pressEnterSubject.asSignal(onErrorJustReturn: ())
    }()
    
    lazy private(set) var pressShiftEnterSignal = {
        pressShiftEnterSubject.asSignal(onErrorJustReturn: ())
    }()
    
    lazy private(set) var pressEscapeSignal = {
        pressEscapeSubject.asSignal(onErrorJustReturn: ())
    }()
    
    private(set) var currentKeyword: String?
    
    lazy private(set) var searchObservable = {
        searchInputView.input.rx.controlEvent(.editingChanged)
            // 过滤预输入
            .filter { [weak searchInputView] _ in
                searchInputView?.input.markedTextRange == nil
            }
            .do(onNext: { [weak self] _ in
                self?.currentKeyword = self?.searchInputView.input.text
            })
            // 限流300ms
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            // 编辑事件映射至文本变化
            .map { [weak searchInputView] _ in
                searchInputView?.input.text
            }
    }()
    
    let indexSubject = PublishSubject<(Int, Int)>()
    
    // 和每次UI关联
    let traceId = OPTraceService.default().generateTrace().traceId
    
    /// iPad台前调度, 从物理键盘切换到软键盘, 输入框高度跟随的修复setting配置
    var keyboardFixFromHardwareToVirtualOnStageManager: Bool = false
    
    override init(frame: CGRect) {
        keyboardHelper = OPComponentKeyboardHelper()
        super.init(frame: frame)
        keyboardHelper.delegate = self
        backgroundColor = isPad ? UIColor.ud.bgBody : UIColor.ud.bgFiller
        layer.ud.setShadow(type: .s4Up)
        
        addSubview(visibleContainer)
        visibleContainer.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(isPad ? 74 : 56)
        }
        
        // 添加兜底隐藏自身的逻辑
        let tap = UITapGestureRecognizer(target: self, action: #selector(selfClicked))
        addGestureRecognizer(tap)
        
        setupInitialState()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupInitialState() {
        upArrow.isEnabled = false
        downArrow.isEnabled = false
        indexLabel.text = nil
    }
    
    // MARK: Life Cycle
    
    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        return searchInputView.becomeFirstResponder()
    }
    
    override var isFirstResponder: Bool {
        searchInputView.isFirstResponder
    }
    
    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        return searchInputView.resignFirstResponder()
    }
    
    override var canResignFirstResponder: Bool {
        searchInputView.canResignFirstResponder
    }
    
    // MARK: UI
    
    private let isPad = BDPDeviceHelper.isPadDevice()
    
    lazy var visibleContainer: UIView = {
        let container = UIView()
        
        container.addSubview(mainContainer)
        mainContainer.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(isPad ? 20 : 16)
            make.top.bottom.equalToSuperview().inset(isPad ? 13 : 12)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(visibleContainerClicked))
        container.addGestureRecognizer(tap)
        return container
    }()
    
    // 遮挡 selfClicked 事件
    @objc private func visibleContainerClicked() {}
    
    @objc private func selfClicked() {
        guard let superview else {
            return
        }
        guard self.frame.minY < superview.bounds.minY + superview.bounds.height / 2 else {
            return
        }
        // 搜索框组件异常过高的情况下（在键盘回调高度异常的情况），允许用户点击来收起搜索框
        Self.logger.error("selfClicked, isFirstResponder: \(self.isFirstResponder)")
        if self.isFirstResponder {
            _ = self.resignFirstResponder()
        } else {
            // 退出查找逻辑
            self.pressEscapeSubject.onNext(())
        }
    }
    
    private lazy var mainContainer: UIView = {
        let mainContainer = UIView(frame: .zero)
        
        mainContainer.addSubview(finishButton)
        finishButton.snp.makeConstraints { make in
            make.centerY.left.equalToSuperview()
            make.width.equalTo(finishButtonWidth)
        }
        
        mainContainer.addSubview(arrowContainer)
        arrowContainer.snp.makeConstraints { make in
            make.centerY.right.equalToSuperview()
            make.width.equalTo(isPad ? 72 : 60)
        }
        
        mainContainer.addSubview(searchInputView)
        searchInputView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(finishButton.snp.right).offset(isPad ? 20 : 12)
            make.right.equalTo(arrowContainer.snp.left).offset(isPad ? -20 : -12)
            make.height.equalTo(isPad ? 48 : 32)
        }
        return mainContainer
    }()
    
    private var finishButtonWidth: CGFloat {
        guard let finishButtonLabel = finishButton.titleLabel, let labelText = finishButtonLabel.text else {
            return isPad ? 32 : 28
        }
        return labelText.getWidth(font: finishButtonLabel.font)
    }
    
    private lazy var finishButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(BundleI18n.WebBrowser.LittleApp_MoreFeat_DoneBttn, for: .normal)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        if let label = button.titleLabel {
            label.font = isPad ? UDFont.headline : UDFont.body1
            label.textAlignment = .left
        }
        return button
    }()
    
    private lazy var arrowContainer: UIView = {
        let container = UIView(frame: .zero)
        container.addSubview(upArrow)
        upArrow.snp.makeConstraints { make in
            make.top.bottom.left.equalToSuperview()
        }
        
        container.addSubview(downArrow)
        downArrow.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview()
        }
        return container
    }()
    
    private lazy var upArrow: UIButton = {
        Self.getButton(.upOutlined)
    }()
    
    private lazy var downArrow: UIButton = {
        Self.getButton(.downOutlined)
    }()
    
    private static func getButton(_ type: UDIconType) -> UIButton {
        let button = UIButton(type: .custom)
        let image = UDIcon.getIconByKey(type, iconColor: UIColor.ud.iconN1)
        button.setImage(image, for: .normal)
        let imageDisable = UDIcon.getIconByKey(type, iconColor: UIColor.ud.iconDisabled)
        button.setImage(imageDisable, for: .disabled)
        return button
    }
    
    private lazy var searchInputView: UDTextField = {
        var config = UDTextFieldUIConfig()
        config.isShowBorder = true
        if !isPad {
            config.borderColor = .clear
            config.borderActivatedColor = .clear
            config.textMargins = .init(top: 0, left: 12, bottom: 0, right: 8) // 0, 12, 0是关键
        }
        config.rightImageMargin = 8
        config.clearButtonMode = .whileEditing
        config.font = isPad ? UDFont.body0 : UDFont.body2
        let inputView = UDTextField(config: config, textFieldType: WebSearchTextField.self)
        inputView.setRightView(indexLabel)
        inputView.delegate = self
        inputView.input.placeholder = BundleI18n.WebBrowser.LittleApp_MoreFeat_FindPlaceholder
        inputView.input.returnKeyType = .search
        if !isPad {
            inputView.layer.cornerRadius = 6
            inputView.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        }
        
        if let input = inputView.input as? WebSearchTextField {
            input.keyPressDelegate = self
        }
        
        return inputView
    }()
    
    private lazy var indexLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = UIColor.ud.textCaption
        label.font = isPad ? UDFont.body0 : UDFont.body2
        return label
    }()
}

// MARK: - Public function

extension WebSearchBar {
    func update(index: (Int, Int)?) {
        guard let index else {
            // 上下按钮置灰 and disable, 且隐藏 x/x
            setupInitialState()
            return
        }
        let enabled = index != (0, 0)
        upArrow.isEnabled = enabled
        downArrow.isEnabled = enabled
        // 显示 x/x
        indexLabel.text = !searchInputView.input.text.isEmpty ? "\(index.0)/\(index.1)" : nil
    }
    
    func resume(keyword: String, index: (Int, Int)) {
        searchInputView.input.text = keyword
        searchInputView.input.selectAll(nil)
        update(index: index)
    }
}

// MARK: - UDTextFieldDelegate

extension WebSearchBar: UDTextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let searchTextField = textField as? WebSearchTextField,
           !searchTextField.doNotHandleTextFieldShouldReturn {
            // 软键盘事件
            Self.logger.info("textFieldShouldReturn pressEnterSubject active")
            self.pressEnterSubject.onNext(())
            _ = textField.resignFirstResponder()
        }
        return true
    }
}

// MARK: - OPComponentKeyboardDelegate

extension WebSearchBar: OPComponentKeyboardDelegate {
    func isOwningViewFirstResponder() -> Bool {
        self.isFirstResponder
    }
    
    func keyboardWillShow(keyboardInfo: OPComponentKeyboardInfo) {
        Self.logger.info("keyboardWillShow \(keyboardInfo.keyboardFrame)")
        handleKeyboardHeight(keyboardFrame: keyboardInfo.keyboardFrame, animOption: keyboardInfo.animOption, animDuration: keyboardInfo.animDuration)
    }
    
    func keyboardWillHide(keyboardInfo: OPComponentKeyboardInfo) {
        Self.logger.info("keyboardWillHide \(keyboardInfo.keyboardFrame)")
        // 处理从软键盘变为浮动键盘时，keyboardWillHide事件键盘高度异常的问题
        let frame: CGRect = if keyboardInfo.displayType == .float
            || keyboardInfo.displayType == .splitOrUnlock {
            .zero
        } else {
            keyboardInfo.keyboardFrame
        }
        handleKeyboardHeight(keyboardFrame: frame, animOption: keyboardInfo.animOption, animDuration: keyboardInfo.animDuration)
    }
    
    func keyboardWillChangeFrame(keyboardInfo: OPComponentKeyboardInfo) {
        handleKeyboardFrameChange(keyboardInfo: keyboardInfo)
        if isPad, keyboardFixFromHardwareToVirtualOnStageManager,
            keyboardInfo.displayType == .default,
                  keyboardHelper.isFloatOrSplitKeyboard() {
            // 当前是普通键盘，之前为浮动键盘时，认为正在从浮动键盘切换到普通软键盘
            // 仅在台前调度 + 首次物理 -> 软键盘时应当触发
            handleKeyboardHeight(keyboardFrame: keyboardInfo.keyboardFrame, animOption: keyboardInfo.animOption, animDuration: keyboardInfo.animDuration)
        }
    }
    
    func keyboardDidChangeFrame(keyboardInfo: OPComponentKeyboardInfo) {
        handleKeyboardFrameChange(keyboardInfo: keyboardInfo)
    }
    
    private func handleKeyboardFrameChange(keyboardInfo: OPComponentKeyboardInfo) {
        guard isFirstResponder else {
            return
        }
        // 浮动键盘高度变化，且当前为普通键盘，则视为正在从普通键盘切换到浮动键盘
        if keyboardInfo.displayType == .float || keyboardInfo.displayType == .splitOrUnlock,
           !keyboardHelper.isFloatOrSplitKeyboard() {
            handleKeyboardHeight(keyboardFrame: .zero, animOption: keyboardInfo.animOption, animDuration: keyboardInfo.animDuration)
        }
    }
    
    private func handleKeyboardHeight(keyboardFrame: CGRect, animOption: UIView.AnimationOptions, animDuration: Double) {
        guard let superview else {
            return
        }
        // 浮动或拆分键盘的话，应该避让safeArea
        // 物理键盘的话，如果是给到的height是0，也应该避让safeArea
        
        var bottomMargin: CGFloat = 0
        if keyboardFrame.height <= CGFloat.ulpOfOne {
            // 如果键盘高度等于0, 那么它的y值也有可能为0, 此时只考虑safearea
            bottomMargin = superview.safeAreaInsets.bottom
        } else {
            // 物理键盘(及其悬浮窗)或者软键盘
            // 当前window的总高度, 减去keyboardFrame（已经被映射过一次了）的y，得到键盘相对当前window的高
            // 同时要考虑当前VC相对于当前window的frame
            if let currentWindow = OPComponentKeyboardHelper.currentWindow {
                let keyboardConvertFrame = superview.convert(keyboardFrame, from: currentWindow)
                bottomMargin = superview.bounds.maxY - keyboardConvertFrame.minY
            }
            bottomMargin = max(superview.safeAreaInsets.bottom, bottomMargin)
        }
        if let cacheBottomMargin, abs(cacheBottomMargin - bottomMargin) <= CGFloat.ulpOfOne {
            Self.logger.debug("cacheBottomMargin:\(cacheBottomMargin) is euqal to bottomMargin:\(bottomMargin)")
            return
        }
        Self.logger.info("handleKeyboardHeight bottomMargin from \(cacheBottomMargin ?? 0) to \(bottomMargin)")
        cacheBottomMargin = bottomMargin
        
        UIView.animate(withDuration: animDuration, delay: 0, options: animOption) {
            self.visibleContainer.snp.updateConstraints { make in
                make.bottom.equalToSuperview().inset(bottomMargin)
            }
            self.layoutIfNeeded()
        }
    }
}
