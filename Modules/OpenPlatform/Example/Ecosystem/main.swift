import AppContainer
import Blockit
import BootManager
import EcosystemWeb
import EENavigator
import Foundation
import LarkAccount
import LarkAccountAssembly
import LarkAppConfig
import LarkAppLinkSDK
import LarkAssembler
import LarkBadge
import LarkBaseService
import LarkCloudScheme
import LarkDebug
import LarkFeatureGating
import LarkGuide
import LarkLaunchGuide
import LarkLeanMode
import LarkMicroApp
import LarkNavigation
import LarkRustClientAssembly
import LarkSetting
import LarkSplitViewController
import LarkTab
import LarkTabMicroApp
import LarkUIKit
import LarkWebViewContainer
import LKLoadable
import RustPB
import Swinject
import TTMicroApp
import WebBrowser

#if canImport(LarkOpenPlatformAssembly)
import LarkOpenPlatformAssembly
#endif
import LarkCoreLocation

#if canImport(LarkworkplaceMod)
import LarkWorkplaceMod
#endif

class LarkMainAssembly: FlowBootTask, Identifiable {
    static var identify = "LarkMainAssembly"
    
    override func execute(_ context: BootContext) {
        var assemblies: [LarkAssemblyInterface] = [
            BaseAssembly()
        ]
        assemblies.append(LarkCoreLocationAssembly())
        assemblies.append(ECOInfraDependencyAssembly())
        assemblies.append(ECOProbeDependencyAssembly())
        assemblies.append(MicroAppPrepareAssembly())
        assemblies.append(OpenPlatformAssembly())
//        assemblies.append(SetupOPInterfaceTaskAssembly())
        assemblies.append(WebAssemblyV2())
#if canImport(LarkworkplaceMod)
        assemblies.append(WorkplaceAssembly())
#endif
        _ = Assembler(assemblies: assemblies, container: BootLoader.container)
        BootLoader.assemblyLoaded = true
        TabRegistry.register(.calendar) { _ -> TabRepresentable in
            FakeTab()
        }
        TabRegistry.register(.feed) { _ -> TabRepresentable in
            FakeTab2()
        }
        Navigator.shared.registerRoute(plainPattern: Tab.calendar.urlString) { (_, res) in
            res.end(resource: ApplistViewController())
        }
        Navigator.shared.registerRoute(plainPattern: Tab.feed.urlString) { (_, res) in
            res.end(resource: WebTestViewController(style: .plain))
        }
        assembleMenuPlugin()
    }
}
struct FakeTab: TabRepresentable {
  var tab: Tab { Tab.calendar }
}
struct FakeTab2: TabRepresentable {
  var tab: Tab { Tab.feed }
}
LKLoadableManager.run(appMain)
NewBootManager.register(LarkMainAssembly.self)
NewBootManager.register(InitIdleLoadTask.self)
BootLoader.shared.start(delegate: AppContainer.AppDelegate.self, config: .default)

/// 注册新版菜单的插件
private func assembleMenuPlugin() {
    /// 注册刷新插件
    let webRefreshContext = MenuPluginContext(
        plugin: WebRefreshMenuPlugin.self
    )
    MenuPluginPool.registerPlugin(pluginContext: webRefreshContext)
    
    /// 注册在Safari中打开的插件
    let webOpenInSafariContext = MenuPluginContext(
        plugin: WebOpenInSafariMenuPlugin.self
    )
    MenuPluginPool.registerPlugin(pluginContext: webOpenInSafariContext)
    
    /// 注册网页菜单头部插件
    let webMenuHeaderContext = MenuPluginContext(
        plugin: WebMenuHeaderPlugin.self
    )
    MenuPluginPool.registerPlugin(pluginContext: webMenuHeaderContext)
    
    /// 注册复制链接插件
    let webCopyLinkContext = MenuPluginContext(
        plugin: WebCopyLinkMenuPlugin.self
    )
    MenuPluginPool.registerPlugin(pluginContext: webCopyLinkContext)
    
    /// 注册多任务插件
    let webFloatingContext = MenuPluginContext(
        plugin: WebFloatingMenuPlugin.self
    )
    MenuPluginPool.registerPlugin(pluginContext: webFloatingContext)
}
