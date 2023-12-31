import ECOProbe
import ECOProbeMeta
import LarkFoundation
import LarkOPInterface
import LKCommonsLogging
import OPSDK
import OPWebApp
import SnapKit
import TTMicroApp
import UniverseDesignColor
import UniverseDesignEmpty
import WebBrowser
import WebKit

private let logger = Logger.ecosystemWebLog(WebAppIntegratedLoadExtensionItem.self, category: "WebAppIntegratedLoadExtensionItem")

private let errorDomain = "WebAppIntegratedLoadErrorDomain"
/// 这里的code不要删除，只能增加，不然遇到问题没法查了的
private let invaildURLCode = -1
private let noMobileURL = -2
private let metaPkgInternal = -3
private let lowVersion = -4
private let onlineInvaildURLCode = -5
private let offlineInvaildURLCode = -6
private let onlineMetaPkgInternal = -7
private let offlineMetaPkgInternal = -8
@available(*, deprecated, message: "use fetchWebAppBrowser")
final class WebAppIntegratedLoadExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "WebAppIntegratedLoad"
    let appID: String
    
    let webAppIntegratedConfiguration: WebAppIntegratedConfiguration
    
    weak var webAppIntegratedLoadDelegate: WebAppIntegratedLoadProtocol?
    
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = WebAppIntegratedLoadWebBrowserLifeCycle(item: self)
    
    init(
        appID: String,
        webAppIntegratedConfiguration: WebAppIntegratedConfiguration,
        webAppIntegratedLoadDelegate: WebAppIntegratedLoadProtocol?
    ) {
        self.appID = appID
        self.webAppIntegratedConfiguration = webAppIntegratedConfiguration
        self.webAppIntegratedLoadDelegate = webAppIntegratedLoadDelegate
    }
    
}

@available(*, deprecated, message: "use fetchWebAppBrowser")
final public class WebAppIntegratedLoadWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    
    private weak var item: WebAppIntegratedLoadExtensionItem?
    
    let webAppIntegratedConfiguration: WebAppIntegratedConfiguration
    
    private let trace = OPTraceService.default().generateTrace()
    
    private weak var browser: WebBrowser?
    
    private var failView: UIView?
    
    init(item: WebAppIntegratedLoadExtensionItem) {
        self.item = item
        self.webAppIntegratedConfiguration = item.webAppIntegratedConfiguration
    }
    
    public func viewDidLoad(browser: WebBrowser) {
        logger.info("viewDidLoad")
        self.browser = browser
        guard let appID = item?.appID else { return }
        loadWebAppIntegratedData(appID: appID, browser: browser)
    }
    
    private func loadWebAppIntegratedData(appID: String, browser: WebBrowser) {
        var finish: OPMonitor?
        item?.webAppIntegratedLoadDelegate?.webAppIntegratedDidStartLoad(browser: browser, appID: appID)
        OPMonitor(EPMClientOpenPlatformWebLaunchCode.meta_pkg_load_start)
            .tracing(trace)
            .addCategoryValue("appId", appID)
            .addCategoryValue("scene", webAppIntegratedConfiguration.openWebAppIntegratedScene.rawValue)
            .flush()
        finish = OPMonitor(EPMClientOpenPlatformWebLaunchCode.meta_pkg_load_finish)
            .tracing(trace)
            .addCategoryValue("appId", appID)
            .addCategoryValue("scene", webAppIntegratedConfiguration.openWebAppIntegratedScene.rawValue)
            .timing()
        OPWebAppManager
            .sharedInstance
            .prepareWebApp(
                uniqueId: OPAppUniqueID(
                    appID: appID,
                    //  下边三个参数选择按照包管理要求填写
                    identifier: nil,
                    versionType: .current,
                    appType: .webApp,
                    instanceID: browser.configuration.webBrowserID
                ),
                previewToken: nil,
                //  按照包管理要求，设置为true
                supportOnline: true
            ) { [weak self, weak browser] error, state, ext in
                guard let browser = browser else { return }
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if let error = error {
                        /*
                         下边是包管理要求的特殊处理逻辑参考代码（WebApp的AppLink中），如果是版本不兼容导致的错误，需要提示对应文案
                         if let error = error {
                         var errorMessage = BundleI18n.LarkOpenPlatform.OpenPlatform_AppActions_NetworkErrToast
                         //如果是版本不兼容导致的错误，需要提示对应文案
                         if let error = error as? OPError,
                         let errorExTypeValue = error.userInfo["errorExType"] as? Int {
                         //提示版本太低需要更新
                         if errorExTypeValue == OPWebAppErrorType.verisonCompatible.rawValue {
                         errorMessage = BundleI18n.LarkOpenPlatform.OpenPlatform_H5Installer_ClientUpdate
                         //离线能力未开启，提示不可用
                         } else if errorExTypeValue == OPWebAppErrorType.offlineDisable.rawValue {
                         errorMessage = BundleI18n.LarkOpenPlatform.OpenPlatform_Worker_FeatureUnavailable
                         }
                         }
                         UDToast.removeToast(on: topViewContainer)
                         UDToast.showTips(with: errorMessage, on: topViewContainer)
                         return
                         }
                         */
                        if let ope = error as? OPError, let errorExTypeValue = ope.userInfo["errorExType"] as? Int, errorExTypeValue == OPWebAppErrorType.verisonCompatible.rawValue {
                            self.loadError(browser: browser, failViewError: nil, webAppIntegratedLoadDelegateError: error, monitor: finish)
                        } else {
                            self.loadError(browser: browser, failViewError: error, webAppIntegratedLoadDelegateError: error, monitor: finish)
                        }
                    } else {
                        switch state {
                        case .meta:
                            if let ext = ext {
                                if ext.offlineEnable {
                                    //  离线模式，等包回调即可
                                } else {
                                    if let mobileUrl = ext.mobileUrl {
                                        if let url = URL(string: mobileUrl) {
                                            self.loadResources(browser: browser, appID: appID, url: url, offline: false, monitor: finish)
                                        } else {
                                            let e = NSError(domain: errorDomain, code: onlineInvaildURLCode)
                                            self.loadError(browser: browser, failViewError: e, webAppIntegratedLoadDelegateError: e, monitor: finish)
                                        }
                                    } else {
                                        let e = NSError(domain: errorDomain, code: noMobileURL)
                                        self.loadError(browser: browser, failViewError: e, webAppIntegratedLoadDelegateError: e, monitor: finish)
                                    }
                                }
                            } else {
                                let e = NSError(domain: errorDomain, code: onlineMetaPkgInternal)
                                self.loadError(browser: browser, failViewError: e, webAppIntegratedLoadDelegateError: e, monitor: finish)
                            }
                        case .pkg:
                            if let ext = ext {
                                if ext.offlineEnable {
                                    var offlineURLString = ext.vhost
                                    if var path = ext.mainUrl {
                                        if !path.starts(with: "/") {
                                            //  此处代码对齐离线包项目经理在AppLink中新增代码，咨询后了解到此处含义：假设客户不懂RFC规范并且后端也不懂RFC规范，导致path居然没有以 / 开头，虽然是劣币驱逐良币，但是不做这个兼容就会导致所谓的“安卓能跑iOS不能跑”，因为安卓老代码加了这个代码，所以AppLink那边也加了这个代码，这里也就必须对齐.Tips: 离线包项目经理反馈代码是和老 AppLink 里的代码抄过来的，并非原创
                                            path = "/" + path
                                        }
                                        offlineURLString = offlineURLString + path
                                    }
                                    if let url = URL(string: offlineURLString) {
                                        //  版本可用性逻辑与包管理那边完全一致
                                        /* 包管理那边的参考代码
                                         //判断版本可用性
                                         if let minLarkVersion = meta.extConfig.minLarkVersion as? String,
                                         let larkVersion = BDPDeviceTool.bundleShortVersion {
                                         //如果minLarkVersion大于本地飞书版本，则不允许打开离线包
                                         if BDPVersionManager.iosVersion2Int(minLarkVersion) >
                                         BDPVersionManager.iosVersion2Int(larkVersion) {
                                         let opError = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, userInfo: ["errorExType": OPWebAppErrorType.verisonCompatible.rawValue])
                                         completion?(false, nil, opError)
                                         return
                                         
                                         }
                                         }
                                         */
                                        if let minLarkVersion = ext.minLarkVersion {
                                            if !minLarkVersion.isEmpty {
                                                let larkVersion = LarkFoundation.Utils.appVersion
                                                if !larkVersion.isEmpty {
                                                    if BDPVersionManager.compareVersion(minLarkVersion, with: larkVersion) > 0 {
                                                        self.loadError(browser: browser, failViewError: nil, webAppIntegratedLoadDelegateError: NSError(domain: errorDomain, code: lowVersion), monitor: finish)
                                                    } else {
                                                        self.loadResources(browser: browser, appID: appID, url: url, offline: true, monitor: finish)
                                                    }
                                                } else {
                                                    self.loadResources(browser: browser, appID: appID, url: url, offline: true, monitor: finish)
                                                }
                                            } else {
                                                self.loadResources(browser: browser, appID: appID, url: url, offline: true, monitor: finish)
                                            }
                                        } else {
                                            //  和包管理接口人咨询过：开发者没配置最小版本，可以打开
                                            self.loadResources(browser: browser, appID: appID, url: url, offline: true, monitor: finish)
                                        }
                                    } else {
                                        let e = NSError(domain: errorDomain, code: offlineInvaildURLCode)
                                        self.loadError(browser: browser, failViewError: e, webAppIntegratedLoadDelegateError: e, monitor: finish)
                                    }
                                } else {
                                    //  和包管理对接人沟通了，就算是在线的，也会走这个回调，要求在这里不要做判断，空的就好
                                }
                            } else {
                                let e = NSError(domain: errorDomain, code: offlineMetaPkgInternal)
                                self.loadError(browser: browser, failViewError: e, webAppIntegratedLoadDelegateError: e, monitor: finish)
                            }
                        }
                    }
                }
            }
    }
    
    private func loadResources(browser: WebBrowser, appID: String, url: URL, offline: Bool, monitor: OPMonitor?) {
        if offline {
            registerWebOfflineExtensionItems(browser: browser, appID: appID)
        }
        if let item = item {
            if let delegate = item.webAppIntegratedLoadDelegate {
                delegate.webAppIntegratedDidFinishLoad(browser: browser, appID: appID)
            } else {
                logger.info("has no webAppIntegratedLoadDelegate")
            }
        }
        monitor?
            .setResultTypeSuccess()
            .timing()
            .flush()
        
        // 根据传入的startPath，替换url中的path，以跳转到指定的子路径
        if let updatedUrl = url.replaceWebAppUrlIfNeeded(
            with: webAppIntegratedConfiguration.startPath,
            queryItems: webAppIntegratedConfiguration.startQueryItems,
            openWebAppIntegratedScene: webAppIntegratedConfiguration.openWebAppIntegratedScene
        ) {
            logger.info("replace url path")
            browser.loadURL(updatedUrl)
            return
        }
        browser.loadURL(url)
    }
    
    private func loadError(browser: WebBrowser, failViewError: Error?, webAppIntegratedLoadDelegateError: Error, monitor: OPMonitor?) {
        if let item = item {
            if let delegate = item.webAppIntegratedLoadDelegate {
                delegate.webAppIntegratedDidFailLoad(browser: browser, error: webAppIntegratedLoadDelegateError)
            } else {
                logger.info("has no webAppIntegratedLoadDelegate")
            }
        }
        showFailView(browser: browser, error: failViewError)
        monitor?
            .setResultTypeFail()
            .setError(webAppIntegratedLoadDelegateError)
            .timing()
            .flush()
    }
    
    private func showFailView(browser: WebBrowser, error: Error?) {
        guard webAppIntegratedConfiguration.enableWebAppIntegratedLoadUI else { return }
        if failView != nil {
            failView?.removeFromSuperview()
            failView = nil
        }
        let fail = createFailView(error: error)
        failView = fail
        browser.view.addSubview(fail)
        fail.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview()
        }
    }
    
    private func createFailView(error: Error?) -> UIView {
        let bgview = UIView()
        bgview.backgroundColor = UIColor.ud.bgBody
        var des: UniverseDesignEmpty.UDEmptyConfig.Description?
        if let error = error {
            if let err = error as? NSError {
                //  这个错误真的不一定是 NSError
                des = .init(descriptionText: BundleI18n.EcosystemWeb.OpenPlatform_AppErrPage_PageLoadFailedErrDesc(err.domain, err.code))
            }
        } else {
            // 版本低
            des = .init(descriptionText: BundleI18n.EcosystemWeb.OpenPlatform_GadgetErr_ClientVerTooLow)
        }
        var primaryButtonConfig: (String?, (UIButton) -> Void)?
        if error != nil {
            primaryButtonConfig = (BundleI18n.EcosystemWeb.Lark_Legacy_WebRefresh, { [weak self] (_) in
                guard let self = self else { return }
                self.retryButtonTap()
            })
        }
        let empty = UDEmpty(
            config: .init(
                title: .init(titleText: BundleI18n.EcosystemWeb.loading_failed),
                description: des,
                type: .loadingFailure,
                primaryButtonConfig: primaryButtonConfig
            )
        )
        bgview.addSubview(empty)
        empty.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        return bgview
    }
    
    private func retryButtonTap() {
        guard let browser = browser else { return }
        guard let appID = item?.appID else { return }
        failView?.removeFromSuperview()
        failView = nil
        loadWebAppIntegratedData(appID: appID, browser: browser)
    }
}
