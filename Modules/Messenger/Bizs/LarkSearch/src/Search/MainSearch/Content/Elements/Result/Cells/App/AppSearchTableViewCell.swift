//
//  AppSearchTableViewCell.swift
//  LarkSearch
//
//  Created by SuPeng on 4/9/19.
//

import Foundation
import UIKit
import LarkModel
import LarkCore
import SnapKit
import LarkUIKit
import LarkTag
import LarkAccountInterface
import RustPB
import LarkSDKInterface
import LarkBizAvatar
import LarkSearchCore
import UniverseDesignIcon

final class AppSearchNewTableViewCell: SearchNewDefaultTableViewCell {

    override func set(viewModel: SearchCellViewModel, currentAccount: User?, searchText: String?) {
        super.set(viewModel: viewModel, currentAccount: currentAccount, searchText: searchText)
        setupAvatarWith(viewModel: viewModel)
        setupInfoViewWith(viewModel: viewModel)
    }

    private func setupAvatarWith(viewModel: SearchCellViewModel) {
        let searchResult = viewModel.searchResult
        if case let .openApp(app) = searchResult.meta {
            infoView.avatarView.setAvatarByIdentifier(app.appStoreURL.id, avatarKey: searchResult.avatarKey, avatarViewParams: .init(sizeType: .size(SearchResultDefaultView.searchAvatarImageDefaultSize)))
            let enableDocCustomIcon = (viewModel as? AppSearchViewModel)?.enableDocCustomIcon ?? false
            infoView.avatarView.setMiniIcon(enableDocCustomIcon ? MiniIconProps(.micoApp) : nil)
        } else if case let .facility(facilityInfo) = searchResult.meta {
            guard let userResolver = (viewModel as? AppSearchViewModel)?.userResolver else { return }
            guard SearchFeatureGatingKey.enableSpotlightNativeApp.isUserEnabled(userResolver: userResolver) else { return }
            guard let image = getFacilityIconImage(sourceKey: facilityInfo.sourceKey) else { return }
            infoView.avatarView.image = image
            infoView.avatarView.avatar.layer.masksToBounds = false
            let scale = (SearchResultDefaultView.searchAvatarImageDefaultSize - 6 * 2 ) / SearchResultDefaultView.searchAvatarImageDefaultSize
            infoView.avatarView.transform = CGAffineTransformMakeScale(scale, scale)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        guard let userResolver = (viewModel as? AppSearchViewModel)?.userResolver else { return }
        guard SearchFeatureGatingKey.enableSpotlightNativeApp.isUserEnabled(userResolver: userResolver) else { return }
        //针对spotlight的native app头像样式临时兼容，后续整体框架会调整
        infoView.avatarView.transform = CGAffineTransformIdentity
        infoView.avatarView.avatar.layer.masksToBounds = true
    }

    private func getFacilityIconImage(sourceKey: String) -> UIImage? {
        switch sourceKey {
        case "conversation": return UDIcon.tabChatColorful
        case "calendar": return UDIcon.tabCalendarColorful
        case "space": return UDIcon.tabDriveColorful
        case "mail": return UDIcon.tabMailColorful
        case "todo": return UDIcon.tabTodoColorful
        case "videochat": return UDIcon.tabVideoColorful
        case "contact": return UDIcon.tabContactsColorful
        case "moments": return UDIcon.larkcommunityColorful
        case "bitable": return UDIcon.tabBitableColorful
        case "wiki": return UDIcon.tabWikiColorful
        case "appCenter": return UDIcon.tabAppColorful
        default: return nil
        }
    }

    private func setupInfoViewWith(viewModel: SearchCellViewModel) {
        let searchResult = viewModel.searchResult
        guard let userResolver = (viewModel as? AppSearchViewModel)?.userResolver else { return }

        switch searchResult.meta {
        case .openApp: break
        case .facility: break
        default:
            return
        }

        let nameStatusConfig = SearchResultNameStatusView.SearchNameStatusContent()
        nameStatusConfig.nameAttributedText = searchResult.title

        var finalTags: [Tag] = []
        if case let .openApp(app) = searchResult.meta {
            var sourceType: Search_V2_ResultSourceType = .net
            if let result = searchResult as? Search.Result {
                sourceType = result.sourceType
                if SearchFeatureGatingKey.searchDynamicTag.isUserEnabled(userResolver: userResolver) && sourceType == .net {
                    finalTags = SearchResultNameStatusView.customTagsWith(result: result)
                }
            }
            if !SearchFeatureGatingKey.searchDynamicTag.isUserEnabled(userResolver: userResolver) || sourceType != .net {
                if app.state == .offline {
                    finalTags = [Tag(title: BundleI18n.LarkSearch.Lark_Search_AppRemove, style: .blue, type: .customTitleTag)]
                } else if app.state == .appDeleted {
                    finalTags = [Tag(title: BundleI18n.LarkSearch.Lark_Search_AppDelete, style: .blue, type: .customTitleTag)]
                } else if app.state != .usable {
                    finalTags = [Tag(type: .deactivated)]
                } else {
                    var types = Set<TagType>()
                    app.appAbilities.forEach { (ability) in
                        switch ability {
                        case .bot:
                            types.insert(.robot)
                        case .h5, .microApp, .localComponent:
                            types.insert(.app)
                        @unknown default:
                            assert(false, "new value")
                            break
                        }
                    }
                    var typesArr: [TagType] = []
                    if types.contains(.app) {
                        typesArr.append(.app) // 当为应用的时候只显示应用
                    } else if types.contains(.robot) {
                        typesArr.append(.robot) // 否则如果为机器人的时候显示机器人
                    }
                    finalTags = typesArr.map { Tag(type: $0) }
                    // 未安装应用没吐ability时，默认应用
                    if !app.isAvailable {
                        if finalTags.isEmpty { finalTags.append(Tag(type: .app)) }
                        finalTags.append(Tag(title: BundleI18n.LarkSearch.Lark_Search_AppNotInstalled,
                                            style: .init(textColor: UIColor.ud.W600, backColor: UIColor.ud.W100),
                                            type: .customTitleTag))
                    }
                }
            }

        } else if case .facility = searchResult.meta, SearchFeatureGatingKey.enableSpotlightNativeApp.isUserEnabled(userResolver: userResolver) {
            if let result = searchResult as? Search.Result {
                if result.sourceType == .local {
                    finalTags = SearchResultNameStatusView.customTagsWith(result: result)
                }
            }
            if viewModel.searchResult.isSpotlight, SearchFeatureGatingKey.enableSpotlightLocalTag.isUserEnabled(userResolver: userResolver) {
                nameStatusConfig.shouldAddLocalTag = true
            }
        }

        nameStatusConfig.tags = finalTags
        infoView.nameStatusView.updateContent(content: nameStatusConfig)
        if searchResult.extra.length > 0 {
            infoView.secondDescriptionLabel.attributedText = searchResult.extra
            infoView.secondDescriptionLabel.isHidden = false
        }
    }
}
