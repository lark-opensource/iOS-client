//
//  WidgetModel.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/5/20.
//

import Foundation
import LarkWorkplaceModel
import LarkContainer
import LarkAccountInterface

final class WidgetModel {
    /// widget左上角的iconKey
    let iconKey: String
    /// widget的Name
    let name: String
    /// widget的cardSchema
    let cardSchema: String
    /// widget container state
    var widgetContainerState: WidgetContainerState
    /// observe card size change
    var cardSizeDidChange: ((WidgetView, WidgetContainerState, CGSize) -> Void)?
    /// render callback
    var renderCallback: ((Bool) -> Void)?

    // TODO: 即将下线的业务，暂时直接拿 userResovler
    private var userService: PassportUserService? {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: WorkplaceScope.userScopeCompatibleMode)
        let userService = try? userResolver.resolve(assert: PassportUserService.self)
        return userService
    }

    init(item: WPAppItem) {
        self.iconKey = item.iconKey ?? ""
        self.name = item.name
        self.cardSchema = item.url?.mobileCardWidgetURL ?? ""
        let cardSize = CGSize(
            width: ItemModel.widgetDefaultWidth,
            height: ItemModel.widgetDefaultHeight
        )
        widgetContainerState = WidgetContainerState(expandSize: cardSize)
        /// render 渲染结果
        renderCallback = { [weak self](renderResult) in
            if renderResult {
                let userId = self?.userService?.user.userID
                let tenantId = self?.userService?.userTenant.tenantID
                WPEventReport(
                    name: WPEvent.appcenter_widgetopen.rawValue,
                    userId: userId,
                    tenantId: tenantId
                )
                    .set(key: WPEventValueKey.item_id.rawValue, value: item.itemId)
                    .post()
            }
        }
    }
}

/// 返回的配置
struct WidgetConfig: Codable {
    let subTitle: String?
    let version: String?
    let needRequestBusinessData: Bool?
    let mobileHeaderLinkUrl: String?
    /// widget 是否支持展开配置
    let widgetCanExpand: Bool?
}
