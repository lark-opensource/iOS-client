//
//  MenuIPhonePanel.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/2/1.
//

import Foundation
import UIKit
import LarkBadge
import LarkLocalizations
import FigmaKit

/// iPhone菜单面板
final class MenuIPhonePanel: UIView {

    /// 分割线行高
    private let lineHeight: CGFloat = 0.5
    /// 取消按钮高度
    private let cancelButtonHeight: CGFloat = 34
    /// 取消按钮的布局下移
    private let cancelButtonTopOffset: CGFloat = 8
    /// 取消按钮标题字号
    private let cancelButtonTitleFont = UIFont.systemFont(ofSize: 16, weight: .regular)
    /// 面板圆角
    private let containerCornerRadius: CGFloat = 12

    /// 圆角遮罩图层
    private let containerMaskLayer = CAShapeLayer()
    /// 背景视图
    private var backgroundView: UIView?
    /// 面板容器视图
    private var container: UIView?
    /// 毛玻璃视图
    private var blurView: VisualBlurView?
    /// 父视图的badge路径
    private let parentPath: Path
    /// 选项集合视图
    private var itemPage: MenuIPhonePanelItemPage?

    private var headerView: MenuHeaderView?

    /// 是否显示附加视图
    private var isShowAdditionPage = false

    /// 面板底部视图容器
    private var bottomContainer: UIView?
    /// 分割线
    private var lineView: UIView?
    /// 取消按钮
    private var cancelButton: UIButton?

    /// 初始化时的选项数据模型
    private var initItemModels: [MenuItemModelProtocol]

    /// 初始化是的附加视图
    private var initAdditionView: MenuAdditionView?

    /// 菜单操作事件的代理
    weak var actionMenuDelegate: MenuActionDelegate?

    init(parentPath: Path, itemModels: [MenuItemModelProtocol] = [], headerView: MenuAdditionView? = nil) {
        self.parentPath = parentPath
        self.initItemModels = itemModels
        self.initAdditionView = headerView
        super.init(frame: .zero)

        setupSubviews()
        setupStaticConstrain()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 初始化子视图
    private func setupSubviews() {
        setupCurrentView()
        setupBackgroundView()
        setupContainerView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.updateMaskLayer() // 约束更新完成后更新遮罩的大小

    }

    /// 更新遮罩的大小
    private func updateMaskLayer() {
        guard let container = self.container else {
            return
        }
        self.containerMaskLayer.frame = container.bounds
        let maskPath = UIBezierPath(roundedRect: container.bounds, byRoundingCorners: .init(arrayLiteral: [.topLeft, .topRight]), cornerRadii: CGSize(width: self.containerCornerRadius, height: self.containerCornerRadius))
        self.containerMaskLayer.path = maskPath.cgPath
        container.layer.mask = self.containerMaskLayer
    }

    /// 初始化当前View
    private func setupCurrentView() {
        self.backgroundColor = .clear
    }

    /// 初始化背景视图
    private func setupBackgroundView() {
        if let background = self.backgroundView {
            background.removeFromSuperview()
            self.backgroundView = nil
        }
        let newBackgroundView = UIView()
        newBackgroundView.backgroundColor = UIColor.ud.bgMask

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapBackgroundView))
        tap.numberOfTouchesRequired = 1
        newBackgroundView.addGestureRecognizer(tap)

        self.backgroundView = newBackgroundView
        self.addSubview(newBackgroundView)
    }

    /// 初始化容器视图
    private func setupContainerView() {
        if let container = self.container {
            container.removeFromSuperview()
            self.container = nil
        }

        let newContainerView = UIView()
        newContainerView.backgroundColor = .clear
        self.container = newContainerView
        // 初始化container子view
        setupBlurView()
        setupItemPage()
        setupHeaderView()
        setupBottomContainer()
        setupLineView()
        setupCancelButton()
        self.addSubview(newContainerView)
    }

    /// 初始化毛玻璃视图
    private func setupBlurView() {
        if let blurView = self.blurView {
            blurView.removeFromSuperview()
            self.blurView = nil
        }

        let newBlurView = VisualBlurView()
        newBlurView.blurRadius = 54
        newBlurView.fillColor = UIColor.ud.bgFloatBase
        newBlurView.fillOpacity = 0.85
        self.blurView = newBlurView
        self.container?.addSubview(newBlurView)
    }

    /// 初始化选项集合视图
    private func setupItemPage() {
        if let itemPage = self.itemPage {
            itemPage.removeFromSuperview()
            self.itemPage = nil
        }
        guard let container = self.container else {
            return
        }

        let newItemPage = MenuIPhonePanelItemPage(parent: self.parentPath, itemModels: self.initItemModels)
        self.initItemModels = [] // 及时释放内存
        newItemPage.delegate = self
        self.itemPage = newItemPage
        container.addSubview(newItemPage)
    }

    /// 初始化头部视图
    private func setupHeaderView() {
        if let headerView = self.headerView {
            headerView.removeFromSuperview()
            self.headerView = nil
        }
        guard let container = self.container else {
            return
        }

        let newHeaderView = MenuHeaderView(headerView: self.initAdditionView)
        self.initAdditionView = nil // 及时释放内存
        self.headerView = newHeaderView
        container.addSubview(newHeaderView)
    }

    /// 初始化底部容器视图
    private func setupBottomContainer() {
        if let container = self.bottomContainer {
            container.removeFromSuperview()
            self.bottomContainer = nil
        }
        guard let container = self.container else {
            return
        }
        let newBottomContainer = UIView()
        self.bottomContainer = newBottomContainer
        container.addSubview(newBottomContainer)
    }

    /// 初始化分割线
    private func setupLineView() {
        if let line = self.lineView {
            line.removeFromSuperview()
            self.lineView = nil
        }
        guard let container = self.bottomContainer else {
            return
        }
        let newLineView = UIView()
        newLineView.backgroundColor = UIColor.ud.lineDividerDefault
        self.lineView = newLineView
        container.addSubview(newLineView)
    }

    /// 初始化取消按钮
    private func setupCancelButton() {
        if let cancelButton = self.cancelButton {
            cancelButton.removeFromSuperview()
            self.cancelButton = nil
        }
        guard let container = self.bottomContainer else {
            return
        }
        let newCancelButton = UIButton()
        newCancelButton.setTitle(BundleI18n.LarkUIKit.Lark_Legacy_Cancel, for: .normal)
        newCancelButton.setTitleColor(UIColor.menu.cancelButtonTextColor, for: .normal)
        newCancelButton.backgroundColor = UIColor.menu.cancelButtonBackgroundColor
        newCancelButton.titleLabel?.font = self.cancelButtonTitleFont
        newCancelButton.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        self.cancelButton = newCancelButton
        container.addSubview(newCancelButton)
    }

    /// 点击按钮的触发方法
    @objc func cancelAction() {
        self.tapBackgroundView()
    }

    /// 初始化子视图的约束
    private func setupStaticConstrain() {
        setupBackgroundViewStaticConstrain()
        updateContainerViewConstrainWhenShow()
    }

    /// 初始化背景视图约束
    private func setupBackgroundViewStaticConstrain() {
        guard let background = self.backgroundView else {
            return
        }
        background.snp.makeConstraints {
            make in
            make.trailing.leading.top.bottom.equalToSuperview()
        }
    }

    /// 更新容器视图约束当展示出来时
    private func updateContainerViewConstrainWhenShow() {
        guard let container = self.container else {
            return
        }
        container.snp.remakeConstraints {
            make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
        }
        // 更新container子view的约束
        setupBlurViewConstrain()
        setupHeaderViewStaticConstrain()
        setupItemPageViewDynamicConstrain()
        setupBottomViewContainerStaticConstrain()
        setupBottomLineStaticConstrain()
        setupCancelButtonStaticConstrain()
    }

    /// 更新容器视图约束当消失后
    private func updateContainerViewConstrainWhenHide() {
        guard let container = self.container else {
            return
        }
        container.snp.remakeConstraints {
            make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.snp.bottom)
        }
    }

    /// 更新毛玻璃视图的约束
    private func setupBlurViewConstrain() {
        guard let blurView = self.blurView else {
            return
        }
        blurView.snp.makeConstraints {
            make in make.leading.trailing.top.bottom.equalToSuperview()
        }
    }

    /// 初始化头部视图的约束
    private func setupHeaderViewStaticConstrain() {
        guard let headerView = self.headerView else {
            return
        }
        headerView.snp.makeConstraints {
            make in
            make.top.leading.trailing.equalToSuperview()
        }
    }

    /// 更新选项集合视图的约束
    private func setupItemPageViewDynamicConstrain() {
        guard let item = self.itemPage, let headerView = self.headerView else {
            return
        }
        item.snp.remakeConstraints {
            make in
            make.trailing.leading.equalToSuperview()
            make.top.equalTo(headerView.snp.bottom)
        }
    }

    /// 初始化底部容器视图约束
    private func setupBottomViewContainerStaticConstrain() {
        guard let item = self.itemPage, let container = self.bottomContainer else {
            return
        }

        container.snp.makeConstraints {
            make in
            make.top.equalTo(item.snp.bottom)
            make.trailing.leading.bottom.equalToSuperview()
        }

    }

    /// 初始化分割线约束
    private func setupBottomLineStaticConstrain() {
        guard let line = self.lineView else {
            return
        }
        line.snp.makeConstraints {
            make in
            make.height.equalTo(self.lineHeight)
            make.top.trailing.leading.equalToSuperview()
        }
    }

    /// 初始化取消按钮约束
    private func setupCancelButtonStaticConstrain() {
        guard let line = self.lineView, let cancel = self.cancelButton, let container = self.bottomContainer else {
            return
        }
        cancel.snp.makeConstraints {
            make in
            make.height.equalTo(self.cancelButtonHeight)
            make.top.equalTo(line.snp.bottom).offset(self.cancelButtonTopOffset)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(container.safeAreaLayoutGuide.snp.bottom)
        }
    }

    /// 点击背景后的行为
    @objc func tapBackgroundView() {
        self.actionMenu(for: nil, autoClose: true, animation: true, action: nil)
    }

    /// 更新约束使其显示
    private func updateLayoutShow() {
        self.backgroundView?.alpha = 1
        updateContainerViewConstrainWhenShow()
    }

    /// 更新约束使其隐藏
    private func updateLayoutHide() {
        self.backgroundView?.alpha = 0
        updateContainerViewConstrainWhenHide()
    }
}

extension MenuIPhonePanel: MenuPanelVisibleProtocol {

    func hide(animation: Bool, duration: Double, complete: ((Bool) -> Void)?) {
        if animation {
            updateLayoutShow()
            layoutIfNeeded()
            UIView.animate(withDuration: duration, animations: { [weak self] in
                self?.updateLayoutHide()
                self?.layoutIfNeeded()
            }) {
                complete?($0)
            }
        } else {
            updateLayoutHide()
            layoutIfNeeded()
            complete?(true)
        }
    }

    func show(animation: Bool, duration: Double, complete: ((Bool) -> Void)?) {
        if animation {
            updateLayoutHide()
            layoutIfNeeded()
            UIView.animate(withDuration: duration, animations: { [weak self] in
                self?.updateLayoutShow()
                self?.layoutIfNeeded()
            }) {
                complete?($0)
            }
        } else {
            updateLayoutShow()
            layoutIfNeeded()
            complete?(true)
        }
    }
}

extension MenuIPhonePanel: MenuPanelDataUpdaterProtocol {
    /// 更新头部视图
    /// - Parameter view: 新的附加视图
    func updatePanelHeader(for view: MenuAdditionView?) {
        guard let headerView = self.headerView else {
            return
        }
        headerView.updateHeaderView(for: view)
    }

    func updatePanelFooter(for view: MenuAdditionView?) {
        assertionFailure("RegularMenu isn't implement this method")
    }

    /// 更新选项视图
    /// - Parameter models: 需要更新选项数据模型
    func updateItemModels(for models: [MenuItemModelProtocol]) {
        guard let item = self.itemPage else {
            return
        }
        item.updateModels(for: models)
    }
}

extension MenuIPhonePanel: MenuActionDelegate {
    func actionMenu(for identifier: String?, autoClose: Bool, animation: Bool, action: (() -> Void)?) {
        actionMenuDelegate?.actionMenu(for: identifier, autoClose: autoClose, animation: animation, action: action)
    }
}
