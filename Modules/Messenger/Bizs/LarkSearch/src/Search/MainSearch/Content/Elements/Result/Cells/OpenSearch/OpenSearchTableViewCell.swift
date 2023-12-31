//
//  OpenSearchTableViewCell.swift
//  LarkSearch
//
//  Created by SuPeng on 4/9/19.
//

import Foundation
import UIKit
import RustPB
import LarkModel
import LarkCore
import SnapKit
import LarkUIKit
import LarkTag
import LarkAccountInterface
import LarkMessengerInterface
import LarkAvatarComponent
import AvatarComponent
import ByteWebImage
import LarkSearchCore
import LKCommonsLogging
import LarkSDKInterface
import LarkSearchFilter

enum SlashTag: Int32 {
    case `default` = 0
    case primary, success, warning, error
    var style: LarkTag.Style {
        switch self {
        case .primary: return .blue
        case .success: return .init(textColor: UIColor.ud.functionSuccessContentDefault, backColor: UIColor.ud.functionSuccessFillSolid02)
        case .warning: return .init(textColor: UIColor.ud.functionWarningContentDefault, backColor: UIColor.ud.functionWarningFillSolid02)
        case .error: return .init(textColor: UIColor.ud.functionDangerContentDefault, backColor: UIColor.ud.functionDangerFillSolid02)
        default: return .init(textColor: UIColor.ud.N600, backColor: UIColor.ud.N200)
        }
    }
}

final class OpenSearchFilterTableViewCell: UITableViewCell, SearchTableViewCellProtocol {
    var viewModel: SearchCellViewModel?
    var content = CompactList()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectedBackgroundView = SearchCellSelectedView()
        self.backgroundColor = UIColor.ud.bgBody

        addSubview(content)
        content.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        updateCellStyle(animated: animated)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        updateCellStyle(animated: animated)
    }

    func set(viewModel: SearchCellViewModel, currentAccount: User?, searchText: String?) {
        self.viewModel = viewModel

        let searchResult = viewModel.searchResult
        content.icon.image = Resources.icon_search_20.withRenderingMode(.alwaysTemplate)
        content.icon.tintColor = UIColor.ud.iconN3
        content.title.attributedText = searchResult.title
        let summary = searchResult.summary
        content.summary.isHidden = summary.length == 0
        if summary.length > 0 {
            content.summary.attributedText = summary
        }
    }
}

final class CompactList: UIView {
    var icon: LarkAvatar = {
        var config = AvatarComponentUIConfig()
        config.style = .square
        return LarkAvatar(frame: .zero, config: config)
    }()
    var title = UILabel()
    var summary = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        title.textColor = UIColor.ud.textTitle
        title.font = UIFont.systemFont(ofSize: 16)

        summary.textColor = UIColor.ud.textPlaceholder
        summary.font = UIFont.systemFont(ofSize: 14)

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 4
        contentStack.alignment = .leading

        addSubview(icon)
        addSubview(contentStack)
        contentStack.addArrangedSubview(title)
        contentStack.addArrangedSubview(summary)

        icon.snp.makeConstraints {
            $0.left.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }
        contentStack.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalTo(icon.snp.right).offset(12)
            $0.right.equalToSuperview().inset(16).priority(850)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let height: CGFloat = summary.isHidden ? 48 : 70
        return .init(width: UIView.noIntrinsicMetric, height: height)
    }
}

final class OpenSearchNewTableViewCell: SearchNewDefaultTableViewCell {
    static let logger = Logger.log(OpenSearchNewTableViewCell.self, category: "Module.IM.Search")

    override func set(viewModel: SearchCellViewModel, currentAccount: User?, searchText: String?) {
        super.set(viewModel: viewModel, currentAccount: currentAccount, searchText: searchText)
        setupAvatarWith(viewModel: viewModel)
        setupInfoViewWith(viewModel: viewModel)
    }

    private func setupAvatarWith(viewModel: SearchCellViewModel) {
        let searchResult = viewModel.searchResult
        guard case .slash(_) = viewModel.searchResult.meta else { return }

        if let encodingURL = searchResult.imageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let imageURL = URL(string: encodingURL) {
            infoView.avatarView.avatar.bt.setLarkImage(with: .default(key: imageURL.absoluteString),
                                                       placeholder: SearchImageUtils.generateAvatarImage(withTitle: searchResult.title.string, bgColor: .ud.primaryPri200),
                                                       trackStart: {
                return TrackInfo(scene: .Search, fromType: .avatar)
            },
                                                       completion: { [weak self] result in
                if case let .failure(error) = result {
                    Self.logger.error("[LarkSearch] openSearch cell avatar load failed",
                                      additionalData: ["error": error.localizedDescription])
                    self?.infoView.avatarView.image = SearchImageUtils.generateAvatarImage(withTitle: searchResult.title.string, bgColor: .ud.N300)
                }
            })
        } else {
            infoView.avatarView.isHidden = infoView.avatarView.image == nil && searchResult.avatarKey.isEmpty
        }
    }

    private func setupInfoViewWith(viewModel: SearchCellViewModel) {
        let searchResult = viewModel.searchResult
        let nameStatusConfig = SearchResultNameStatusView.SearchNameStatusContent()

        nameStatusConfig.nameAttributedText = searchResult.title

        if case .slash(let meta) = searchResult.meta {
            var sourceType: Search_V2_ResultSourceType = .net
            if let result = searchResult as? Search.Result {
                sourceType = result.sourceType
            }
            var finalTags: [Tag] = []
            if SearchFeatureGatingKey.searchDynamicTag.isEnabled, sourceType == .net {
                if let result = searchResult as? Search.Result {
                    finalTags = SearchResultNameStatusView.customTagsWith(result: result)
                }
            } else {
                finalTags = meta.tags.map { (tag) -> Tag in
                   let tagenum = SlashTag(rawValue: tag.type) ?? .default
                   return Tag(title: tag.text, style: tagenum.style, type: .customTitleTag)
                }
                if let result = searchResult as? Search.Result {
                    let customTags = result.explanationTags.map { Tag(title: $0.text, style: SearchResultNameStatusView.getTagColor(withTagType: $0.tagType), type: .customTitleTag) }
                    finalTags.append(contentsOf: customTags)
                }
            }
            nameStatusConfig.tags = finalTags
            let extra = searchResult.extra
            if !extra.string.isEmpty {
                infoView.secondDescriptionLabel.attributedText = extra
                infoView.secondDescriptionLabel.isHidden = false
            }
        }
        infoView.nameStatusView.updateContent(content: nameStatusConfig)
    }
}
