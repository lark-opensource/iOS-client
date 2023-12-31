//
//  WhiteboardViewController.swift
//  Whiteboard
//
//  Created by helijian on 2022/12/6.
//

import Foundation
import ByteViewNetwork
import ByteViewCommon
import UniverseDesignColor
import ByteViewUDColor
import UniverseDesignIcon
import LarkAlertController
import ByteViewUI
import UniverseDesignToast

public enum WhiteboardViewStyle: Equatable {
    case phone
    case ipad
}

public struct WhiteboardInitData {
    var clientConfig: WhiteboardClientConfig
    var canEdit: Bool
    var shouldShowMenuFirst: Bool
    var viewStyle: WhiteboardViewStyle
    var isFixedViewStyle: Bool
    var isSaveEnabled: Bool
    var defaultToolConfig: DefaultWhiteboardToolConfig
    var whiteboardInfo: WhiteboardInfo?

    public init(clientConfig: WhiteboardClientConfig,
                canEdit: Bool,
                shouldShowMenuFirst: Bool,
                viewStyle: WhiteboardViewStyle,
                isFixedViewStyle: Bool,
                isSaveEnabled: Bool,
                defaultToolConfig: DefaultWhiteboardToolConfig,
                whiteboardInfo: WhiteboardInfo? = nil) {
        self.clientConfig = clientConfig
        self.canEdit = canEdit
        self.shouldShowMenuFirst = shouldShowMenuFirst
        self.viewStyle = viewStyle
        self.isFixedViewStyle = isFixedViewStyle
        self.isSaveEnabled = isSaveEnabled
        self.defaultToolConfig = defaultToolConfig
        self.whiteboardInfo = whiteboardInfo
    }
}

public final class WhiteboardViewController: WhiteboardSnapshotBaseViewController {
    enum MeetingLayoutStyle: Int {
        case tiled = 1
        case overlay
        case fullscreen
    }
    let whiteboardView: WhiteboardView
    // 用于发请求
    let userId: String
    let maxPageCount: Int
    let whiteboardId: Int64
    let isSaveEnabled: Bool
    var gesture: WhiteboardGestRecognizer?
    // 是否需要放大画布（自己发起共享的需要）
    var shouldResetScale: Bool = false
    // 是否直接进入编辑模式(自己发起共享的需要以及小窗回来）
    var shouldShowMenuFirst: Bool
    // 只展示内容，不展示菜单
    var showContentOnly: Bool = false {
        didSet {
            self.setContentOnly()
        }
    }
    // 标志是否为固定的style, 如手机只有固定的phone style
    private var isFixedViewStyle: Bool
    // 白板view类型，主要为了适配iPad的分屏
    var viewStyle: WhiteboardViewStyle
    // 适配沉浸态（修改菜单按钮位置以及可拖动区域）
    var currentMeetingLayoutStyle: MeetingLayoutStyle = .tiled {
        didSet {
            guard oldValue != currentMeetingLayoutStyle else { return }
            if Display.pad, viewStyle == .ipad {
                adaptMeetingLayoutChange()
            }
        }
    }

    // MARK: 手机模式工具栏
    var hasActivateTool: Bool = false
    // 用于在手机多白板展示期间，reload snapCell
    weak var snapShotVC: WhiteboardPhoneSnapshotViewController?
    weak var moreVC: WhiteboardMoreViewController?
    // 用于作为shareBar提供给会议框架布局
    public var phoneToolBarGuide: UILayoutGuide?
    // 用于协助菜单按钮确定位置布局
    public var bottomBarGuide: UILayoutGuide = UILayoutGuide()

    public var isPhoneToolbarVisible: Bool {
        return !phoneToolBar.isHidden
    }

    lazy var phoneToolBar: WhiteboardPhoneToolBar = {
        let toolBar = WhiteboardPhoneToolBar(shouldShowMenuFirst: self.shouldShowMenuFirst, toolConfig: DefaultWhiteboardToolConfig(pen: self.currentPenToolConfig, highlighter: self.currentHighlighterToolConfig, shape: self.currentShapeToolConfig), whiteboardId: whiteboardId)
        toolBar.isHidden = true
        toolBar.delegate = self
        return toolBar
    }()

    // MARK: 手机模式菜单开关按钮
    // 有无编辑权限（按钮能否展示）
    var canEdit: Bool = false
    var isDragging = false
    var panOffsetX: CGFloat = 0
    var panOffsetY: CGFloat = 0
    var dragbleMargin = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    lazy var showMenuButton: UIView = {
        let button = UIButton()
        button.backgroundColor = UIColor.ud.bgFloat
        button.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
        button.layer.borderWidth = 0.5
        button.layer.cornerRadius = 24
        button.layer.masksToBounds = true
        button.layer.shadowRadius = 20
        button.layer.shadowOffset = CGSize(width: 0, height: 8)
        button.layer.shadowOpacity = 1
        button.layer.shadowColor = UIColor.ud.vcTokenVCShadowSm.cgColor
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        button.addGestureRecognizer(pan)
        button.setImage(UDIcon.getIconByKey(.penOutlined, iconColor: .ud.iconN2, size: CGSize(width: 22, height: 22)), for: .normal)
        button.addTarget(self, action: #selector(didTapMenuButton), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    // MARK: pad模式工具栏
    enum Layout {
        static let itemSize: CGSize = CGSize(width: 172, height: 97)
        static let itemMinimumLineSpacing: CGFloat = 12
        static let containViewWidth: CGFloat = 204
        static let multiButtonSize: CGSize = CGSize(width: 77, height: 48)
    }

    enum PagesLayoutStyle {
        case adaption(CGFloat)
        case maxHeight
    }

    var ipadItems: [WhiteboardSnapshotItem] = []
    // 工具栏配置
    var currentPenToolConfig: BrushAndColorMemory
    var currentHighlighterToolConfig: BrushAndColorMemory
    var currentShapeToolConfig: ShapeTypeAndColor
    var currentTool: ActionToolType = .move
    // 页面展示状态，用于确定高度
    var pagesLayoutStyle: PagesLayoutStyle = .maxHeight

    // 多白板按钮图像
    let unFoldImage = UDIcon.getIconByKey(.multiBoardOutlined, renderingMode: .alwaysOriginal, iconColor: UIColor.ud.primaryContentDefault, size: CGSize(width: 20, height: 20))
    let foldImage = UDIcon.getIconByKey(.multiBoardOutlined, renderingMode: .alwaysOriginal, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20))

    lazy var multiPageButton: UIButton = {
        var button = UIButton()
        button.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        button.layer.cornerRadius = 24
        button.layer.borderColor = UIColor.ud.lineBorderComponent.cgColor
        button.layer.borderWidth = 1
        button.setImage(self.foldImage, for: .normal)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitle("", for: .normal)
        button.isHidden = false
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        button.addTarget(self, action: #selector(showMultiPages), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    private var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = Layout.itemSize
        layout.minimumLineSpacing = Layout.itemMinimumLineSpacing
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16)
        return layout
    }()

    lazy var collectionView: UICollectionView = {
        let collection = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.layout)
        collection.backgroundColor = UIColor.clear
        collection.showsVerticalScrollIndicator = true
        collection.showsHorizontalScrollIndicator = false
        collection.register(WhiteboardIPadSnapshotCell.self, forCellWithReuseIdentifier: WhiteboardIPadSnapshotCell.description())
        collection.delegate = self
        collection.dataSource = self
        collection.alwaysBounceVertical = true
        collection.isScrollEnabled = true
        collection.bounces = true
        return collection
    }()

    // 多白板容器view
    lazy var containView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()

    private lazy var line: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    // 新建白板页面
    lazy var createPageButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor.clear
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.ud.primaryContentDefault.cgColor
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitle(BundleI18n.Whiteboard.View_MV_NewBoardsButton, for: .normal)
        button.addTarget(self, action: #selector(createPage), for: .touchUpInside)
        return button
    }()

    // 创建白板的时候可能需要loading
    lazy var loadingView = LoadingView(frame: CGRect(x: 0, y: 0, width: 36, height: 36), style: .white)

    // 工具栏
    lazy var iPadToolBar: WhiteboardIPadToolBar = {
        let tool = WhiteboardIPadToolBar(isSharer: self.shouldShowMenuFirst,
                                         whiteboardId: whiteboardId,
                                         isSaveEnabled: isSaveEnabled)
        tool.delegate = self
        tool.isHidden = true
        return tool
    }()

    lazy var iPadShapeTool: ToolAndColorView = {
        let tool = ToolAndColorView(toolWithColorType: .shape)
        tool.isHidden = true
        tool.delegate = self
        return tool
    }()

    lazy var iPadBrushAndColorView: ToolAndColorView = {
        let view = ToolAndColorView(toolWithColorType: .brush)
        view.delegate = self
        view.isHidden = true
        return view
    }()

    lazy var iPadEraserView: EraserView = {
        let view = EraserView(isSharer: self.whiteboardView.isSelfSharing())
        view.delegate = self
        view.isHidden = true
        return view
    }()

    lazy var iPadSaveView: UIView = {
        let containerView = UIView()
        containerView.clipsToBounds = true
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
        containerView.layer.cornerRadius = 6
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowOpacity = 1
        containerView.layer.shadowColor = UIColor.ud.vcTokenVCShadowSm.cgColor
        containerView.backgroundColor = .ud.bgFloat
        containerView.isHidden = true

        let view = UIStackView(arrangedSubviews: [saveCurrentButton, saveAllButton])
        view.axis = .vertical
        view.alignment = .fill
        view.spacing = 1

        containerView.addSubview(view)
        view.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(5)
            $0.left.right.equalToSuperview().inset(4)
        }
        [saveCurrentButton, saveAllButton].forEach { button in
            button.snp.makeConstraints {
                $0.height.equalTo(40)
            }
        }

        return containerView
    }()

    // 保存当前白板
    lazy var saveCurrentButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.setBackgroundColor(.clear, for: .normal)
        button.setBackgroundColor(.ud.fillHover, for: .highlighted)
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitle(BundleI18n.Whiteboard.View_G_SaveThisWhiteBoard_Button, for: .normal)
        button.contentEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8)
        button.addTarget(self, action: #selector(didTapSaveCurrent), for: .touchUpInside)
        return button
    }()

    // 保存所有白板
    lazy var saveAllButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.setBackgroundColor(.clear, for: .normal)
        button.setBackgroundColor(.ud.fillHover, for: .highlighted)
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitle(BundleI18n.Whiteboard.View_G_SaveAllWhiteBoard_Button, for: .normal)
        button.contentEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8)
        button.addTarget(self, action: #selector(didTapSaveAll), for: .touchUpInside)
        return button
    }()

    private func setupPhoneLayout() {
        self.whiteboardView.touchEventDelegate = self
        view.addSubview(phoneToolBar)
        phoneToolBar.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview().priority(.required)
        }
        view.addSubview(showMenuButton)
        setShowButtonLayout()
        phoneToolBarGuide = UILayoutGuide()
        view.addLayoutGuide(phoneToolBarGuide!)
        phoneToolBarGuide?.snp.makeConstraints { maker in
            maker.edges.equalTo(phoneToolBar)
        }
    }

    private func setupIPadLayout() {
        view.addSubview(multiPageButton)
        multiPageButton.snp.makeConstraints { maker in
            maker.right.equalToSuperview().inset(16)
            maker.bottom.equalTo(whiteboardView.snp.bottom).offset(-24)
            maker.size.equalTo(Layout.multiButtonSize)
        }
        view.addSubview(containView)
        containView.snp.makeConstraints { maker in
            maker.right.equalToSuperview().inset(16)
            maker.bottom.equalTo(multiPageButton.snp.top).offset(-8)
            maker.width.equalTo(Layout.containViewWidth)
            if case .adaption(let height) = pagesLayoutStyle {
                maker.height.equalTo(height)
            } else {
                maker.top.equalToSuperview().inset(12)
            }
        }
        containView.addSubview(createPageButton)
        createPageButton.snp.makeConstraints { maker in
            maker.left.right.bottom.equalToSuperview().inset(16)
        }
        containView.addSubview(line)
        line.snp.makeConstraints { maker in
            maker.height.equalTo(1)
            maker.left.right.equalToSuperview()
            maker.bottom.equalTo(createPageButton.snp.top).offset(-19)
        }
        containView.addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview()
            maker.top.equalToSuperview()
            maker.bottom.equalTo(line.snp.top).offset(-3)
        }
        view.addSubview(iPadToolBar)
        iPadToolBar.snp.makeConstraints { maker in
            maker.left.equalToSuperview().inset(12)
            maker.top.equalToSuperview().inset(12)
        }
        view.addSubview(iPadBrushAndColorView)
        iPadBrushAndColorView.configSelection(selection: currentPenToolConfig)
        iPadBrushAndColorView.snp.makeConstraints { maker in
            maker.left.equalTo(iPadToolBar.snp.right).offset(4)
            maker.top.equalTo(iPadToolBar.snp.top).offset(50)
            maker.size.equalTo(CGSize(width: 182, height: 227))
        }
        view.addSubview(iPadShapeTool)
        iPadShapeTool.configShapeTool(shapeToolConfig: currentShapeToolConfig)
        iPadShapeTool.snp.makeConstraints { maker in
            maker.left.equalTo(iPadToolBar.snp.right).offset(4)
            maker.top.equalTo(iPadToolBar.snp.top).offset(138)
            maker.size.equalTo(CGSize(width: 182, height: 277))
        }
        view.addSubview(iPadEraserView)
        iPadEraserView.snp.makeConstraints { maker in
            maker.left.equalTo(iPadToolBar.snp.right).offset(4)
            maker.top.equalTo(iPadToolBar.snp.top).offset(182)
        }

        view.addSubview(iPadSaveView)
        iPadSaveView.snp.makeConstraints {
            $0.left.equalTo(iPadToolBar.snp.right).offset(4)
            $0.top.equalTo(iPadToolBar.snp.top).offset(314)
        }
    }

    // 隐藏各种工具栏以及按钮，只展示白板页面
    private func setContentOnly() {
        DispatchQueue.main.async {
            if self.showContentOnly {
                self.showMenuButton.isHidden = true
                self.phoneToolBar.isHidden = true
                self.iPadToolBar.isHidden = true
                self.multiPageButton.isHidden = true
                self.containView.isHidden = true
                self.multiPageButton.setImage(self.foldImage, for: .normal)
                self.multiPageButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
                self.setFailofGestRecognizer(shouldReceive: false)
            } else if self.canEdit {
                if case .ipad = self.viewStyle {
                    self.multiPageButton.isHidden = false
                    self.iPadToolBar.isHidden = false
                    self.setFailofGestRecognizer(shouldReceive: self.currentTool != .move)
                }
            } else {
                self.setFailofGestRecognizer(shouldReceive: false)
            }
        }
    }

    // 如果是共享者，配置默认工具
    func configDefaultTool(manualy: Bool = false) {
        if shouldShowMenuFirst || manualy {
            currentTool = .pen
            self.whiteboardView.setTool(tool: .Pencil)
            self.whiteboardView.setStrokeWidth(currentPenToolConfig.brushType.brushValue)
            self.whiteboardView.setColor(currentPenToolConfig.color)
            if manualy, viewStyle == .phone {
                self.phoneToolBar.configBar(tool: .pen)
            }
            hasActivateTool = true
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(whiteboardView)
        // 设置代理用于处理白板事件，如undo,redo,snapshot等
        whiteboardView.setWhiteboardViewDelegate(delegate: self)
        whiteboardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        var shouldLoadPhoneLayout: Bool = false
        var shouldLoadIPadLayout: Bool = false
        if isFixedViewStyle {
            switch viewStyle {
            case .phone:
                shouldLoadPhoneLayout = true
            case .ipad:
                shouldLoadIPadLayout = true
            }
        } else {
            // 非固定模式（ipad)，存在两种模式切换的可能，因此都需要加入到视图
            shouldLoadPhoneLayout = true
            shouldLoadIPadLayout = true
        }
        view.addLayoutGuide(bottomBarGuide)
        // 添加手机工具栏
        if shouldLoadPhoneLayout {
            setupPhoneLayout()
        }
        // 添加pad工具栏
        if shouldLoadIPadLayout {
            setupIPadLayout()
        }
        configDefaultTool()
        if Display.phone {
            self.setFailofGestRecognizer(shouldReceive: false)
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if case .ipad = viewStyle {
            whiteboardView.getMultiPageInfo()
        }
        setContentOnly()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldResetScale {
            whiteboardView.setLayerScale(true)
            shouldResetScale = false
        }
        if case .phone = viewStyle, !showContentOnly, canEdit {
            changeWhiteboardPhoneMenuHiddenStatus(to: !showMenuButton.isHidden, isUpdate: true)
        }
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let point = self.iPadToolBar.convert(CGPoint(x: iPadToolBar.frame.width, y: iPadToolBar.frame.height), to: whiteboardView)
        // 非ipad模式要禁止工具栏笔画不能穿透
        if viewStyle == .ipad {
            whiteboardView.setToolBarPoint(point: point)
        } else {
            whiteboardView.setToolBarPoint(point: nil)
            setShowButtonLayout()
        }
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
                whiteboardView.changeTheme(theme: traitCollection.userInterfaceStyle)
                if viewStyle == .phone {
                    phoneToolBar.resetDetailToolContainerViewBoardColor()
                    showMenuButton.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
                }
            }
        }
    }

    public init(clientConfig: WhiteboardClientConfig,
                canEdit: Bool,
                shouldShowMenuFirst: Bool,
                viewStyle: WhiteboardViewStyle,
                isFixedViewStyle: Bool,
                isSaveEnabled: Bool,
                defaultToolConfig: DefaultWhiteboardToolConfig,
                whiteboardInfo: WhiteboardInfo?) {
        self.userId = clientConfig.account.id
        self.maxPageCount = clientConfig.maxPageCount
        self.shouldShowMenuFirst = shouldShowMenuFirst
        self.viewStyle = viewStyle
        self.isFixedViewStyle = isFixedViewStyle
        self.isSaveEnabled = isSaveEnabled
        self.canEdit = canEdit
        self.whiteboardId = whiteboardInfo?.whiteboardID ?? 0
        self.currentPenToolConfig = defaultToolConfig.penBrushAndColor
        self.currentShapeToolConfig = defaultToolConfig.shapeTypeAndColor
        self.currentHighlighterToolConfig = defaultToolConfig.highlighterBrushAndColor
        self.whiteboardView = WhiteboardView(clientConfig: clientConfig, viewStyle: viewStyle, whiteboardInfo: whiteboardInfo)
        super.init(nibName: nil, bundle: nil)
        if let whiteboardInfo = whiteboardInfo, whiteboardInfo.sharer == clientConfig.account {
            shouldResetScale = true
        }
        currentTool = shouldShowMenuFirst ? .pen : .move
    }

    public convenience init(initData: WhiteboardInitData) {
        self.init(clientConfig: initData.clientConfig,
                  canEdit: initData.canEdit,
                  shouldShowMenuFirst: initData.shouldShowMenuFirst,
                  viewStyle: initData.viewStyle,
                  isFixedViewStyle: initData.isFixedViewStyle,
                  isSaveEnabled: initData.isSaveEnabled,
                  defaultToolConfig: initData.defaultToolConfig,
                  whiteboardInfo: initData.whiteboardInfo)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Public
extension WhiteboardViewController {
    public func changeMeetingLayoutStyle(to style: Int) {
        self.currentMeetingLayoutStyle = MeetingLayoutStyle(rawValue: style) ?? .tiled
    }

    public func configDependencies(_ dependencies: Dependencies? = nil) {
        self.whiteboardView.configDependencies(dependencies)
    }

    public func configDataDelegate(delegate: WhiteboardDataDelegate) {
        whiteboardView.setWhiteboardDataDelegate(delegate: delegate)
    }

    public func setShowContentOnly(isOnly: Bool) {
        self.showContentOnly = isOnly
    }

    public func shouldShowMenuFromFloatingWindow(shouldShow: Bool) {
        self.shouldShowMenuFirst = shouldShow
    }

    public func setFailofGestRecognizer(shouldReceive: Bool) {
        if #available(iOS 13.0, *) {
            self.whiteboardView.gesture?.shouldReceiveEvent = shouldReceive
        } else {
            self.whiteboardView.reConfigGesture(shouldReceive: shouldReceive)
        }
    }

    public func setLayerMiniScale() {
        self.whiteboardView.setMiniScale()
    }

    public func dismissPresentedViewController() {
        self.snapShotVC?.dismiss(animated: false)
        self.moreVC?.dismiss(animated: false)
    }

    public func setNewViewLayoutStyle(_ viewStyle: WhiteboardViewStyle, _ forceUpdate: Bool = false) {
        guard (viewStyle != self.viewStyle && !isFixedViewStyle) || forceUpdate else { return }
        self.viewStyle = viewStyle
        self.whiteboardView.viewStyle = viewStyle
        self.shouldShowMenuFirst = false
        logger.info("setNewViewLayoutStyle \(viewStyle) \(self.showContentOnly) \(self.canEdit)")
        switch viewStyle {
        case .phone:
            self.phoneToolBar.configToolBarWithCurentSettings(pen: currentPenToolConfig, highlighter: currentHighlighterToolConfig, shape: currentShapeToolConfig, currentTool: currentTool)
            if currentTool == .move {
                // 打开菜单时，需要重新配置当前菜单设置
                self.hasActivateTool = false
            }
            self.iPadToolBar.isHidden = true
            self.iPadShapeTool.isHidden = true
            self.iPadBrushAndColorView.isHidden = true
            self.iPadEraserView.isHidden = true
            self.iPadSaveView.isHidden = true
            self.multiPageButton.setImage(self.foldImage, for: .normal)
            self.multiPageButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
            self.multiPageButton.isHidden = true
            self.containView.isHidden = true
            setShowButtonLayout()
            self.showMenuButton.isHidden = (self.showContentOnly || !self.canEdit || currentTool == .move)
            if !self.showContentOnly, self.canEdit, currentTool != .move {
                self.phoneToolBar.isHidden = false
                changeWhiteboardPhoneMenuHiddenStatus(to: false)
            } else {
                self.phoneToolBar.isHidden = true
                self.setFailofGestRecognizer(shouldReceive: false)
            }
        case .ipad:
            changeWhiteboardPhoneMenuHiddenStatus(to: true)
            whiteboardView.getMultiPageInfo()
            self.iPadToolBar.configCurrentTool(tool: currentTool)
            self.iPadToolBar.isHidden = (self.showContentOnly || !self.canEdit)
            self.multiPageButton.isHidden = (self.showContentOnly || !self.canEdit)
            self.phoneToolBar.isHidden = true
            self.showMenuButton.isHidden = true
            self.setFailofGestRecognizer(shouldReceive: currentTool != .move && !iPadToolBar.isHidden)
            self.dismiss(animated: false)
        }
    }
}

// MARK: 用于外部调用设置whiteboard的部分参数或者属性
extension WhiteboardViewController {
    public func receiveWhiteboardInfo(_ info: WhiteboardInfo) {
        whiteboardView.receiveWhiteboardInfo(info)
    }

    public func setScrollViewBgColor(_ color: UIColor) {
        whiteboardView.scrollViewBgColor = color
    }

    public func didChangeEditAuthority(canEdit: Bool) {
        guard self.canEdit != canEdit else { return }
        if self.showContentOnly {
            self.canEdit = canEdit
            return
        }
        logger.info("didChangeEditAuthority showContentOnly: \(showContentOnly), canEdit: \(canEdit)")
        DispatchQueue.main.async {
            if self.canEdit {
                UDToast.showToast(with: UDToastConfig(toastType: .info, text: BundleI18n.Whiteboard.View_G_WithdrawEditBoardPermit, operation: nil), on: self.view)
            }
            self.canEdit = canEdit
            switch self.viewStyle {
            case .phone:
                if !canEdit {
                    self.phoneToolBar.isHidden = true
                    self.showMenuButton.isHidden = true
                    self.changeWhiteboardPhoneMenuHiddenStatus(to: true)
                } else {
                    self.showMenuButton.isHidden = false
                    self.phoneToolBar.isHidden = true
                    self.setFailofGestRecognizer(shouldReceive: false)
                }
            case .ipad:
                self.iPadToolBar.isHidden = !canEdit
                self.multiPageButton.isHidden = !canEdit
                self.iPadShapeTool.isHidden = true
                self.iPadBrushAndColorView.isHidden = true
                self.iPadEraserView.isHidden = true
                self.iPadSaveView.isHidden = true
                self.setFailofGestRecognizer(shouldReceive: (canEdit && self.currentTool != .move))
            }
            if !self.canEdit {
                self.dismiss(animated: false)
            }
        }
    }
}


extension WhiteboardViewController: WhiteboardViewDelegate {
    func changeUndoState(canUndo: Bool) {
        switch viewStyle {
        case .phone:
            self.changePhoneUndoState(canUndo: canUndo)
        case .ipad:
            self.changeIPadUndoState(canUndo: canUndo)
        }
    }

    func changeRedoState(canRedo: Bool) {
        if case .ipad = viewStyle {
            changeIpadRedoState(canRedo: canRedo)
        }
    }

    // 展示多白板时，拉数据需要时间，用于刷新多白板的某个cell，期间处于loading状态
    func shouldReloadSnapshot(item: WhiteboardSnapshotItem) {
        logger.info("shouldReloadSnapshot \(item.index) \(item.state)")
        switch viewStyle {
        case .phone:
            self.shouldReloadPhoneSnapshot(item: item)
        case .ipad:
            self.shouldReloadIpadSnapshot(item: item)
        }
    }

    // 用于更新多白板页面的选择框
    func changeMultiPageInfo(currentPageNum: Int32, totalPages: Int) {
        logger.info("changeMultiPageInfo \(currentPageNum) \(totalPages)")
        switch viewStyle {
        case .ipad:
            changeIpadMultiPageInfo(currentPageNum: currentPageNum, totalPages: totalPages)
        default:
            break
        }
    }

    // reload 多白板页面
    func shouldReloadTotalSnapshot() {
        logger.info("shouldReloadTotalSnapshot \(viewStyle)")
        switch viewStyle {
        case .phone:
            shouldReloadPhoneTotalSnapshot()
        case .ipad:
            shouldReloadIpadTotalSnapshot()
        }
    }

    // 用于将ipad页面的多白板以及二级菜单隐藏以及降低手机工具栏透明度。
    func changeDrawingState(isDrawing: Bool) {
        changeIpadDrawingState(isDrawing: isDrawing)
        whiteboardTouchDrawTracking(isDrawing: isDrawing)
    }

    func whiteboardTouchDrawTracking(isDrawing: Bool) {
        DispatchQueue.main.async {
            if isDrawing {
                // nolint-next-line: magic number
                UIView.animate(withDuration: 0.25, animations: {
                    self.phoneToolBar.alpha = 0.3
                })
            } else {
                // nolint-next-line: magic number
                UIView.animate(withDuration: 0.25, animations: {
                    self.phoneToolBar.alpha = 1
                })
            }
        }
    }
}

extension WhiteboardViewController: ToolBarActionDelegate {

    var hasMultiBoards: Bool {
        whiteboardView.hasMultiBoards
    }

    func didTapUndo() {
        whiteboardView.didTapUndo()
    }

    func didTapRedo() {
        whiteboardView.didTapRedo()
    }

    @objc func didTapSaveCurrent() {
        if whiteboardView.hasMultiBoards {
            WhiteboardTracks.trackBoardClick(.saveCurrent, whiteboardId: whiteboardId, isSharer: whiteboardView.isSelfSharing())
        } else {
            WhiteboardTracks.trackBoardClick(.save, whiteboardId: whiteboardId, isSharer: whiteboardView.isSelfSharing())
        }
        whiteboardView.saveCurrent()
        iPadSaveView.isHidden = true
        iPadToolBar.configCurrentTool(tool: .create(with: whiteboardView.currentTool))
    }

    @objc func didTapSaveAll() {
        WhiteboardTracks.trackBoardClick(.saveAll, whiteboardId: whiteboardId, isSharer: whiteboardView.isSelfSharing())
        whiteboardView.saveAll()
        iPadSaveView.isHidden = true
        iPadToolBar.configCurrentTool(tool: .create(with: whiteboardView.currentTool))
    }

    func didChangeToolType(toolType: ActionToolType) {
        if [.rectangle, .ellipse, .triangle, .line, .arrow].contains(toolType) {
            currentTool = .shape
        }
        if [.pen, .highlighter, .shape, .save].contains(toolType) {
            currentTool = toolType
        }
        switch viewStyle {
        case .phone:
            didChangePhoneToolType(toolType: toolType)
        case .ipad:
            didChangeIPadToolType(toolType: toolType)
        }
    }

    func didTapActionWithSelectedState(action: ActionToolType) {
        switch viewStyle {
        case .ipad:
            didTapIPadActionWithSelectedState(action: action)
        case .phone:
            break
        }
    }

    func didTapMore() {
        switch viewStyle {
        case .phone:
            didTapPhoneMore()
        case .ipad:
            break
        }
    }

    func didTapExit() {
        switch viewStyle {
        case .phone:
            didTapPhoneExit()
        case .ipad:
            break
        }
    }

    func didTapEraser() {
        currentTool = .eraser
        switch viewStyle {
        case .phone:
            didTapPhoneEraser()
        case .ipad:
            didTapIPadEraser()
        }
    }

    func didChangeColor(color: ColorType) {
        switch viewStyle {
        case .phone:
            didChangePhoneColor(color: color)
        case .ipad:
            break
        }
    }

    func didChangeBrushType(brushType: BrushType) {
        switch viewStyle {
        case .phone:
            didChangePhoneBrushType(brushType: brushType)
        case .ipad:
            break
        }
    }

    func didChangeShapeType(shapeTool: ActionToolType) {
        switch viewStyle {
        case .phone:
            didChangePhoneShapeType(shapeTool: shapeTool)
        case .ipad:
            break
        }
    }

    func didTapMove() {
        currentTool = .move
        switch viewStyle {
        case .ipad:
            didTapIPadMove()
        case .phone:
            break
        }
    }

    // 配置arrow,line的填充色
    func configShapeToSDK(shape: ActionToolType) {
        switch shape {
        case .line, .arrow:
            whiteboardView.setFillColor(currentShapeToolConfig.color)
        default:
            whiteboardView.setFillColor()
        }
    }
}
