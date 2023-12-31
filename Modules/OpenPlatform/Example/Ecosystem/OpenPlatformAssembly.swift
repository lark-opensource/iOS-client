//
//  OpenPlatformAssembly.swift
//  Ecosystem
//
//  Created by yinyuan on 2021/3/30.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import Swinject
import EENavigator
import LarkRustClient
import LarkAppLinkSDK
import OPFoundation
import LarkMicroApp
import LarkAccountInterface
import RxSwift
import LarkWebViewContainer
import WebBrowser
import EcosystemWeb
import LarkAssembler
import TTMicroApp
import OPPlugin
import BootManager

public class OpenPlatformAssembly: LarkAssemblyInterface {

    private let disposeBag = DisposeBag()
    
    public init() {}
    
    public func registContainer(container: Container) {
        container.register(EMAProtocol.self) { resolver -> EMAProtocol in
            EMAProtocolImpl(resolver: resolver)
        }.inObjectScope(.container)
    }
    
    public func registLaunch(container:Container){
        NewBootManager.register(OpenPlatformBeforeLoginTask.self)
        NewBootManager.register(SetupOPInterfaceTask.self)
        NewBootManager.register(SetupOpenPlatformTask.self)
    }

    public func registLarkAppLink(container: Swinject.Container) {
//        assemblerOpenApp(container: container)
        
        assemblerAppLink(container: container)
        
        assemblerAppReviewManager(container: container)
        
        assemblerDrive(container: container)
        assemblerLocation(container: container)
        assemblerMedia(container: container)
        let userContainer = container.inObjectScope(OPUserScope.userScope)
        
        userContainer.register(PrefetchRequestV2Proxy.self) { (r) -> PrefetchRequestV2Proxy in
            return try OpenPluginPrefetchRequestProvider(resolver: r)
        }
    }
    
    private func assemblerAppLink(container: Container) {
        //  注册小程序 AppLink 协议
        LarkAppLinkSDK.registerHandler(path: "/client/mini_program/open", handler: { (applink: AppLink) in
            // 解析 appLink 参数
            var queryParameters: [String: String] = [:]
            if let components = URLComponents(url: applink.url, resolvingAgainstBaseURL: false),
                let queryItems = components.queryItems {
                for queryItem in queryItems {
                    queryParameters[queryItem.name] = queryItem.value
                }
            }

            let sslocalModel = SSLocalModel()
            sslocalModel.type = .open
            guard let appId = queryParameters["appId"] else {
                return
            }
            sslocalModel.app_id = appId
            if let path = queryParameters["path_ios"] ?? queryParameters["path"] {
                sslocalModel.start_page = path
            }
            if let launchQuery = queryParameters[kBdpLaunchQueryKey] {
                sslocalModel.bdp_launch_query = launchQuery
            }
            if let requestAbility = queryParameters[kBdpLaunchRequestAbilityKey] {
                sslocalModel.required_launch_ability = requestAbility
            }
            guard let url = sslocalModel.generateURL() else {
                return
            }
            EERoute.shared().openURL(byPushViewController: url, window: nil)
        })
    }
    
    private func assemblerOpenApp(container: Container) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            
            OpenAppEngine.shared.notifyLoginIfNeeded()
            // 监听账户状态变化
            AccountServiceAdapter
                .shared
                .accountChangedObservable
                .subscribe(onNext: { (account) in
                    if account != nil {
                        OpenAppEngine.shared.notifyLoginIfNeeded()
                    }
                })
                .disposed(by: self.disposeBag)
        }
       
    }
    
    private func assemblerAppReviewManager(container: Container) {
        container.register(AppReviewService.self) { _ in
            return AppReviewManager()
        }.inObjectScope(.container)
    }
    
    private func assemblerDrive(container: Container) {
        container.register(OpenPluginDriveUploadProxy.self) { resolver -> OpenPluginDriveUploadProxy in
            return OpenPlatformDriveSDKMockProvider(resolver: resolver)
        }.inObjectScope(.container)
        container.register(OpenPluginDriveDownloadProxy.self) { resolver -> OpenPluginDriveDownloadProxy in
            return OpenPlatformDriveSDKMockProvider(resolver: resolver)
        }.inObjectScope(.container)
        container.register(OpenPluginDrivePreviewProxy.self) { resolver -> OpenPluginDrivePreviewProxy in
            return OpenPlatformDriveSDKMockProvider(resolver: resolver)
        }.inObjectScope(.container)
    }
    

    private func assemblerLocation(container: Container) {
        container.register(OpenPluginSearchPoiProxy.self) { _ in
            return OpenPlatformMockSearchPOIProvider()
        }.inObjectScope(.container)
    }
    
    private func assemblerMedia(container: Container) {
        container.register(OpenPluginMediaProxy.self) { _ in
            return OpenPlatformMockMediaProvider()
        }.inObjectScope(.container)
    }
}
