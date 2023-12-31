//
//  IMMentionNameStatusView.swift
//  LarkIMMention
//
//  Created by jiangxiangrui on 2022/7/21.
//

import Foundation
import UIKit
import RustPB
import LarkTag
import LarkBizTag

final class IMMentionNameStatusView: UIView {
    
    let textContentView = UIStackView()
    lazy var tagView: MentionFocusView = {
        let tags = MentionFocusView()
        tags.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tags.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return tags
    }()
    
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

    lazy var chatterTagBuilder: ChatterTagViewBuilder = ChatterTagViewBuilder()
    lazy var nameTag: IMMentionTagView = {
        let view = IMMentionTagView()
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.setContentHuggingPriority(.required, for: .horizontal)
        return view
    }()
    
    var node: MentionItemNode? {
        didSet {
            guard let node = node else { return }
            if node.name != oldValue?.name {
                update(name: node.name)
            }
            
            update(focusStatus: node.focusStatus)
            
            if node.subTitle != oldValue?.subTitle {
                update(subTitle: node.subTitle)
            }
            
            // 自定义标签和外部标签放在tagData,其他放在tags
            nameTag.update(id: node.id, tags: node.tags, tagData: node.tagData)
            nameTag.isHidden = nameTag.isTagEmpty
        }
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
        textContentView.addArrangedSubview(tagView)
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
    
    // MARK: - Private
    private func update(name: NSAttributedString?) {
        nameLabel.attributedText = name
        if let name = name {
            nameLabel.snp.updateConstraints {
                $0.width.greaterThanOrEqualTo(name.length == 1 ? 20 : 34)
            }
        }
    }
    
    private func update(focusStatus: [Basic_V1_Chatter.ChatterCustomStatus]?) {
        let isAddedTag = tagView.setStatus(status: focusStatus)
        tagView.isHidden = !isAddedTag
    }
    
    private func update(subTitle: NSAttributedString?) {
        subTitleLabel.attributedText = subTitle
        subTitleLabel.isHidden = subTitle == nil || subTitle?.string.isEmpty == true
    }
    
    private func convert(tags: [PickerOptionTagType]) -> [LarkTag.TagType] {
        return tags.compactMap {
            switch $0 {
            case .external: return .external
            case .team: return .team
            case .`public`: return .`public`
            case .oncall: return .oncall
            case .connect: return .connect
            case .onLeave: return .onLeave
            case .robot: return .robot
            case .unregistered: return .unregistered
            default: return nil
            }
        }
    }
}
