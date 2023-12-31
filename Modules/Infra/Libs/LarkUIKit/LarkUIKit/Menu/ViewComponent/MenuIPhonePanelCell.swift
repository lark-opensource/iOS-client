//
//  MenuIPhonePanelCell.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/1/28.
//

import Foundation
import UIKit
import LarkBadge
import SnapKit
import EENavigator
import UniverseDesignToast
import LarkSetting
import LarkFeatureGating

/// iPhone菜单选项的视图
final class MenuIPhonePanelCell: UICollectionViewCell {

    /// 选项图片圆的高度和宽度
    private let imageViewCellWidthAndHeight: CGFloat = 52
    /// 选项图片圆和标题之间的间隙
    private let imageViewCellAndTitleSpacingHeight: CGFloat = 6
    /// 选项图片的高度和宽度
    private let imageViewWidthAndHeight: CGFloat = 24
    /// 选项图片的圆角度数
    private let imageViewCellRadius: CGFloat = 12

    /// 文字行高
    private let textLineHeight: CGFloat = 16

    /// 标题区域视图
    private var titleAreaCell: UIView?
    /// 标题视图
    private var titleLabel: UILabel?

    /// 标题的段落样式
    private var paraStyle: NSMutableParagraphStyle?
    /// 图片视图
    private var imageView: UIImageView?
    /// 图片区域视图
    private var imageViewCell: UIView?
    /// badge视图
    private var imageBadgeView: BadgeView?

    /// 选项的视图模型
    private var viewModel: MenuIPhonePanelCellViewModelProtocol?
    /// 选项的视图状态
    private var itemStatus: UIControl.State = .normal

    /// 处理点击事件的代理
    weak var delegate: MenuActionDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupSubViews()
        self.setupStaticConstrain()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 初始化子视图
    private func setupSubViews() {
        self.setupTitleAreaCell()
        self.setupTitleLabel()
        self.setupImageViewCell()
        self.setupImageView()
        self.setupImageBadge()
    }

    /// 初始化子视图静态约束
    private func setupStaticConstrain() {
        self.setupImageViewCellStaticConstrain()
        self.setupBadgeViewStaticConstrain()
        self.setupImageViewStaticConstrain()
        self.setupTitleAreaCellStaticConstrain()
        self.setupTitleViewStaticConstrain()
    }

    /// 根据视图模型更新视图
    /// - Parameter viewModel: 需要更新的视图模型
    func updateViewModel(viewModel: MenuIPhonePanelCellViewModelProtocol) {
        self.viewModel = viewModel
        self.updateViewStatus()
        self.updateSubViewContent()
    }

    /// 初始化标题区域视图
    private func setupTitleAreaCell() {
        if let area = self.titleAreaCell {
            area.removeFromSuperview()
            self.titleAreaCell = nil
        }

        let new = UIView()
        self.titleAreaCell = new
        self.addSubview(new)
    }

    /// 初始化标题
    private func setupTitleLabel() {
        if let titleLabel = self.titleLabel {
            titleLabel.removeFromSuperview()
            self.titleLabel = nil
        }
        guard let area = self.titleAreaCell else {
            return
        }
        let newLabel = UILabel()
        newLabel.textAlignment = .center
        newLabel.numberOfLines = 2
        newLabel.lineBreakMode = .byTruncatingTail
        self.titleLabel = newLabel
        area.addSubview(newLabel)

        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.lineBreakMode = .byTruncatingTail
        self.paraStyle = style
    }

    /// 初始化图片区域视图
    private func setupImageViewCell() {
        if let imageCell = self.imageViewCell {
            imageCell.removeFromSuperview()
            self.imageViewCell = nil
        }
        let newView = UIView()
        self.imageViewCell = newView
        newView.layer.cornerRadius = self.imageViewCellRadius
        self.addSubview(newView)
    }

    /// 初始化图片视图
    private func setupImageView() {
        if let imageView = self.imageView {
            imageView.removeFromSuperview()
            self.imageView = nil
        }
        guard let imageCell = self.imageViewCell else {
            return
        }
        let newImageView = UIImageView()
        newImageView.contentMode = .scaleAspectFit
        self.imageView = newImageView
        imageCell.addSubview(newImageView)
    }

    /// 初始化badge视图
    private func setupImageBadge() {
        if let badge = self.imageBadgeView {
            badge.removeFromSuperview()
            self.imageBadgeView = nil
        }

        guard let imageCell = self.imageViewCell else {
            return
        }
        let newBadgeView = BadgeView(with: .clear) // 初始化之后设置为clear会让其隐藏

        self.imageBadgeView = newBadgeView
        imageCell.addSubview(newBadgeView)
    }

    /// 根据视图模型的是否禁用标志决定选项是否响应事件
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

    /// 更新子视图的全部内容
    private func updateSubViewContent() {
        updateTitleContent()

        updateImageViewCellContent()
        updateImageViewBadge()
        updateImageViewContent()
    }

    /// 更新子视图的内容当视图状态发生改变后
    private func updateSubViewStyleWhenStatusChanged() {
        self.updateImageViewContent()
        self.updateTitleColor()
        self.updateImageViewCellContent()
    }

    /// 更新标题的内容
    private func updateTitleContent() {
        guard let viewModel = self.viewModel, let titleLabel = self.titleLabel else {
            return
        }
        self.updateTitleFontAndContent()
        self.updateTitleColor()
    }

    /// 更新标题的字号
    private func updateTitleFontAndContent() {
        guard let viewModel = self.viewModel,
              let titleArea = self.titleAreaCell,
              let titleLabel = self.titleLabel,
              let paraStyle = self.paraStyle else {
            return
        }
        let size = titleArea.frame.size
        let font = viewModel.font(for: size, lineHeight: self.textLineHeight)
        titleLabel.font = font
        // 修改行间距，使行间距加上字体的行高等于文本的行高
        paraStyle.lineSpacing = max(self.textLineHeight - font.lineHeight, 0)
        let attributeString = NSMutableAttributedString(string: viewModel.title,
                                                        attributes: [NSAttributedString.Key.paragraphStyle: paraStyle])
        titleLabel.attributedText = attributeString
    }

    /// 更新标题的颜色
    private func updateTitleColor() {
        guard let viewModel = self.viewModel, let titleLabel = self.titleLabel else {
            return
        }
        titleLabel.textColor = viewModel.titleColor(for: self.itemStatus)
    }

    /// 更新图片区域视图的内容
    private func updateImageViewCellContent() {
        guard let viewModel = self.viewModel, let imageViewCell = self.imageViewCell else {
            return
        }
        imageViewCell.backgroundColor = viewModel.backgroundColor(for: self.itemStatus)
    }

    /// 更新badge的内容
    private func updateImageViewBadge() {
        guard let viewModel = self.viewModel, let badge = self.imageBadgeView else {
            return
        }
        if case let .number(maxBadgeNumber) = viewModel.menuBadgeType.type, let max = maxBadgeNumber {
            badge.setMaxNumber(to: Int(max))
        }
        badge.style = viewModel.badgeStyle // 设置badge的显示风格
        badge.type = viewModel.badgeType // 设置badge的显示类型
        BadgeManager.setBadge(viewModel.path, type: viewModel.badgeType, strategy: .weak)
    }

    /// 更新图片的内容
    private func updateImageViewContent() {
        guard let viewModel = self.viewModel, let imageView = self.imageView else {
            return
        }
        imageView.tintColor = viewModel.imageColor(for: self.itemStatus)
        imageView.image = viewModel.image(for: self.itemStatus)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.updateTitleFontAndContent() // 当布局改变之后重新更新标题字号
        self.updateImageViewBadgeLayout() // 当布局改变之后更新badge的位置
    }

    /// 更新badge的位置约束
    private func updateImageViewBadgeLayout() {
        guard let cell = self.imageViewCell, let badgeView = self.imageBadgeView else {
            return
        }

        let badgeSize = badgeView.frame.size
        let badgeWidth = badgeSize.width
        let badgeHeight = badgeSize.height
        let cellRadius = self.imageViewCellRadius
        let down = (1 - pow(2, 0.5) / 2) * cellRadius
        let left = down + (badgeWidth - badgeHeight) / 2

        badgeView.snp.updateConstraints {
            make in
            make.centerX.equalTo(cell.snp.trailing).offset(-left)
            make.centerY.equalTo(cell.snp.top).offset(down)
        }
    }

    /// 初始化标题区域视图的约束
    private func setupTitleAreaCellStaticConstrain() {
        guard let area = self.titleAreaCell, let imageViewCell = self.imageViewCell else {
            return
        }

        area.snp.makeConstraints {
            make in
            make.bottom.equalToSuperview()
            make.top.equalTo(imageViewCell.snp.bottom).offset(self.imageViewCellAndTitleSpacingHeight)
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-8)
        }
    }

    /// 初始化标题的约束
    private func setupTitleViewStaticConstrain() {
        guard let titleView = self.titleLabel else {
            return
        }

        titleView.snp.makeConstraints {
            make in
            make.trailing.leading.top.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    /// 初始化图片区域视图的约束
    private func setupImageViewCellStaticConstrain() {
        guard let imageViewCell = self.imageViewCell else {
            return
        }

        imageViewCell.snp.makeConstraints {
            make in
            make.width.height.equalTo(self.imageViewCellWidthAndHeight)
            make.top.centerX.equalToSuperview()
        }
    }

    /// 初始化badge的约束
    private func setupBadgeViewStaticConstrain() {
        guard let cell = self.imageViewCell, let badgeView = self.imageBadgeView else {
            return
        }
        badgeView.snp.makeConstraints {
            make in
            make.centerX.equalTo(cell.snp.trailing)
            make.centerY.equalTo(cell.snp.top)
            make.size.equalTo(CGSize.zero)
        }
    }

    /// 初始化图片的约束
    private func setupImageViewStaticConstrain() {
        guard let imageView = self.imageView else {
            return
        }
        imageView.snp.makeConstraints {
            make in
            make.centerX.centerY.equalToSuperview()
            make.width.height.equalTo(self.imageViewWidthAndHeight)
        }
    }

    /// 执行点击选项之后的操作
    func executeAction() {
        guard let viewModel = self.viewModel else {
            return
        }
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_hidemenuitems")) {//Global 纯UI相关，成本比较大，先不改
            // 开启后disable状态接受点击，点击后提示用户当前开发者已禁用此功能
            //https://bytedance.feishu.cn/docx/doxcnN7P1NBk7xTzVynqF1lBzAg
            if viewModel.disable {
                guard let mainSceneWindow = Navigator.shared.mainSceneWindow else {  //Global 纯UI相关，成本比较大，先不改
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
                updateSubViewStyleWhenStatusChanged()
            }
        } else {
            self.itemStatus = .selected // 触摸开始后设置为选中状态
            updateSubViewStyleWhenStatusChanged()
        }

        super.touchesBegan(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_hidemenuitems")) {//Global 纯UI相关，成本比较大，先不改
            if self.itemStatus != .disabled {
                self.itemStatus = .normal // 触摸结束后设置为正常状态
                updateSubViewStyleWhenStatusChanged()
            }
        } else {
            self.itemStatus = .normal // 触摸结束后设置为正常状态
            updateSubViewStyleWhenStatusChanged()
        }

        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_hidemenuitems")) {//Global 纯UI相关，成本比较大，先不改
            if self.itemStatus != .disabled {
                self.itemStatus = .normal // 触摸取消后设置为正常状态
                updateSubViewStyleWhenStatusChanged()
            }
        } else {
            self.itemStatus = .normal // 触摸取消后设置为正常状态
            updateSubViewStyleWhenStatusChanged()
        }

        super.touchesCancelled(touches, with: event)
    }

}
