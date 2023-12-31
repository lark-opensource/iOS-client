//
//  QRCodeMenuSubModule.swift
//  LarkQRCode
//
//  Created by liuxianyu on 2023/1/4.
//

import UIKit
import Foundation
import LarkOpenFeed
import LarkOpenIM
import EENavigator
import LarkNavigator
import UniverseDesignIcon
import LarkTab
import LarkFoundation

final class QRCodeMenuSubModule: FeedFloatMenuSubModule {
    public override class var name: String { return "QRCodeMenuSubModule" }

    public override var type: FloatMenuOptionType {
        return .scanQRCode
    }

    public override class func canInitialize(context: FeedFloatMenuContext) -> Bool {
        return true
    }

    public override func canHandle(model: FeedFloatMenuMetaModel) -> Bool {
        let scanEnable: Bool = !Utils.isiOSAppOnMacSystem
        return scanEnable
    }

    public override func handler(model: FeedFloatMenuMetaModel) -> [Module<FeedFloatMenuContext, FeedFloatMenuMetaModel>] {
        return [self]
    }

    public override func menuOptionItem(model: FeedFloatMenuMetaModel) -> FloatMenuOptionItem? {
        return FloatMenuOptionItem(
            icon: UDIcon.getIconByKey(.scanOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2),
            title: BundleI18n.LarkQRCode.Lark_Legacy_LarkScan,
            type: type
        )
    }

    public override func didClick() {
        guard let from = context.feedContext.page else { return }
        var params = NaviParams()
        params.switchTab = Tab.feed.url
        self.context.userResolver.navigator.presentOrPush(
            body: QRCodeControllerBody(),
            naviParams: params,
            from: from,
            prepareForPresent: { (vc) in
                vc.modalPresentationStyle = .fullScreen
            })
    }
}
