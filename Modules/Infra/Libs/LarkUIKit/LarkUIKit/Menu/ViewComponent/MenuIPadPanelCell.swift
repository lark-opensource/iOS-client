//
//  MenuIPadPanelCell.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/2/2.
//

import Foundation
import UIKit
import LarkBadge
import EENavigator
import UniverseDesignToast
import LarkSetting
import LarkFeatureGating

/// iPad菜单选项的视图
final class MenuIPadPanelCell: UICollectionViewCell {

    /// 选项视图左边距
    private static let cellLeftSpacing: CGFloat = 16
    /// 图片的宽高
    private static let imageWidthAndHeight: CGFloat = 20
    /// 图片的上边距
    private static let imageTopSpacing: CGFloat = 17
    /// 标题的左边距
    private static let titleLeftSpacing: CGFloat = 12
    /// 标题的上边距
    private static let titleTopSpacing: CGFloat = 16
    /// 标题的下边距
    private static let titleBottomSpacing: CGFloat = 16
    /// badge的左边距
    private static let badgeLeftSpacing: CGFloat = 4
    /// 选项视图的右边距
    private static let cellRightSpacing: CGFloat = 16
    /// 分割线的高度
    private static let lineHeight: CGFloat = 1

    /// 视图模型
    private var viewModel: MenuIPadPanelCellViewModelProtocol?
    /// 选项的视图状态
    private var itemStatus: UIControl.State = .normal

    /// 处理点击事件的代理
    weak var delegate: MenuActionDelegate?

    /// 图片
    private var imageView: UIImageView?
    /// 标题
    private var titleView: UILabel?
    /// 分割线
    private var borderLine: UIView?
    /// badge视图
    private var badgeView: BadgeView?
    /// 监听hover状态的手势
    private var hoverGesture: UIGestureRecognizer?
    /// 是否应该显示badge
    private var isShowBadge = false

    override init(frame: CGRect) {
        super.init(frame: .zero)

        setupSubviews()
        setupStaticConstrain()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 初始化子视图
    private func setupSubviews() {
        setupHoverGesture()
        setupImageView()
        setupTitleView()
        setupBadgeView()
        setupBorderLine()
    }

    /// 初始化hover手势
    private func setupHoverGesture() {
        if #available(iOS 13.0, *) {
            if let gesture = self.hoverGesture {
                self.removeGestureRecognizer(gesture)
                self.hoverGesture = nil
            }
            let gesture = UIHoverGestureRecognizer(target: self, action: #selector(hover(gesture:)))
            self.hoverGesture = gesture
            self.addGestureRecognizer(gesture)
        }
    }

    /// 处理hover手势状态变化的方法
    /// - Parameter gesture: hover手势
    @available(iOS 13.0, *)
    @objc func hover(gesture: UIHoverGestureRecognizer) {
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_hidemenuitems")) { //Global 纯UI相关，成本比较大，先不改
            // 开启后disable状态接受点击，点击后提示用户当前开发者已禁用此功能
            if self.itemStatus != .disabled {
                switch gesture.state {
                case .began, .changed:
                    self.itemStatus = .focused
                default:
                    self.itemStatus = .normal
                }
            }
        } else {
            switch gesture.state {
            case .began, .changed:
                self.itemStatus = .focused
            default:
                self.itemStatus = .normal
            }
        }

        self.updateSubViewStyleWhenStatusChanged()
    }

    /// 初始化图片
    private func setupImageView() {
        if let imageView = self.imageView {
            imageView.removeFromSuperview()
            self.imageView = nil
        }
        let new = UIImageView()
        new.contentMode = .scaleAspectFit

        self.addSubview(new)
        self.imageView = new
    }

    /// 初始化标题
    private func setupTitleView() {
        if let title = self.titleView {
            title.removeFromSuperview()
            self.titleView = nil
        }
        let new = UILabel()
        new.lineBreakMode = .byTruncatingTail
        new.numberOfLines = 2
        new.textAlignment = .left
        self.addSubview(new)
        self.titleView = new
    }

    /// 初始化分割线
    private func setupBorderLine() {
        if let borderLine = self.borderLine {
            borderLine.removeFromSuperview()
            self.borderLine = nil
        }
        let new = UIView()
        new.backgroundColor = UIColor.menu.panelLineColor
        new.isHidden = true // 初始化的分割线要先隐藏
        self.borderLine = new
        self.addSubview(new)
    }

    /// 初始化badge视图
    private func setupBadgeView() {
        if let badgeView = self.badgeView {
            badgeView.removeFromSuperview()
            self.badgeView = nil
        }
        let new = BadgeView(with: .clear)
        new.isHidden = true
        self.addSubview(new)
        self.badgeView = new
    }

    /// 初始化视图的静态约束
    private func setupStaticConstrain() {
        setupImageViewStaticConstrain()
        setupTitleViewDynmaicConstrain()
        updateBadgeViewDynamicConstrin()
        setupBorderLineStaticConstrin()
    }

    /// 初始化图片的约束
    private func setupImageViewStaticConstrain() {
        guard let imageView = self.imageView else {
            return
        }
        imageView.snp.makeConstraints {
            make in
            make.leading.equalToSuperview().offset(MenuIPadPanelCell.cellLeftSpacing)
            make.top.equalToSuperview().offset(MenuIPadPanelCell.imageTopSpacing)
            make.width.height.equalTo(MenuIPadPanelCell.imageWidthAndHeight)
        }
    }

    /// 设置标题约束
    private func setupTitleViewDynmaicConstrain() {
        guard let titleView = self.titleView, let imageView = self.imageView else {
            return
        }
        titleView.snp.remakeConstraints {
            make in
            make.leading.equalTo(imageView.snp.trailing).offset(MenuIPadPanelCell.titleLeftSpacing)
            make.top.equalToSuperview().offset(MenuIPadPanelCell.titleTopSpacing)
            make.bottom.equalToSuperview().offset(-MenuIPadPanelCell.titleBottomSpacing)
            make.width.equalTo(0)
        }
    }

    /// 更新badge视图的约束
    private func updateBadgeViewDynamicConstrin() {
        guard let imageView = self.imageView,
              let titleView = self.titleView,
              let badgeView = self.badgeView else {
            return
        }
        badgeView.snp.remakeConstraints {
            make in
            make.size.equalTo(CGSize.zero)
            if self.isShowBadge {
                make.centerY.equalTo(imageView.snp.centerY)
                make.leading.equalTo(titleView.snp.trailing).offset(MenuIPadPanelCell.badgeLeftSpacing)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateTitleViewDynamicConstrain()
    }

    /// 更新标题约束
    private func updateTitleViewDynamicConstrain() {
        guard let viewModel = self.viewModel,
              let titleView = self.titleView,
              let badgeView = self.badgeView else {
            return
        }
        let width = self.frame.width
        let badgeViewWidth = self.isShowBadge ? badgeView.frame.width + MenuIPadPanelCell.badgeLeftSpacing : 0
        let titleMaxWidth = width -
            MenuIPadPanelCell.cellLeftSpacing -
            MenuIPadPanelCell.imageWidthAndHeight -
            MenuIPadPanelCell.titleLeftSpacing -
            badgeViewWidth -
            MenuIPadPanelCell.cellRightSpacing
        let titleReallyWidth = Self.computeStringLength(for: viewModel.title, font: viewModel.font)
        let titleWidth = min(titleMaxWidth, titleReallyWidth)
        titleView.snp.updateConstraints {
            make in
            make.width.equalTo(titleWidth)
        }
    }

    /// 初始化分割线的约束
    private func setupBorderLineStaticConstrin() {
        guard let borderLine = self.borderLine else {
            return
        }
        borderLine.snp.makeConstraints {
            make in
            make.bottom.trailing.leading.equalToSuperview()
            make.height.equalTo(MenuIPadPanelCell.lineHeight)
        }
    }

    /// 更新视图
    /// - Parameter viewModel: 需要更新的视图模型
    func updateViewModel(for viewModel: MenuIPadPanelCellViewModelProtocol) {
        self.viewModel = viewModel
        self.isShowBadge = viewModel.isShowBadge

        updateBadgeViewDynamicConstrin()

        updateViewStatus()
        updateSubViewContent()

        // 强制刷新布局，以免badge未更新，但是文本更新了，文本长度不正确
        setNeedsLayout()
        layoutIfNeeded()
    }

    /// 更新子视图的全部内容
    private func updateSubViewContent() {
        updateTitleContent()

        updateCellContent()
        updateBadge()
        updateImageViewContent()
        updateBorderLine()
    }

    /// 更新子视图当视图状态改变之后
    private func updateSubViewStyleWhenStatusChanged() {
        self.updateImageViewContent()
        self.updateTitleColor()
        self.updateCellContent()
    }

    /// 根据视图模型的是否禁用标志决定选项是否响应点击事件
    private func updateViewStatus() {
        guard let viewModel = self.viewModel else {
            return
        }
        if !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_hidemenuitems")) {//Global 纯UI相关，成本比较大，先不改
            // 开启后disable状态接受点击，点击后提示用户当前开发者已禁用此功能
            //https://bytedance.feishu.cn/docx/doxcnN7P1NBk7xTzVynqF1lBzAg
            self.isUserInteractionEnabled = !viewModel.disable
        }
        if viewModel.disable {
            self.itemStatus = .disabled
        } else {
            self.itemStatus = .normal
        }
    }

    /// 更新标题内容
    private func updateTitleContent() {
        guard let viewModel = self.viewModel, let titleLabel = self.titleView else {
            return
        }
        titleLabel.text = viewModel.title
        titleLabel.font = viewModel.font
        self.updateTitleColor()
    }

    /// 更新标题颜色
    private func updateTitleColor() {
        guard let viewModel = self.viewModel, let titleLabel = self.titleView else {
            return
        }
        titleLabel.textColor = viewModel.titleColor(for: self.itemStatus)
    }

    /// 更新选项的背景颜色
    private func updateCellContent() {
        guard let viewModel = self.viewModel else {
            return
        }
        self.backgroundColor = viewModel.backgroundColor(for: self.itemStatus)
    }

    /// 更新badge视图
    private func updateBadge() {
        guard let viewModel = self.viewModel, let badgeView = self.badgeView else {
            return
        }
        if case let .number(maxBadgeNumber) = viewModel.menuBadgeType.type, let max = maxBadgeNumber {
            badgeView.setMaxNumber(to: Int(max))
        }
        badgeView.style = viewModel.badgeStyle
        badgeView.type = viewModel.badgeType
        BadgeManager.setBadge(viewModel.path, type: viewModel.badgeType, strategy: .weak)
        badgeView.isHidden = !viewModel.isShowBadge
    }

    /// 更新图片
    private func updateImageViewContent() {
        guard let viewModel = self.viewModel, let imageView = self.imageView else {
            return
        }
        imageView.tintColor = viewModel.imageColor(for: self.itemStatus)
        imageView.image = viewModel.image(for: self.itemStatus)
    }

    /// 更新分割线
    private func updateBorderLine() {
        guard let viewModel = self.viewModel, let borderLine = self.borderLine else {
            return
        }
        borderLine.isHidden = !viewModel.isShowBorderLine
    }

    /// 预先计算选项 的宽度
    /// - Parameters:
    ///   - title: 文字
    ///   - font: 字号
    ///   - isShowBadge: 是否有badge
    ///   - badgeType: badge的类型
    /// - Returns: 预估选项的宽度
    static func prepareContentLength(for title: String,
                                     font: UIFont,
                                     isShowBadge: Bool,
                                     badgeType: BadgeType,
                                     badgeStyle: BadgeStyle,
                                     menuBadgeType: MenuBadgeType) -> CGFloat {
        let titleLength = Self.computeStringLength(for: title, font: font)

        var length = Self.cellLeftSpacing +
            Self.imageWidthAndHeight +
            Self.titleLeftSpacing +
            titleLength +
            Self.cellRightSpacing
        if isShowBadge {
            var max: Int?
            if case .number(let maxNumber) = menuBadgeType.type, let maxN = maxNumber {
                max = Int(maxN)
            }
            return length + Self.badgeLeftSpacing + BadgeView.computeSize(for: badgeType, style: badgeStyle, maxNumber: max).width
        } else {
            return length
        }
    }

    /// 计算指定文本以指定字体显示的长度
    /// - Parameters:
    ///   - title: 需要计算的文本
    ///   - font: 字号
    /// - Returns: 文本的长度
    private static func computeStringLength(for title: String, font: UIFont) -> CGFloat {
        let label = UILabel()
        label.font = font
        label.text = title
        return label.sizeThatFits(CGSize(width: CGFloat(MAXFLOAT), height: CGFloat(MAXFLOAT))).width
    }

    /// 处理点击事件
    func executeAction() {
        guard let viewModel = self.viewModel else {
            return
        }
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_hidemenuitems")) {//Global 纯UI相关，成本比较大，先不改
            if viewModel.disable {
                guard let mainSceneWindow = Navigator.shared.mainSceneWindow else { //Global 纯UI相关，成本比较大，先不改
                    return
                }
                UDToast.showTips(with: BundleI18n.LarkUIKit.OpenPlatform_MoreAppFcns_DevDisabledFcns, on: mainSceneWindow, delay: 2.0)
                return
            }
        }
        if let delegate = self.delegate {
            delegate.actionMenu(for: viewModel.identifier, autoClose: viewModel.autoClosePanelWhenClick, animation: true) {
                viewModel.action(viewModel.identifier)
            }
        } else {
            viewModel.action(viewModel.identifier)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_hidemenuitems")) {//Global 纯UI相关，成本比较大，先不改
            if self.itemStatus != .disabled {
                self.itemStatus = .selected // 触摸开始后设置为选中状态
            }
        } else {
            self.itemStatus = .selected // 触摸开始后设置为选中状态
        }

        updateSubViewStyleWhenStatusChanged()

        super.touchesBegan(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_hidemenuitems")) {//Global 纯UI相关，成本比较大，先不改
            if self.itemStatus != .disabled {
                self.itemStatus = .normal // 触摸结束后设置为正常状态
            }
        } else {
            self.itemStatus = .normal // 触摸结束后设置为正常状态
        }

        updateSubViewStyleWhenStatusChanged()

        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_hidemenuitems")) {//Global 纯UI相关，成本比较大，先不改
            if self.itemStatus != .disabled {
                self.itemStatus = .normal // 触摸结束后设置为正常状态
            }
        } else {
            self.itemStatus = .normal // 触摸结束后设置为正常状态
        }

        updateSubViewStyleWhenStatusChanged()

        super.touchesCancelled(touches, with: event)
    }

}
