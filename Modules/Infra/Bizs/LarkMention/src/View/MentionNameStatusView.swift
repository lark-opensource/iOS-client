//
//  MentionNameStatusView.swift
//  LarkMention
//
//  Created by Yuri on 2022/5/31.
//

import Foundation
import UIKit
import LarkTag

final class MentionNameStatusView: UIView {
    
    let textContentView = UIStackView()
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 16)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 12)
        label.setContentCompressionResistancePriority(.defaultLow + 1, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        return label
    }()
    
    lazy var nameTag: TagWrapperView = {
        let nameTag = TagWrapperView()
        nameTag.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameTag.setContentHuggingPriority(.required, for: .horizontal)
        return nameTag
    }()
    
    private var currentItem: PickerOptionType?
    func update(item: PickerOptionType) {
        func removeArrangedSubview(_ view: UIView) {
            textContentView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        func insertArrangedSubviewIfNeed(_ view: UIView, at index: Int) {
            if view.superview == nil {
                textContentView.insertArrangedSubview(view, at: index)
            }
        }
        var index = 0
        if let name = item.name, item.name != currentItem?.name {
            insertArrangedSubviewIfNeed(nameLabel, at: index)
            nameLabel.attributedText = name
            if name.length == 1 {
                nameLabel.snp.remakeConstraints {
                    $0.top.bottom.equalToSuperview()
                    $0.width.greaterThanOrEqualTo(20)
                }
            } else {
                nameLabel.snp.remakeConstraints {
                    $0.top.bottom.equalToSuperview()
                    $0.width.greaterThanOrEqualTo(34)
                }
            }
            
        }
        if item.name == nil {
            removeArrangedSubview(nameLabel)
        }

        if let subTitle = item.subTitle {
            index += 1
            if subTitle != currentItem?.subTitle {
                insertArrangedSubviewIfNeed(subTitleLabel, at: index)
                subTitleLabel.attributedText = subTitle
            }
        }
    
        if item.subTitle == nil {
            removeArrangedSubview(subTitleLabel)
        }
        if let tags = item.tags, !tags.isEmpty, item.tags != currentItem?.tags {
            index += 1
            insertArrangedSubviewIfNeed(nameTag, at: index)
            nameTag.setTags(convert(tags: tags))
        }
        if (item.tags?.count ?? 0) == 0 {
            removeArrangedSubview(nameTag)
        }
        currentItem = item
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        textContentView.axis = .horizontal
        textContentView.alignment = .center
        textContentView.distribution = .fill
        textContentView.spacing = 8
        addSubview(textContentView)
        textContentView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
        }
        
        textContentView.addArrangedSubview(nameLabel)
        textContentView.addArrangedSubview(subTitleLabel)
        textContentView.addArrangedSubview(nameTag)
        
        nameLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.width.greaterThanOrEqualTo(34)
        }
        subTitleLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func convert(tags: [PickerOptionTagType]) -> [LarkTag.TagType] {
        return tags.compactMap {
            switch $0 {
            case .external: return .external
            case .team: return .team
            case .`public`: return .`public`
            case .oncall: return .oncall
            case .connect: return .connect
            case .allStaff: return .allStaff
            case .officialOncall: return .officialOncall
            default: return nil
            }
        }
    }
}

