//
//  UDActionSheet.swift
//  UniverseDesignActionPanel
//
//  Created by 姚启灏 on 2020/10/29.
//

import Foundation
import UniverseDesignPopover
import UIKit
import UniverseDesignFont

// MARK: UDActionSheet 方法接口
public extension UDActionSheet {
    /// ActionSheet Set Title
    /// - Parameter title: Title
    func setTitle(_ title: String) {
        self.setTitle(title, font: SheetCons.titleFont)
    }
    /// ActionSheet Set Title, alignment
    /// - Parameter title: Title
    /// - Parameter alignment: Title alignment
    func setTitle(_ title: String, alignment: NSTextAlignment = .center) {
        self.setTitle(title, font: SheetCons.titleFont, alignment: alignment)
    }

    /// ActionSheet Set Title
    /// - Parameter title: Title
    /// - Parameter font: title font
    func setTitle(_ title: String, font: UIFont) {
        self.setTitle(title, font: font, alignment: .center)
    }

    /// ActionSheet Set Title
    /// - Parameter title: Title
    /// - Parameter font: title font
    func setTitle(_ title: String, font: UIFont, alignment: NSTextAlignment) {
        let fontFigmaHeight = font.figmaHeight
        let baselineOffset = (fontFigmaHeight - font.lineHeight) / 2.0 / 2.0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = fontFigmaHeight
        paragraphStyle.maximumLineHeight = fontFigmaHeight
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = alignment
        self._titleViewAlignment = alignment
        titleView.attributedText = NSAttributedString(
            string: title,
            attributes: [
                .baselineOffset: baselineOffset,
                .paragraphStyle: paragraphStyle,
                .foregroundColor: config.titleColor,
                .font: font
            ]
          )
    }

    /// Add Item
    /// - Parameter item: UDActionSheetItem
    func addItem(_ item: UDActionSheetItem) {
        switch item.style {
        case .cancel:
            self.cancelItem = item
        case .default, .destructive:
            self.defaultItems.append(item)
        }
    }

    /// Add Default Item
    /// - Parameters:
    ///   - text: Default Item text
    ///   - action: tap action
    func addDefaultItem(text: String, action: (() -> Void)? = nil) {
        let item = UDActionSheetItem(title: text,
                                     style: .default,
                                     action: action)
        self.addItem(item)
    }

    /// Add Destructive Item
    /// - Parameters:
    ///   - text: Destructive Item text
    ///   - action: tap action
    func addDestructiveItem(text: String, action: (() -> Void)? = nil) {
        let item = UDActionSheetItem(title: text,
                                     style: .destructive,
                                     action: action)
        self.addItem(item)
    }

    /// Add RedCancel Item
    /// - Parameters:
    ///   - text: RedCancel Item text
    ///   - action: tap action
    func setRedCancelItem(text: String, action: (() -> Void)? = nil) {
        let item = UDActionSheetItem(title: text,
                                     titleColor: UDActionPanelColorTheme.acPrimaryBtnErrorColor,
                                     style: .cancel,
                                     action: action)
        self.addItem(item)
    }

    /// Add Cancel Item
    /// - Parameters:
    ///   - text: Cancel Item text
    ///   - action: tap action
    func setCancelItem(text: String, action: (() -> Void)? = nil) {
        let item = UDActionSheetItem(title: text,
                                     titleColor: UDActionPanelColorTheme.acPrimaryBtnNormalColor,
                                     style: .cancel,
                                     action: action)
        self.addItem(item)
    }

    /// Remove Items
    func removeAllItem() {
        self.cancelItem = nil
        self.defaultItems = []
    }

    /// 是否在 转屏 / 分屏 时关闭 actionSheet
    func dismissWhenViewTransition(_ isActionSheetDismissedWhenWillTransition: Bool) {
        self.isActionSheetDismissedWhenWillTransition = isActionSheetDismissedWhenWillTransition
    }
}

// MARK: UDActionSheet 初始化
open class UDActionSheet: UIViewController {
    /// UDActionSheet UI 配置
    public let config: UDActionSheetUIConfig
    /// UDActionSheet 关闭回调
    public var dismissCallback: (() -> Void)?

    /// 初始化方法
    /// - Parameter config: UDActionSheetUIConfig
    public init(config: UDActionSheetUIConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.setTransitioningDelegate()
    }
    
    /// 是否支持自动旋转
    @available(*, deprecated, message: "Use overrideSupportedInterfaceOrientations to support More Orientation")
    public var isAutorotatable: Bool = false {
        didSet {
            if isAutorotatable {
                overrideSupportedInterfaceOrientations = .allButUpsideDown
            } else {
                overrideSupportedInterfaceOrientations = .portrait
            }
        }
    }

    /// 业务指定 UDDialog 支持的旋转方向，默认为 .portrait
    public var overrideSupportedInterfaceOrientations: UIInterfaceOrientationMask = .portrait

    internal var _titleViewAlignment: NSTextAlignment = .center

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return overrideSupportedInterfaceOrientations
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.initView()
        self.addTapGesture()
        if isPopover {
            currentStyle = .popover
        } else if isAlert {
            currentStyle = .alert
        } else {
            currentStyle = .actionSheet
        }
    }

    /// 初始化视图
    private func initView() {
        titleView.addSubview(dividerViewUnderTitle)
        primaryView.addSubview(titleView)
        primaryView.addSubview(listItemView)
        cancelView.addSubview(cancelButton)
        containerView.addSubview(primaryView)
        containerView.addSubview(dividerViewUnderListItems)
        containerView.addSubview(cancelView)
        self.view.addSubview(containerView)

        setContainerView()
        setPrimaryView()
        setTitleView()
        setListItemView()
        setCancelView()
    }

    /// 设置转场代理
    private func setTransitioningDelegate() {
        switch config.style {
        case .normal:
            self.transitioningDelegate = normalTransition
        case .autoPopover(let popSource):
            self.popoverTransition = UDPopoverTransition(sourceView: popSource.sourceView,
                                                         sourceRect: popSource.sourceRect,
                                                         permittedArrowDirections: popSource.arrowDirection,
                                                         dismissCompletion: transitionDismissCompletion)
            self.transitioningDelegate = popoverTransition
            self.popoverPresentationController?.permittedArrowDirections = popSource.arrowDirection
            self.popoverPresentationController?.sourceView = popSource.sourceView
            self.popoverPresentationController?.sourceRect = popSource.sourceRect
        case .autoAlert:
            self.alertTransition = UDAlertTransition(dismissCompletion: transitionDismissCompletion)
            self.transitioningDelegate = alertTransition
        }
    }

    // config.style为原始style，currentStyle当前style
    private var currentStyle: ConfigStyle = .actionSheet {
        didSet {
            guard oldValue.rawValue != currentStyle.rawValue else { return }
            // 根据当前展示的样式，改变present的动画
            // 因为当前只有alert情况下会改变，所以只对alertTransition的动画改变
            switch currentStyle {
            case .popover:
                break
            case .alert:
                // 如果展示alert，动画是缩放效果
                self.alertTransition?.presentTransform = .scale
            case .actionSheet:
                // 如果是actionSheet，动画是平移效果
                self.alertTransition?.presentTransform = .translation
            }
        }
    }

    /// UI padding
    private var padding = 12
    private var titleTopPadding = 16
    private var titleBottomPadding = 16.5
    /// ListItemView Cell Height
    private var cellHeight = 48
    /// title 分割线高度
    private var lineHeight = 0.5
    /// alert 样式 divider 分割线高度
    private var dividerHeight = 8
    /// 自定义转场变换 - actionsheet
    private let normalTransition = UDActionSheetTransition()
    /// 自定义转场变换 - alert
    private var alertTransition: UDAlertTransition?
    /// 自定义转场变换 - popover
    private var popoverTransition: UDPopoverTransition?
    // 这个值为了保证willTransition（to newTraitCollection)从开始到结束的过程中，traitCollection都用新的
    private var collectionTransition: UITraitCollection?
    /// actionSheet 容器，包含 primaryView， cancelView 和 divierView
    private lazy var containerView: UIView = UIView()
    /// actionSheet 上部视图，包括 标题 和 选项列表
    private lazy var primaryView: UIView = UIView()
    /// 标题区域
    private lazy var titleView: UILabel = UILabel()
    /// 标题 与 选项 的分割线
    private lazy var dividerViewUnderTitle = UIView()
    /// 选项区域视图
    private lazy var listItemView: UITableView = UITableView()
    /// 选项区域 与 取消视图的分割线
    private lazy var dividerViewUnderListItems: UIView = UIView()
    /// 取消视图
    private lazy var cancelView: UIView = UIView()
    /// 取消按钮
    private lazy var cancelButton: UIButton = UIButton()
    /// actionsheet 常规选项数组
    private var defaultItems: [UDActionSheetItem] = []
    /// 取消选项
    private var cancelItem: UDActionSheetItem?
    /// 是否点击过选项
    private var isActionSheetItemDidClicked: Bool = false
    /// 是否在 willTransition 时关闭 actionSheet
    private var isActionSheetDismissedWhenWillTransition: Bool = false
    /// view 是否计算完布局
    private var isViewLayouted: Bool = false
    /// 转场关闭的相关回调
    private lazy var transitionDismissCompletion: (() -> Void) = { [weak self] in
        guard let self = self else { return }
        if self.isActionSheetItemDidClicked {
            self.dismissCallback?()
        } else {
            self.config.dismissedByTapOutside?()
            self.dismissCallback?()
        }
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: UDActionSheet 生命周期
extension UDActionSheet {
    @available(iOS 13.0, *)
    open override var overrideUserInterfaceStyle: UIUserInterfaceStyle {
        didSet {
            self.normalTransition.dimmingView.overrideUserInterfaceStyle = self.overrideUserInterfaceStyle
            self.popoverTransition?.dimmingView.overrideUserInterfaceStyle = self.overrideUserInterfaceStyle
            // self.alertTransition?.dimmingView.overrideUserInterfaceStyle = self.overrideUserInterfaceStyle
        }
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 此时设置popover 颜色，否则显示title时，popover 箭头颜色显示有问题
        self.popoverPresentationController?.backgroundColor = config.backgroundColor
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        layoutViews()
    }

    open override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        guard !self.isActionSheetDismissedWhenWillTransition else {
            self.dismiss(animated: false)
            return
        }
        collectionTransition = newCollection
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] (_) in
            self?.collectionTransition = nil
        }
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard self.isViewLoaded else { return }
        super.viewWillTransition(to: size, with: coordinator)
        guard self.isActionSheetDismissedWhenWillTransition, self.isViewLayouted else {
            return
        }
        self.dismiss(animated: true)
    }

    open override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag) { [weak self] in
            self?.dismissCallback?()
            completion?()
        }
    }
}

// MARK: UDActionSheet 外观设置
extension UDActionSheet {
    private func setContainerView() {
        self.containerView.layer.masksToBounds = true
        self.containerView.layer.cornerRadius = config.cornerRadius
        updateContainerViewClear(true)
    }

    private func setTitleView() {
        titleView.textColor = config.titleColor
        titleView.textAlignment = self._titleViewAlignment
        titleView.numberOfLines = 0

        dividerViewUnderTitle.backgroundColor = UDActionPanelColorTheme.acPrimaryLineNormalColor
    }

    private func setPrimaryView() {
        primaryView.clipsToBounds = true
        primaryView.backgroundColor = config.backgroundColor
        primaryView.layer.cornerRadius = config.cornerRadius
    }

    private func setListItemView() {
        listItemView.backgroundColor = .clear
        listItemView.rowHeight = CGFloat(cellHeight)
        listItemView.delegate = self
        listItemView.dataSource = self
        listItemView.alwaysBounceVertical = false
        listItemView.bounces = false
        listItemView.separatorStyle = .singleLine
        listItemView.separatorColor = UDActionPanelColorTheme.acPrimaryLineNormalColor
        listItemView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        listItemView.register(UDActionSheetTableCell.self, forCellReuseIdentifier: UDActionSheetTableCell.identifier)
    }

    private func setCancelView() {
        guard let cancel = cancelItem else { return }
        dividerViewUnderListItems.backgroundColor = UIColor.ud.lineDividerDefault
        cancelView.backgroundColor = config.backgroundColor

        cancelButton.setTitle(cancel.title, for: .normal)
        cancelButton.setTitleColor(cancel.titleColor ?? UDActionPanelColorTheme.acPrimaryBtnNormalColor, for: .normal)
        cancelButton.titleLabel?.font = SheetCons.cancelButtonTitle
        cancelButton.titleLabel?.textAlignment = .center
        // cancel按钮点击变色
        cancelButton.addTarget(self, action: #selector(cancelButtonClickTouchDown),for: [.touchDown, .touchDragInside])
        // 防止手势拖拽出 取消 范围外时，按钮颜色不恢复
        cancelButton.addTarget(self, action: #selector(cancelButtonDragExit), for: [.touchDragExit, .touchDragOutside, .touchUpInside, .touchUpOutside])
    }
}

// MARK: UDActionSheet 布局设置
extension UDActionSheet {
    /// 针对 style 进行布局
    public func layoutViews() {
        if isPopover {
            currentStyle = .popover
            popoverLayoutSubViews()
        } else if isAlert {
            currentStyle = .alert
            alertLayoutSubViews()
        } else {
            currentStyle = .actionSheet
            actionSheetLayoutSubViews()
        }
        isViewLayouted = true
    }

    /// 当前是 actionSheet 样式布局
    private func actionSheetLayoutSubViews() {
        updateActionSheetConstraints()
        updateViewCornerRadius(isCorner: true)
        updateContainerViewClear(true)
    }

    /// 当前是 popover 样式布局
    private func popoverLayoutSubViews() {
        calculatePreferredContentSize()
        updateActionSheetConstraints()
    }

    /// 当前是 alert 样式布局
    private func alertLayoutSubViews() {
        calculatePreferredContentSize()
        updateActionSheetConstraints()
        updateViewCornerRadius(isCorner: false)
        updateContainerViewClear(false)
    }

    /// 更新 UDActionSheet 约束
    private func updateActionSheetConstraints() {
        updateContainerViewConstraints()
        updateCancelViewConstraints()
        updateTitleViewConstraints()
        updateListItemView()
        updatePrimaryViewConstraints()
    }

    /// 设置整个容器的约束
    private func updateContainerViewConstraints() {
        switch currentStyle {
        case .actionSheet:
            // TODO: 临时的横屏方案，等具体的设计规范确定后，再做更新
            if isActionSheetInLandMark {
                containerView.snp.remakeConstraints { make in
                    make.width.equalTo(351)
                    make.centerX.equalToSuperview()
                    make.top.greaterThanOrEqualToSuperview().offset(padding)
                    make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-padding)
                }
            } else {
                containerView.snp.remakeConstraints { make in
                    make.leading.equalToSuperview().offset(padding)
                    make.trailing.equalToSuperview().offset(-padding)
                    make.top.greaterThanOrEqualToSuperview().offset(padding)
                    make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-padding)
                }
            }
        case .popover:
            containerView.snp.remakeConstraints { make in
                if config.isShowTitle,
                   let arrowDirection = self.popoverPresentationController?.arrowDirection {
                    switch arrowDirection {
                    case .up:
                        make.top.equalToSuperview().offset(padding)
                        make.bottom.equalToSuperview()
                    case .down:
                        make.top.equalToSuperview()
                        make.bottom.equalToSuperview().offset(-padding)
                    default:
                        make.top.bottom.equalToSuperview()
                    }
                } else {
                    make.top.bottom.equalToSuperview()
                }
                make.leading.trailing.equalToSuperview()
            }
        case .alert:
            containerView.snp.remakeConstraints { (make) in
                make.centerX.centerY.equalToSuperview()
                make.width.equalTo(351)
            }
        }
    }

    /// 更新 标题区域 约束
    private func updateTitleViewConstraints() {
        titleView.isHidden = !config.isShowTitle
        guard config.isShowTitle else { return }
        titleView.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().offset(titleTopPadding)
            make.leading.equalToSuperview().offset(padding)
            make.trailing.equalToSuperview().offset(-padding)
        }
        updateDividerViewUnderTitleConstraints()
    }

    /// 更新 标题区域 与 列表选项区域 的分割线约束
    private func updateDividerViewUnderTitleConstraints() {
        dividerViewUnderTitle.snp.remakeConstraints { (make) in
            make.leading.trailing.equalTo(primaryView)
            make.top.equalTo(titleView.snp.bottom).offset(titleBottomPadding)
            make.height.equalTo(lineHeight)
        }
    }

    /// 更新 列表选项区域 约束
    private func updateListItemView() {
        listItemView.snp.remakeConstraints { (make) in
            if config.isShowTitle {
                make.top.equalTo(dividerViewUnderTitle.snp.bottom)
            } else {
                make.top.equalToSuperview()
            }
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(listItemViewHeight)
        }

        listItemView.reloadData()
    }

    /// 设置列表选项区域的约束
    private func updatePrimaryViewConstraints() {
        switch currentStyle {
        case .actionSheet:
            if cancelItem != nil {
                primaryView.snp.remakeConstraints { (make) in
                    make.top.left.right.equalToSuperview()
                    make.bottom.equalTo(cancelView.snp.top).offset(-padding)
                }
            } else {
                primaryView.snp.remakeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
            }
        case .popover:
            primaryView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        case .alert:
            primaryView.snp.remakeConstraints { (make) in
                make.top.left.right.equalToSuperview()
                make.bottom.equalTo(cancelView.snp.top).offset(-8)
            }
        }
    }

    /// 设置取消区域的约束
    private func updateCancelViewConstraints() {
        switch currentStyle {
        case .actionSheet:
            if cancelItem != nil {
                cancelView.isHidden = false
                cancelView.snp.remakeConstraints { make in
                    make.bottom.left.right.equalToSuperview()
                    make.height.equalTo(cellHeight)
                }
                cancelButton.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                }
            } else {
                cancelView.isHidden = true
                cancelView.snp.removeConstraints()
                cancelButton.snp.removeConstraints()
            }
            dividerViewUnderListItems.isHidden = true
        case .popover:
            cancelView.isHidden = true
            dividerViewUnderListItems.isHidden = true
            cancelView.snp.removeConstraints()
            cancelButton.snp.removeConstraints()
        case .alert:
            cancelView.isHidden = false
            dividerViewUnderListItems.isHidden = false

            cancelView.snp.remakeConstraints { (make) in
                make.left.bottom.right.equalToSuperview()
                make.height.equalTo(cellHeight)
            }
            cancelButton.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
            dividerViewUnderListItems.snp.remakeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(primaryView.snp.bottom)
                make.left.right.equalToSuperview()
                make.height.equalTo(dividerHeight)
            }
        }
    }

    // 更新圆角，true: 添加圆角，false: 不添加圆角
    private func updateViewCornerRadius(isCorner: Bool) {
        let radius = isCorner ? config.cornerRadius : 0
        primaryView.layer.cornerRadius = radius
        cancelView.layer.cornerRadius = radius
    }

    // 更新背景颜色，true：透明，false：N200颜色
    private func updateContainerViewClear(_ isHidden: Bool) {
        containerView.backgroundColor = isHidden ? UIColor.clear : UIColor.ud.bgBody
    }

    /// 计算 preferContentSize
    private func calculatePreferredContentSize() {
        switch config.style {
        case .normal:
            break
        case .autoPopover(let popSource):
            let width = popSource.preferredContentWidth
            guard config.isShowTitle,
                  !(titleView.text?.isEmpty ?? true) else {
                /// Need to set the corresponding preferredContentSize
                /// Settings in other life cycles will not take effect
                self.preferredContentSize = CGSize(width: width,
                                                   height: listItemViewHeight)
                return
            }

            let textHeight = self.height(text: self.titleView.text ?? "",
                                         font: SheetCons.titleFont,
                                         width: width - CGFloat(padding * 2))
            self.preferredContentSize = CGSize(width: width,
                                               height: listItemViewHeight + textHeight + CGFloat(padding * 2) + 12)
        case .autoAlert:
            // 设计给出的规范，宽度是351。https://bytedance.feishu.cn/docs/doccnBjH44jyxj158rNDo5XJ8cb#YC0ABn
            let width: CGFloat = 351.0
            guard config.isShowTitle, !(titleView.text?.isEmpty ?? true) else {
                self.preferredContentSize = CGSize(width: width, height: listItemViewHeight)
                return
            }
            let textHeight = UIFont.systemFont(ofSize: 14, weight: .regular).lineHeight
            self.preferredContentSize = CGSize(width: width,
                                               height: listItemViewHeight + textHeight + CGFloat(padding * 2))
        }
    }

    /// 标题视图 高度
    private func height(text: String, font: UIFont, width: CGFloat) -> CGFloat {
        var size: CGRect
        let textSize = CGSize(width: width, height: CGFloat.infinity)
        let lineHeight = font.figmaHeight
        let baselineOffset = (lineHeight - font.lineHeight) / 2.0 / 2.0
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.minimumLineHeight = lineHeight
        mutableParagraphStyle.maximumLineHeight = lineHeight
        size = (text as NSString).boundingRect(with: textSize,
                            options: [.usesLineFragmentOrigin],
                            attributes: [
                              .font: font,
                              .baselineOffset : baselineOffset,
                              .paragraphStyle : mutableParagraphStyle
                              ],
                            context: nil)
        return ceil(size.height)
    }
}

// MARK: UDActionSheet 点击、拖拽事件
extension UDActionSheet {

    private func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
    }

    @objc
    private func tapped(_ sender: UITapGestureRecognizer) {
        let tappedPoint = sender.location(in: self.view)
        let cancelViewFrame = cancelView.convert(cancelView.bounds, to: self.view)
        let primaryViewFrame = primaryView.convert(primaryView.bounds, to: self.view)
        if cancelViewFrame.contains(tappedPoint), cancelItem?.isEnable ?? false {
            self.isActionSheetItemDidClicked = true
            self.cancelItem?.action?()
        }

        if !primaryViewFrame.contains(tappedPoint) {
            self.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                if !self.isActionSheetItemDidClicked {
                    self.config.dismissedByTapOutside?()
                }
            }
        }
    }

    /// cancel 按钮 按下反馈
    @objc private func cancelButtonClickTouchDown() {
        cancelButton.backgroundColor = UDActionPanelColorTheme.acPrimaryBgPressedColor
    }
    /// cancel 按钮拖拽出按钮范围后，恢复颜色
    @objc private func cancelButtonDragExit() {
        cancelButton.backgroundColor = UIColor.clear
    }
}

// MARK: UDActionSheet 代理实现
extension UDActionSheet: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return defaultItems.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let name = String(describing: UDActionSheetTableCell.self)
        if let cell = listItemView.dequeueReusableCell(withIdentifier: name) as? UDActionSheetTableCell {
            let item = defaultItems[indexPath.row]
            let isHiddenLine = indexPath.row == 0 && (!config.isShowTitle)
            cell.set(item: item)
            return cell
        } else {
            return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        self.isActionSheetItemDidClicked = true
        let item = defaultItems[indexPath.row]
        self.dismiss(animated: true) {
            item.action?()
        }
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (indexPath.row == defaultItems.count-1) {
            cell.separatorInset = UIEdgeInsets(top: 0,left: 1000,bottom: 0,right: 0)
        }
    }
}

// MARK: UDActionSheet 计算属性
extension UDActionSheet {
    /// actionsheet 选项区域高度
    private var listItemViewHeight: CGFloat {
        return CGFloat(defaultItems.count > 9 ? cellHeight * 9 : cellHeight * defaultItems.count)
    }

    /// actionSheet 处于 popover 样式
    private var isPopover: Bool {
        switch config.style {
        case .autoPopover:
            return UIDevice.current.userInterfaceIdiom == .pad && self.isInPoperover
        default:
            return false
        }
    }

    /// actionSheet 处于 alert 样式
    private var isAlert: Bool {
        switch config.style {
        case .autoAlert:
            // 获取collectionTransition，取不到用系统的traitCollection
            return UIDevice.current.userInterfaceIdiom == .pad &&
                (collectionTransition ?? traitCollection).horizontalSizeClass == .regular
        default:
            return false
        }
    }

    /// actionSheet 处于 actionsheet 手机横屏样式
    private var isActionSheetInLandMark: Bool {
        get {
            return UIDevice.current.userInterfaceIdiom == .phone && isDeviceLandMark
        }
    }

    /// 屏幕尺寸（仅针对手机时判断）
    private var screenSize: CGSize {
        get {
            return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        }
    }

    /// 设备横屏
    private var isDeviceLandMark: Bool {
        get {
            return screenSize.width > screenSize.height
        }
    }
}

// UIConfig.style的enum是auto...表示两个状态之间的切换，此处的enum只是判断当前展示的样式
private enum ConfigStyle: Int {
    case popover = 0
    case alert = 1
    case actionSheet = 2
}

private enum SheetCons {
    static var titleFont: UIFont { UDFont.body2(.fixed) }
    static var titleFigmaHeight = SheetCons.titleFont.figmaHeight
    static var cancelButtonTitle: UIFont { UIFont.ud.title4(.fixed) }
}
