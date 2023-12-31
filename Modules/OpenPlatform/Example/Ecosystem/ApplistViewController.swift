import RustPB
import TTMicroApp
import LarkUIKit
import EENavigator
import LKTracing
import OPSDK
import OPBlock
import OPGadget
import EEMicroAppSDK
import LarkUIKit
import LarkFeatureGating
import OPFoundation
import Heimdallr
import WebBrowser
import LarkAccountInterface
import LarkLeanMode
import LarkGuide
import LarkNavigation
import LarkTab
import AnimatedTabBar
import RxRelay
import LKCommonsLogging
import LarkAppLinkSDK
import EENavigator
import ECOProbe
import ECOProbeMeta
import LKLoadable
import UniverseDesignTheme
import UniverseDesignDialog
import UniverseDesignInput
import LarkSuspendable
import CoreGraphics
import EcosystemWeb
import OPWebApp
import LarkSetting
import LarkRustHTTP
#if canImport(LarkWorkplace)
import LarkWorkplace
#endif
import Foundation
import SnapKit

struct App {
    let name: String
    let action: () -> Void
}
struct AppSection {
    let name: String?
    var apps: [App]
}
enum GadgetDebugNavigateType {
    case push
    case child
    case present
}

class ApplistViewController: BaseUIViewController,
                             TabRootViewController,
                             LarkNaviBarDataSource,
                             LarkNaviBarDelegate,
                             LarkNaviBarAbility,
                             UITableViewDataSource,
                             UITableViewDelegate,
                             OPRenderSlotDelegate,
                             OPDebugScanDelegate {

    var tab: Tab { Tab.calendar }
    var controller: UIViewController { self }
    var titleText: BehaviorRelay<String> { BehaviorRelay(value: "Ecosystem工程主页") }
    var isNaviBarEnabled: Bool { true }
    var isDrawerEnabled: Bool { true }
    private let batchGadgetLoader = OPGadgetLoader()
    private var recentScanedApps = [App]()
    lazy var appSections: [AppSection] = {
        var debugTool: App? = nil
#if canImport(LarkWorkplace)
        debugTool = App(name: "工作台预览测试"){ [weak self] in
                guard let `self` = self else { return }
                let alertController = UIAlertController(
                    title: "工作台预览测试", message: nil, preferredStyle: .alert
                )
                alertController.addTextField { textField in
                    textField.placeholder = "token"
                }
                let confirmAction = UIAlertAction(title: "确定", style: .default) { [weak alertController] _ in
                    guard let alertController = alertController,
                          let token = alertController.textFields?.first?.text else {
                        return
                    }
                    self.navigate(url: "https://applink.feishu.cn/client/workplace/preview?token=\(token)")
                }
                let cancelAction = UIAlertAction(title: "取消", style: .cancel) { _ in }
                alertController.addAction(confirmAction)
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
            }
#endif
        var debugTools = [
            App(name: "小程序Debug页面"){ [weak self] in self?.navigate(nextVC: EMADebugViewController(common: nil))},
            App(
                name: "开启深色模式随系统变化",
                action: {
                    if #available(iOS 13, *) {
                        UDThemeManager.setUserInterfaceStyle(.unspecified)
                    } else {
                        assertionFailure("请升级到至少iOS13")
                    }
                }
            ),
            App(name: "扫码", action: {
                [weak self] in
                self?._scan()
            }),
        ]
        if let debugTool {
            debugTools.append(debugTool)
        }
        let onLineApps = [
            //            BOE 小程序
            //            App(name: "小程序示例"){ [weak self] in self?.navigate(url:"sslocal://microapp?app_id=cli_a2770a4f58b8901c")},
            //            App(name: "Universal Design"){ [weak self] in self?.navigate(url:"sslocal://microapp?app_id=cli_a2b692d0b6b8d01b")},
            //            App(name: "订阅号"){ [weak self] in self?.navigate(url:"sslocal://microapp?app_id=cli_a070cc071078d01b")},
            //            App(name: "BT小助手"){ [weak self] in self?.navigate(url:"sslocal://microapp?app_id=cli_9f10cc6249f9501b")},
            App(name: "小程序示例"){ [weak self] in self?.navigate(url:"sslocal://microapp?app_id=cli_9cf4d4ab0a7a9103")},
            App(name: "Universal Design"){ [weak self] in self?.navigate(url:"sslocal://microapp?app_id=cli_9f9523d441bf100b")},
            App(name: "订阅号"){ [weak self] in self?.navigate(url:"sslocal://microapp?app_id=cli_9e52d4b850fa500e")},
            App(name: "BT小助手"){ [weak self] in self?.navigate(url:"sslocal://microapp?app_id=cli_9cc01007af761108")},
            App(name: "People"){ [weak self] in self?.navigate(url:"sslocal://microapp?app_id=cli_9daefaa604681104")},
            App(name: "打卡"){ [weak self] in self?.navigate(url:"sslocal://microapp?app_id=cli_9c21a4767c305107")},
            App(name: "投票"){ [weak self] in self?.navigate(url:"sslocal://microapp?app_id=tt26b3500eb9998b36&start_page=pages%2Fvote-index%2Findex%3Fgroupid%3D6724871640557043976")},
            App(name: "我的工卡"){ [weak self] in self?.navigate(url:"sslocal://microapp?app_id=cli_9b49b4877738d102")},
            App(name: "审批"){ [weak self] in self?.navigate(url:"sslocal://microapp?app_id=cli_9cb844403dbb9108")},
            App(name: "ITService"){ [weak self] in self?.navigate(url:"sslocal://microapp?app_id=cli_9b6543d4c4eed102")},
            App(name: "Profile"){ [weak self] in self?.navigate(url:"sslocal://microapp?app_id=cli_9ccf3351bbb99101")},
            App(name: "Hi Travel"){ [weak self] in self?.navigate(url:"sslocal://microapp?app_id=cli_9c74b9c7042e9108")}                ]

        var blockPages = [
            App(name: "Block 测试容器"){[weak self] in self?.navigate(nextVC: BlockDebugViewController())},
        ]
#if canImport(LarkWorkplace)
        let blockPreview = App(name: "block预览"){ [weak self] in
                guard let self = self else { return }
                let alertController = UIAlertController(title: "打开block预览", message: nil, preferredStyle: .alert)
                alertController.addTextField { textField in
                    textField.placeholder = "输入预览页URL"
                }
                let confirmAction = UIAlertAction(title: "确定", style: .default) { [weak alertController] _ in
                    guard let alertController = alertController,
                    let urlTextField = alertController.textFields?.first else {
                        return
                    }
                    guard let url = URL(string: urlTextField.text ?? "") else {
                        return
                    }
                    let blockPreviewBody = BlockPreviewBody(url: url)
                    Navigator.shared.showDetailOrPush(body: blockPreviewBody, from: self)
                }
                alertController.addAction(confirmAction)
                let cancelAction = UIAlertAction(title: "取消", style: .cancel) { _ in }
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
            }
        blockPages.append(blockPreview)
#endif
        let gadgetPages = [
            App(name: "Push打开重构Gadget"){ [weak self] in self?.navigate(withDebugType: .push)},
            App(name: "嵌入式打开重构Gadget"){ [weak self] in self?.navigate(withDebugType: .child)},
            App(name: "Present打开重构Gadget"){ [weak self] in self?.navigate(withDebugType: .present)}
        ]
        let botPages = [
            App(name: "打开机器人Profile页", action: { [weak self] in
                guard let self = self else { return }
                let alertController = UIAlertController(title: "打开机器人Profile页", message: nil, preferredStyle: .alert)
                alertController.addTextField { textField in
                    textField.text = "cli_9b510f95daf91107"
                    textField.placeholder = "输入机器人appId"
                }
                alertController.addTextField { textField in
                    textField.text = "6619085506166669572"
                    textField.placeholder = "输入机器人botId"
                }
                let confirmAction = UIAlertAction(title: "确定", style: .default) { [weak alertController] _ in
                    guard let alertController = alertController, let appIdTextField = alertController.textFields?.first, let botIdTextField = alertController.textFields?.last else {
                        return
                    }
                    let appDetailBody = AppDetailBody(botId: botIdTextField.text ?? "", appId: appIdTextField.text ?? "", params: [:], scene: nil, chatID: nil)
                    Navigator.shared.showDetailOrPush(body: appDetailBody, wrap: LkNavigationController.self, from: self)
                }
                alertController.addAction(confirmAction)
                let cancelAction = UIAlertAction(title: "取消", style: .cancel) { _ in }
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
            })
        ]
        return [
            AppSection(name: "调试", apps: debugTools),
            AppSection(name: "Gadget测试", apps: gadgetPages),
            AppSection(name: "block测试", apps: blockPages),
            AppSection(name: "bot测试", apps: botPages),
            AppSection(name: "建议工作台打开", apps: onLineApps)
        ]
    }()
    lazy var appListView: UITableView = {
        let listView = UITableView(frame: CGRect.zero, style: .grouped)
        listView.delegate = self
        listView.dataSource = self
        listView.register(UITableViewCell.self, forCellReuseIdentifier: "ApplistCell")
        return listView
    }()
    
    //批量请求meta数据
    func batchRequestMeta() {
        guard let metaProvider = BDPModuleManager(of: .gadget)
            .resolveModule(with: MetaInfoModuleProtocol.self) as? MetaInfoModuleProtocol else {
            return
        }
        """
        "cli_a2770a4f58b8901c": "0.0.9",
        "cli_a2b692d0b6b8d01b": "1.0.61"

        "cli_a070cc071078d01b": "1.0.0",
    "cli_9f10cc6249f9501b": "1.0.0"
"""
        self.batchGadgetLoader.batchRemoteMetaWith(["cli_a2770a4f58b8901c": "0.0.9",
                                                  "cli_a2b692d0b6b8d01b": "1.0.16"
                                                 ], strategy: .update,
                                                   batchCompleteCallback: { resultList, _ in
            resultList?.forEach {appID, meta, error in
                print("meta:\(meta), error:\(error)")
            }
        })
//        (metaProvider as? MetaInfoModule)?.batchRequestRemoteMeta(["cli_a2770a4f58b8901c": "0.0.9",
//                                                                   "cli_a2b692d0b6b8d01b": "1.0.16"
//                                                                   ],
//                                                                  scene: "gadget_launch",
//                                                                  shouldSaveMeta: true,
//                                                                  success: { resultList, _ in
//            resultList.forEach {appID, meta, error in
//                print("meta:\(meta), error:\(error)")
//            }
//        }, failure: { error in
//            print("failure with error:\(error)")
//        })
    }
    
    func preloadWithData() {
        let gadgetIdsA = ["cli_9cf4d4ab0a7a9103",
                         "cli_9f9523d441bf100b",
                         "cli_9e52d4b850fa500e",
                         "cli_9cc01007af761108",
                         "cli_9daefaa604681104",
                          "cli_9c21a4767c305107"]
        
        let gadgetIdsB = ["tt26b3500eb9998b36",
                            "cli_9b49b4877738d102",
                            "cli_9b6543d4c4eed102",
                            "cli_9c74b9c7042e9108"]
        
        let gadgetUniqueIdsA = gadgetIdsA.flatMap{ OPAppUniqueID(appID: $0, identifier: nil, versionType: .current, appType: .gadget) }
        let gadgetUniqueIdsB = gadgetIdsB.flatMap{ OPAppUniqueID(appID: $0, identifier: nil, versionType: .current, appType: .gadget) }

        let blockUniqueIds = [OPAppUniqueID(appID: "cli_9f4623178bbe500c", identifier: "blk_5fcc9f0a2a868003b127e616", versionType: .current, appType: .block),
                              OPAppUniqueID(appID: "cli_a180fc58feb8d00b", identifier: "blk_610a40455f800004c32b6bb6", versionType: .current, appType: .block)]
        
        var directhandleInfoList = gadgetUniqueIdsA.flatMap{ BDPPreloadHandleInfo(uniqueID: $0, scene: BDPPreloadScene.PreloadPull, scheduleType: .directHandle, extra: nil) }
//        var toBeScheduleHandleInSilentUpdate = gadgetUniqueIdsA.flatMap{ BDPPreloadHandleInfo(uniqueID: $0, scene: .silenceUpdatePush, scheduleType: .toBeScheduled, extra:nil) }
        let toBeScheduleHandleInfoList = gadgetUniqueIdsB.flatMap{ BDPPreloadHandleInfo(uniqueID: $0, scene: BDPPreloadScene.PreloadPull, scheduleType: .toBeScheduled, extra:nil) }
        let blockHandleInfoList = blockUniqueIds.flatMap{ BDPPreloadHandleInfo(uniqueID: $0, scene: BDPPreloadScene.PreloadPull, scheduleType: .directHandle, extra:nil) }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1, execute: {
            BDPPreloadHandlerManager.sharedInstance.handlePkgPreloadEvent(preloadInfoList: directhandleInfoList)
        })
        
//        DispatchQueue(label: "com.test.queue.gadget").async{
            BDPPreloadHandlerManager.sharedInstance.handlePkgPreloadEvent(preloadInfoList: toBeScheduleHandleInfoList)
//        }
        DispatchQueue(label: "com.test.queue.block").async{
            BDPPreloadHandlerManager.sharedInstance.handlePkgPreloadEvent(preloadInfoList: blockHandleInfoList)
        }
        DispatchQueue(label: "com.test.queue.block.b").async{
            BDPPreloadHandlerManager.sharedInstance.handlePkgPreloadEvent(preloadInfoList: blockHandleInfoList)
        }
        
        for index in 0...100 {
            DispatchQueue(label: "com.test.queue.gadget.\(index)").async{
                BDPPreloadHandlerManager.sharedInstance.handlePkgPreloadEvent(preloadInfoList: [directhandleInfoList[index % 5]])
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(appListView)
        appListView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin).offset(naviHeight)
            make.leading.bottom.trailing.equalToSuperview()
        }
        
        OPApplicationService.current
            .pluginManager(for: .block) // 仅注入到 Block 类型应用中
            .registerPlugin(plugin: OPBlockAPIAdapterPlugin(apis: [
                .login,
                .getUserInfo,
                .openSchema,
                .enterProfile,
                .chooseChat,
                .chooseContact,
                .chooseImage,
                .showToast,
                .hideToast,
                .showModal,
                .docsPicker,
                .createRequestTask,
                .operateRequestTask,
                .createSocketTask,
                .operateSocketTask,
                .setStorage,
                .setStorageSync,
                .getStorage,
                .getStorageSync,
                .removeStorage,
                .removeStorageSync,
                .getStorageInfo,
                .getStorageInfoSync,
                .clearStorage,
                .clearStorageSync,
                .setContainerConfig,
                .showBlockErrorPage,
                .hideBlockErrorPage,
                .getEnvVariable,
                .getKAInfo,
                .onServerBadgePush,
                .offServerBadgePush
            ]))
        OPApplicationService.current.registerContainerService(
            for: .block,
            service: OPBlockContainerService()
        )
        OPApplicationService.current.registerContainerService(
            for: .gadget,
            service: OPGadgetContainerService()
        )
    }

    func navigate(url: String) {
        guard let url = URL(string: url) else { return }
        openURL(url: url)
    }
    
    func navigate(withDebugType type: GadgetDebugNavigateType) {
        switch type {
        case .present:
            let renderSlot = OPPresentControllerRenderSlot(
                presentingViewController: self,
                defaultHidden: false)
            let uniqueID = OPAppUniqueID(appID: "cli_9cf4d4ab0a7a9103", identifier: nil, versionType: .current, appType: .gadget, instanceID: nil)
            let application = OPApplicationService.current.createApplication(appID: uniqueID.appID)
            let container = application.createContainer(
                uniqueID: uniqueID,
                containerConfig: OPGadgetContainerConfig(previewToken: nil, enableAutoDestroy: true))
            renderSlot.delegate = self
            container.mount(
                data: OPGadgetContainerMountData(scene: .undefined, startPage: nil),
                renderSlot: renderSlot)
        case .push:
            guard let navigationController = self.navigationController else { return }
            let renderSlot = OPPushControllerRenderSlot(
                navigationController: navigationController,
                defaultHidden: false)
            let uniqueID = OPAppUniqueID(appID: "cli_9cb844403dbb9108", identifier: nil, versionType: .current, appType: .gadget)
            let application = OPApplicationService.current.getApplication(appID: uniqueID.appID) ?? OPApplicationService.current.createApplication(appID: uniqueID.appID)
            let container = application.getContainer(uniqueID: uniqueID) ?? application.createContainer(
                uniqueID: uniqueID,
                containerConfig: OPGadgetContainerConfig(previewToken: nil, enableAutoDestroy: true)
            )
            renderSlot.delegate = self
            container.mount(
                data: OPGadgetContainerMountData(scene: .undefined, startPage: nil),
                renderSlot: renderSlot)
        case .child:
            if BDPDeviceHelper.isPadDevice() {
                let lksplit = self.larkSplitViewController?.secondaryViewController
                let split = self.splitViewController
                let detail = lksplit ?? split?.viewControllers.last
                autoDissmisModals(detail)
                Navigator.shared.showDetail(OPTabGadgetTestViewController(),
                                            wrap: LkNavigationController.self,
                                            from: self,
                                            completion: nil)
            } else {
                OPNavigatorHelper.push(OPTabGadgetTestViewController(), window: view.window)
            }
        }
    }
    
    func navigate(nextVC: UIViewController) {
        if BDPDeviceHelper.isPadDevice() {
            let navigationController = LkNavigationController(rootViewController: nextVC)
            Navigator.shared.navigationProvider = { return navigationController }
            navigationController.navigationBar.isTranslucent = false
            self.present(navigationController, animated: true, completion: {
                nextVC.navigationItem.leftBarButtonItem = UIBarButtonItem(
                    barButtonSystemItem: .done,
                    target: self,
                    action: #selector(self.dismissSelf)
                )
            })
        } else {
            OPNavigatorHelper.topmostNav(searchSubViews: false, window: view.window)?.pushViewController(nextVC, animated: true)
        }
    }
    private func openURL(url: URL) {
        if url.host?.contains("applink.") == true {
            Navigator.shared.push(url, from: self)
            return
        }
        EERoute.shared().openURL(byPushViewController: url, window: self.view.window)
    }

    func domainConfig(envType: OPEnvType) -> MicroAppDomainConfig {
        switch envType {
        case .online:
            return MicroAppDomainConfig(settings: [DomainKey.openAppFeed: ["open.feishu.cn"],
                                                   DomainKey.mpConfig: ["open.feishu.cn"],
                                                   DomainKey.cdn: ["s3.pstatp.com"],
                                                   DomainKey.mpTt: ["i.snssdk.com"],
                                                   DomainKey.vod: ["vod.bytedanceapi.com"],
                                                   DomainKey.mpRefer: ["tmaservice.developer.toutiao.com"],
                                                   DomainKey.mpApplink: ["applink.feishu.cn"],
                                                   DomainKey.open: ["open.feishu.cn"]])
        case .staging:
            return MicroAppDomainConfig(settings: [DomainKey.openAppFeed: ["mina-staging.bytedance.net"],
                                                   DomainKey.mpConfig: ["mina-staging.bytedance.net"],
                                                   DomainKey.cdn: ["s3.pstatp.com"],
                                                   DomainKey.mpTt: ["i.snssdk.com"],
                                                   DomainKey.vod: ["vod.bytedanceapi.com"],
                                                   DomainKey.mpRefer: ["tmaservice.developer.toutiao.com"],
                                                   DomainKey.mpApplink: ["applink.feishu.cn"],
                                                   DomainKey.open: ["open.feishu-staging.cn"]])
        case .preRelease:
            return MicroAppDomainConfig(settings: [DomainKey.openAppFeed: ["open.feishu.cn"],
                                                   DomainKey.mpConfig: ["open.feishu.cn"],
                                                   DomainKey.cdn: ["s3.pstatp.com"],
                                                   DomainKey.mpTt: ["i.snssdk.com"],
                                                   DomainKey.vod: ["vod.bytedanceapi.com"],
                                                   DomainKey.mpRefer: ["tmaservice.developer.toutiao.com"],
                                                   DomainKey.mpApplink: ["applink.feishu.cn"],
                                                   DomainKey.open: ["open.feishu.cn"]])
        @unknown default:
            fatalError("有未支持的环境，务必及时兼容")
        }
    }

// MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appSections[section].apps.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ApplistCell", for: indexPath)
        cell.accessibilityIdentifier = "gadget.example.applist-\(indexPath.section)-\(indexPath.row)"
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.text = appSections[indexPath.section].apps[indexPath.row].name
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return appSections[section].name
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return appSections.count
    }

    @objc
    func dismissSelf() {
        self.presentedViewController?.dismiss(animated: true, completion: nil)
    }

// MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {tableView.deselectRow(at: indexPath, animated: true)}
        self.appSections[indexPath.section].apps[indexPath.row].action()
    }
    
    private func autoDissmisModals(_ from: UIViewController?) {
        from?.presentedViewController?.dismiss(animated: false, completion: nil)
        from?.navigationController?.presentedViewController?.dismiss(animated: false, completion: nil)
        from?.larkSplitViewController?.presentedViewController?.dismiss(animated: false, completion: nil)
        from?.splitViewController?.presentedViewController?.dismiss(animated: false, completion: nil)
        from?.tabBarController?.presentedViewController?.dismiss(animated: false, completion: nil)
    }

// MARK: - OPRenderSlotDelegate
    func onRenderAttatched(renderSlot: OPRenderSlotProtocol) {
        
    }
    
    func onRenderRemoved(renderSlot: OPRenderSlotProtocol) {
        
    }
    
    func currentViewControllerForPresent() -> UIViewController? {
        return self
    }
    
    func currentNavigationControllerForPush() -> UINavigationController? {
        return self.navigationController
    }

// MARK: - DebugScan

    // MARK: Private
    private func _scan() {
        let scanVC = OPDebugScanViewController.init()
        scanVC.delegate = self
        navigate(nextVC: scanVC)
    }
    
    // MARK: OPDebugScanDelegate
    internal func didCapture(outputValue: String?) {
        guard let schema = outputValue else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.navigate(url: schema)
        }
    }
}
