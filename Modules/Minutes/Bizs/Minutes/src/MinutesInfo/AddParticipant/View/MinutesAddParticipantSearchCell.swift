//
//  MinutesAddParticipantSearchCell.swift
//  Minutes
//
//  Created by panzaofeng on 2021/6/16.
//  Copyright © 2021年 panzaofeng. All rights reserved.
//

import UIKit
import SnapKit
import MinutesFoundation
import MinutesNetwork
import Kingfisher
import UniverseDesignCheckBox
import UniverseDesignTag
import LarkTag
import LarkLocalizations

protocol MinutesAddParticipantSearchCellDelegate: AnyObject {
    func checkboxClicked(item: MinutesAddParticipantCellItem?, isSelected: Bool)
}

class MinutesAddParticipantSearchCell: UITableViewCell {

    var item: MinutesAddParticipantCellItem?

    weak var delegate: MinutesAddParticipantSearchCellDelegate?

    private lazy var selectedIcon: UDCheckBox = {
        let box = UDCheckBox(boxType: .multiple) {[weak self] box in
            self?.delegate?.checkboxClicked(item: self?.item, isSelected: box.isSelected)
        }
        return box
    }()

    lazy var newExternalTag: TagWrapperView = {
        let tagView = TagWrapperView()
        return tagView
    }()

    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.ud.bgBody
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    lazy var languageIdentifier: String = {
        return LanguageManager.currentLanguage.languageIdentifier
    }()

    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(selectedIcon)
        contentView.addSubview(newExternalTag)
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subTitleLabel)

        titleLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1001), for: .horizontal)
        
        selectedIcon.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(20)
            $0.left.equalToSuperview().offset(16)
        }
        newExternalTag.snp.makeConstraints {
            $0.top.equalTo(18)
            $0.height.equalTo(18)
            $0.right.lessThanOrEqualToSuperview().offset(-16)
        }
        iconImageView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(40)
            $0.left.equalTo(48)
        }
        initialLabelConstranints()
    }
    
    private func initialLabelConstranints() {
        titleLabel.snp.makeConstraints({
            $0.top.equalTo(iconImageView.snp.top)
            $0.height.equalTo(22)
            $0.left.equalTo(iconImageView.snp.right).offset(12)
            $0.right.equalTo(newExternalTag.snp.left).offset(-6)
        })
        subTitleLabel.snp.makeConstraints({
            $0.height.equalTo(20)
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.left.equalTo(iconImageView.snp.right).offset(12)
            $0.right.lessThanOrEqualToSuperview().offset(-16)
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(item: MinutesAddParticipantCellItem, isNewExternalTagEnabled: Bool) {
        self.item = item

        switch item.selectType {
        case .disable:
            selectedIcon.isEnabled = false
            selectedIcon.isSelected = false
        case .unselected:
            selectedIcon.isEnabled = true
            selectedIcon.isSelected = false
        case .selected:
            selectedIcon.isEnabled = true
            selectedIcon.isSelected = true
        }
        selectedIcon.snp.updateConstraints { (make) in
            make.width.height.equalTo(24)
        }
        iconImageView.snp.updateConstraints { (make) in
            make.left.equalTo(50)
        }
        // 不可选或者已经选了状态置为灰色
        let alpha: CGFloat = (item.selectType == .disable) ? 0.3 : 1
        iconImageView.alpha = alpha
        titleLabel.alpha = alpha
        subTitleLabel.alpha = alpha

        titleLabel.text = item.title
        if isNewExternalTagEnabled {
            subTitleLabel.text = item.departmentName
        } else {
            subTitleLabel.text = item.detail
        }
        
        newExternalTag.isHidden = true
        
        var tags: [Tag] = []
        if item.displayTag?.tagType == 2 {
            var i18nValue = DisplayTagPicker.GetTagValue(item.displayTag)
            if i18nValue?.isEmpty == true {
                i18nValue = item.displayTag?.tagValue?.value
            }
            let customTag = Tag(title: i18nValue ?? "", style: .blue, type: .organization, size: .mini)
            tags.append(customTag)
        } else if item.displayTag?.tagType == 1 {
            var externalTag = Tag(type: .organization, style: .blue, size: .mini)
            if isNewExternalTagEnabled {
                let tenantName = item.tenantName
                if tenantName?.isEmpty == false {
                    externalTag = Tag(title: tenantName, style: .blue, type: .organization, size: .mini)
                }
            }
            tags.append(externalTag)
        }
        newExternalTag.setElements(tags)
        newExternalTag.isHidden = tags.count == 0
        
        guard let url = item.imageURL else {
            iconImageView.image = nil
            return
        }
        iconImageView.setAvatarImage(with: url, placeholder: UIImage.dynamicIcon(.adsMobileAvatarCircle, dimension: 48, color: UIColor.ud.N300))
        updateDetails(item: item, isNewExternalTagEnabled: isNewExternalTagEnabled)
    }

    private func updateDetails(item: MinutesAddParticipantCellItem, isNewExternalTagEnabled: Bool) {
        if isNewExternalTagEnabled {
            subTitleLabel.text = item.departmentName
        } else {
            subTitleLabel.text = item.detail
        }
        let hideDetail = isNewExternalTagEnabled ? subTitleLabel.text?.isEmpty == true : (item.detail == nil || item.detail?.isEmpty == true)
        
        newExternalTag.snp.remakeConstraints { (make) in
            hideDetail ? make.centerY.equalToSuperview() : make.top.equalTo(18)
            make.height.equalTo(18)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }

        let newTagSpace: CGFloat = 6
        let count: Int = newExternalTag.tags?.count ?? 0
        let part1: CGFloat = 72.0 * CGFloat(count)
        var part2: CGFloat = newTagSpace * CGFloat(count - 1)
        if count < 1 {
            part2 = 0
        }
        let tagMinWidth: CGFloat = part1 + part2
 
        // 左边距：16  右边距：21  选择icon：24 头像icon： 50
        // 头像左边距：50，头像icon：40
        // 头像和title间距：12 title右边距：16
        var titleMaxWidth = ScreenUtils.sceneScreenSize.width - 50 - 40 - 12 - tagMinWidth - 16

        titleLabel.snp.remakeConstraints { (make) in
            hideDetail ? make.centerY.equalToSuperview() : make.centerY.equalTo(newExternalTag.snp.centerY)
            make.height.equalTo(22)
            make.width.lessThanOrEqualTo(titleMaxWidth)
            make.right.equalTo(newExternalTag.snp.left).offset(-6)
            make.left.equalTo(iconImageView.snp.right).offset(12)
        }

        subTitleLabel.isHidden = hideDetail
    }
}
