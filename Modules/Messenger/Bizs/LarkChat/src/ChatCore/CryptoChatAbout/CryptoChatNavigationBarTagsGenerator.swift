//
//  CryptoChatNavigationBarTagsGenerator.swift
//  LarkChat
//
//  Created by zc09v on 2022/3/15.
//

import Foundation
import LarkModel
import LarkAccountInterface
import LarkTag
import UniverseDesignColor
import LarkMessengerInterface
import LarkMessageCore
import UIKit
import LarkBizTag

class CryptoChatNavigationBarTagsGenerator: ChatNavigationBarTagsGenerator {
    override func getTitleTagTypes(chat: Chat, userType: PassportUserType) -> [TagDataItem] {
        let isDark = self.isDarkStyle
        let style = isDark ? Style.secretColor : nil
        var tagDataItems: [TagDataItem] = []
        var tagTypes: [LarkTag.Tag] = []

        /// 如果是单聊 && 对方处于勿扰模式，则添加勿扰icon
        if chat.type == .p2P,
            let chatter = chat.chatter,
            self.serverNTPTimeService?
                .afterThatServerTime(time: chatter.doNotDisturbEndTime) ?? false {
            if isDark {
                tagTypes.append(
                    Tag(
                        type: .cryptoDoNotDisturb,
                        style: Style(
                            textColor: UIColor.clear,
                            backColor: UIColor.ud.udtokenTagNeutralBgSolid
                        )
                    )
                )
            } else {
                tagTypes.append(Tag(type: .doNotDisturb))
            }
        }

        if isDark {
            tagTypes.append(
                Tag(
                    type: .secretCrypto,
                    style: Style(
                        textColor: UIColor.clear,
                        backColor: UIColor.ud.N200 & UIColor.ud.N700
                    )
                )
            )
        } else {
            tagTypes.append(Tag(type: .crypto))
        }

        // 单聊展示暂停使用, 如果已经离职不再展示该标签
        if chat.type == .p2P,
           let chatter = chat.chatter,
           !chatter.isResigned,
           chatter.isFrozen {
            tagTypes.append(Tag(type: .isFrozen, style: style))
        }

        // 这里如果包含了暂停使用的标签 不在展示请假的标签
        if chat.type == .p2P,
            let chatter = chat.chatter,
            chatter.tenantId == currentTenantId,
            chatter.workStatus.status == .onLeave,
            !(tagTypes.contains { $0.type == .isFrozen }) {
            tagTypes.append(Tag(type: .onLeave, style: style))
        }

        if chat.isCrossWithKa {
            UserStyle.on(.connectTag, userType: userType).apply(on: {
                tagTypes.append(Tag(type: .connect, style: style))
            }, off: {})
        } else if chat.tagData?.tagDataItems.isEmpty == false {
            chat.tagData?.tagDataItems.forEach { item in
                let isExternal = item.respTagType == .relationTagExternal
                if isExternal {
                    let info = Tag.defaultTagInfo(for: .external)
                    let darkTextColor = UIColor.ud.udtokenTagNeutralTextInverse & UIColor.ud.udtokenTagTextSBlue
                    let darkBackColor = UIColor.ud.functionInfoFillHover & UIColor.ud.udtokenTagBgBlue
                    tagDataItems.append(TagDataItem(text: item.textVal,
                                                    image: info.image,
                                                    tagType: .external,
                                                    frontColor: isDark ? darkTextColor : style?.textColor,
                                                    backColor: isDark ? darkBackColor : style?.backColor,
                                                    priority: Int(item.priority)
                                                   ))
                } else {
                    let tagDataItem = LarkBizTag.TagDataItem(text: item.textVal,
                                                             tagType: item.respTagType.transform(),
                                                             priority: Int(item.priority))
                    tagDataItems.append(tagDataItem)
                }
            }
        }
        tagDataItems.append(contentsOf: tagTypes.map({ tag in
            let info = Tag.defaultTagInfo(for: tag.type)
            return TagDataItem(text: info.title,
                               image: info.image,
                               tagType: tag.type.convert(),
                               frontColor: tag.style.textColor,
                               backColor: tag.style.backColor)
        }))

        return tagDataItems
    }
}
