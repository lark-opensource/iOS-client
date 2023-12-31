//
//  SearchResultNameStatusView.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/5/18.
//

import Foundation
import UIKit
import SnapKit
import LarkCore
import UniverseDesignFont
import UniverseDesignColor
import LarkTag
import LarkSearchCore
import LKCommonsLogging
import LarkSDKInterface
import RustPB

protocol SearchResultContentView {
    func restoreViewsContent()
}

/// attributedText不置为空会有bug，text会携带attributedText的ui属性
public final class SearchLabel: UILabel {
    override public var text: String? {
        get { super.text }
        set {
            super.attributedText = nil
            super.text = newValue
        }
    }

    override public var attributedText: NSAttributedString? {
        get { super.attributedText }
        set { super.attributedText = newValue }
    }
}

//搜索内容的首行，包括标题，标签等
final class SearchResultNameStatusView: UIStackView, SearchResultContentView {

    static let logger = Logger.log(SearchResultNameStatusView.self, category: "Module.IM.Search")

    public class SearchNameStatusContent {
        var nameText: String?
        var nameAttributedText: NSAttributedString?
        var countText: String?
        var shouldShowChatterStatus: Bool = false
        var descriptionText: String?
        var descriptionType: RustPB.Basic_V1_Chatter.Description.TypeEnum = .onDefault
        var tags: [Tag] = []
        var shouldAddLocalTag: Bool = false
    }

    public let nameLabel: SearchLabel = {
        let nameLabel = SearchLabel()
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.font = UIFont.systemFont(ofSize: 16)
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return nameLabel
    }()

    public let countLabel: SearchLabel = {
        let countLabel = SearchLabel()
        countLabel.textColor = UIColor.ud.textTitle
        countLabel.font = UIFont.systemFont(ofSize: 16)
        countLabel.setContentCompressionResistancePriority(.defaultHigh + 10, for: .horizontal)
        countLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        countLabel.isHidden = true
        return countLabel
    }()

    public var focusView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.isHidden = true
        return imageView
    }()

    public let chatterStatusLabel: ChatterStatusLabel = {
        let statusLabel = ChatterStatusLabel()
        statusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        statusLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        statusLabel.isHidden = true
        return statusLabel
    }()

    public var nameTag: TagWrapperView = {
        let nameTag = TagWrapperView()
        nameTag.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameTag.setContentHuggingPriority(.required, for: .horizontal)
        nameTag.isHidden = true
        nameTag.maxTagCount = 4
        return nameTag
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)

        axis = .horizontal
        alignment = .center
        distribution = .fill
        spacing = 8

        let nameView = UIStackView()
        nameView.axis = .horizontal
        nameView.distribution = .fill
        nameView.alignment = .center
        nameView.spacing = 0
        nameView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        nameView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        nameView.addArrangedSubview(nameLabel)
        nameView.addArrangedSubview(countLabel)

        addArrangedSubview(nameView)
        addArrangedSubview(focusView)
        addArrangedSubview(chatterStatusLabel)
        addArrangedSubview(nameTag)

        setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        setContentHuggingPriority(.defaultLow - 1, for: .horizontal)

        focusView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
        }
    }

    public func updateContent(content: SearchNameStatusContent) {
        if let nameAttributedText = content.nameAttributedText {
            nameLabel.attributedText = nameAttributedText
        } else if let nameText = content.nameText {
            nameLabel.text = nameText
        }

        if let countText = content.countText, !countText.isEmpty {
            countLabel.text = countText
            countLabel.isHidden = false
        } else {
            countLabel.isHidden = true
        }

        if let descriptionText = content.descriptionText, content.shouldShowChatterStatus {
            chatterStatusLabel.isHidden = false
            chatterStatusLabel.set(description: descriptionText, descriptionType: content.descriptionType)
        } else {
            chatterStatusLabel.isHidden = true
        }

        showTagsWith(tags: content.tags, shouldAddLocalTag: content.shouldAddLocalTag)
    }

    func setFocusTag(_ tagView: UIView?) {
        focusView.image = nil
        focusView.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        focusView.snp.removeConstraints()
        if let tagView = tagView {
            focusView.isHidden = false
            focusView.addSubview(tagView)
            tagView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            focusView.isHidden = true
        }
    }

    func showTagsWith(tags: [Tag], shouldAddLocalTag: Bool = false) {
        var finalTags = tags
        if shouldAddLocalTag {
            finalTags.append(Tag(title: "Local",
                            style: Self.getTagColor(withTagType: "B"),
                            type: .customTitleTag))
        }
        nameTag.set(tags: finalTags, autoSort: false)
        nameTag.isHidden = finalTags.isEmpty
    }

    static func customTagsWith(result: Search.Result) -> [Tag] {
        var customTags: [Tag] = []
        for tag in result.explanationTags {
            switch tag.tagStyle {
            case .text:
                guard !tag.text.isEmpty, !tag.tagType.isEmpty else {
                    Self.logger.error("textTag's text or type is empty!, tag's text: \(tag.text), tag's type: \(tag.tagType)")
                    continue
                }
                customTags.append(Tag(title: tag.text,
                                      style: Self.getTagColor(withTagType: tag.tagType),
                                  type: .customTitleTag))
            case .crypto:
                customTags.append(Tag(type: .crypto))
            case .shield:
                customTags.append(Tag(type: .isPrivateMode))
            case .helpDesk:
                customTags.append(Tag(type: .oncall))
            case .officialDoc:
                customTags.append(Tag(title: tag.text,
                                      image: Resources.authorityTag,
                                      style: Self.getTagColor(withTagType: tag.tagType),
                                      type: .customIconTextTag))
            @unknown default:
                Self.logger.error("Tag's style is unknown!, tag's text: \(tag.text), tag's type: \(tag.tagType)")
            }
        }
        return customTags
    }

    func restoreViewsContent() {
        nameLabel.text = nil
        nameLabel.attributedText = nil
        countLabel.text = nil
        countLabel.isHidden = true
        setFocusTag(nil)
        chatterStatusLabel.set(description: "", descriptionType: .onDefault)
        chatterStatusLabel.isHidden = true
        nameTag.clean()
        nameTag.isHidden = true
    }

    static func getTagColor(withTagType tagType: String) -> Style {
        switch tagType {
        case "RN": return .darkGrey
        case "NR": return .init(textColor: .ud.primaryOnPrimaryFill, backColor: .ud.colorfulRed)
        case "N": return .lightGrey
        case "B": return .blue
        case "Y": return .yellow
        case "R": return .red
        case "G": return .init(textColor: .ud.udtokenTagTextGreen, backColor: .ud.udtokenTagBgGreen)
        case "O": return .orange
        case "P": return .purple
        case "W": return .init(textColor: .ud.udtokenTagTextWathet, backColor: .ud.udtokenTagBgWathet)
        case "NT": return .turquoise
        default: return .lightGrey
        }
    }

    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SearchResultInfoStackView: UIStackView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        axis = .vertical
        spacing = 7
        alignment = .leading
        distribution = .fill
    }

    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//默认的Info视图
class SearchResultDefaultInfoView: SearchResultInfoStackView, SearchResultContentView {
    let nameStatusView: SearchResultNameStatusView = SearchResultNameStatusView()
    let firstDescriptionLabel: SearchLabel = {
        let label = SearchLabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14)
        label.isHidden = true
        label.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        return label
    }()

    let secondDescriptionLabel: SearchLabel = {
        let label = SearchLabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14)
        label.isHidden = true
        label.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        return label
    }()

    let extraView: UIView = {
        let extraView = UIView()
        extraView.backgroundColor = .clear
        extraView.isHidden = true
        extraView.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        extraView.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        return extraView
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addArrangedSubview(nameStatusView)
        addArrangedSubview(firstDescriptionLabel)
        addArrangedSubview(secondDescriptionLabel)
        addArrangedSubview(extraView)
    }

    public func restoreViewsContent() {
        nameStatusView.restoreViewsContent()
        firstDescriptionLabel.text = nil
        firstDescriptionLabel.isHidden = true
        secondDescriptionLabel.text = nil
        secondDescriptionLabel.isHidden = true
        extraView.isHidden = true
    }

    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
