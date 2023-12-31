//
//  chatPickMessageNavgationBarContentSubModule.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/11/16.
//

import Foundation
import LarkUIKit
import LarkOpenChat
import RxSwift
import LarkCore
import LarkModel
import LarkSDKInterface
import LarkSetting
import LarkContainer

class ChatMessagePickerNavgationBarContentSubModule: ChatNavgationBarBaseContentSubModule {
    @ScopedInjectedLazy private var fgService: FeatureGatingService?

    override func createContentView(metaModel: ChatNavigationBarMetaModel) {
        if self._contentView != nil {
            return
        }
        self.factory.updateChat(metaModel.chat)
        let config = NavigationBarTitleViewConfig(showExtraFields: fgService?.staticFeatureGatingValue(with: "pc.show.user.admin.info") ?? false,
                                                  canTap: false,
                                                  itemsOfTop: [.nameItem, .tagsItem, .rightArrowItem],
                                                  itemsOfbottom: nil,
                                                  darkStyle: false,
                                                  barStyle: self.context.navigationBarDisplayStyle(),
                                                  tagsGenerator: DefaultChatNavigationBarTagsGenerator(forceShowAllStaffTag: false,
                                                                                                       isDarkStyle: false,
                                                                                                       userResolver: self.context.userResolver),
                                                  inlineService: nil,
                                                  chatterAPI: try? self.context.resolver.resolve(assert: ChatterAPI.self))
        self._contentView = self.factory.createTitleView(config: config,
                                                         delegate: self)
    }
}
