//
//  ItemTagView.swift
//  LarkListItem
//
//  Created by Yuri on 2023/9/27.
//

import UIKit
import SnapKit
import RustPB
#if canImport(LarkTag)
import LarkTag
import LarkBizTag

class ItemTagView: UIStackView {

    lazy var tagBuilder: TagViewBuilder = TagViewBuilder()
    lazy var tagView: TagWrapperView = {
        let tagView = tagBuilder.build()
        return tagView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        render()
        self.isHidden = true
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func render() {
        addArrangedSubview(tagView)
    }

    func update(tags: [ListItemNode.TagType]?) {
        guard let tags, !tags.isEmpty else {
            self.isHidden = true
            return
        }
        tagBuilder.reset(with: [])
        tagBuilder.update(with: compactTagItems(tags: tags))
        for tag in tags {
            if case .relationTag(let data) = tag {
                tagBuilder.addTags(with: data.transform())
            }
        }
        tagBuilder.refresh()
        self.isHidden = tagBuilder.isDisplayedEmpty()
        for subTagView in tagView.subviews { // tag view内部布局没有撑开, 兼容处理
            subTagView.setContentCompressionResistancePriority(.required, for: .horizontal)
            subTagView.setContentHuggingPriority(.required, for: .horizontal)
        }
    }

    // nolint: cyclomatic_complexity
    func compactTagItems(tags: [ListItemNode.TagType]) -> [TagDataItem] {
        let items = tags.compactMap {
            switch $0 {
            case .private:
                return TagDataItem(tagType: .isPrivateMode)
            case .public:
                return TagDataItem(tagType: .public)
            case .external:
                return TagDataItem(tagType: .external)
            case .bot:
                return TagDataItem(tagType: .robot)
            case .doNotDisturb:
                return TagDataItem(tagType: .doNotDisturb)
            case .crypto:
                return TagDataItem(tagType: .crypto)
            case .officialOncall:
                return TagDataItem(tagType: .officialOncall)
            case .oncallOffline:
                return TagDataItem(tagType: .oncallOffline)
            case .onLeave:
                return TagDataItem(tagType: .onLeave)
            case .unregistered:
                return TagDataItem(tagType: .unregistered)
            case .oncall:
                return TagDataItem(tagType: .oncall)
            case .connect:
                return TagDataItem(tagType: .connect)
            case .team:
                return TagDataItem(tagType: .team)
            case .allStaff:
                return TagDataItem(tagType: .allStaff)
            case .custom(let text):
                return TagDataItem(text: text, tagType: .customTitleTag)
            default:
                return nil
            }
        }
        return items
    }
    // enable-lint: cyclomatic_complexity
}
#else

class ItemTagView: UIStackView {

    let contentView = UIView()


    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .blue
        contentView.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentView.setContentHuggingPriority(.required, for: .horizontal)
        contentView.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 60, height: 20))
        }
        addArrangedSubview(contentView)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(tags: [ListItemNode.TagType]?) {
        guard let tags, !tags.isEmpty else {
            self.isHidden = true
            return
        }
        self.isHidden = false
    }
}
#endif
