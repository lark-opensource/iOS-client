//
//  ThreadPreviewNavgationBarContentSubModule.swift
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

public final class ThreadPreviewNavgationBarContentSubModule: ChatNavgationBarBaseContentSubModule {
    public override func createContentView(metaModel: ChatNavigationBarMetaModel) {
        if self._contentView != nil {
            return
        }
        self.factory.updateChat(metaModel.chat)
        let config = NavigationBarTitleViewConfig(showExtraFields: false,
                                                  canTap: false, // 线上就无法点击，这里应该设置为false
                                                  itemsOfTop: [.nameItem],
                                                  itemsOfbottom: [],
                                                  darkStyle: false,
                                                  barStyle: self.context.navigationBarDisplayStyle(),
                                                  tagsGenerator: DefaultChatNavigationBarTagsGenerator(forceShowAllStaffTag: false,
                                                                                                       isDarkStyle: !Display.pad,
                                                                                                       userResolver: self.context.userResolver),
                                                  inlineService: nil,
                                                  chatterAPI: try? self.context.resolver.resolve(assert: ChatterAPI.self))
        self._contentView = self.factory.createTitleView(config: config,
                                                         delegate: self)
    }
}
