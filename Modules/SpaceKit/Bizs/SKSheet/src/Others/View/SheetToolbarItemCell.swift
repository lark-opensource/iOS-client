//
// Created by duanxiaochen.7 on 2020/11/23.
// Affiliated with SKBrowser.
//
// Description: Sheet 工具栏 cell（支持文字或图片）

import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignBadge

class SheetToolbarItemCell: UICollectionViewCell {

    var hasSelectedState = false
    var info: SheetToolbarItemInfo?
    
    lazy var highlightBackground = UIView(frame: .zero).construct { it in
        it.backgroundColor = UIColor.ud.N200
        it.layer.cornerRadius = 6
    }

    lazy var imageView = UIImageView(frame: .zero).construct { (it) in
        it.contentMode = .scaleAspectFit
    }

    lazy var textLabel = UILabel(frame: .zero).construct { it in
        it.textAlignment = .center
        it.font = .systemFont(ofSize: 18, weight: .medium)
    }

    lazy var badgeView = UDBadge(config: .dot)

    override var isHighlighted: Bool {
        didSet {
            highlightBackground.isHidden = !isHighlighted
        }
    }

    override var isSelected: Bool {
        didSet {
            if let info = info, !info.isEnabled {
                imageView.tintColor = UIColor.ud.N400
                textLabel.textColor = UIColor.ud.N400
            } else {
                imageView.tintColor = isSelected && hasSelectedState ? UIColor.ud.colorfulBlue : UIColor.ud.N900
                textLabel.textColor = isSelected && hasSelectedState ? UIColor.ud.colorfulBlue : UIColor.ud.N900
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        textLabel.isHidden = true
        imageView.isHidden = true
        isHighlighted = false
        isSelected = false
    }

    func setupCell(with info: SheetToolbarItemInfo) {
        self.info = info
        accessibilityIdentifier = info.accID
        hasSelectedState = info.hasSelectedState
        textLabel.text = info.text
        imageView.image = info.image?.withRenderingMode(.alwaysTemplate)
        isSelected = info.isSelected
        contentView.docs.removeAllPointer()
        contentView.docs.addHighlight(with: UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 4), radius: 8)

        var itemView: UIView
        if info.text != nil {
            itemView = textLabel
        } else {
            itemView = imageView
        }
        contentView.addSubview(highlightBackground)
        contentView.addSubview(textLabel)
        contentView.addSubview(itemView)
        badgeView.removeFromSuperview()

        itemView.snp.makeConstraints { (make) in
            make.height.equalTo(24)
            make.center.equalToSuperview()
        }
        itemView.isHidden = false

        badgeView = itemView.addBadge(.dot, anchor: .topRight)
        badgeView.config.dotSize = .small
        badgeView.isHidden = !info.isBadged

        highlightBackground.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        highlightBackground.isHidden = !isHighlighted
    }
}
