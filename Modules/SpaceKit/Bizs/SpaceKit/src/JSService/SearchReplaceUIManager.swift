//
//  SearchReplaceUIManager.swift
//  SpaceKit
//
//  Created by Webster on 2019/6/18.
//  swiftlint:disable file_length
//  方法调用序列比较复杂，建议留下 debug log 方便后期调试

import Foundation
import SnapKit
import SKCommon
import SKBrowser
import SKUIKit
import SKResource
import SKFoundation
import UniverseDesignColor
import UniverseDesignShadow
import SpaceInterface


struct SearchRestultNum {
    var current: Int = 0
    var total: Int = 0
}

protocol SearchReplaceUIManagerController: UIViewController {
    var contentHeight: CGFloat { get }
    var viewDistanceToWindowBottom: CGFloat { get }
    func setBottomPlaceholderHeight(height: CGFloat)
}

extension BrowserViewController: SearchReplaceUIManagerController {
    var contentHeight: CGFloat {
        return editor.bounds.height
    }

    var viewDistanceToWindowBottom: CGFloat {
        return browserViewDistanceToWindowBottom
    }
    
    func setBottomPlaceholderHeight(height: CGFloat) {
        updateBottomPlaceholderHeight(height: height)
    }
}

protocol SearchReplaceUIManagerDelegate: AnyObject {
    var supportedViewController: SearchReplaceUIManagerController? { get }
    func requestNewSearch(_ manager: SearchReplaceUIManager, content: String, exitKeyboard: Bool)
    func requestClearSearch(_ manager: SearchReplaceUIManager)
    func requestSwitchSearch(_ manager: SearchReplaceUIManager, result: SearchRestultNum)
    func requestChangeKeyboard(_ innerHeight: CGFloat, openKeyboard: Bool)
    func didClickSwitchButton(_ manager: SearchReplaceUIManager, isPrevious: Bool)
}

/// 查找替换功能管理类
class SearchReplaceUIManager {
    var postAnimatorNotify: Bool = false

    weak var delegate: SearchReplaceUIManagerDelegate?
    private weak var container: UIView?
    private var placeholderText: String
    private var finishButtonText: String
    private var searchTxt: String?
    private var searchResult: SearchRestultNum = SearchRestultNum()
    private var docType: DocsType

    private var contentHeight: CGFloat {
        guard let hostVC = delegate?.supportedViewController else { return 0 }
        return hostVC.contentHeight
    }

    /// VC Follow 时 hostView 下面 VC 写的 bottomBar 的高度
    private var viewDistanceToWindowBottom: CGFloat {
        guard let hostVC = delegate?.supportedViewController else { return 0 }
        return hostVC.viewDistanceToWindowBottom
    }

    /// VC Follow 时这个值是 0，代表 hostView 不受 home indicator 影响
    private var homeIndicatorAffectedHeight: CGFloat {
        guard let hostVC = delegate?.supportedViewController else { return 0 }
        return hostVC.view.safeAreaInsets.bottom
    }

    /**
     点击 NavigateView 的时候，不需要显示键盘
     点击 输入框的时候，会重新置为 true。
     用这个变量来判断旋转的时候，需不需要再次唤起键盘
     */
    private var needKeyboard = false
    private var keyboard: Keyboard?
    private var keyboardHeight: CGFloat = 0
    private var inputManagerViewLayoutFromBottom = false
     
    /// 输入框+完成键。横屏时还带一个左右按键
    private lazy var inputManagerView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        view.layer.ud.setShadow(type: .s2Down)
        return view
    }()
    /// 只在 iPhone 横屏时候显示，在输入框右边的左右按键
    private lazy var inputManagerNavigateButtons: NavigateButtonsView = makeNavigateView()
    /// input manager 在键盘上方时的高度（只有手机横屏时候会用到这里）
    private let inputManagerViewHeight: CGFloat = 44

    /// 键盘上方吸附的白条，右边有左右方向键
    private lazy var navigateAccessoryView: NavigateButtonsView = makeNavigateView()
    private let navigateAccessoryViewHeight: CGFloat = 44

    /// 输入文字后点击左右按钮会隐藏键盘，browser 底部的白条里有左右按键
    private lazy var bottomNavigateView: NavigateButtonsView = makeNavigateView()
    private let bottomNavigatorHeight: CGFloat = 44
    
    private var currentOrentation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
    
    private var haveChangedForOrentation: Bool = false

    private func makeNavigateView() -> NavigateButtonsView {
        let view = NavigateButtonsView()
        view.delegate = self
        view.backgroundColor = UDColor.bgBody
        view.enableButton(true)
        return view
    }

    private var topSafeAreaView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        return view
    }()

    private lazy var bottomSafeAreaView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        return view
    }()

    private lazy var finishButton: UIButton = {
        let btn = UIButton()
        btn.setTitle(finishButtonText, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        btn.setTitleColor(UDColor.colorfulBlue, for: .normal)
        btn.addTarget(self, action: #selector(didReceivedFinishEvent), for: .touchUpInside)
        return btn
    }()

    lazy var findTextField: DocsSearchTextField = {
        let view = DocsSearchTextField()
        view.returnKeyType = .search
        view.initialPlaceHolder = placeholderText
        view.updateNumberLabel(with: SearchRestultNum())
        view.addTarget(self, action: #selector(searchBeginEditing), for: .editingDidBegin)
        view.addTarget(self, action: #selector(searchEditingChanged), for: .editingChanged)
        view.addTarget(self, action: #selector(searchEditingExit), for: .editingDidEndOnExit)
        return view
    }()

    init(_ container: UIView?, placeholderText: String, finishButtonText: String, docType: DocsType) {
        self.container = container
        self.placeholderText = placeholderText
        self.finishButtonText = finishButtonText
        self.docType = docType
        self.keyboard = Keyboard(listenTo: [findTextField], trigger: DocsKeyboardTrigger.search.rawValue)
        setupInputManagerView()
        self.container?.layoutIfNeeded()
        keyboard?.on(events: [.didShow, .willHide]) { [weak self] opt in
            switch opt.event {
            case .didShow:
                self?.handleKeyboardShow(opt)
            case .willHide:
                self?.handleKeyboardHide(opt)
            default:
                ()
            }
        }
        addObserverForOrientationDidChange()
        keyboard?.start()
    }

    deinit {
        keyboard?.stop()
        keyboard = nil
    }

    private func addObserverForOrientationDidChange() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(statusBarOrientationWillChange(_:)),
                                               name: UIApplication.willChangeStatusBarOrientationNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(statusBarOrientationDidChange(_:)),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
    }
    
    @objc
    private func statusBarOrientationWillChange(_ notification: Notification) {
        guard let int = notification.userInfo?[UIApplication.statusBarOrientationUserInfoKey] as? Int,
            let newOrientation = UIInterfaceOrientation(rawValue: int) else {
                return
        }
        if currentOrentation != newOrientation {
            haveChangedForOrentation = false
        }
        currentOrentation = newOrientation
    }

    @objc
    private func statusBarOrientationDidChange(_ notification: Notification) {
        if haveChangedForOrentation { return }
        haveChangedForOrentation = true
        removeView()
        showView(keyboardOn: needKeyboard)
    }

    @objc
    func didReceivedFinishEvent() {
        DocsLogger.debug("SRUIM didReceivedFinishEvent")
        finishSearch()
    }
        
    func finishSearch() {
        DocsLogger.debug("SRUIM finishSearch")
        findTextField.text = ""
        handleAllSearchHidden()
        removeView()
        keyboard?.stop()
        delegate?.requestClearSearch(self)
    }

    @objc
    private func searchBeginEditing() {
        DocsLogger.debug("SRUIM searchBeginEditing")
        guard !needKeyboard else { return }
        needKeyboard = true
    }

    @objc
    func searchEditingChanged() {
        DocsLogger.debug("SRUIM searchEditingChanged")
        let realTimeTxt = findTextField.text
        if let currentTxt = realTimeTxt,
            let oldTxt = searchTxt,
            currentTxt != oldTxt {
            delegate?.requestNewSearch(self, content: currentTxt, exitKeyboard: false)
            searchTxt = realTimeTxt
        }
    }

    @objc
    func searchEditingExit() {
        DocsLogger.debug("SRUIM searchEditingExit")
        let text = findTextField.text ?? ""
        delegate?.requestNewSearch(self, content: text, exitKeyboard: true)
        needKeyboard = false
    }
}

extension SearchReplaceUIManager {
    func showView(keyboardOn: Bool) {
        DocsLogger.debug("SRUIM showView(\(keyboardOn))")
        guard let hostView = delegate?.supportedViewController?.view else { return }
        hostView.addSubview(topSafeAreaView)
        topSafeAreaView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(hostView.safeAreaLayoutGuide.snp.top)
        }
        topSafeAreaView.layer.zPosition = 1
        hostView.addSubview(bottomSafeAreaView)
        bottomSafeAreaView.snp.makeConstraints { make in
            make.left.width.bottom.equalToSuperview()
            make.top.equalTo(hostView.safeAreaLayoutGuide.snp.bottom)
        }
        bottomSafeAreaView.layer.zPosition = 1
        needKeyboard = keyboardOn
        postWillDisplayNotification()
        let orientation = UIApplication.shared.statusBarOrientation
        if orientation.isLandscape, SKDisplay.phone { // iPhone 横屏的布局
            showInputManagerViewForLandscapePhone(keyboardOn: keyboardOn)
        } else { // iPhone 竖屏的布局 和 iPad 的布局
            showInputManagerViewFromTop()
        }
        if keyboardOn { findTextField.becomeFirstResponder() }
        searchTxt = findTextField.text
        updateNavigateBarButtonsEnable()
    }

    func removeView() {
        DocsLogger.debug("SRUIM removeView")
        topSafeAreaView.removeFromSuperview()
        bottomSafeAreaView.removeFromSuperview()
        inputManagerView.removeFromSuperview()
        navigateAccessoryView.removeFromSuperview()
        findTextField.resignFirstResponder()
        bottomNavigateView.removeFromSuperview()
        postDidHideNotification()
        // 设置回归到普通状态
        updateBottomPlaceholderHeight(reset: true)
    }

    private func updateNavigateBarButtonsEnable() {
        DocsLogger.debug("SRUIM updateNavigateViewEnable")
        if searchResult.total <= 0 || searchResult.current < 0 {
            navigateAccessoryView.enableButton(false)
            bottomNavigateView.enableButton(false)
            inputManagerNavigateButtons.enableButton(false)
            return
        }
        let previousEnable = searchResult.current > 0
        let nextEnable = (searchResult.current + 1) < searchResult.total

        navigateAccessoryView.previousButton.isEnabled = previousEnable
        bottomNavigateView.previousButton.isEnabled = previousEnable
        inputManagerNavigateButtons.previousButton.isEnabled = previousEnable

        navigateAccessoryView.nextButton.isEnabled = nextEnable
        bottomNavigateView.nextButton.isEnabled = nextEnable
        inputManagerNavigateButtons.nextButton.isEnabled = nextEnable
    }

    private func setupInputManagerView() {
        DocsLogger.debug("SRUIM setupInputManagerView")
        inputManagerView.addSubview(inputManagerNavigateButtons)
        inputManagerView.addSubview(findTextField)
        inputManagerView.addSubview(finishButton)
        var finishButtonSize = finishButton.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        finishButtonSize = CGSize(width: finishButtonSize.width + 11, height: finishButtonSize.height)
        finishButton.snp.makeConstraints { (make) in
            make.width.equalTo(finishButtonSize.width)
            make.centerY.equalToSuperview()
            make.right.equalTo(inputManagerView.safeAreaLayoutGuide.snp.right).offset(-12)
        }
        finishButton.docs.addHighlight(with: UIEdgeInsets(top: 0, left: -6, bottom: 0, right: -6), radius: 8)
        inputManagerNavigateButtons.snp.makeConstraints { (make) in
            make.height.centerY.equalToSuperview()
            make.width.equalTo(0)
            make.right.equalTo(finishButton.snp.left).offset(-12)
        }
        findTextField.snp.makeConstraints { (make) in
            make.height.equalTo(32)
            make.centerY.equalToSuperview()
            make.left.equalTo(inputManagerView.safeAreaLayoutGuide.snp.left).offset(12)
            make.right.equalTo(inputManagerNavigateButtons.snp.left)
        }
    }

    /// InputManagerView 是否要显示左右按键
    private func inputManagerViewShowNavigateButtons(_ show: Bool) {
        DocsLogger.debug("SRUIM inputManagerViewShowNavigateButtons(\(show))")
        let navigateWidth = show ? 110 : 0
        inputManagerNavigateButtons.snp.updateConstraints { (make) in
            make.width.equalTo(navigateWidth)
        }
        inputManagerNavigateButtons.layer.shadowOpacity = show ? 0 : 1
        inputManagerView.layoutIfNeeded()
    }

    private func showInputManagerViewFromTop() {
        DocsLogger.debug("SRUIM showInputManagerViewFromTop")
        guard let hostVC = delegate?.supportedViewController as? BaseViewController else { return }
        inputManagerView.removeFromSuperview()
        hostVC.view.addSubview(inputManagerView)
        inputManagerViewShowNavigateButtons(false)
        inputManagerView.snp.remakeConstraints { it in
            it.width.left.equalToSuperview()
            it.bottom.equalTo(hostVC.navigationBar)
            it.top.equalTo(self.topSafeAreaView.snp.bottom)
        }
        inputManagerView.alpha = 0
        UIView.animate(withDuration: 0.1) { [weak self] in
            self?.inputManagerView.alpha = 1
        } completion: { [weak self] (completed) in
            if completed {
                guard let self = self else { return }
                self.updateViewPosition(keyboardOn: self.needKeyboard)
            }
        }
    }

    private func showInputManagerViewForLandscapePhone(keyboardOn: Bool) {
        DocsLogger.debug("SRUIM showInputManagerViewForLandscapePhone(\(keyboardOn))")
        guard let hostVC = delegate?.supportedViewController else { return }
        showNavigateAccessoryView(false)
        showBottomNavigateBar(false)
        if inputManagerView.superview != nil { inputManagerView.removeFromSuperview() }
        hostVC.view.addSubview(inputManagerView)
        inputManagerViewShowNavigateButtons(true)
        inputManagerView.alpha = 0.0
        UIView.animate(
            withDuration: 0.1,
            animations: { [unowned hostVC] in
                self.inputManagerView.snp.remakeConstraints { it in
                    it.width.left.equalToSuperview()
                    it.bottom.equalTo(self.bottomSafeAreaView.snp.top)
                    it.height.equalTo(self.inputManagerViewHeight)
                }
                hostVC.view.layoutIfNeeded()
            },
            completion: { _ in
                /// 计算 inputY 的逻辑依赖 hostVC.view.bounds.height、 hostViewDistanceToWindowBottom 和 keyboardHeight
                /// 这三个值在转屏完成后才是准的，所以需要用 UIAnimate 的方式延后 0.1 秒，等到转屏完成，调用 updateViewPosition
                self.updateViewPosition(keyboardOn: keyboardOn)
            }
        )
    }

    /// iPhone 竖屏和 iPad 任何时候，键盘起来，键盘上方会有导航按钮
    private func showNavigateAccessoryView(_ shouldShow: Bool) {
        DocsLogger.debug("SRUIM showNavigateAccessoryView(\(shouldShow))")
        guard let hostView = delegate?.supportedViewController?.view else { return }
        if navigateAccessoryView.superview != nil { navigateAccessoryView.removeFromSuperview() }
        if UIApplication.shared.statusBarOrientation.isLandscape, SKDisplay.phone { return }
        guard bottomSafeAreaView.superview != nil else { return }
        if shouldShow {
            showBottomNavigateBar(false)
            let browserBottomDistanceToWindow = viewDistanceToWindowBottom
            let inputY = hostView.bounds.height + browserBottomDistanceToWindow - max(keyboardHeight, browserBottomDistanceToWindow) - navigateAccessoryViewHeight
            hostView.addSubview(navigateAccessoryView)
            navigateAccessoryView.frame = CGRect(x: 0, y: inputY, width: hostView.bounds.width, height: navigateAccessoryViewHeight)
            
            navigateAccessoryView.snp.remakeConstraints { (make) in
                make.left.width.equalToSuperview()
                make.top.equalTo(inputY)
                make.height.equalTo(navigateAccessoryViewHeight)
            }
            
            bottomSafeAreaView.snp.remakeConstraints { make in
                make.left.width.bottom.equalToSuperview()
                make.top.equalTo(navigateAccessoryView.snp.bottom)
            }
            hostView.layoutIfNeeded()
        } else {
            bottomSafeAreaView.snp.remakeConstraints { make in
                make.left.width.bottom.equalToSuperview()
                make.top.equalTo(hostView.safeAreaLayoutGuide.snp.bottom)
            }
            hostView.layoutIfNeeded()
        }
    }

    /// 输入文字后点击左右导航按钮，会隐藏键盘，需要显示一个底部的导航 view
    private func showBottomNavigateBar(_ shouldShow: Bool) {
        DocsLogger.debug("SRUIM showBottomNavigateBar(\(shouldShow))")
        if UIApplication.shared.statusBarOrientation.isLandscape, SKDisplay.phone {
            // iPhone 横屏没有 bottomNavigateBar，取而代之的是 inputManagerView
            return
        }
        guard let hostView = delegate?.supportedViewController?.view else { return }
        if bottomNavigateView.superview != nil { bottomNavigateView.removeFromSuperview() }
        if shouldShow {
            showNavigateAccessoryView(false)
            hostView.addSubview(bottomNavigateView)
            bottomNavigateView.snp.remakeConstraints { (make) in
                make.left.width.equalToSuperview()
                if bottomSafeAreaView.superview != nil {
                    make.bottom.equalTo(bottomSafeAreaView.snp.top)
                } else {
                    make.bottom.equalTo(hostView.safeAreaLayoutGuide.snp.bottom)
                }
                make.height.equalTo(bottomNavigatorHeight)
            }
            hostView.layoutIfNeeded()
        }
        updateBottomPlaceholderHeight()
    }

    private func updateViewPosition(keyboardOn: Bool) {
        DocsLogger.debug("SRUIM updateViewPosition")
        guard let hostVC = delegate?.supportedViewController as? BaseViewController else { return }
        if SKDisplay.phone {
            if UIApplication.shared.statusBarOrientation.isLandscape { // iPhone 在横屏的时候需要把 inputManagerView 挪到键盘上面
                showNavigateAccessoryView(false)
                showBottomNavigateBar(false)
                if inputManagerView.superview == nil { hostVC.view.addSubview(inputManagerView) }
                inputManagerViewShowNavigateButtons(true)
                /**
                 这里的计算方法有点复杂，我来解释一下。
                 keyboardOn == true 的时候：
                   由于 Magic Share 的存在，browserView 可能并不贴在屏幕底端，所以要计算 hostVC.view.bounds.height + viewDistanceToWindowBottom
                   其中的 viewDistanceToWindowBottom 就考虑了 Magic Share 的组件。
                   接下来需要减去弹出键盘的高度。一般情况下用 keyboardHeight 就能拿对，但是有一个 case 很奇葩，那就是手机使用了外接键盘（例如模拟器）
                   这个时候 keyboardHeight == 0，所以我们要取 max(keyboardHeight, homeIndicatorAffectedHeight) 而不是单纯的取 keyboardHeight
                   其中的 homeIndicatorAffectedHeight 也是通过拿 safeAreaInsets 来取的。然后 inputManagerView 就不会被 home indicator 给盖住了
                 keyboardOn == false 的时候：
                   键盘没起来的时候，我们就不需要考虑键盘高度的因素了，我们只需要保证 inputManagerView 不被 home indicator 遮住就可以，直接用
                   hostVC.view.bounds.height - homeIndicatorAffectedHeight 就能拿到 inputManagerView 的 maxY
                 */
                let minY = keyboardOn ?
                    (hostVC.view.bounds.height + viewDistanceToWindowBottom - max(max(keyboardHeight, homeIndicatorAffectedHeight), viewDistanceToWindowBottom) - inputManagerViewHeight) :
                    (hostVC.view.bounds.height - homeIndicatorAffectedHeight - inputManagerViewHeight)
                self.inputManagerView.snp.remakeConstraints { it in
                    it.width.left.equalToSuperview()
                    it.height.equalTo(self.inputManagerViewHeight)
                    it.top.equalTo(minY)
                }
                inputManagerView.layer.ud.setShadow(type: .s4Up)
                inputManagerViewLayoutFromBottom = !keyboardOn
            } else {
                showNavigateAccessoryView(keyboardOn)
                showBottomNavigateBar(!keyboardOn)
                self.inputManagerView.snp.remakeConstraints { it in
                    it.width.left.equalToSuperview()
                    it.bottom.equalTo(hostVC.navigationBar)
                    if topSafeAreaView.superview != nil {
                        it.top.equalTo(topSafeAreaView.snp.bottom)
                    } else {
                        it.top.equalTo(hostVC.view.safeAreaLayoutGuide.snp.top)
                    }
                }
                inputManagerView.layer.ud.setShadow(type: .s2Down)
                inputManagerViewLayoutFromBottom = false
            }
        } else {  // iPad 的 view 不管横竖屏一直在屏幕顶部，只不过需要更新一下大小
            inputManagerViewShowNavigateButtons(false)
            showNavigateAccessoryView(keyboardOn)
            showBottomNavigateBar(!keyboardOn)
            self.inputManagerView.snp.remakeConstraints { it in
                it.width.left.equalToSuperview()
                it.bottom.equalTo(hostVC.navigationBar)
                if topSafeAreaView.superview != nil {
                    it.top.equalTo(topSafeAreaView.snp.bottom)
                } else {
                    it.top.equalTo(hostVC.view.safeAreaLayoutGuide.snp.top)
                }
            }
            inputManagerViewLayoutFromBottom = false
        }
        inputManagerView.alpha = 1
        hostVC.view.layoutIfNeeded()
        updateBottomPlaceholderHeight()
    }

    private func postWillDisplayNotification() {
        DocsLogger.debug("SRUIM postWillDisplayNotification")
        if !postAnimatorNotify { return }
        let notify = Notification.Name.MakeDocsAnimationStartIgnoreKeyboard
        NotificationCenter.default.post(name: notify, object: nil)
    }

    private func postDidHideNotification() {
        DocsLogger.debug("SRUIM postDidHideNotification")
        if !postAnimatorNotify { return }
        let notify = Notification.Name.MakeDocsAnimationEndIgnoreKeyboard
        NotificationCenter.default.post(name: notify, object: nil)
    }
    
    private func updateBottomPlaceholderHeight(reset: Bool = false) {
        // sheet 有额外的逻辑依赖native传入的高度给前端，算webView渲染区域的时候没把底部站位的空白view计算进去, 这里需要把sheet排除
        // https://meego.feishu.cn/larksuite/issue/detail/14196360?#detail
        guard docType != .sheet else {
            return
        }
        delegate?.supportedViewController?.setBottomPlaceholderHeight(height: reset ? 0 : homeIndicatorAffectedHeight + bottomNavigatorHeight)
    }
}

extension SearchReplaceUIManager: NavigateButtonsViewDelegate {
    func updateResult(current: Int, total: Int) {
        DocsLogger.debug("SRUIM updateResult(\(current), \(total))")
        ///假如total是5， current的索引是(0-4)
        searchResult.current = current
        searchResult.total = total
        findTextField.updateNumberLabel(with: searchResult)
        updateNavigateBarButtonsEnable()
    }

    fileprivate func requestNextResult(_ view: NavigateButtonsView) {
        DocsLogger.debug("SRUIM requestNextResult(\(view))")
        guard searchResult.total > 0 else {
            showBottomNavigateBar(true)
            resignTextField()
            return
        }
        needKeyboard = false
        let maxIndex = searchResult.total - 1
        let minIndex = 0
        searchResult.current = min(max(minIndex, searchResult.current), maxIndex)

        if searchResult.current + 1 > maxIndex {
            searchResult.current = minIndex
        } else {
            searchResult.current += 1
        }
        delegate?.requestSwitchSearch(self, result: searchResult)
        delegate?.didClickSwitchButton(self, isPrevious: true)
        showBottomNavigateBar(true)
        resignTextField()

    }

    fileprivate func requestPreviousResult(_ view: NavigateButtonsView) {
        DocsLogger.debug("SRUIM requestPreviousResult(\(view))")
        guard searchResult.total > 0 else {
            showBottomNavigateBar(true)
            resignTextField()
            return
        }
        needKeyboard = false
        let maxIndex = searchResult.total - 1
        let minIndex = 0
        searchResult.current = min(max(minIndex, searchResult.current), maxIndex)

        if searchResult.current - 1 < minIndex {
            searchResult.current = maxIndex
        } else {
            searchResult.current -= 1
        }
        delegate?.requestSwitchSearch(self, result: searchResult)
        delegate?.didClickSwitchButton(self, isPrevious: false)
        showBottomNavigateBar(true)
        resignTextField()

    }

    func resignTextField() {
        DocsLogger.debug("SRUIM resignTextField")
        if findTextField.isFirstResponder {
            findTextField.resignFirstResponder()
        }
    }

    private func handleKeyboardShow(_ options: Keyboard.KeyboardOptions) {
        DocsLogger.debug("SRUIM handleKeyboardShow(\(options))")
        keyboardHeight = options.endFrame.height
        needKeyboard = true
        let maxHeight = contentHeight + viewDistanceToWindowBottom
        let innerHeight = maxHeight - keyboardHeight - navigateAccessoryViewHeight // 键盘起来之后的 webview 可视区高度
        delegate?.requestChangeKeyboard(innerHeight, openKeyboard: true)
        self.updateViewPosition(keyboardOn: true)
    }

    private func handleKeyboardHide(_ options: Keyboard.KeyboardOptions) {
        DocsLogger.debug("SRUIM handleKeyboardHide(\(options))")
        needKeyboard = false
        var innerHeight = contentHeight - homeIndicatorAffectedHeight
        if UIApplication.shared.statusBarOrientation.isLandscape && SKDisplay.phone {
            innerHeight -= inputManagerView.frame.size.height
        } else {
            var needSubTractBottomNavigatorHeight = bottomNavigateView.superview != nil
            if !UserScopeNoChangeFG.ZJ.searchWebSafeAreaUpdateFixDisable {
                needSubTractBottomNavigatorHeight = bottomNavigateView.superview != nil || findTextField.superview != nil
            }
            
            if needSubTractBottomNavigatorHeight { innerHeight -= bottomNavigatorHeight }
        }
        delegate?.requestChangeKeyboard(innerHeight, openKeyboard: false)
        self.updateViewPosition(keyboardOn: false)
    }

    private func handleAllSearchHidden() {
        DocsLogger.debug("SRUIM handleAllSearchHidden")
        delegate?.requestChangeKeyboard(contentHeight, openKeyboard: false)
    }
}


// MARK: - 切换查找结果

private protocol NavigateButtonsViewDelegate: AnyObject {
    func requestPreviousResult(_ view: NavigateButtonsView)
    func requestNextResult(_ view: NavigateButtonsView)
}

private class NavigateButtonsView: UIView {
    weak var delegate: NavigateButtonsViewDelegate?

    lazy var previousButton: UIButton = {
        let button = UIButton()
        button.setImage(BundleResources.SKResource.Common.Global.icon_global_back_nor,
                        withColorsForStates: [(UDColor.iconN1, .normal),
                                              (UDColor.N600, .highlighted),
                                              (UDColor.iconDisabled, .disabled)])
        button.addTarget(self, action: #selector(didClickPreviousButton), for: .touchUpInside)
        button.isEnabled = false
        button.docs.addHighlight(with: UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1), radius: 8)
        return button
    }()

    lazy var nextButton: UIButton = {
        let button = UIButton()
        button.setImage(BundleResources.SKResource.Common.Tool.icon_tool_behind_nor,
                        withColorsForStates: [(UDColor.iconN1, .normal),
                                              (UDColor.N600, .highlighted),
                                              (UDColor.iconDisabled, .disabled)])
        button.addTarget(self, action: #selector(didClickNextButton), for: .touchUpInside)
        button.isEnabled = false
        button.docs.addHighlight(with: UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1), radius: 8)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UDColor.bgBody
        layer.ud.setShadow(type: .s4Up)
        addSubview(previousButton)
        addSubview(nextButton)

        nextButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(32)
            make.right.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }
        nextButton.docs.addHighlight(with: UIEdgeInsets(top: -5, left: -10, bottom: -5, right: -10), radius: 8)
        previousButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(32)
            make.right.equalTo(nextButton.snp.left).offset(-22)
            make.centerY.equalToSuperview()
        }
        previousButton.docs.addHighlight(with: UIEdgeInsets(top: -5, left: -10, bottom: -5, right: -10), radius: 8)
    }

    func enableButton(_ enable: Bool) {
        previousButton.isEnabled = enable
        nextButton.isEnabled = enable
    }

    @objc
    func didClickPreviousButton() {
        delegate?.requestPreviousResult(self)
    }

    @objc
    func didClickNextButton() {
        delegate?.requestNextResult(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
