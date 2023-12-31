//
//  WorkPlaceViewController+OpenApp.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/5/24.
//

import Foundation
import EENavigator
import LKCommonsLogging
import WebBrowser
import ECOProbe
import ECOProbeMeta
import LarkWorkplaceModel
import LarkUIKit

// 原生工作台打开应用相关函数
extension WorkPlaceViewController {
    /// 打开应用并上报产品埋点
    ///
    /// - Parameters:
    ///  - with: 应用基本信息 View Model
    func openAppAndReportEvent(with item: WorkPlaceItem, sectionType: SectionType) {
        guard let itemModel = item as? ItemModel else {
            Self.logger.error("item isn't ItemModel, open failed, itemId: \(item.getItemId() ?? "")")
            return
        }
        // 打开应用
        let context = WorkplaceOpenContext(
            isTemplate: false,
            appIsCommon: sectionType == .favorite,
            isAuxWindow: false,
            templateId: "",
            exposeUIType: sectionType.exposeUIType
        )
        openService.openItem(with: itemModel.item, from: self, context: context)
    }

    /// 点击添加应用跳转到应用搜索页面
    func openAddApp() {
        Self.logger.info("open AddApp")
        let body = FavoriteSettingBody(showCommonBar: true)
        context.navigator.showDetailOrPush(body: body, wrap: LkNavigationController.self, from: self)
        context.tracker
            .start(.appcenter_click_addapps)
            .post()
    }
}
