//
//  ImageTitleCell.swift
//  LarkSettingUI
//
//  Created by aslan on 2023/10/30.
//

import Foundation
import UIKit
import UniverseDesignIcon
import ByteWebImage
import FigmaKit

open class ImageTitleCellProp: CellProp {
    var title: String
    var imageUrl: String?
    var image: UIImage?

    /// imageUrl 和 image 二选一，优先以imageUrl加载
    public init(
        imageUrl: String? = nil,
        image: UIImage? = nil,
         title: String,
         cellIdentifier: String = "ImageTitleCell",
         separatorLineStyle: CellSeparatorLineStyle = .normal,
         selectionStyle: CellSelectionStyle = .normal,
         id: String? = nil) {
        self.imageUrl = imageUrl
        self.image = image
        self.title = title
        super.init(cellIdentifier: cellIdentifier,
                   separatorLineStyle: separatorLineStyle,
                   selectionStyle: selectionStyle,
                   id: id)
    }
}

open class ImageTitleCell: BaseCell {

    let horizontalSpacing: CGFloat = 16.0
    let innerSpacing: CGFloat = 12.0
    let imageCornerRadius = 6.0
    let imageHeight: CGFloat = 24.0

    open override func update(_ info: CellProp) {
        super.update(info)
        guard let info = info as? ImageTitleCellProp else { return }
        titleLabel.setFigmaText(info.title)
        if let imageUrl = info.imageUrl {
            iconView.bt.setLarkImage(with: .default(key: imageUrl))
        } else {
            iconView.image = info.image
        }
    }

    lazy var contentContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = innerSpacing
        return stack
    }()

    private(set) lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.ux.setSmoothCorner(radius: imageCornerRadius)
        return imageView
    }()

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal) // 必须完整显示，不能被压缩
        return label
    }()

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(contentContainer)
        setupContainerStackView(contentContainer)
        contentContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(horizontalSpacing)
            make.trailing.equalToSuperview().offset(-horizontalSpacing)
            make.top.equalToSuperview().offset(innerSpacing)
            make.bottom.equalToSuperview().offset(-innerSpacing)
            make.height.greaterThanOrEqualTo(imageHeight)
        }
        iconView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: imageHeight, height: imageHeight))
            make.centerY.equalToSuperview()
        }
    }

    func setupContainerStackView(_ contentContainer: UIStackView) {
        if let leadingView = getLeadingView() {
            contentContainer.addArrangedSubview(leadingView)
        }
        contentContainer.addArrangedSubview(iconView)
        contentContainer.addArrangedSubview(titleLabel)
        if let trailingView = getTrailingView() {
            contentContainer.addArrangedSubview(trailingView)
        }
    }
    /// 必须明确尺寸约束，否则会布局混乱
    open func getLeadingView() -> UIView? {
        return nil
    }
    /// 必须明确尺寸约束，否则会布局混乱
    open func getTrailingView() -> UIView? {
        return nil
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
