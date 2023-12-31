//
//  HorizontalTabCell.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2021/5/23.
//

import LarkUIKit
import LarkInteraction

/// 应用中心主页全部应用对应的Header里边的横向滑动按钮对应的表格视图的cell
final class HorizontalTabCell: UICollectionViewCell {

    private lazy var highlightedBlueColor: UIColor = {
        // swiftlint:disable init_color_with_token
        return UIColor(
            red: 51 / 255,
            green: 119 / 255,
            blue: 1,
            alpha: 1
        )
        // swiftlint:enable init_color_with_token
    }()

    override var isSelected: Bool {
        didSet {
            updateStyle(with: isSelected)
        }
    }
    /// tab字号
    var fontSize: CGFloat = 14.0
    private lazy var container: UIView = {
        UIView()
    }()
    /// 标题
    private lazy var label: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: fontSize)
        label.textAlignment = .center
        return label
    }()

    /// 下划线
    private lazy var hLineView: UIView = {
        let view = UIView()
        view.backgroundColor = highlightedBlueColor
        view.alpha = 0
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
        contentView.addSubview(container)
        container.addSubview(label)
        container.addSubview(hLineView)
        container.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.width.equalToSuperview()
            make.height.equalTo(24)
        }
        // 标题布局
        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.height.equalTo(18)
        }
        // 下划线布局
        hLineView.snp.makeConstraints { (make) in
            make.height.equalTo(2)
            make.bottom.equalToSuperview()
            make.left.equalTo(label.snp.left)
            make.right.equalTo(label.snp.right)
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

    func setTitle(with text: String, size: CGFloat) {
        fontSize = size
        label.text = text
        label.font = .systemFont(ofSize: size)
        label.snp.remakeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.height.equalTo(size + 4)
        }
    }

    /// 更新cell样式
    /// - Parameter isSelected: 是否选中
    private func updateStyle(with isSelected: Bool) {
        if isSelected {
            /// 选中 标题颜色变蓝 下划线alpha变为1
            label.font = .systemFont(ofSize: fontSize, weight: .medium)
            label.textColor = highlightedBlueColor
            hLineView.alpha = 1
        } else {
            /// 未选中 标题颜色变为n900 下划线alpha变为0
            label.font = .systemFont(ofSize: fontSize)
            label.textColor = UIColor.ud.textTitle
            hLineView.alpha = 0
        }
    }

    static let labelHeight: CGFloat = 20
    static let lineHeight: CGFloat = 2
    static let cellHeight: CGFloat = labelHeight + lineHeight
    static let cellPadding: CGFloat = 10
}
