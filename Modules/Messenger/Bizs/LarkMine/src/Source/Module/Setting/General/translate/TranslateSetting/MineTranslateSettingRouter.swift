//
//  MineTranslateSettingRouter.swift
//  LarkMine
//
//  Created by 李勇 on 2019/5/13.
//

import Foundation

/// 翻译设置路由
protocol MineTranslateSettingRouter: MineModuleRouter {
    /// 翻译目标语言设置
    func pushTranslateTagetLanguageSettingController()
    /// 不自动翻译语言设置
    func pushDisableAutoTranslateLanguagesSettingController()
    /// 翻译效果高级设置
    func pushLanguagesConfigurationSettingController()
    /// 源语言列表
    func pushLanguagesListSettingController(currGloabalScopes: Int?, detailModelType: DetailModelType)
}
