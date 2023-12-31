//
//  DocsToolBar.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/1/9.
//

// swiftlint:disable file_length
import UIKit
import LarkUIKit
import SKCommon
import SKUIKit
import SKFoundation
import EENavigator
import UniverseDesignColor
import LarkContainer

protocol DocsToolBarDelegate: AnyObject {
    func docsToolBar(_ toolBar: DocsToolBar, changeInputView inputView: UIView?)
    func docsToolBarShouldEndEditing(_ toolBar: DocsToolBar, editMode: DocsToolBar.EditMode, byUser: Bool)
    func docsToolBarRequestDocsInfo(_ toolBar: DocsToolBar) -> DocsInfo?
    func docsToolBarRequestInvokeScript(_ toolBar: DocsToolBar, script: DocsJSCallBack)
    func docsToolBarToggleDisplayTypeToFloating(_ toolBar: DocsToolBar, frame: CGRect)
    func docsToolBarToggleDisplayTypeToDefault(_ toolBar: DocsToolBar)
}

// 仅作为Docs和Sheet工具栏，增删改代码请联系 @junlin(工作日) 或 @weibin(法定假期)
// .normal和.sheetInput模式不足以满足需求，可以考虑拆出BaseToolBar，Docs、Sheet等分别继承，避免过于庞大

/// Docs编辑器的工具栏
public final class DocsToolBar: UIView {
    weak var delegate: DocsToolBarDelegate?
    var sheetInputDelegate: SheetInputViewDelegate? {
        get { return sheetInputView.delegate }
        set { sheetInputView.delegate = newValue }
    }

    // MARK: 📕External Interface
    /// 工具栏正常情况下的固有高度
    static var inherentHeight: CGFloat = Const.inherentHeight
    /// 其他Panel使用键盘高度作为自身高度
    var useKeyboardHeight: Bool = true
    /// 设置Panel最小高度，仅当useKeyboardHeight开启时可用
    var minimumPanelHeight: CGFloat = 180
    /// 开启Taptic Engine反馈
    var useTapticEngine: Bool = true
    /// 当前工具栏编辑模式
    var mode: EditMode = .normal
    /// 当前键盘displayType default/float
    var currentKeyboardDisplayType: Keyboard.DisplayType = .default

    ///sheet@doc工具栏输入框是否出现
    var willRestoreByKeyboard: Bool = false

    var changeSubPanelAfterKeyboardDidShow: Bool = false

    ///工具栏距离导航栏底部距离
    var maxTopContent: CGFloat = CGFloat.greatestFiniteMagnitude

    /// 实在没办法了才用此下策
    /// 这个值代表着 UtilAtFinderService 要延时多久来 handle 前端请求
    /// 绝大多数情况下这个值都是 0，代表不延时
    /// 只有在新增面板里选择 mention 系列的 block 之后，才会设置成 500ms
    /// 哎......臣妾也没办法啊
    /// 设置这个变量的原因是，当我打开新增面板时，系统键盘会收起，toolbar 丢失
    /// 如果选择插入一个 mention block 的话，前端会调用 biz.util.atfinder 来进入 at 模块
    /// 但是在这个状态下，点击工具栏上的返回按钮，返回不了之前的普通的工具栏，因为这个时候工具栏的 lastMode 是 .none，对应的很多 callback 也是 nil
    /// 所以 DocsToolbarManager.restoreTool 就不能成功让工具栏从 at 状态回到普通状态
    /// 那么怎么解决这个问题呢？
    /// 前端答应在新增面板里选择 mention block 之后，再调用一次 biz.navigation.setDocToolbarV2，把普通状态的 map 传过来
    /// 但是前端调用 biz.navigation.setDocToolbarV2 之后就会马上调用 biz.util.atfinder
    /// 所以 setDocToolbarV2 的 handler 函数执行不完，无法让工具栏先恢复普通状态再换到 at 状态
    /// 前端也拒绝在这两个函数调用之间加延时，毕竟新增面板的回调里面只有 mention 才需要有延时，其他类型的 block 不需要。前端不想帮我们做这个决策
    /// 所以这个延时只能我们这边做啦～
    /// 这个值会在 BaseToolbarPlugin.setAtFinderServiceDelayHandleOnce 方法里设置成 500ms
    /// 然后 util.atfinder 会在 handle 之后立即将这个值清零，所以这个延时不会影响其他业务调用
    var atFinderServiceDelayHandleInterval = DispatchTimeInterval.milliseconds(0)

    var restoreCallback: ((String) -> Void)?

    // MARK: 📗Internal Interface
    private var items: [DocsBaseToolBarItem] = []
    //private var keyboardItem: DocsBaseToolBarItem = DocsKeyboardToolBarItem()

    // MARK: 📘Data

    /// (sheetInput模式专用)标识Sheet不在标记状态且工具栏存在的情况，此时无任何二级面板
    private var isSheetToolBarFloating: Bool {
        guard mode == .sheetInput else { return false }
        return !sheetInputView.isFirstResponder
    }

    public var currentTrigger: String {
        if mode == .sheetInput {
            return DocsKeyboardTrigger.sheet.rawValue
        } else {
            return DocsKeyboardTrigger.editor.rawValue
        }
    }
    private weak var currentPanel: SKSubToolBarPanel?
    private weak var currentMain: SKMainToolBarPanel?
    private weak var currentDisplayPanel: SKSubToolBarPanel? //覆盖二级菜单栏显示Panel
    private weak var currentTitleView: UIView?
    private var keyboardHeight: CGFloat = 0
    ///和keyboardHeight的区别是keyboardShowHeight不会为0，仅记录键盘展示状态的高度值，用于给toolBarPanel设置frame
    private var keyboardShowHeight: CGFloat = Const.estimateKeyboardHeight
    private var isJustInit: Bool = true
    private var restoreTag: String?
    private var restoreKeyboardHeight: CGFloat?
    private var sheetInputInfo: NSMutableAttributedString? = nil

    // MARK: 📙UI Widget
    /// Sheet输入模式输入框对应的UITextView
    var sheetInputTextView: UITextView {
        return sheetInputView.inputTextView
    }
    private lazy var feedbackGenerator = UISelectionFeedbackGenerator()
    // Navigator-mainSceneWindow 都是使用了safeAreaInsets.bottom
    private lazy var sheetInputView: SheetInputView = {
        let sheetInputView = SheetInputView(bottomSafeAreaHeight: self.userResolver.navigator.mainSceneWindow?.safeAreaInsets.bottom, from: .docs)
        return sheetInputView
    }()
    
    var barContainerView: UIView = {
        let view = UIView()
        view.layer.zPosition = 1
        return view
    }()
    
    var titleContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    private lazy var bottomSeparateLine: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.N300
        return view
    }()
    private lazy var safeAreaButtomMask: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        view.isUserInteractionEnabled = false
        view.layer.zPosition = 0
        return view
    }()
    
    let userResolver: UserResolver
    
    init(frame: CGRect, userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(frame: frame)
        setupView()
        configure()
        _addObserver()
    }

    private func _addObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(showSeparateLine),
                                               name: Notification.Name.NavigationShowHighlightPanel,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(hideSeparateLine),
                                               name: Notification.Name.NavigationHideHighlightPanel,
                                               object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// (sheetInput模式专用)开始sheet编辑
    func beginSheetEdit(with info: NSMutableAttributedString?,
                        autoHideKeyboard: Bool = true,
                        animated: Bool,
                        segmentArr: [SheetSegmentBase]? = nil,
                        inputView: UIView? = nil,
                        sheetCellStyle: SheetStyleJSON? = SheetStyleJSON(),
                        sheetCellID: String? = nil,
                        sheetDocsInfo: DocsInfo? = nil) {
        guard mode == .sheetInput else { assertionFailure("SheetInput mode special"); return }
        if let view = inputView {
            sheetInputView.inputView = view
        }
        sheetInputInfo = info
        if let info = info {
            // 没有在二级面板编辑的时候，sheet的fx栏才显示
            // 我也不知道下面为什么要搞出 currentPanel 和 currentDisplayPanel 两个变量，真 nb 的逻辑
            let isShowingSystemKeyboard = currentPanel == nil
            if isShowingSystemKeyboard {
                removeTitleView()
            }
            if currentDisplayPanel != nil {
                removeDisplayPanel()
            }
            setSheetInputViewVisible(to: isShowingSystemKeyboard, animated: animated)
            sheetInputView.cellStyle = sheetCellStyle
            sheetInputView.attributeArray = segmentArr ?? []
            sheetInputView.editCellID = sheetCellID
            sheetInputView.beginEditWith(info)
        } else {
            setSheetInputViewVisible(to: false, animated: animated)
            if currentPanel == nil && autoHideKeyboard && !willRestoreByKeyboard {
                hideKeyboard(false)
            } else {
                sheetInputView.beginEditWith(nil)
                if willRestoreByKeyboard { setSheetInputViewVisible(to: true, animated: true) }
            }
        }
        sheetInputView.sheetDocsInfo = sheetDocsInfo
    }

    func resetSheetStatus() {
        sheetInputView.resetCurrentInputHeight()
    }

    // MARK: 📕External Method Interface
    /// 设置工具栏编辑模式
    func setEditMode(to mode: EditMode, animated: Bool) {
        guard mode != self.mode else { return }
        let oldMode = self.mode
        self.mode = mode
        onEditModeChanged(oldValue: oldMode)
    }

    /// 更新键盘的高度，应在每次系统键盘高度更新时设置(不包括Panel类型item的菜单)
    func setKeyboardHeight(_ height: CGFloat) {
        keyboardHeight = height
        if height > 0 { 
            keyboardShowHeight = height
        }
    }

    /// 由外部控制显示键盘(结束编辑)，需要保证是第一响应者
    func showKeyboard() {
        changeInputView(nil)
        if mode == .sheetInput && sheetInputInfo != nil {
            setSheetInputViewVisible(to: true, animated: true)
        }
    }

    /// 由外部控制收起键盘(结束编辑)，需要保证是第一响应者
    func hideKeyboard(_ deleteMain: Bool = false) {
        if deleteMain {
            for view in barContainerView.subviews {
                view.removeFromSuperview()
            }
        }
        reset()
        doEndEditing(byUser: false)
    }

    /// 重置工具栏状态，恢复出厂设置用的，没啥特殊需求就别调用了
    private func reset() {
        isJustInit = true
        currentPanel?.showRootView()
        currentPanel?.snp.removeConstraints()
        currentPanel = nil
        removeTitleView()
        isJustInit = false
        if let panel = currentMain as? DocsMainToolBar {
            panel.reset()
        }
    }

    /// 刷新item状态，如果item不正常可以使用
    func reloadItems() {
        /* weibin
        itemCollectionView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.itemCollectionView.layoutIfNeeded()
        }*/
    }

    /// 刷新panel状态，如果panel不正常可以使用
    func reloadPanel() {
        doReloadPanel()
    }

    /// 当可能导致工具栏面板(present新页面)被系统收起的影响被消除时，调用此方法检查是否需要恢复。(如present图片选择器，在dismiss之后需要恢复图片选择面板)
    /// 此处为通知前端
    func restoreH5EditStateIfNeeded() {
        guard let tag = restoreTag else { return }
        var script: DocsJSCallBack?
        switch tag {
        case DocsAssetToolBarItem.restoreTag: script = DocsAssetToolBarItem.restoreScript
        default: break
        }
        if let script = script {
            delegate?.docsToolBarRequestInvokeScript(self, script: script)
        }
        if let restoreKbh = restoreKeyboardHeight {
            keyboardHeight = restoreKbh
        }
        restoreKeyboardHeight = nil
    }

    /// 当可能导致工具栏面板(present新页面)被系统收起的影响被消除时，调用此方法检查是否需要恢复。(如present图片选择器，在dismiss之后需要恢复图片选择面板)
    /// 此处为native响应前端，并执行对应操作
    func restoreEditStateIfNeeded() {
        if restoreTag == nil {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500) { [weak self] in //在恢复编辑态的时候，键盘会有弹起动画，如果马上恢复对应的inputview会导致拿到的键盘高度不对，这里需要延时处理
            DocsLogger.debug("restoreEditStateIfNeeded")
            guard let tag = self?.restoreTag else { return }
            self?.restoreCallback?(tag)
            self?.restoreTag = nil
        }
    }

    /// (sheetInput模式专用)结束sheet编辑
    func endSheetEdit() {
        willRestoreByKeyboard = false
        guard mode == .sheetInput else {
            spaceAssertionFailure("SheetInput mode special"); return
        }
        hideKeyboard(false)
    }
    
    public var hideBarContainer: Bool = false {
        didSet {
            barContainerView.isHidden = hideBarContainer
        }
    }
}

extension DocsToolBar: DocsToolBarItemDelegate {
    func requestHideToolBar(item: DocsBaseToolBarItem?) {
        doEndEditing(byUser: false)
    }

    func requestJumpAnotherTitleView(in item: DocsBaseToolBarItem) {
        //setTitleView(titleView, item: item)
        //打开颜色选择面板的回调
        guard let info = delegate?.docsToolBarRequestDocsInfo(self) else { return }
        logSheetToolBarOperation((item as? SheetCellToolItem) != nil ? "fore_color_open" : "font_color_open", info: info)
    }

    func requestExitTitleView(in item: DocsBaseToolBarItem) {
        //removeTitleView(item: item)
    }

    func requestTapicFeedback(item: DocsBaseToolBarItem) {
        onTapticFeedback()
    }

    func requestJumpKeyboard(in item: DocsBaseToolBarItem) {
    }

    func requestDocsInfo(item: DocsBaseToolBarItem) -> DocsInfo? {
        return delegate?.docsToolBarRequestDocsInfo(self)
    }

    func requestAddRestoreTag(item: DocsBaseToolBarItem?, tag: String?) {
        restoreTag = tag
        restoreKeyboardHeight = keyboardHeight
    }
}

extension DocsToolBar {
    // MARK: 📓Internal Supporting Method

    /*先注释 不是我写的 分配给我删除
    private func detectIfModelChanged(oldValue: [DocsBaseToolBarItem], newValue: [DocsBaseToolBarItem]) -> Bool {
        // 🌈实现比对算法可以优化性能
        return true
    }

    private func checkItemSelected() -> Int? {
        return items.firstIndex { return $0.info().isSelected }
    }
    */

    /*没用到，先注释
    private func initialItems() {
        items.forEach {
            $0.delegate = self
            if $0.type() == .panel {
                $0.attachViewInitSize = CGSize(width: self.frame.width, height: self.keyboardHeight)
            }
        }
    }
    */

    private func removeInputView() {
        sheetInputView.removeFromSuperview()
        sheetInputView.snp.removeConstraints()
    }

    private func putInputView(show: Bool) {
        insertSubview(sheetInputView, belowSubview: barContainerView)
        sheetInputView.snp.makeConstraints { (make) in
           make.leading.trailing.equalToSuperview()
           make.bottom.equalToSuperview().offset(0)
           make.height.equalTo(93)
        }
        sheetInputView.layoutIfNeeded()
        sheetInputView.alpha = show ? 1.0 : 0.0
    }

    private func onEditModeChanged(oldValue: EditMode) {
        if self.mode == .normal {
            removeInputView()
        } else if self.mode == .sheetInput {
            removeInputView()
            putInputView(show: false)
        }
    }

    // MARK: 📚SheetInputView Supporting Method
    private func setSheetInputViewVisible(to visible: Bool, animated: Bool, completion: (() -> Void)? = nil) {
        //guard sheetInputView.mode != .full else { return }
        let bottomOffset = visible ? 0 : sheetInputView.frame.height
        sheetInputView.snp.updateConstraints { (make) in
            make.bottom.equalToSuperview().offset(bottomOffset)
        }
        UIView.animate(withDuration: animated ? 0.25 : 0, animations: {
            self.sheetInputView.layoutIfNeeded()
            self.sheetInputView.alpha = visible ? 1.0 : 0.0
        }, completion: { _ in
            completion?()
        })
    }

    private func doReloadPanel() {
        if let view = currentPanel {
            let layoutView = layoutPanel(view)
            currentPanel = layoutView as? SKSubToolBarPanel
            changeInputView(currentPanel)
        } else {
            changeInputView(nil)
        }
    }

    /*
    private func panelView(at index: Int) -> UIView? {
        guard index >= 0, index <  items.count  else { return nil }
        guard items[index].type() == .panel else { return  nil }
        return loadPanel(with: items[index])
    }*/

    private func layoutPanel(_ panel: UIView) -> UIView {
        let panelView = panel
        var targetHeight = keyboardShowHeight
        if let toolPanel = panel as? SKSubToolBarPanel, let height = toolPanel.panelHeight {
            targetHeight = height
        }
        targetHeight = max(targetHeight, minimumPanelHeight + (userResolver.navigator.mainSceneWindow?.safeAreaInsets.bottom ?? 0))

        let heightConstraints = panelView.constraints.filter { ($0.firstItem === panelView) && ($0.firstAttribute == NSLayoutConstraint.Attribute.height) }
        if  heightConstraints.count > 0 {
            let constraint = heightConstraints[0]
            constraint.constant = targetHeight
            panelView.layoutIfNeeded()
        }
        panelView.frame = CGRect(origin: .zero, size: CGSize(width: frame.width, height: targetHeight))
        return panelView
    }

    /* ↓↓↓ Compatible with Docs && Sheet ↓↓↓ */
    @inline(__always)
    public func changeInputView(_ panel: UIView?) {
        switch mode {
        case .normal: delegate?.docsToolBar(self, changeInputView: panel)
        case .sheetInput: sheetInputView.inputView = panel
        }
    }

    @inline(__always)
    private func doEndEditing(byUser: Bool? = nil) {
        switch mode {
        case .sheetInput:
            setSheetInputViewVisible(to: false, animated: true)
            notifyDidHideSheetInputView()
            sheetInputView.onEndEditing(byUser: byUser ?? false)
        default:
            ()
        }
        delegate?.docsToolBarShouldEndEditing(self, editMode: mode, byUser: byUser ?? false)
    }
    /* ↑↑↑ Compatible with Docs && Sheet ↑↑↑ */
    private func onTapticFeedback() {
        guard useTapticEngine else { return }
        feedbackGenerator.prepare()
        feedbackGenerator.selectionChanged()
    }

    private func setupView() {
        self.snp.makeConstraints { (make) in
            make.height.equalTo(DocsToolBar.inherentHeight)
        }
        addSubview(barContainerView)
        barContainerView.snp.makeConstraints { (make) in
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(Const.inherentHeight)
        }
//        addSubview(bottomSeparateLine)
//        bottomSeparateLine.snp.makeConstraints { (make) in
//            make.leading.trailing.bottom.equalToSuperview()
//            make.height.equalTo(0.5)
//        }
        addSubview(safeAreaButtomMask)
        safeAreaButtomMask.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.snp.bottom)
            //iOS15.1系统外接键盘时的悬浮小键盘后面没有遮罩
            //需要加高safeAreaButtomMask的高度，避免后面的内容被透出来
            make.height.equalTo(74)
        }
    }

    @objc
    func hideSeparateLine() {
//        bottomSeparateLine.isHidden = true
    }

    @objc
    func showSeparateLine() {
//        bottomSeparateLine.isHidden = false
        //颜色选择面板退出的时候需要把二级工具栏重新展示出来
        (currentMain as? DocsMainToolBarV2)?.showAttachToolBar(true)
        (currentMain as? DocsMainToolBarV2)?.delegate?.hideHighlightView()
    }

    private func configure() {
        barContainerView.backgroundColor = .clear
        sheetInputView.heightInset = Const.inherentHeight
        layer.shadowOffset = CGSize(width: 0, height: -6)
        layer.shadowOpacity = 0.08
        layer.shadowRadius = 24
        isJustInit = false
        sheetInputView.uiDelegate = self
    }

    /// 当Sheet输入框隐藏时(进入其他面板也属于隐藏)，通知前端
    private func notifyDidHideSheetInputView() {
        self.sheetInputView.onKeyboardHide()
    }

    /// 当Sheet准备编辑时执行恢复编辑态的任务(状态量、响应者、UI更新)
    private func restoreSheetInputView(inputView: UIView? = nil) {
        guard mode == .sheetInput else { return }
        if !sheetInputView.isFirstResponder {
            setEditMode(to: .sheetInput, animated: false)
            beginSheetEdit(with: nil, autoHideKeyboard: false, animated: false, inputView: inputView)
        }
    }

    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.isHidden { return nil }
        if sheetInputView.mode != .full {
            if currentTitleView != nil {
                let titleResult = titleContainerView.hitTest(convert(point, to: titleContainerView), with: event)
                if titleResult != nil { return titleResult }
            }
            let selfResult = barContainerView.hitTest(convert(point, to: barContainerView), with: event)
            if selfResult != nil { return selfResult }
        }
        if mode == .sheetInput {
            let sheetResult = sheetInputView.hitTest(convert(point, to: sheetInputView), with: event)
            if sheetResult != nil { return sheetResult }
        }
        return nil
    }
}

extension DocsToolBar: SheetInputViewUIDelegate {
    public func inputViewWillHide(_ inputView: SheetInputView?) {
        
    }
    

    public func inputView(_ inputView: SheetInputView, changeMode mode: SheetInputView.SheetInputMode) {
        switch mode {
        case .basic, .multi:
            insertSubview(sheetInputView, belowSubview: barContainerView)
        case .full:
            bringSubviewToFront(sheetInputView)
        }
    }

    public func inputView(_ inputView: SheetInputView, updateHeight height: CGFloat, layoutNow: Bool) {
        self.sheetInputView.snp.updateConstraints { (make) in
            make.height.equalTo(height)
        }

        if layoutNow {
            sheetInputView.layoutIfNeeded()
            sheetInputView.superview?.layoutIfNeeded()
            self.layoutIfNeeded()
        }
    }

    /*没用到，先注释
    func inputView(_ inputView: SheetInputView, modify mode: SheetInputView.SheetInputMode, request height: CGFloat) {

        switch mode {
        case .basic, .multi:
            insertSubview(sheetInputView, belowSubview: barContainerView)
        case .full:
            bringSubviewToFront(sheetInputView)
        }

        DispatchQueue.main.async {
            self.sheetInputView.snp.updateConstraints { (make) in
                make.height.equalTo(height)
            }
            self.sheetInputView.layoutIfNeeded()
            self.layoutIfNeeded()
        }
    }
     */

    public func inputViewReceive(_ keyboardEvent: Keyboard.KeyboardEvent, options: Keyboard.KeyboardOptions) {
        //16.0上浮动键盘切为妙控后打开图片查看器时键盘事件有时是浮动键盘的位置和尺寸，先屏蔽
        if SKDisplay.pad, #available(iOS 16.0, *), UserScopeNoChangeFG.LJW.toolbarAdapterForKeyboard { return }
        if SKDisplay.pad, self.currentKeyboardDisplayType == .floating, options.displayType == .default {
            //ipad键盘displayType由float转为default切换一下相关工具栏二级面板（图片选择器）的展示
            delegate?.docsToolBarToggleDisplayTypeToDefault(self)
        } else if currentKeyboardDisplayType == .default, options.displayType == .floating {
            delegate?.docsToolBarToggleDisplayTypeToFloating(self, frame: options.endFrame)
        }
        self.currentKeyboardDisplayType = options.displayType
        DocsLogger.info("DocsToolBar received keyboard event: \(keyboardEvent)", component: LogComponents.toolbar)
    }
}

public extension DocsToolBar {
    enum ItemType {
        /// 带有菜单面板的Item
        case panel
        /// 点击后触发时间的Item
        case button
    }

    enum EditMode {
        /// 标准工具栏
        case normal
        /// 带有Sheet输入栏的工具栏
        case sheetInput
    }

    struct SheetInputInfo {
        var text: String?
    }

    struct Const {
        static let itemWidth: CGFloat = 44
        static let imageWidth: CGFloat = 24
        static let highlightColorWidth: CGFloat = 30
        static let displayColor: CGFloat = 18
        static let pickerColorWidth: CGFloat = 22
        static let pickerColorHeight: CGFloat = 4
        static let bgColorWidth: CGFloat = 36 // 选中态的 icon 的背景
        static let highlightCellInset: CGFloat = 3
        static let itemPadding: CGFloat = 8
        static let horPadding: CGFloat = 7
        static let staticHorPadding: CGFloat = 6
        static let separateWidth: CGFloat = 1
        static let separateVerPadding: CGFloat = 10
        static let inherentHeight: CGFloat = 44
        static let sheetInputViewHeight: CGFloat = 44
        static let iconCellId: String = "iconCellId"
        /// 预估键盘高度，用于当无法获取键盘高度且需要一个大致高度时
        // disable-lint: magic number
        static let estimateKeyboardHeight: CGFloat = SKDisplay.mainScreenBounds.height * 0.3
        // enable-lint: magic number
    }
}

extension DocsToolBar {
    public func convertMainItem(id: String, frameTo hostView: UIView?) -> CGRect? {
        guard let rect = currentMain?.getCellFrame(byToolBarItemID: id) else { return nil }
        return currentMain?.convert(rect, to: hostView)
    }

    public func scrollToItem(byID id: String) {
        currentMain?.rollToItem(byID: id)
    }

    func updateToolBarHeight(_ height: CGFloat) {
        self.snp.updateConstraints { (make) in
            make.height.equalTo(height)
        }
        barContainerView.snp.updateConstraints { (make) in
            make.height.equalTo(height)
        }
            
        self.superview?.layoutIfNeeded()
    }

    //把mainToolBar当做cointainer在这管理
    func attachMainTBPanel(_ panel: SKMainToolBarPanel) {
        self.isHidden = false
        currentMain = panel
        if barContainerView.subviews.contains(panel) { return }
        for view in barContainerView.subviews {
            if let mayBeTarget = view as? SKMainToolBarPanel {
                mayBeTarget.removeFromSuperview()
            }
        }
        barContainerView.addSubview(panel)
        panel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview()
            make.trailing.bottom.equalToSuperview()
            make.height.equalToSuperview()
        }
        //去掉工具栏初次显示时有概率出现的展开动画
        barContainerView.layoutIfNeeded()
        guard let info = delegate?.docsToolBarRequestDocsInfo(self) else {
            return
        }
        showToolBarView(info: info)
    }

    func changeSubTBPanel(_ panel: SKSubToolBarPanel) {
        willRestoreByKeyboard = false
        let noNeedReload = (panel === currentPanel && panel.frame.height == keyboardShowHeight && panel.canEqualToKeyboardHeight)
        if mode == .sheetInput {
            let newInputView = (sheetInputView.inputView == nil) ? panel : nil
            restoreSheetInputView(inputView: newInputView)
            setSheetInputViewVisible(to: false, animated: true)
        }
        if !noNeedReload {
            currentPanel?.snp.removeConstraints()
            let layoutedPanel = layoutPanel(panel)
            currentPanel = layoutedPanel as? SKSubToolBarPanel
        }
        changeInputView(currentPanel)

        if let mindNodeView = panel as? MindNoteAttributionView {
            mindNodeView.reloadColorWell()
            if let info = delegate?.docsToolBarRequestDocsInfo(self), !noNeedReload {
                self.docsShowFontColorView(info: info)
            }
        }
    }

    func attachDisplaySubTBPanel(_ panel: SKSubToolBarPanel) {
        guard let curMainPanel = currentMain else {
            return
        }
        currentDisplayPanel = panel
        if let subPanelHeight = panel.getCurrentDisplayHeight() {
            updateToolBarHeight(subPanelHeight)
        }
        let transition = CATransition()
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.type = .push
        transition.subtype = .fromRight
        panel.layer.add(transition, forKey: nil)
        curMainPanel.addSubview(panel)
        curMainPanel.bringSubviewToFront(panel)
        panel.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(self.safeAreaInsets.bottom)
        }
    }

    func setTitleView(_ titleView: UIView) {
        insertSubview(titleContainerView, aboveSubview: barContainerView)
        titleContainerView.snp.makeConstraints { (make) in
            make.edges.equalTo(barContainerView)
        }
        titleContainerView.addSubview(titleView)
        titleView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        currentTitleView = titleView
    }

    func removeTitleView() {
        currentTitleView?.removeFromSuperview()
        currentTitleView?.snp.removeConstraints()
        titleContainerView.removeFromSuperview()
        titleContainerView.snp.removeConstraints()
        currentTitleView = nil
    }

    func removeDisplayPanel() {
        currentDisplayPanel?.showRootView()
        currentDisplayPanel = nil
    }

    func clearSubPanel() {
        currentPanel?.snp.removeConstraints()
        currentPanel = nil
    }

    //替代onClickKeyboard
    func pressKeyboardItem(resign: Bool) {
        if resign && isSheetToolBarFloating {
            // 工具栏悬浮时，点击键盘按钮不用主动拉起来编辑，由前端驱动
//            willRestoreByKeyboard = true
//            if mode == .sheetInput { restoreSheetInputView() }
//            sheetInputView.beginEditWith(nil)
        } else if resign {
            willRestoreByKeyboard = false
            doEndEditing(byUser: true)
        } else {
            willRestoreByKeyboard = false
            changeInputView(nil)
            if mode == .sheetInput { setSheetInputViewVisible(to: true, animated: true) }
        }
    }

    //获取当前sheet输入框的高度
    func getSheetInputViewHeight() -> CGFloat {
        guard sheetInputView.alpha > 0 && sheetInputView.isHidden == false else { return 0 }
        return sheetInputView.frame.height
    }
}
