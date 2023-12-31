//
//  MenuGroupCell.swift
//  SKDoc
//
//  Created by zoujie on 2021/1/24.
//  


import SKFoundation
import UIKit
import SKUIKit
import UniverseDesignColor

class MenuGroupCell: UICollectionViewCell {
    private var contentButtons: [UIButton] = []
    private var members: [BlockMenuItem] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .clear
        layer.cornerRadius = 8
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        removeAllPointer()
    }
    
    func removeAllPointer() {
        contentView.subviews.forEach { (subView) in
            subView.docs.removeAllPointer()
        }
    }

    public func setItems(blockMenuItem: BlockMenuItem?) {
        guard let members = blockMenuItem?.members, members.count > 0 else {
            return
        }
        //避免cell复用，导致布局混乱
        contentView.subviews.forEach { (subView) in
            subView.removeFromSuperview()
        }

        contentButtons.removeAll()
        self.members = members
        var lastButton: UIButton?

        var totalLeftOffset: CGFloat = 0

        for (i, item) in members.enumerated() {
            let button = UIButton()
            button.setBackgroundImage(UIImage.docs.create(by: UDColor.N900.withAlphaComponent(0.1)), for: .highlighted)
            button.setBackgroundImage(UIImage.docs.create(by: UDColor.bgBodyOverlay), for: .normal)
            button.layer.masksToBounds = true
            button.setImage(item.loadImage()?.ud.withTintColor(UDColor.iconN1), for: [.normal, .highlighted])

            if i == 0 {
                //button设置左上角和左下角为圆角
                button.layer.cornerRadius = 8
                button.layer.maskedCorners = .left
            } else if i == members.count - 1 {
                //button设置右上角和右下角为圆角
                button.layer.cornerRadius = 8
                button.layer.maskedCorners = .right
            }

            contentView.addSubview(button)

            button.snp.makeConstraints { (make) in
                make.top.bottom.equalToSuperview()
                if  i == 0 {
                    make.left.equalToSuperview()
                } else if i == members.count - 1 {
                    make.right.equalToSuperview()
                } else if lastButton != nil {
                    make.left.equalToSuperview().offset(totalLeftOffset)
                }
                make.width.equalTo(BlockMenuConst.cellWidth)
            }
            totalLeftOffset += BlockMenuConst.cellWidth + BlockMenuConst.groupSeparatorWidth

            if item.id != BlockMenuV2Identifier.separator.rawValue {
                button.tag = i
                button.addTarget(self, action: #selector(clickedItem(button:)), for: .touchUpInside)
            }

            if !(item.enable ?? true) {
                button.setBackgroundImage(UIImage.lu.fromColor(UDColor.bgBodyOverlay), for: .normal)
                button.setImage(item.loadImage()?.ud.withTintColor(UDColor.iconDisabled), for: [.normal, .highlighted])
            } else {
                button.docs.addStandardHover()
                if item.selected ?? false {
                    
                    button.setBackgroundImage(UIImage.lu.fromColor(UDColor.fillActive.withAlphaComponent(0.16)), for: .normal)
                    button.setBackgroundImage(UIImage.lu.fromColor(UDColor.B900.withAlphaComponent(0.16)), for: .highlighted)
                    button.setImage(item.loadImage()?.ud.withTintColor(UDColor.primaryContentDefault), for: [.normal, .highlighted])
                    button.layer.zPosition = 1
                } else {
                    button.setBackgroundImage(UIImage.lu.fromColor(UDColor.N900.withAlphaComponent(0.1)), for: .highlighted)
                    button.setBackgroundImage(UIImage.lu.fromColor(UDColor.bgBodyOverlay), for: .normal)
                    button.setImage(item.loadImage()?.ud.withTintColor(UDColor.iconN1), for: [.normal, .highlighted])
                    button.layer.zPosition = 0
                }
            }

            contentButtons.append(button)
            lastButton = button
        }
    }

    @objc
    private func clickedItem(button: UIButton) {
        guard members[button.tag].enable ?? true else { return }
        members[button.tag].action?()
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        updateFrame()
        return layoutAttributes
    }

    public func updateFrame() {
        var totalLeftOffset: CGFloat = 0
        let buttons = contentView.subviews.filter { $0 is UIButton }
        for (i, button) in buttons.enumerated() {
            button.snp.updateConstraints { (make) in
                if i > 0 && i < buttons.count - 1 {
                    make.left.equalToSuperview().offset(totalLeftOffset)
                }
                make.width.equalTo(BlockMenuConst.cellWidth)
            }
            totalLeftOffset += BlockMenuConst.cellWidth + BlockMenuConst.groupSeparatorWidth
        }
        self.contentView.layoutIfNeeded()
    }
}
