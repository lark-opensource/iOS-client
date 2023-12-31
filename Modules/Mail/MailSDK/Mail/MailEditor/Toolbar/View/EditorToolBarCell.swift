//
//  EditorToolBarCell.swift
//  MailSDK
//
//  Created by majx on 2019/6/24
//

import UIKit
import LarkInteraction

class EditorToolBarFooter: UICollectionReusableView {
    let line = UIView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(line)
        line.backgroundColor = UIColor.ud.lineDividerDefault
        line.snp.makeConstraints { (make) in
            make.top.equalTo(8)
            make.bottom.equalTo(-8)
            make.width.equalTo(1)
            make.centerX.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
// cell
class EditorToolBarCell: UICollectionViewCell {
    var isEnabled: Bool = true {
        didSet {
            contentView.isUserInteractionEnabled = isEnabled
            contentView.alpha = isEnabled ? 1.0 : 0.3
        }
    }

    private var itemView: EditorToolBarItemView = {
        let itemView = EditorToolBarItemView(frame: CGRect(origin: .zero, size: CGSize(width: EditorToolBar.Const.imageWidth,
                                                                                       height: EditorToolBar.Const.imageWidth)))
       return itemView
    }()

    override var isHighlighted: Bool {
        didSet {
////            itemView.icon.tintColor = isHighlighted ? UIColor.ud.primaryContentDefault : .clear
            itemView.iconBG.backgroundColor = isHighlighted ? UIColor.ud.primaryContentDefault.withAlphaComponent(0.1) : .clear
            layoutIfNeeded()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
//        selectedBackgroundView = UIView()
//        selectedBackgroundView?.backgroundColor = UIColor.ud.fillPressed
        contentView.addSubview(itemView)
    }

    override func layoutSubviews() {
        itemView.frame = bounds
//        selectedBackgroundView?.frame = bounds.inset(by: UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        isEnabled = false
    }
    
    func update(image: UIImage, _ isSelected: Bool, useOrigin: Bool = false) {
        if useOrigin {
            // myai icon 缩小 1point
            itemView.icon.image = image
            itemView.icon.bounds = CGRect(x: 0, y: 0, width: EditorToolBar.Const.imageWidth - 1, height: EditorToolBar.Const.imageWidth - 1)
        } else {
            itemView.icon.image = image.withRenderingMode(.alwaysTemplate)
            itemView.icon.bounds = CGRect(x: 0, y: 0, width: EditorToolBar.Const.imageWidth,
                                          height: EditorToolBar.Const.imageWidth)
        }
        itemView.icon.tintColor = isSelected ? UIColor.ud.primaryContentDefault : UIColor.ud.iconN1
        itemView.iconBG.backgroundColor = isSelected ? UIColor.ud.primaryContentDefault.withAlphaComponent(0.1) : .clear
    }
}

// icon
class EditorToolBarItemView: UIView {
    lazy var icon: UIImageView = UIImageView()
    lazy var iconBG = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(iconBG)
        iconBG.frame = CGRect(origin: .zero, size: CGSize(width: EditorToolBar.Const.imageWidth + 4,
                                                        height: EditorToolBar.Const.imageWidth + 4))
        iconBG.layer.cornerRadius = 4
        iconBG.layer.masksToBounds = true
        addSubview(icon)
        icon.contentMode = .scaleAspectFit
        icon.frame = CGRect(origin: .zero, size: CGSize(width: EditorToolBar.Const.imageWidth,
                                                        height: EditorToolBar.Const.imageWidth))
        icon.layer.cornerRadius = 4
        icon.layer.masksToBounds = true
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: PointerStyle(
                    effect: .highlight,
                    shape: .roundedSize({ (_, _) -> (CGSize, CGFloat) in
                        return (CGSize(width: EditorToolBar.Const.imageWidth + 10, height: EditorToolBar.Const.imageWidth + 10), 4)
                    })
                )
            )
            self.addLKInteraction(pointer)
        }
    }

    override func layoutSubviews() {
        icon.center = center
        iconBG.center = center
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
