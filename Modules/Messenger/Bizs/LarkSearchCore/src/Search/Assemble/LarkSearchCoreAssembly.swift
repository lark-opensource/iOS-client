//
//  LarkSearchAssembly.swift
//  LarkSearch
//
//  Created by ChalrieSu on 2018/8/10.
//

import UIKit
import Foundation
import LarkContainer
import Swinject
import EENavigator
import LarkSDKInterface
import LarkMessengerInterface
import LarkRustClient
import LarkDebug
import LarkDebugExtensionPoint
import LarkAssembler
import LarkAppLinkSDK
import LarkAssetsBrowser
import UniverseDesignToast
import LarkSetting
import LarkNavigator

public enum PickerContainerSettings {
    private static var userScopeFG: Bool {
        let v = FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.user.picker")
        return v
    }
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}

public final class SearchCoreAssembly: LarkAssemblyInterface {
    public func registContainer(container: Container) {
        let user = container.inObjectScope(PickerContainerSettings.userScope)
        let userContainer = container.inObjectScope(.userV2)
        userContainer.register(SearchRemoteSettings.self) { r -> SearchRemoteSettings in
            let rustService = try r.resolve(assert: RustService.self)
            let v = SearchRemoteSettings(rustService: rustService)
            v.preload()
            return v
        }
        userContainer.register(SearchAPI.self) { (r) -> SearchAPI in
            let rustService = try r.resolve(assert: SDKRustService.self)
            return RustSearchAPI(userResolver: r, client: rustService)
        }
        user.register(PickerServiceContainer.self) { resolver -> PickerServiceContainer in
            return PickerServiceContainer(resolver: resolver)
        }
    }

    public func registRouter(container: Container) {
        getRegistRouter(container: container)
    }

    private func getRegistRouter(container: Container) -> Router {
        return Navigator.shared.registerRoute.type(PickerSelectedBody.self)
            .factory(cache: true, PickerSelectedHandler.init(resolver:))
    }

    public func registDebugItem(container: Container) {
        ({ ASLDebugItem(userResolver: container.getCurrentUserResolver()) }, SectionType.debugTool)
    }

    public func registLarkAppLink(container: Container) {
        // 注册通过 AppLink 调用图片浏览器
        LarkAppLinkSDK.registerHandler(path: WikiAssetBrowser.appLinkPath) { (applink: AppLink) in
            /* Used in EENavigator.
            guard let from = applink.context?.from() else {
                assertionFailure("Missing applink from")
                return
            }
             */
            if let params = WikiAssetParser.getAssetBrowserParams(resolver: container.getCurrentUserResolver(), from: applink.url) {
                let browser = WikiAssetBrowser(userResolver: container.getCurrentUserResolver())
                browser.displayAssets = params.assets
                browser.currentPageIndex = params.startIndex
                browser.isQRDetectionEnabled = params.isQRDetectionEnabled
                browser.isSavingImageEnabled = params.isSavingImageEnabled
                browser.pageIndicator = LKAssetDefaultPageIndicator()
                browser.show()
            }
        }
    }

    public init() {}
}

public final class PickerSelectedHandler: UserTypedRouterHandler {
    public func handle(_ body: PickerSelectedBody, req: EENavigator.Request, res: Response) throws {
        let pickerSelectedVC = PickerSelectedViewController(resolver: self.userResolver,
                                                            delegate: body.picker,
                                                            confirmTitle: body.confirmTitle,
                                                            allowSelectNone: body.allowSelectNone,
                                                            targetPreview: body.targetPreview,
                                                            completion: body.completion)
        pickerSelectedVC.shouldDisplayCountTitle = body.shouldDisplayCountTitle
        pickerSelectedVC.fromVC = body.picker.fromVC
        pickerSelectedVC.scene = body.picker.scene
        pickerSelectedVC.isNew = body.picker is SearchPickerView
        pickerSelectedVC.userId = body.userId
        pickerSelectedVC.isUseDocIcon = body.isUseDocIcon
        res.end(resource: pickerSelectedVC)
    }
}

public struct PickerSelectedBody: PlainBody {
    public static let pattern = "//client/contact/picker/selected"

    let picker: Picker
    let confirmTitle: String
    let allowSelectNone: Bool
    let shouldDisplayCountTitle: Bool
    let completion: (UIViewController) -> Void
    let targetPreview: Bool
    var userId: String?
    var isUseDocIcon: Bool = false

    public init(picker: Picker, confirmTitle: String, allowSelectNone: Bool, shouldDisplayCountTitle: Bool = true, targetPreview: Bool = false, completion: @escaping (UIViewController) -> Void) {
        self.picker = picker
        self.confirmTitle = confirmTitle
        self.allowSelectNone = allowSelectNone
        self.shouldDisplayCountTitle = shouldDisplayCountTitle
        self.targetPreview = targetPreview
        self.completion = completion
    }
}
