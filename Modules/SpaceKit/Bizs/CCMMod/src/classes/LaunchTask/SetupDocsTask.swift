//
//  SetupDocsTask.swift
//  LarkSpaceKit
//
//  Created by KT on 2020/7/8.
//

import Foundation
import BootManager
import LarkContainer
import LarkAppConfig
import LarkAccountInterface
import LarkDebugExtensionPoint
import LarkPerf
import SKFoundation
import EENavigator

#if MessengerMod
import LarkMessengerInterface
#endif

import LarkTab
import LarkUIKit
import SKCommon
import SKInfra

class SetupDocsTask: UserFlowBootTask, Identifiable {
    static var identify = "SetupDocsTask"

    override class var compatibleMode: Bool { CCMUserScope.compatibleMode }

    override var scope: Set<BizScope> {
        return [.docs]
    }

    @ScopedProvider<AppConfiguration>
    private var appConfiguration

    override func execute(_ context: BootContext) {
        // 原afterAccountLoaded
        DebugRegistry.registerDebugItem(DocsDebugItem(), to: .debugTool)
        
        // SpaceKitAssemble.registNonAssembleTask()
        
        HostAppBridge.shared.register(service: ShareToLarkService.self) { (service) -> Any? in
            guard let from = service.fromVC else { return nil }
            #if MessengerMod
            let prepare: ((UIViewController) -> Void)? = {
                $0.modalPresentationStyle = .formSheet
            }
            switch service.contentType {
            case let .link(title, content):
                let shareBody = ShareContentBody(title: title, content: content)
                Navigator.shared.present(body: shareBody, from: from, prepare: prepare)
            case let .text(content, callback):
                var shareBody = ForwardTextBody(text: content, sentHandler: callback)
                Navigator.shared.present(body: shareBody, from: from, prepare: prepare)
            case let .image(name, image):
                let shareBody = ShareImageBody(name: name,
                                               image: image,
                                               type: .forward,
                                               needFilterExternal: true)
                Navigator.shared.present(body: shareBody, from: from, prepare: prepare)
            @unknown default:
                break
            }
            #endif
            return nil
        }

        HostAppBridge.shared.register(service: SwitchTabService.self) { (service) -> Any? in
            let docHome = Tab.doc.url.append(fragment: service.path)
            Navigator.shared.switchTab(docHome, from: service.from, animated: true)
            return nil
        }

        appConfiguration?.register(cookieDomainAlias: .docsMainDomain)
        assembleMenuPlugin()
    }
    
    private func assembleMenuPlugin() {
       // 注册剪存插件
       let clippingDocContext = MenuPluginContext(
           plugin: ClippingDocMenuPlugin.self
       )
       MenuPluginPool.registerPlugin(pluginContext: clippingDocContext)
    }
}
