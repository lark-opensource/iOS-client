//
//  ToolBarCollectionCell.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/9.
//

import UIKit
import ByteViewCommon

class ToolBarCollectionCell: UICollectionViewCell {
    var item: ToolBarItem?

    var isLandscapeMode: Bool { false }

    var containerBackgroundColor: UIColor {
        UIColor.ud.bgFloat
    }

    lazy var imageContainerView = UIView()

    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    // 用于参会人数量 label
    lazy var numberLabel: BVLabel = {
        let label = BVLabel()
        label.textColor = UIColor.ud.N700
        label.isHidden = true
        return label
    }()

    lazy var textBadgeLabel: BVLabel = {
        let label = BVLabel()
        label.textColor = UIColor.ud.udtokenTagTextSYellow
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.backgroundColor = UIColor.ud.udtokenTagBgYellow
        label.textAlignment = .center
        label.textContainerInset = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        label.isHidden = true
        return label
    }()

    lazy var redPointView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.functionDangerContentDefault
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet {
            imageContainerView.backgroundColor = isSelected ? UIColor.ud.N900.withAlphaComponent(0.1) : containerBackgroundColor
        }
    }

    override var isHighlighted: Bool {
        didSet {
            imageContainerView.backgroundColor = isHighlighted ? UIColor.ud.N900.withAlphaComponent(0.1) : containerBackgroundColor
        }
    }

    func setupSubviews() {
        imageContainerView.backgroundColor = containerBackgroundColor
        imageContainerView.vc.setSquircleMask(cornerRadius: 10, rect: CGRect(x: 0, y: 0, width: 52, height: 52))
        contentView.addSubview(imageContainerView)
        imageContainerView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 52, height: 52))
        }

        imageContainerView.addInteraction(type: .hover)
        imageContainerView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.size.equalTo(ToolBarItemLayout.collectionIconSize)
            make.center.equalToSuperview()
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(imageContainerView.snp.bottom).offset(6)
            make.left.right.equalToSuperview().inset(4)
        }

        contentView.addSubview(numberLabel)
        numberLabel.snp.makeConstraints { make in
            make.height.equalTo(18)
            make.top.equalTo(imageContainerView).inset(6)
            make.left.equalTo(imageContainerView).inset(30)
        }

        contentView.addSubview(textBadgeLabel)
        textBadgeLabel.snp.makeConstraints { make in
            make.height.equalTo(18)
            make.width.greaterThanOrEqualTo(8)
            make.right.equalTo(imageContainerView).offset(10)
            make.top.equalTo(imageContainerView).offset(-6)
        }

        contentView.addSubview(redPointView)
        redPointView.snp.makeConstraints { make in
            make.size.equalTo(10)
            make.top.equalTo(imageContainerView).inset(-2)
            make.right.equalTo(imageContainerView).inset(-2)
        }
    }

    static let attributes: [NSAttributedString.Key: Any] = {
        return VCFontConfig.tinyAssist.toAttributes(alignment: .center, lineBreakMode: .byWordWrapping)
    }()

    func update(with item: ToolBarItem) {
        self.item = item
        isUserInteractionEnabled = item.isEnabled
        var attributes = Self.attributes
        attributes[.foregroundColor] = item.isEnabled ? UIColor.ud.textCaption : UIColor.ud.textDisabled
        titleLabel.attributedText = NSAttributedString(string: item.title, attributes: attributes)

        imageView.image = ToolBarImageCache.image(for: item, location: isLandscapeMode ? .phoneMore : .landscapeMore)

        numberLabel.isHidden = true
        switch item.badgeType {
        case .none:
            textBadgeLabel.isHidden = true
            redPointView.isHidden = true
        case .dot:
            textBadgeLabel.isHidden = true
            redPointView.isHidden = false
        case .text(let text):
            textBadgeLabel.isHidden = false
            textBadgeLabel.attributedText = NSAttributedString(string: text, config: .tinyAssist, alignment: .center)
            redPointView.isHidden = true
        }

        // 参会人特化逻辑
        if let participantItem = item as? ToolBarParticipantsItem {
            numberLabel.isHidden = false
            numberLabel.attributedText = NSAttributedString(string: "\(participantItem.participantNumber)", config: .assist, alignment: .center)
        }
    }
}

class ToolBarLandscapeCollectionCell: ToolBarCollectionCell {
    override var containerBackgroundColor: UIColor {
        UIColor.ud.bgFloat
    }

    override var isLandscapeMode: Bool { true }

    override func setupSubviews() {
        super.setupSubviews()
        imageContainerView.vc.setSquircleMask(cornerRadius: 10, rect: CGRect(x: 0, y: 0, width: 46, height: 46))
        imageContainerView.snp.updateConstraints { make in
            make.size.equalTo(CGSize(width: 46, height: 46))
        }

        imageContainerView.backgroundColor = UIColor.ud.bgFloat

        imageView.snp.updateConstraints { (make) in
            make.size.equalTo(ToolBarItemLayout.landscapeCollectionIconSize)
        }

        titleLabel.snp.updateConstraints { (make) in
            make.top.equalTo(imageContainerView.snp.bottom).offset(4)
        }

        textBadgeLabel.snp.updateConstraints { make in
            make.right.equalTo(imageContainerView).offset(6)
        }
    }
}
