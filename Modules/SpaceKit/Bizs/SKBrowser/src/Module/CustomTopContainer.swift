//
//  CustomTopContainer.swift
//  SKBrowser
//
//  Created by lizechuang on 2020/11/4.
//

import UIKit
import SKFoundation
import SKUIKit
import SnapKit
import RxSwift
import UniverseDesignColor
import SKCommon

class CustomTopContainer: UIView {

    var navBar: SKNavigationBar

    private lazy var statusBar = UIView().construct { (view) in
        view.backgroundColor = UDColor.bgBody
    }

    private lazy var bottomDivider = UIView().construct { (view) in
        view.backgroundColor = UDColor.lineDividerDefault
        view.isHidden = true
    }

    // special logic
    private var customCenterView: CustomSubTopContainer?
    private var customRightView: CustomSubTopContainer?

    // pattern property
    var titleHorizontalAlignment: UIControl.ContentHorizontalAlignment? {
        get { return navBar.layoutAttributes.titleHorizontalAlignment }
        set { navBar.layoutAttributes.titleHorizontalAlignment = newValue ?? .center }
    }

    var titleInfo: NavigationTitleInfo? {
        get { return navBar.titleInfo }
        set { navBar.titleInfo = newValue }
    }

    var layoutAttributes: SKNavigationBar.LayoutAttributes {
        get { return navBar.layoutAttributes }
        set { navBar.layoutAttributes = newValue }
    }

    weak var previousGestureDelegate: UIGestureRecognizerDelegate?
    var interactivePopGestureRecognizer: UIGestureRecognizer?

    var interactivePopGestureAction: (() -> Void)?

    init(navBar: SKNavigationBar) {
        self.navBar = navBar
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopInterceptPopGesture()
    }
}

// MARK: pattern build
extension CustomTopContainer {
    public func setup() {
        if navBar.superview != nil && navBar.superview != self {
            navBar.removeFromSuperview()
            navBar.snp.removeConstraints()
        }
        addSubview(statusBar)
        statusBar.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.top)
        }
        addSubview(navBar)
        navBar.snp.makeConstraints { (make) in
            make.top.equalTo(statusBar.snp.bottom)
            make.left.right.equalToSuperview()
        }
        addSubview(bottomDivider)
        bottomDivider.snp.makeConstraints { (make) in
            make.top.equalTo(navBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    public func shouldShowDivider(_ show: Bool) {
        bottomDivider.isHidden = !show
    }

    /// 设置导航栏各个部位的颜色
    /// - Parameters:
    ///   - backgroundColor: bar 整体的背景色，保持当前不变请显式传 nil，不传则恢复默认值 bgBody，需要透明请传 .clear
    ///   - itemForegroundColorMapping: bar item 的文字/图标颜色，保持当前不变请显式传 nil，不传则恢复默认配置，要变则所有 item 一起变（使用了 customView 的 SKBarButtonItem 不会跟着变化，需要业务方自行处理）
    ///   - separatorColor: 导航栏底部分割线(若有)的颜色，保持当前不变请显式传 nil，不传则恢复默认值 lineDividerDefault，如果本来就没有显示分割线，则设置无效
    public func setCustomAppearance(backgroundColor: UIColor? = UDColor.bgBody,
                                    separatorColor: UIColor? = UDColor.lineDividerDefault) {
        navBar.customizeBarAppearance(backgroundColor: backgroundColor, itemForegroundColorMapping: nil, separatorColor: separatorColor)
        statusBar.backgroundColor = backgroundColor
    }

    public func updateCurNavBarSizeType(_ sizeType: SKNavigationBar.SizeType) {
        self.navBar.sizeType = sizeType
    }
}

// MARK: - special logic
extension CustomTopContainer {
    public func setCustomCenterView(_ view: CustomSubTopContainer?) {
        // 设置之前判断有没有存在的场景
        if let customCenterView = customCenterView, customCenterView.superview != nil {
            customCenterView.removeFromSuperview()
            customCenterView.snp.removeConstraints()
        }
        // 添加场景
        if let view = view {
            addSubview(view)
            var centerXOffset: CGFloat = 0.0
            if let rightView = customRightView {
                centerXOffset = rightView.currentLayout().width / 2
            }
            view.snp.makeConstraints { make in
                make.centerY.equalTo(navBar.snp.centerY)
                make.centerX.equalTo(navBar.snp.centerX).offset(-centerXOffset)
                make.width.equalTo(view.currentLayout().width)
                make.height.equalTo(view.currentLayout().height)
            }
        }
        self.customCenterView = view
    }

    public func setCustomRightView(_ view: CustomSubTopContainer?) {
        // 设置之前判断有没有存在的场景
        if let customRightView = customRightView, customRightView.superview != nil {
            customRightView.removeFromSuperview()
            customRightView.snp.removeConstraints()
        }
        // 添加场景
        if let view = view {
            addSubview(view)
            bringSubviewToFront(view)
            view.snp.makeConstraints { make in
                make.right.top.bottom.equalToSuperview()
                make.width.equalTo(view.currentLayout().width)
            }
        }
        self.customRightView = view
    }
    
    public func getCustomCenterView() -> CustomSubTopContainer? {
        return customCenterView
    }
}

// MARK: - intercept pop gesture
extension CustomTopContainer: UIGestureRecognizerDelegate {

    public func startInterceptPopGesture(gesture: UIGestureRecognizer?) {
        if gesture?.delegate !== self {
            if UserScopeNoChangeFG.ZJ.btCustomTopContainerPopgestureFixDisable {
                previousGestureDelegate = gesture?.delegate
            }
            gesture?.delegate = self
            self.interactivePopGestureRecognizer = gesture
            DocsLogger.info("TopContainer -- add naviPopGestureDelegate previousGestureDelegate")
        }
    }
    
    func stopInterceptPopGesture() {
        interactivePopGestureRecognizer?.delegate = previousGestureDelegate
        DocsLogger.info("TopContainer -- remove naviPopGestureDelegate previousGestureDelegate's nil is \(previousGestureDelegate == nil)")
        interactivePopGestureRecognizer = nil
        previousGestureDelegate = nil
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        interactivePopGestureAction?()
        return false
    }
    
    open func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
        if otherGestureRecognizer is UILongPressGestureRecognizer {
            return false
        }
        return gestureRecognizer is UIScreenEdgePanGestureRecognizer
    }
}
