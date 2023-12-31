//
//  MinutesInfoParticipantTableViewCell.swift
//  Minutes
//
//  Created by sihuahao on 2021/4/14.
//

import UIKit
import SnapKit
import MinutesFoundation
import MinutesNetwork
import UniverseDesignTag
import LarkTag
import LarkLocalizations

struct DisplayTagPicker {
    static let languageIdentifier: String =  LanguageManager.currentLanguage.languageIdentifier
    
    static func GetTagValue(_ tag: DisplayTag?) -> String? {
        if languageIdentifier.contains("zh") {
            return tag?.tagValue?.i18nValue?.zh
        }
        if languageIdentifier.contains("en") {
            return tag?.tagValue?.i18nValue?.en
        }
        if languageIdentifier.contains("ja") {
            return tag?.tagValue?.i18nValue?.ja
        }
        return tag?.tagValue?.value
    }
}


class MinutesInfoParticipantTableViewCell: UITableViewCell {

    private var participant: Participant?

    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.ud.bgBodyOverlay
        imageView.layer.cornerRadius = 24
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

    lazy var telephoneView: UIImageView = {
        let imageView = UIImageView(image: BundleResources.Minutes.minutes_telephone)
        return imageView
    }()
    
    lazy var newExternalTag: TagWrapperView = {
        let tagView = TagWrapperView()
        return tagView
    }()
    
    lazy var languageIdentifier: String = {
        return LanguageManager.currentLanguage.languageIdentifier
    }()

    private func externalLabelWidth(text: String) -> CGFloat {
        let textWidth = text.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11)]).width
        return textWidth + 8
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(telephoneView)
        contentView.addSubview(newExternalTag)
        contentView.addSubview(subTitleLabel)

        createConstraints()
        
        telephoneView.isHidden = true
        newExternalTag.isHidden = true
        titleLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1001), for: .horizontal)
    }
    
    private func createConstraints() {
        iconImageView.snp.makeConstraints({
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(48)
            $0.left.equalTo(20)
        })

        newExternalTag.snp.makeConstraints {
            $0.top.equalTo(18)
            $0.width.equalTo(10)
            $0.height.equalTo(18)
            $0.right.lessThanOrEqualToSuperview().offset(-16)
        }

        telephoneView.snp.makeConstraints({
            $0.centerY.equalTo(newExternalTag.snp.centerY)
            $0.width.height.equalTo(20)
            $0.right.lessThanOrEqualToSuperview().offset(-16)
        })

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

    private func getDetail(with collaborator: Participant) -> String? {
        if collaborator.displayTag?.tagType == 1  {
            return collaborator.tenantName
        } else {
            return collaborator.departmentName
        }
    }

    func update(item: Participant, isNewExternalTagEnabled: Bool) {
        self.participant = item
        iconImageView.snp.updateConstraints { (make) in
            make.left.equalTo(20)
        }

        titleLabel.text = item.userName

        newExternalTag.isHidden = true
        
        var tags: [Tag] = []
        if item.isHostUser == true {
            let organizerTag = Tag(title: BundleI18n.Minutes.MMWeb_G_OrganizerLabel, style: .blue, type: .organization, size: .mini)
            tags.append(organizerTag)
        }
        
        if item.displayTag?.tagType == 2 {         // 自定义
            var i18nValue = DisplayTagPicker.GetTagValue(item.displayTag)
            if i18nValue?.isEmpty == true {
                i18nValue = item.displayTag?.tagValue?.value
            }
            let customTag = Tag(title: i18nValue ?? "", style: .blue, type: .organization, size: .mini)
            tags.append(customTag)
        } else if item.displayTag?.tagType == 1 {  // 外部
            var externalTag = Tag(type: .organization, style: .blue, size: .mini)
            // 企业标签
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
        
        iconImageView.setAvatarImage(with: item.avatarURL, placeholder: UIImage.dynamicIcon(.adsMobileAvatarCircle, dimension: 48, color: UIColor.ud.N300))
        updateDetails(item: item, isNewExternalTagEnabled: isNewExternalTagEnabled)
    }
    
    private func updateDetails(item: Participant, isNewExternalTagEnabled: Bool) {
        let detail = getDetail(with: item)
        
        if isNewExternalTagEnabled {
            // 新标签下，主标题显示租户名称或者外部标签，子标题显示部门名称
            subTitleLabel.text = item.departmentName
        } else {
            // 现有实现，主标题只显示外部，子标题如果是外部租户则显示租户名称，否则显示部门名称
            subTitleLabel.text = detail
        }

        var isSubtitleViewHidden = isNewExternalTagEnabled ? subTitleLabel.text?.isEmpty == true : (detail == nil || detail?.isEmpty == true)
        subTitleLabel.isHidden = isSubtitleViewHidden
        
        newExternalTag.snp.remakeConstraints { (make) in
            isSubtitleViewHidden ? make.centerY.equalToSuperview() : make.top.equalTo(18)
            make.height.equalTo(18)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }

        var tagMinWidth: CGFloat = 0.0

        let newTagSpace: CGFloat = 6
        let count: Int = newExternalTag.tags?.count ?? 0
        let part1: CGFloat = 72 * CGFloat(count)
        var part2: CGFloat = newTagSpace * CGFloat(count - 1)
        if count < 1 {
            part2 = 0
        }
        let newTagMinWidth: CGFloat = part1 + part2
        tagMinWidth = newTagMinWidth
        
        // 左边距：20  右边距：16  头像：48
        // 头像和title间距：12
        // tag最小宽度: 55，新tag等效宽度是72
        // title和tag间距：6
        var titleMaxWidth = ScreenUtils.sceneScreenSize.width - 20 - 16 - 48 - 12 - tagMinWidth - 6
        
        let isTagViewHidden = newExternalTag.isHidden
        if let isBind = item.isBind, isBind == true {
            // 减去图片的大小和间距
            titleMaxWidth = titleMaxWidth - 20 - 12

            telephoneView.isHidden = false
            telephoneView.snp.remakeConstraints { (make) in
                isSubtitleViewHidden ? make.centerY.equalToSuperview() : make.centerY.equalTo(newExternalTag.snp.centerY)
                make.width.height.equalTo(20)
                make.right.equalTo(newExternalTag.snp.left).offset(-6)
            }
        
            titleLabel.snp.remakeConstraints { (make) in
                isSubtitleViewHidden ? make.centerY.equalToSuperview() : make.centerY.equalTo(newExternalTag.snp.centerY)
                make.height.equalTo(22)
                make.width.lessThanOrEqualTo(titleMaxWidth)
                make.right.equalTo(telephoneView.snp.left).offset(-4)
                make.left.equalTo(iconImageView.snp.right).offset(12)
            }
        } else {
            telephoneView.isHidden = true

            titleLabel.snp.remakeConstraints { (make) in
                isSubtitleViewHidden ? make.centerY.equalToSuperview() : make.centerY.equalTo(newExternalTag.snp.centerY)
                make.height.equalTo(22)
                make.width.lessThanOrEqualTo(titleMaxWidth)
                isTagViewHidden ? make.right.equalToSuperview().offset(-16) : make.right.equalTo(newExternalTag.snp.left).offset(-6)
                make.left.equalTo(iconImageView.snp.right).offset(12)
            }
        }
    }
}

