//
//  CCMFeedFloatMenuSubModule.swift
//  MessengerMod
//
//  Created by liuxianyu on 2022/12/18.
//

import Foundation
import UniverseDesignIcon
import LarkOpenIM
import LarkOpenFeed
import LarkTab
import EENavigator
import SKUIKit
import LarkContainer
import LarkQuickLaunchInterface

final class CCMCreateDocsMenuSubModule: FeedFloatMenuSubModule {
    
    @InjectedUnsafeLazy public var temporaryTabService: TemporaryTabService
    
    public override class var name: String { return "CCMCreateDocsMenuSubModule" }

    public override var type: FloatMenuOptionType {
        return .createDocs
    }

    public override class func canInitialize(context: FeedFloatMenuContext) -> Bool {
        return true
    }

    public override func canHandle(model: FeedFloatMenuMetaModel) -> Bool {
        return true
    }

    public override func handler(model: FeedFloatMenuMetaModel) -> [Module<FeedFloatMenuContext, FeedFloatMenuMetaModel>] {
        return [self]
    }

    public override func menuOptionItem(model: FeedFloatMenuMetaModel) -> FloatMenuOptionItem? {
        return FloatMenuOptionItem(
            icon: UDIcon.getIconByKey(.addDocOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2),
            title: BundleI18n.CCMMod.Lark_Legacy_ConversationCreateDoc,
            type: type
        )
    }

    public override func didClick() {
        guard let from = context.feedContext.page else { return }
        if temporaryTabService.isTemporaryEnabled {
            Navigator.shared.push(body: CreateDocBody(), from: from)
        } else {
            Navigator.shared.switchTab(Tab.doc.url, from: from, animated: true) {
                Navigator.shared.push(body: CreateDocBody(), from: from)
            }
        }
    }
}
