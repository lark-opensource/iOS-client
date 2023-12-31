//
//  MenuActionCell.swift
//  LarkMenuController
//
//  Created by bytedance on 2021/12/23.
//

import Foundation
import UIKit
import SnapKit
import LKCommonsLogging
import LarkInteraction
import UniverseDesignColor
import LarkBadge

final class MenuActionCell: UICollectionViewCell {

    static let labelFont: CGFloat = 11
    private var imageView: UIImageView = .init(image: nil)
    private var titleLabel: UILabel = .init()
    lazy var badgeView: BadgeView = {
        let badgeView = BadgeView(with: .dot(.web))
        return badgeView
    }()

    // 阴影 layer，用于触摸手势 hover 时显示阴影
    private var pointerLayer: UIView = UIView()

    var imageInset: UIEdgeInsets = .zero {
        didSet {
            if oldValue == imageInset { return }
            self.imageView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview().inset(self.imageInset)
            }
        }
    }

    var item: MenuActionItem? {
        didSet {
            self.badgeView.isHidden = !(item?.isShowDot ?? false)
            let enable = item?.enable ?? false
            item?.image.setActionImage(imageView: self.imageView, enable: enable)
            self.titleLabel.text = item?.name
            self.titleLabel.textColor = enable ? UIColor.ud.textTitle : UIColor.ud.iconDisabled
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(self.pointerLayer)
        pointerLayer.backgroundColor = UIColor.ud.fillHover
        pointerLayer.layer.cornerRadius = 12
        pointerLayer.isHidden = true

        let wrapperView = UIView()
        self.contentView.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { (make) in
            make.centerX.top.equalToSuperview()
            make.width.height.equalTo(22)
        }

        self.imageView = UIImageView()
        wrapperView.addSubview(self.imageView)
        self.imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(self.imageInset)
        }
        self.imageView.isUserInteractionEnabled = false

        let label = UILabel()
        label.numberOfLines = 2
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: MenuActionCell.labelFont)
        label.textColor = UIColor.ud.textTitle
        label.adjustsFontSizeToFitWidth = true
        label.baselineAdjustment = .alignCenters
        self.titleLabel = label
        self.contentView.addSubview(label)
        self.titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(wrapperView.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
        }
        wrapperView.accessibilityIdentifier = "menu.action.cell.wrapper"
        imageView.accessibilityIdentifier = "menu.action.cell.image"
        label.accessibilityIdentifier = "menu.action.cell.label"
        self.contentView.addSubview(badgeView)
        badgeView.snp.makeConstraints { (maker) in
            maker.top.equalTo(imageView.snp.top).offset(-5)
            maker.left.equalTo(imageView.snp.right).offset(-5)
            maker.width.height.equalTo(8)
        }
        badgeView.isHidden = true

        self.pointerLayer.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
            maker.bottom.equalTo(titleLabel).offset(12)
        }

        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(
                    effect: .highlight,
                    shape: .roundedBounds({ (interaction, _) -> (CGRect, CGFloat) in
                        guard let view = interaction.view?.superview as? MenuActionCell else {
                            return (.zero, 0)
                        }
                        // 上下留6pt的空间
                        let height = view.titleLabel.frame.maxY + 12
                        // actionbarview宽度大于384时，刚好允许一排6个item的阴影宽度为60(60*6+14)，否则，适应较窄的情况，宽度为56
                        let width = view.bounds.width
                        // 阴影横向居中
                        let xOffset = (view.bounds.width - width) / 2
                        // 阴影纵向居中 不用view.bounds是因为有item的title有两行时，其他item下部会空出来，存在而视觉不可见，但不应该影响阴影位置
                        let yOffset: CGFloat = (view.titleLabel.frame.maxY - height) / 2
                        return (CGRect(x: xOffset, y: yOffset, width: width, height: height), 8)
                    })
                )
            )
            self.contentView.addLKInteraction(pointer)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 设置 pointer 阴影显隐
    func setPointerLayer(show: Bool) {
        self.pointerLayer.isHidden = !show
    }
}
