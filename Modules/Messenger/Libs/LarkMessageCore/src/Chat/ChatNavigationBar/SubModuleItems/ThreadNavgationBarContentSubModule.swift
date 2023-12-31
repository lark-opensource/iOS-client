//
//  ThreadNavgationBarContentSubModule.swift
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
import RustPB

/// Thread场景创建导航栏对外部的依赖，因为不通用所以不放到ChatNavgationBarContext、XxxOpenService中，由Thread场景直接注入
public protocol ThreadNavgationBarContentDependency: AnyObject {
    /// title底部是否强制显示「全员」tag
    func forceShowAllStaffTag() -> Bool
    func titleClicked()
}
public final class DefaultThreadNavgationBarContentDependencyImpl: ThreadNavgationBarContentDependency {
    public init() {}
    /// title底部是否强制显示「全员」tag
    public func forceShowAllStaffTag() -> Bool { return false }
    public func titleClicked() {}
}

final class ThreadChatNavigationBarTagsGenerator: DefaultChatNavigationBarTagsGenerator {

    override func getCustomBackgroundColorFor(item: RustPB.Basic_V1_TagData.TagDataItem, isDark: Bool) -> UIColor? {
        if item.respTagType == .tenantEntityTag {
             /// 暗色模式下 要是用深一些的背景色 浅色背景下 用浅一些的背景色
            return isDark ? UIColor.ud.udtokenTagBgIndigoSolid : UIColor.ud.udtokenTagBgIndigo
        }
        return nil
    }
}

public final class ThreadNavgationBarContentSubModule: ChatNavgationBarBaseContentSubModule {
    /// Thread场景不能在subModule内解决，需要通过Dependency展开导航栏
    public override func titleClicked() {
        (try? self.context.userResolver.resolve(type: ThreadNavgationBarContentDependency.self))?.titleClicked()
    }

    public override func createContentView(metaModel: ChatNavigationBarMetaModel) {
        if self._contentView != nil {
            return
        }
        let forceShowAllStaffTag = (try? self.context.userResolver.resolve(type: ThreadNavgationBarContentDependency.self))?.forceShowAllStaffTag() ?? false
        self.factory.updateChat(metaModel.chat)
        let config = NavigationBarTitleViewConfig(showExtraFields: false,
                                                  canTap: true,
                                                  itemsOfTop: [.nameItem, .tagsItem],
                                                  itemsOfbottom: [],
                                                  darkStyle: false,
                                                  barStyle: self.context.navigationBarDisplayStyle(),
                                                  tagsGenerator: ThreadChatNavigationBarTagsGenerator(forceShowAllStaffTag: forceShowAllStaffTag,
                                                                                                       isDarkStyle: !Display.pad,
                                                                                                       userResolver: self.context.userResolver),
                                                  inlineService: nil,
                                                  chatterAPI: try? self.context.resolver.resolve(assert: ChatterAPI.self))
        self._contentView = self.factory.createTitleView(config: config,
                                                         delegate: self)
    }
}
