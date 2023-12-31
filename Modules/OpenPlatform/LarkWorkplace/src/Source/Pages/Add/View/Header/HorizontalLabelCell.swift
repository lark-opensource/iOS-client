//
//  HorizontalLabelCell.swift
//  LarkWorkplace
//
//  Created by 武嘉晟 on 2019/9/29.
//

import LarkUIKit
import LarkInteraction
import ByteWebImage

/// 应用中心主页全部应用对应的Header里边的横向滑动按钮对应的表格视图的cell
final class HorizontalLabelCell: UICollectionViewCell {
    private var unselectedFont: UIFont = .systemFont(ofSize: 14)
    private var selectedFont: UIFont = .systemFont(ofSize: 14, weight: .medium)

    override var isSelected: Bool {
        didSet {
            updateSelectedStyle(with: isSelected)
        }
    }

    /// 标题容器，包含头像和标题
    private lazy var titleContainer: UIStackView = {
        let containerView = UIStackView(arrangedSubviews: [avatarView, label])
        containerView.axis = .horizontal
        containerView.alignment = .center
        containerView.distribution = .equalSpacing
        containerView.spacing = 6
        containerView.backgroundColor = .clear
        return containerView
    }()

    /// 头像
    private lazy var avatarView: WPMaskImageView = {
        let icon = WPMaskImageView()
        icon.backgroundColor = UIColor.ud.bgFiller
        icon.clipsToBounds = true
        icon.sqRadius = WPUIConst.AvatarRadius.xs6
        icon.sqBorder = WPUIConst.BorderW.pt1
        return icon
    }()

    /// 标题
    private lazy var label: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = unselectedFont
        label.textAlignment = .center
        return label
    }()

    /// 下划线
    private lazy var hLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.primaryContentDefault
        view.alpha = 0
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.clipsToBounds = false
        contentView.addSubview(titleContainer)
        contentView.addSubview(hLineView)
        /// 标题布局
        titleContainer.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.centerX.equalTo(hLineView.snp.centerX)
        }
        // 头像大小
        avatarView.snp.makeConstraints { make in
            make.width.height.equalTo(22)
        }

        /// 下划线布局
        hLineView.layer.cornerRadius = 2
        hLineView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        hLineView.snp.makeConstraints { (make) in
            make.height.equalTo(2)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().inset(10)
            make.right.equalToSuperview().inset(10)
        }

        // 标题高亮适配
        label.addPointer(
            .init(
                effect: .highlight,
                shape: { (size) -> PointerInfo.ShapeSizeInfo in
                    return (CGSize(width: size.width, height: highLightCommonTextHeight), highLightCorner)
                }
            )
        )
    }

    /// 视图更新
    ///
    /// - Parameters:
    ///   - text: 标题文字
    ///   - avatarURLStr: 头像 URL
    ///   - selectedFont: 标题被选中时的字体
    ///   - unselectedFont: 标题未被选中时的字体
    ///   - cellLeftPadding: 标题区域左侧 Padding
    ///   - cellRightPadding: 标题区域右侧 Padding
    func refreshViews(text: String, avatarURLStr: String?, selectedFont: UIFont, unselectedFont: UIFont, cellLeftPadding: CGFloat, cellRightPadding: CGFloat) {
        label.text = text
        updateAvatarView(with: avatarURLStr)
        updateStyle(selectedFont: selectedFont, unselectedFont: unselectedFont, cellLeftPadding: cellLeftPadding, cellRightPadding: cellRightPadding)
    }

    /// 更新头像，如果 `urlStr` 为 `nil` 或 `urlStr` 为空，不展示头像
    ///
    /// - Parameter urlStr: 图像链接
    private func updateAvatarView(with urlStr: String?) {
        guard let imageURLStr = urlStr, !imageURLStr.isEmpty else {
            avatarView.isHidden = true
            return
        }
        avatarView.bt.setLarkImage(.default(key: imageURLStr), placeholder: Resources.icon_placeholder)
        avatarView.isHidden = false
    }

    /// 更新显示风格和布局
    ///
    /// - Parameters:
    ///   - selectedFont: 标题被选中时的字体
    ///   - unselectedFont: 标题未被选中时的子图
    ///   - cellLeftPadding: 标题区域左侧 Padding
    ///   - cellRightPadding: 标题区域右侧 Padding
    private func updateStyle(
        selectedFont: UIFont,
        unselectedFont: UIFont,
        cellLeftPadding: CGFloat,
        cellRightPadding: CGFloat
    ) {
        label.font = isSelected ? selectedFont : unselectedFont
        self.selectedFont = selectedFont
        self.unselectedFont = unselectedFont
        hLineView.snp.updateConstraints { (make) in
            make.left.equalToSuperview().inset(cellLeftPadding)
            make.right.equalToSuperview().inset(cellRightPadding)
        }
    }

    /// 更新 选中 / 非选中 样式
    ///
    /// - Parameter isSelected: 是否选中
    private func updateSelectedStyle(with isSelected: Bool) {
        if isSelected {
            /// 选中 标题颜色变蓝 下划线alpha变为1
            label.font = selectedFont
            label.textColor = UIColor.ud.primaryContentDefault
            hLineView.alpha = 1
        } else {
            /// 未选中 标题颜色变为n600 下划线alpha变为0
            label.font = unselectedFont
            label.textColor = UIColor.ud.textCaption
            hLineView.alpha = 0
        }
    }
}
