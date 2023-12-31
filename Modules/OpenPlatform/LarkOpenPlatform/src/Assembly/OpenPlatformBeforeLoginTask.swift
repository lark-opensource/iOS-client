//
//  OpenPlatformBeforeLoginTask.swift
//  LarkOpenPlatform
//
//  Created by ChenMengqi on 2022/2/8.
//

import Foundation
import BootManager
import LKLoadable
import TTMicroApp
import LarkMicroApp
import AppContainer
import WebBrowser
import LarkUIKit
import LarkContainer
#if NativeApp
import NativeAppPublicKit
#endif
import LarkSetting

final class OpenPlatformBeforeLoginTask: FlowBootTask, Identifiable {// user:global
    static var identify: TaskIdentify = "OpenPlatformBeforeLoginTask"
    override var runOnlyOnce: Bool {
        return true
    }

    override func execute(_ context: BootContext) {
        MicroAppAssembly.gadgetOB = GadgetObservableManager(resolver: BootLoader.container.getCurrentUserResolver(compatibleMode: true))
        OpenAppEngine.shared.assembleSetup(resolver: BootLoader.container, larkOpenProtocolType: EMAProtocolImpl.self, larkLiveFaceDelegate: EMALiveFaceProtocolImpl())
        setupConfig()
        setupEditor()
        #if NativeApp
        BootLoader.container.resolve(NativeAppManagerInternalProtocol.self)?.setupNativeAppManager()
        #endif
    }

    private func setupConfig() {
        EMAConfigManager.setSettingsFetchServiceProviderWith({
            return Injected<ECOSettingsFetchingService>().wrappedValue
        })
        EMAConfigManager.registeLegacyKey()
    }

    /// 初始化Editor逻辑，飞书生命周期只可以运行一次
    private func setupEditor() {
        BDPAppPageManagerForEditor.shared.bdpAppPageInitBlock = { (appPage) in
            handlerBDPAppPageInit(with: appPage)
        }
        BDPAppPageManagerForEditor.shared.bdpAppPageDeallocBlock = { (appPage) in
            handlerBDPAppPageDealloc(with: appPage)
        }
    }
}
