//
//  MyAIServiceImpl+Scene.swift
//  LarkAI
//
//  Created by 李勇 on 2023/10/10.
//

import Foundation
import EENavigator
import LarkContainer
import ServerPB
import RxSwift
import LarkEnv
import LarkModel
import LarkSetting
import LarkLocalizations
import UniverseDesignToast
import UniverseDesignDialog
import LarkSDKInterface
import LarkMessengerInterface
import LarkAccountInterface
import UniverseDesignTheme
import Swinject
import LarkCore

/// 把MyAISceneService相关逻辑放这里
public extension MyAIServiceImpl {
    func openSceneList(from: NavigatorFrom, chat: Chat, selected: @escaping ((_ sceneId: Int64) -> Void)) {
        // 判断FG：我的场景迁移至Web；从settings获取域名：https://cloud-boe.bytedance.net/appSettings-v2/detail/config/190164/detail/status
        guard self.userResolver.fg.dynamicFeatureGatingValue(with: "lark.myai.webview"),
              let urlSetting = (try? self.userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "my_ai_scenario_url"))) as? [String: String],
              var urlString = urlSetting["url"], !urlString.isEmpty else {
            let sceneViewController = SceneListViewController(viewModel: SceneListViewModel(userResolver: self.userResolver, chat: chat, selected: selected))
            self.userResolver.navigator.present(sceneViewController, from: from)
            return
        }
        // 替换语言为当前设备的语言
        if let languageKey = urlSetting["language_replace_key"], !languageKey.isEmpty {
            urlString = urlString.replacingOccurrences(of: languageKey, with: LanguageManager.currentLanguage.localeIdentifier)
        }
        // 添加打开「我的场景」所需参数：https://bytedance.larkoffice.com/wiki/PCs3wqmQci5W5EkeHO5cfAkQndf
        let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
        var theme: String = "light"; if #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark { theme = "dark" }
        let deviceId = (try? self.userResolver.resolve(type: PassportService.self))?.deviceID ?? ""
        urlString += "?terminal_type=4&app_version=\(appVersion)&theme=\(theme)&device_id=\(deviceId)&chat_id=\(chat.id)"
        // 隐藏底部的LauncherBar：https://bytedance.larkoffice.com/wiki/PUydwBcGWiM9Ilk2HF5cf6h9nsh
        urlString += "&lk_meta=%7B%22page-meta%22%3A%7B%22showBottomNavBar%22%3A%22false%22%7D%7D"
        // 如果是BOE环境，则需要加上泳道信息（H5依赖此配置进行调试）
        if EnvManager.env.isStaging { urlString += "&app_feat_env=\(PassportDebugEnv.xttEnv)" }

        guard let url = URL(string: urlString) else { return }
        // showTemporary：配置在iPad上不在临时区打开，和iPhone保持一样的present效果
        self.userResolver.navigator.present(url, context: ["showTemporary": false], from: from)
    }

    func openCreateScene(from: NavigatorFrom, chat: Chat) {
        let vm = SceneDetailViewModel(userResolver: self.userResolver, chat: chat)
        let vc = SceneDetailViewController(viewModel: vm)
        userResolver.navigator.present(vc, from: from)
    }

    func openEditScene(from: NavigatorFrom, chat: Chat, scene: ServerPB_Office_ai_MyAIScene) {
        let vm = SceneDetailViewModel(userResolver: self.userResolver, chat: chat, sceneId: scene.sceneID)
        let vc = SceneDetailViewController(viewModel: vm)
        userResolver.navigator.present(vc, from: from)
    }

    /// 添加某个场景到我的场景列表
    func handleSceneAddByApplink(_ applink: URL, from: NavigatorFrom) {
        MyAIServiceImpl.logger.info("my ai add scene by aplink begin")
        // 判断 MyAI 的开关
        guard self.enable.value else {
            MyAIServiceImpl.logger.info("my ai add scene by aplink error: aiService.enable == false")
            if let view = from.fromViewController?.view { UDToast.showTips(with: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_UnavailableStayTuned_Toast, on: view) }
            return
        }
        guard let query = applink.getQuery(), let token = query["token"], !token.isEmpty else {
            MyAIServiceImpl.logger.info("my ai add scene by aplink error: no token")
            return
        }
        // 如果需求FG没开，我的场景界面都没有，执行添加动作没有任何意义
        guard self.userResolver.fg.dynamicFeatureGatingValue(with: "lark.myai.mode.mvp") else {
            MyAIServiceImpl.logger.info("my ai add scene by aplink error: fg close")
            if let view = from.fromViewController?.view { UDToast.showTips(with: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_UnavailableStayTuned_Toast, on: view) }
            return
        }

        // 通过token获取场景信息，进行弹窗
        var request = ServerPB_Office_ai_GetSceneDetailByTokenRequest()
        request.token = token
        self.rustClient?.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiSceneGetSceneDetailByToken).observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response: ServerPB_Office_ai_GetSceneDetailByTokenResponse) in
                guard let `self` = self else { return }
                self.alertForSceneAdd(name: response.sceneName, token: token, from: from)
                MyAIServiceImpl.logger.info("my ai add scene by aplink, get info success")
            }, onError: { error in
                if let view = from.fromViewController?.view {
                    if let apiError = error.transformToAPIError().metaErrorStack.first(where: { $0 is APIError }) as? APIError {
                        // 如果是重复添加，则前面展示!
                        if apiError.errorCode == 500_104 {
                            UDToast.showWarning(with: UDToast.errorMessage(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, error: apiError), on: view)
                        } else {
                            UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: view, error: apiError)
                        }
                    } else {
                        UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: view, error: error)
                    }
                }
                MyAIServiceImpl.logger.info("my ai add scene by aplink, get info error: \(error)")
            }).disposed(by: self.disposeBag)
    }

    /// 弹窗确认是否添加场景
    private func alertForSceneAdd(name: String, token: String, from: NavigatorFrom) {
        let aiBrandName = MyAIResourceManager.getMyAIBrandNameFromSetting(userResolver: userResolver)
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_AddScenario_Popup_Title(name))
        dialog.setContent(text: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_AddScenario_Popup_Desc)
        dialog.addSecondaryButton(text: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_AddScenario_PopupCancel_Button, dismissCompletion: {
            IMTracker.Scene.Click.confirm(params: ["view_type": "add_shared_scene", "click": "cancel"])
        })
        dialog.addPrimaryButton(text: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_AddScenario_PopupAdd_Button, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            MyAIServiceImpl.logger.info("my ai add scene by aplink, add scene begin")
            IMTracker.Scene.Click.confirm(params: ["view_type": "add_shared_scene", "click": "confirm"])
            var request = ServerPB_Office_ai_AddNewSceneToMeRequest()
            request.token = token
            // 透传请求
            self.rustClient?.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiSceneAddNewSceneToMe).observeOn(MainScheduler.instance).subscribe(onNext: { _ in
                if let view = from.fromViewController?.view { UDToast.showTips(with: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_ScenarioAdded_Toast, on: view) }
                MyAIServiceImpl.logger.info("my ai add scene by aplink, add scene success")
            }, onError: { error in
                if let view = from.fromViewController?.view {
                    if let apiError = error.transformToAPIError().metaErrorStack.first(where: { $0 is APIError }) as? APIError {
                        UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: view, error: apiError)
                    } else {
                        UDToast.showFailure(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: view, error: error)
                    }
                }
                MyAIServiceImpl.logger.info("my ai add scene by aplink, add scene error: \(error)")
            }).disposed(by: self.disposeBag)
        })
        from.fromViewController?.present(dialog, animated: true)
        IMTracker.Scene.View.confirm(params: ["view_type": "add_shared_scene"])
    }
}
