//
//  TemplateVC+Open.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2021/4/23.
//

import Foundation
import EENavigator
import LarkOPInterface
import RxSwift
import LKCommonsLogging
import LarkAlertController
import LarkUIKit
import WebBrowser
import UniverseDesignToast
import LarkWorkplaceModel

// 模板工作台打开应用相关函数
extension TemplateViewController {
    /// 打开应用并上报产品埋点
    ///
    /// - Parameters:
    ///  - with: 服务端下发的应用基本信息 Data Model
    func openAppAndReportEvent(
        with info: WPAppItem,
        appScene: WPTemplateModule.ComponentDetail.Favorite.AppSubType?,
        exposeUIType: WPExposeUIType
    ) {
        // 打开应用
        let context = WorkplaceOpenContext(
            isTemplate: true,
            appIsCommon: true,
            isAuxWindow: false,
            appScene: appScene,
            templateId: initData.id,
            exposeUIType: exposeUIType
        )
        openService.openItem(with: info, from: self, context: context)
    }

    /// 点击添加应用跳转到应用搜索页面
    func openAddApp() {
        Self.logger.info("open AddApp")
        let body = FavoriteSettingBody(showCommonBar: false) { [weak self] in
            self?.dataProduce()
        }
        context.navigator.showDetailOrPush(body: body, wrap: LkNavigationController.self, from: self)
        context.tracker
            .start(.appcenter_click_addapps)
            .post()
    }
}
