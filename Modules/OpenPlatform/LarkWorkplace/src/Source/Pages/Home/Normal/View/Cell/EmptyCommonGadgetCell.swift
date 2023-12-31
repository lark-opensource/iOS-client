//
//  EmptyCommonGadgetCell.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/5/8.
//
// 设计稿参考：https://app.zeplin.io/project/5d75f6e0d402aa1a8f8bc242/screen/5ea50d8a395ffa255f3153d6

import LarkUIKit
import UniverseDesignIcon
import UniverseDesignColor

private let kCornerRadius: CGFloat = 6.0

/// 工作台方形「添加应用」cell
final class EmptyCommonGadgetCell: UICollectionViewCell {
    // MARK: Cell properties
    /// ➕号图标
    private lazy var addGadgetIcon: UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.clipsToBounds = true
        iconImageView.image = UDIcon.addOutlined.withRenderingMode(.alwaysTemplate)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = UIColor.ud.primaryContentDefault
        return iconImageView
    }()
    /// 添加应用的Label
    private lazy var addGadgetLabel: UILabel = {
        let addGadgetLabel = UILabel()
        addGadgetLabel.text = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_AddApp
        // swiftlint:disable init_font_with_token
        addGadgetLabel.font = UIFont.systemFont(ofSize: 17)
        // swiftlint:enable init_font_with_token
        addGadgetLabel.textColor = UIColor.ud.primaryContentDefault
        addGadgetLabel.textAlignment = .center
        return addGadgetLabel
    }()

//    private lazy var borderLayer: CAShapeLayer = {
//        let viewBorder = CAShapeLayer()
//        viewBorder.lineDashPattern = [3, 3]
//        viewBorder.lineWidth = 1.0
//        viewBorder.frame = contentView.bounds
//        viewBorder.fillColor = nil
//        return viewBorder
//    }()

    // MARK: Cell initial
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupContentView()
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        return super.preferredLayoutAttributesFitting(layoutAttributes)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

//        borderLayer.frame = bounds
//        borderLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: kCornerRadius).cgPath
    }

    // MARK: Cell layout
    /// 设置contentview样式（外层样式）
    private func setupContentView() {
        contentView.backgroundColor = UIColor.ud.bgFiller
        contentView.layer.cornerRadius = kCornerRadius
        contentView.layer.masksToBounds = true

        /// 虚线描边
//        contentView.layer.addSublayer(borderLayer)
//        borderLayer.ud.setStrokeColor(UIColor.ud.lineBorderComponent)
    }

    /// 设置视图
    private func setupSubviews() {
        let stackView = UIStackView()
        stackView.spacing = 4
        stackView.axis = .horizontal
        stackView.addArrangedSubview(addGadgetIcon)
        stackView.addArrangedSubview(addGadgetLabel)

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        // 通过子视图撑大
        addGadgetIcon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.height.width.equalTo(20)
        }
        addGadgetLabel.snp.makeConstraints { (make) in
            make.height.equalTo(24)
        }
    }
}
