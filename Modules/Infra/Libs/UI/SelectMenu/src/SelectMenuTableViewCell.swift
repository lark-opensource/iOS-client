//
//  SelectMenuTableViewCell.swift
//  LarkDynamic
//
//  Created by Songwen Ding on 2019/7/18.
//

import Foundation
import UIKit
import LarkUIKit
import ByteWebImage
import UniverseDesignIcon
import UniverseDesignCheckBox

final class SelectMenuTableViewCell: BaseTableViewCell {
    public var bgColor: UIColor = UIColor.ud.bgBody
    private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private var accessoryImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = BundleResources.SelectMenu.accessory_select
        return imageView
    }()

    private var seprater: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()
    
    private var multiCheckBox: UDCheckBox = {
        let checkBox = UDCheckBox(boxType: .multiple)
        checkBox.isUserInteractionEnabled = false
        return checkBox
    }()

    var title: String? {
        set { self.titleLabel.text = newValue }
        get { return self.titleLabel.text }
    }

    var icon: SelectMenuViewModel.Icon? {
        didSet {
            iconImageView.isHidden = (icon == nil)
            let size = (icon != nil) ? 16 : 0
            iconImageView.snp.updateConstraints { make in
                make.width.height.equalTo(size)
            }
            updateTitleLabelConstraints()
            if let token = icon?.udToken as? String,
               let image = Self.getIconByKey(token, iconColor: icon?.color) {
                self.iconImageView.image = image
            } else if let imgKey = icon?.imgKey {
                self.iconImageView.bt.setLarkImage(.default(key: imgKey))
            }
        }
    }
    
    var isChosen: Bool = false {
        didSet {
            accessoryImageView.isHidden = (!isChosen || isMulti)
            multiCheckBox.isSelected = (isChosen && isMulti)
            updateTitleLabelConstraints()
        }
    }
    
    var isMulti: Bool = false {
        didSet {
            let size = isMulti ? 20 : 0
            multiCheckBox.snp.updateConstraints { make in
                make.width.height.equalTo(size)
            }
            updateTitleLabelConstraints()
            accessoryImageView.isHidden = (!isChosen || isMulti)
            multiCheckBox.isSelected = (isChosen && isMulti)
            multiCheckBox.isHidden = !isMulti
        }
    }

    public static func getIconByKey(
        _ key: String,
        renderingMode: UIImage.RenderingMode = .automatic,
        iconColor: UIColor? = nil,
        size: CGSize? = nil
    ) -> UIImage? {
        switch key {
        case "wiki-bitable_colorful":
            return UDIcon.getIconByKey(.fileBitableColorful, renderingMode: renderingMode, iconColor: iconColor, size: size)
        default:
            return UDIcon.getIconByString(key, renderingMode: renderingMode, iconColor: iconColor, size: size)
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.contentView.backgroundColor = highlighted ? UIColor.ud.fillPressed : bgColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.contentView.backgroundColor = selected ? UIColor.ud.fillPressed : bgColor
    }
    /// 标识是否是tableView的最后一个cell
    var isLastCell: Bool = false
    var titleAlignment: NSTextAlignment = .left {
        didSet {
            titleLabel.textAlignment = titleAlignment
            updateTitleLabelConstraints()
        }
    }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(multiCheckBox)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.accessoryImageView)
        self.contentView.addSubview(self.seprater)
        self.contentView.addSubview(self.iconImageView)
        multiCheckBox.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(0)
        }
        self.iconImageView.snp.makeConstraints({ make in
            make.trailing.equalTo(titleLabel.snp.leading).offset(-4)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(0)
        })
        self.titleLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.lessThanOrEqualTo(contentView.bounds.width - 32)
        }
        self.accessoryImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
        }
        self.seprater.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(0.5)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // R模式下，最后一个cell不显示横线
        let shouldHideSeprator = isLastCell
        self.seprater.isHidden = shouldHideSeprator
    }
    
    private func updateTitleLabelConstraints() {
        var othersWidth = 32.0
        var leadingOffset = 16.0
        if isMulti {
            othersWidth += (20 + 12)
            leadingOffset += (20 + 12)
        } else if isChosen {
            othersWidth += (20 + 16)
        }
        if let _ = icon {
            othersWidth += (16 + 4)
            leadingOffset += (16 + 4)
        }
        titleLabel.snp.remakeConstraints { make in
            if titleAlignment == .center {
                make.center.equalToSuperview()
            } else {
                make.leading.equalToSuperview().offset(leadingOffset)
                make.centerY.equalToSuperview()
            }
            make.width.lessThanOrEqualTo(contentView.bounds.width - othersWidth)
        }
    }
}

