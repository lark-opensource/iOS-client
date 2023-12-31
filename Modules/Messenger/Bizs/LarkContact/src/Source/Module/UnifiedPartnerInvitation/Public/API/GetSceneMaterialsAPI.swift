//
//  GetSceneMaterialsAPI.swift
//  LarkContact
//
//  Created by bytedance on 2022/4/15.
//

import Foundation
import LarkRustClient
import LarkContainer
import ServerPB
import RxSwift
import LKCommonsLogging
import EEAtomic
import LarkUIKit

typealias GetMaterialsBySceneRequest = ServerPB_Retention_GetMaterialsBySceneRequest
typealias GetMaterialsBySceneResponse = ServerPB_Retention_GetMaterialsBySceneResponse

public enum OnboardingSceneType: String {
    // 判断是否命中"新 onboarding 页"实验
    case onboardingFlowAB   = "onboarding_flow_ab"
    // 判断是否是用户首登事件
    case firstLoginEvent    = "first_login_event"
    // 判断是否展示留资强制表单页
    case register           = "register"
    // 判断是否展示 onboarding 页
    case newOnBoarding      = "new_onboarding"
    // 判断是否展示强引导页
    case oldOnboarding      = "old_onboarding"
    // 行业Onboarding素材
    case authorizationPage  = "authorization_page"
}

protocol GetSceneMaterialsAPI {
    func getMaterialsBySceneRequest(scenes: [OnboardingSceneType]) -> Observable<GetMaterialsBySceneResponse>?
}

final class ServerGetSceneMaterialsAPI: GetSceneMaterialsAPI, UserResolverWrapper {

    @ScopedInjectedLazy private var rustService: RustService?

    static let logger = Logger.log(GetSceneMaterialsAPI.self, category: "LarkContact.GetSceneMaterialsAPI")
    var userResolver: LarkContainer.UserResolver
    init(resolver: UserResolver) {
        self.userResolver = resolver
    }
    public func getMaterialsBySceneRequest(scenes: [OnboardingSceneType]) -> Observable<GetMaterialsBySceneResponse>? {
        guard let rustService = self.rustService else { return nil }
        var request = GetMaterialsBySceneRequest()
        request.scenes = scenes.map({
            return $0.rawValue
        })
        request.platformType = Display.pad ? .platformIpad : .platformIphone
        Self.logger.info("request materials by scene :\(request.scenes.description)")
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .getMaterialsByScene)
    }
}
