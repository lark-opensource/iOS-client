//
//  MailEditorLoader.swift
//  MailSDK
//
//  Created by Ryan on 2020/4/27.
//

import UIKit
import WebKit
import LarkAppConfig
import LarkFoundation
import LarkEditorJS
import LarkWebViewContainer
import LarkLocalizations
import RxSwift
import Homeric
import UniverseDesignTheme
import LarkStorage

let docsJSMessageName = "invoke"
let notifyReady = "biz.notify.ready"

enum ChangeEditorType: Int {
    case settingChange = 0
    case switchMailAccount = 1
    case switchLarkAccount = 2
    case cacheInvalidChange = 3
    case enterpriseFGChange = 4
    case aiNickNameChange = 5
}

protocol MailEditorLoaderDelegate: AnyObject {
    func getCurrentAccountContext() -> MailAccountContext
}

class MailEditorLoader: NSObject {

    // The internal editor that maintenance by the loader, must be private
    private var currentCommonEditor: MailSendWebView?
    private var currentNewMailEditor: MailSendWebView?
    private var currentAIEditor: MailSendWebView?
    var sendSence: String = ""
    var isFirstStart = true
    var timer: Timer?
    var failRetryCount = 0
    var forceUnziped = false
    private(set) var disposeBag = DisposeBag()
    let notiDisposeBag = DisposeBag()

    var fontStyleCode: String = ""

    var isEditorDebugMode: Bool {
        #if DEBUG
        let kvStore = MailKVStore(space: .global, mSpace: .global)
        return kvStore.bool(forKey: MailDebugViewController.kMailEditorDebug)
        #else
        return false
        #endif
    }


    var isCommonEditorBundleExis: Bool {
        let commonBundlePath = CommonJSUtil.getJSPath()
        return AbsPath(commonBundlePath).exists
    }
    
    var oooEditor: MailSendWebView {
        let editorValue: MailSendWebView = createEditor()
        MailLogger.info("oooEditor create one")
        var param: [String: String] = ["isBackground": "false"]
        if !sendSence.isEmpty {
            param["sence"] = sendSence
        }
        MailTracker.log(event: "mail_editor_create_type", params: param)
        return editorValue
    }
    
    var commonEditor: MailSendWebView {
        let type: String
        let editorValue: MailSendWebView
        if let editor = currentCommonEditor, editor.isReady {
            MailLogger.info("commonEditor is ready, return directly")
            editor.useCached = true
            editorValue = editor
            currentCommonEditor = nil
            type = "true"
        } else {
            let editor = createEditor()
            editorValue = editor
            MailLogger.info("commonEditor not ready, create one")
            type = "false"
        }
        var param: [String: String] = ["isBackground": type]
        if !sendSence.isEmpty {
            param["sence"] = sendSence
        }
        MailTracker.log(event: "mail_editor_create_type", params: param)
        return editorValue
    }
    var newMailEditor: MailSendWebView {
       let type: String
       let editorValue: MailSendWebView
       if let editor = currentNewMailEditor, editor.isReady {
           MailLogger.info("newMailEditor is ready, return directly")
           editor.useCached = true
           editorValue = editor
           currentNewMailEditor = nil
           type = "true"
       } else {
           let editor = createEditor()
           editor.canPreRender = true
           editorValue = editor
           MailLogger.info("newMailEditor not ready, create one")
           type = "false"
       }
       var param: [String: String] = ["isBackground": type]
       if !sendSence.isEmpty {
           param["sence"] = sendSence
       }
       MailTracker.log(event: "mail_editor_create_type", params: param)
       // 为三方注册delegate
       return editorValue
   }
    
    var AIEditor: MailSendWebView {
        let editorValue: MailSendWebView
        if let editor = currentAIEditor, editor.isReady {
            MailLogger.info("AIEditor is ready, return directly")
            editor.useCached = true
            editorValue = editor
            currentAIEditor = nil
        } else {
            let editor = createEditor(aiEditor: true)
            editorValue = editor
            MailLogger.info("AIEditor not ready, create one")
        }
        return editorValue
    }


    var user: User? {
        delegate?.getCurrentAccountContext().user
    }

    weak var delegate: MailEditorLoaderDelegate?
    lazy var enterpriseFG: Bool = FeatureManager.realTimeOpen(.enterpriseSignature)

    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceivedBundleReady), name: Notification.Name.LarkEditorJS.BUNDLE_RESOUCE_HAS_BEEN_UNZIP, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        EventBus.accountChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                guard let `self` = self else { return }
                if case .accountChange(let change) = push {
                    if self.currentNewMailEditor != nil {
                        if !FeatureManager.realTimeOpen(.enterpriseSignature) {
                            let oldSig = self.currentNewMailEditor?.oldSignature
                            let newSig = change.account.mailSetting.signature
                            if oldSig != newSig {
                                self.changeNewEditor(type: .settingChange)
                                MailLogger.info("deinit sig not the same")
                            } else {
                                MailLogger.info("deinit sig is the same")
                            }
                        }
                        if let oldFromAddress = self.currentNewMailEditor?.draft?.fromAddress {
                            let newFromAddress = change.account.mailSetting.emailAlias.defaultAddress.address
                            if oldFromAddress != newFromAddress {
                                self.changeNewEditor(type: .settingChange)
                                MailLogger.info("[Mail_Alias_Setting] deinit Alias NOT the same")
                            } else {
                                MailLogger.info("[Mail_Alias_Setting] deinit Alias IS the same")
                            }
                        }
                    }
                }

            }).disposed(by: notiDisposeBag)

        EventBus.accountChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (change) in
                guard let `self` = self else { return }
                if case .currentAccountChange = change {
                    self.changeNewEditor(type: .switchMailAccount)
                }
            }).disposed(by: notiDisposeBag)
        PushDispatcher
            .shared
            .mailChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                guard let `self` = self else { return }
                switch push {
                case .cacheInvalidChange(let change):
                    self.changeNewEditor(type: .cacheInvalidChange)
                default:
                    break
                }
        }).disposed(by: notiDisposeBag)
        
        let (fontNormalBase64, fontBoldBase64) = getLarkCircularFontBase64String()
        if !fontNormalBase64.isEmpty && !fontBoldBase64.isEmpty {
            fontStyleCode = """
            @font-face {
                font-family: 'Lark Circular';
                font-weight: normal;
                src: local('Lark Circular'),
                     url('data:@file/octet-stream;base64,\(fontNormalBase64)');
            }
            @font-face {
                font-family: 'Lark Circular';
                font-weight: bold;
                src: local('Lark Circular'),
                     url('data:@file/octet-stream;base64,\(fontBoldBase64)');
            }
            """
        }
    }
    @objc
    func appDidBecomeActive() {
        if canPreloadEditor() {
            MailLogger.info("fg open, reset the pool")
            if let ready = self.currentCommonEditor?.isReady,
                ready == false {
                clear()
            }
            preloadEditor()
        }
    }

    @objc
    func didReceivedBundleReady() {
        preloadEditor()
    }
    var businessWindow: UIWindow? {
        return UIApplication.shared.windows.first {
            $0.rootViewController != nil && $0.windowLevel == .normal
        }
    }

    func createEditor(aiEditor: Bool = false) -> MailSendWebView {
        // 每次打开草稿需要拉取一下Rust签名数据
        MailLogger.info("createEditor in loader")
        let config = WKWebViewConfiguration()

        var userContentController = WKUserContentController()
        userContentController.add(self, name: "nativeLog")
        config.userContentController = userContentController

        config.websiteDataStore = WKWebsiteDataStore.default()
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")

        // 需要通过 SchemeManager 自定义协议拦截（主要用作图片拦截）
        config.processPool = MailNewBaseWebView.defaultWKProcessPool
        MailCustomURLProtocolService.schemes.forEach {
            if LarkFoundation.Utils.isSimulator, isEditorDebugMode, ($0 == .http || $0 == .https)  {
                return
            } else {
                let handler = $0.makeSchemeHandler(provider: delegate?.getCurrentAccountContext())
                config.setURLSchemeHandler(handler, forURLScheme: $0.rawValue)
            }
        }
        let builder = LarkWebViewConfigBuilder().setWebViewConfig(config)
        let webviewConfig = builder.build(bizType: .mail, performanceTimingEnable: true)
        let editView = MailSendWebView(frame: .zero, config: webviewConfig)
        editView.editorLoader = self
        editView.inputAccessory.realInputAccessoryView = nil
        editView.scrollView.isScrollEnabled = false
        editView.scrollView.bounces = false
        editView.scrollView.panGestureRecognizer.isEnabled = false
        editView.scrollView.isDirectionalLockEnabled = false
        editView.disableScroll = true
        editView.navigationDelegate = self
        // In ipad, the webview will use another ua which does not contain any field about lark. docs backend will fails this kind of request. So we add the 'lark' field into the ua
        if Display.pad {
            editView.setValue("Lark", forKey: "applicationNameForUserAgent")
        }
        loadEditorFromFileHTML(webview: editView, aiEditor: aiEditor)
        lazy var pluginRender = EditorPluginRender(webViewDelegate: editView, loader: self)
        editView.configuration.userContentController.add(pluginRender, name: docsJSMessageName)
        editView.pluginRender = pluginRender
        guard let token = delegate?.getCurrentAccountContext().user.token,
              let domain = delegate?.getCurrentAccountContext().user.domain
        else {
            mailAssertionFailure("must have token and domain to init the editor webview");
            return editView
        }

        // Set in cookie into the webview
        var baseURLComponents = domain.split(separator: ".")
        baseURLComponents.removeFirst()
        // Must have a '.' at the start of the domain to enable SSO
        let cookieDomain = "https://.\(baseURLComponents.joined(separator: "."))"
        if let url = URL(string: cookieDomain) {
            let properties = [url.cookiePreperties(value: token, forName: "session"),
                              url.cookiePreperties(value: token, forName: "osession"),
                              url.cookiePreperties(value: token, forName: "bear-session")]
            let cookieStore = editView.configuration.websiteDataStore.httpCookieStore
            for prop in properties {
                cookieStore.setCookie(HTTPCookie(properties: prop)!, completionHandler: nil)
            }
        }
        return editView
    }

    func loadEditorFromFileHTML(webview: WKWebView, aiEditor: Bool = false) {
        guard isCommonEditorBundleExis else {
            mailAssertionFailure("must have commnon bundle !!!!")
            return
        }
        guard let user = user else {
            mailAssertionFailure("User shouldn't be nil !!!!")
            return
        }

        var temUrl: URL?
        if LarkFoundation.Utils.isSimulator, isEditorDebugMode {
            var path = "http://0.0.0.0:9002"
            #if DEBUG
            let kvStore = MailKVStore(space: .global, mSpace: .global)
            let ip = kvStore.value(forKey: MailDebugViewController.kMailEditorIP) ?? ""
            if path.count > 5 {
                path = "http://\(ip)"
            }
            #endif
            temUrl = URL(string: path)
        } else {
            var path = LarkEditorJS.mail.getEditorHtmlPath()
            let oldPath = LarkEditorJS.mail.getEditorHtmlPathOld()
            if !FeatureManager.open(.mobileEditorKit) && AbsPath(oldPath).exists {
                path = oldPath
            }
            temUrl = URL(fileURLWithPath: path)
        }
        guard let url = temUrl else {
            MailLogger.error("mail editor url error")
            return
        }
        var urlstr = url.absoluteString + "?staging=" + "\(MailEnvConfig.isStagingEnv)"
        urlstr.append("&atUserEnable=true")
        urlstr.append("&inline_image=true")
        urlstr.append("&isOversea=\(user.isOverSea ?? false)")
        urlstr.append("&userId=\(user.userID)")
        if aiEditor {
            urlstr.append("&bgTransparent=true")
        }

        MailTracker.startRecordTimeConsuming(event: "mail_editor_preload_time", params: ["is_first_start": isFirstStart ? "true" : "false"])
        isFirstStart = false

        let fullUrl = URL(string: urlstr)!
        MailLogger.debug("editor url: \(fullUrl)")
        if LarkFoundation.Utils.isSimulator, isEditorDebugMode {
            webview.load(URLRequest(url: fullUrl))
        } else {
            webview.loadFileURL(URL(string: urlstr)!, allowingReadAccessTo: URL(fileURLWithPath: CommonJSUtil.getExecuteJSPath()))
        }
    }

    func showCalendarIcon() -> Bool {
        guard FeatureManager.open(.sendMailCalendar) else { return false }
        let status = Store.settingData.getCachedCurrentAccount()?.mailSetting.mailOnboardStatus
        let userType = Store.settingData.getCachedCurrentAccount()?.mailSetting.userType
        let isShare = Store.settingData.getCachedCurrentAccount()?.isShared ?? false
        if userType != .larkServer {
            return false
        }
        let showMx =  (status == .active || status == .softInput)
        return showMx && !isShare
    }

    func genImageDic() -> [[String: Any]] {
        var images: [[String: Any]] = []
        if let sigData = Store.settingData.getCachedCurrentSigData() {
            for sig in sigData.signatures {
                for image in sig.images {
                    if image.fileToken.isEmpty {
                        MailLogger.info("sig image token empty")
                        continue
                    }
                    var temDic: [String: Any] = [:]
                    temDic["name"] = image.imageName
                    temDic["token"] = image.fileToken
                    temDic["cid"] = image.cid
                    temDic["size"] = image.imageSize
                    temDic["isIllegal"] = image.isIllegal
                    temDic["path"] = "cid:" + image.cid
                    images.append(temDic)
                }
            }
        }
        return images
    }
    static func getBffDomain(domain: [InitSettingKey: [String]]) -> [String]? {
        var bffDomain = domain["mail_node_page_v2"]
        if bffDomain == nil {
            bffDomain = domain["mail_node_page"]
        } else if let tem = bffDomain, tem.isEmpty {
            bffDomain = domain["mail_node_page"]
        }
        if bffDomain == nil {
            bffDomain = domain[InitSettingKey.suiteMainDomain]
        } else if let tem = bffDomain, tem.isEmpty {
            bffDomain = domain[InitSettingKey.suiteMainDomain]
        }
        if var bffDomain = bffDomain {
            bffDomain = bffDomain.map({ (str) -> String in
                guard let index = str.firstIndex(of: "(") else { return str }
                return String(str[..<index])
            })
            return bffDomain
        } else {
            return nil
        }
    }
    static func getHomeDomain(domain: [InitSettingKey: [String]]) -> [String]? {
        return domain[InitSettingKey.docsHome]
    }

    func getDomainJavaScriptString(isOOO: Bool,
                                   editable: Bool,
                                   bgTransparent: Bool = false) -> String {
        let domain = ConfigurationManager.shared.settings
        guard var docsApi = domain[InitSettingKey.docsApi], var docsPeer = domain[InitSettingKey.docsPeer] else {
            return ""
        }
        guard var docsLong = domain[InitSettingKey.docsLong] else {
            return ""
        }
        let bffDomain = MailEditorLoader.getBffDomain(domain: domain)
        guard let bffDomain = bffDomain else {
            mailAssertionFailure("bffDomain shouldn't be nil !!!!")
            return ""
        }
        guard let user = user else {
            mailAssertionFailure("User shouldn't be nil !!!!")
            return ""
        }
        docsLong = docsLong.map({ (urlStr) -> String in
            return "wss://\(urlStr)/ws/v2"
        })

        docsApi = docsApi.map({ (str) -> String in
            guard let index = str.firstIndex(of: "(") else { return str }
            return String(str[..<index])
        })
        docsPeer = docsPeer.map({ (str) -> String in
            guard let index = str.firstIndex(of: "(") else { return str }
            return String(str[..<index])
        })
        
        var param = ["common": ["domainPool": docsPeer],
                     "space_api": docsApi,
                     "MailBFFDomain": bffDomain,
                     /// 新 editor kit 接口
                     "domainPool": docsPeer,
                     "spaceApi": docsApi,
                     "urlMapper": ["downloadLark": "http://"],
                     "DocsLongApiDomainList": docsLong,
                     "mailBffDomain": bffDomain.first ?? ""] as [String: Any]
        if let home = MailEditorLoader.getHomeDomain(domain: domain) {
            param["DocsHome"] = home // 旧 editor 接口
            param["docsHomeDomain"] = home.first // 新 editor kit 接口
        }
        var darkMode = false
        if FeatureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)), #available(iOS 13.0, *) {
            darkMode = UDThemeManager.getRealUserInterfaceStyle() == .dark
        }
        let aiNickName = delegate?.getCurrentAccountContext().provider.myAIServiceProvider?.aiNickName ?? delegate?.getCurrentAccountContext().provider.myAIServiceProvider?.aiDefaultName ?? ""
        let aiEnable = delegate?.getCurrentAccountContext().provider.myAIServiceProvider?.isAIEnable ?? false
        let aiFg = FeatureManager.open(FeatureKey(fgKey: .mailAI, openInMailClient: false)) &&
        FeatureManager.open(FeatureKey(fgKey: .larkAI, openInMailClient: false)) && !isOOO && aiEnable
        let smartFg = FeatureManager.open(.mailAISmartReply, openInMailClient: false) && aiFg
        
        let configParam = ["domainConfig": param,
                           "accountId": Store.settingData.getCachedCurrentAccount()?.mailAccountID ?? "",
                           "appName": LanguageManager.bundleDisplayName,
                           "lang": BundleI18n.currentLanguage.languageIdentifier,
                           "isOversea": user.isOverSea ?? false,
                           "fgList": [
                                "largeFile": FeatureManager.open(.largeAttachment),
                                "columnStyleQuote": FeatureManager.open(.quoteStyle),
                                "supportMoreFonts": FeatureManager.open(.moreFonts),
                                "supportCopyBlob": FeatureManager.open(.copyBlob),
                                "adminSignature": !isOOO &&
                                    FeatureManager.realTimeOpen(.enterpriseSignature), // 企业签名
                                "newHtmlBlock": FeatureManager.open(.htmlBlock),
                                "grayHistoryQuote": FeatureManager.open(.grayHistoryQuote),
                                "calendar": !isOOO && showCalendarIcon(),
                                "imageErrorRetry": true,
                                "defaultFontSize": FeatureManager.open(.defaultFontSize),
                                "reuseDom": FeatureManager.open(.editorReuseDom),
                                "cacheDraft": FeatureManager.open(.editorCacheDraft),
                                "longDeleteBackward": FeatureManager.open(.longDeleteBackward),
                                "signaturePartialEditable": FeatureManager.open(.signatureEditable),
                                "mailDisplayName": MailAddressChangeManager.shared.addressNameOpen(),
                                "largeAttachmentManage": FeatureManager.open(.largeAttachmentManage, openInMailClient: false),
                                "listStylePositionOutside": FeatureManager.open(.editorListStylePositionOutside),
                                "newInlineStyle": FeatureManager.open(.editorNewInlineStyleInherit),
                                "docAuthOpt": FeatureManager.open(.docAuthOpt, openInMailClient: false),
                                "aigcEnabled": aiFg,
                                "aiInlineModeReply": smartFg
                           ],
                           "darkMode": darkMode,
                           "fontStyleCode": fontStyleCode,
                           "userAddress": user.getUserSetting()?.emailAlias.defaultAddress.address ?? "",
                           "editable": editable,
                           "aiNickname": aiNickName,
                           "bgTransparent": bgTransparent] as [String: Any]
        guard let data = try? JSONSerialization.data(withJSONObject: configParam, options: []), let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
            mailAssertionFailure("fail to serialize json")
            return ""
        }
        return JSONString as String
    }

    func clear() {
        MailLogger.info("clear webview pool")
        currentCommonEditor?.removeFromSuperview()
        currentNewMailEditor?.removeFromSuperview()
        currentCommonEditor = nil
        currentNewMailEditor = nil
    }
    
    func canPreloadEditor() -> Bool {
        let state = UIApplication.shared.applicationState
        if state == .background {
            MailLogger.info("background")
            return false
        }
        if !MailStateManager.shared.hasEnteredMailPage {
            MailLogger.info("!hasEnteredMailPage")
            return false
        }
        guard let token = user?.token, let domain = user?.domain else {
            MailLogger.info("token and domain is nil")
            return false
        }
        return true
    }

    // 对于signature变化的case，需要重新替换editor
    // 对于切换账号的case，也需要重新替换editor
    func changeNewEditor(type: ChangeEditorType) {
        MailLogger.info("change new editor, type=\(type)")
        clearEditor(type: type)
        if (self.currentNewMailEditor == nil &&
            FeatureManager.open(.preRender)) ||
            self.currentCommonEditor == nil {
            preloadEditor()
        }
    }
    func clearEditor(type: ChangeEditorType) {
        if self.currentNewMailEditor != nil && FeatureManager.open(.preRender) {
            self.currentNewMailEditor?.removeFromSuperview()
            self.currentNewMailEditor = nil
        }
        if self.currentCommonEditor != nil && FeatureManager.open(.preRender) {
            if type == .switchLarkAccount ||
                type == .switchMailAccount ||
                type == .cacheInvalidChange ||
                type == .enterpriseFGChange {
                self.currentCommonEditor?.removeFromSuperview()
                self.currentCommonEditor = nil
            }
        }
    }

    func preloadEditor(reNewOne: Bool = false) {
        MailLogger.info("start preload mail editor, reNewOne=\(reNewOne)")
        let canPreload = canPreloadEditor() || reNewOne
        guard canPreload else {
            return
        }
        guard LarkEditorJS.shared.isResourceReady() else {
            mailAssertionFailure("must not preload before the resource is ready")
            return
        }
        
        let width = UIScreen.main.bounds.size.width
        if currentCommonEditor == nil {
            let editorView = createEditor()
            editorView.frame = CGRect(x: -width, y: 0, width: width, height: 1)
            businessWindow?.addSubview(editorView)
            currentCommonEditor = editorView
            MailLogger.info("window is nil: \(businessWindow == nil)")
        }
        if currentNewMailEditor == nil && FeatureManager.open(.preRender) {
            let editorView = createEditor()
            editorView.canPreRender = true
            editorView.frame = CGRect(x: -width, y: 0, width: width, height: 1)
            businessWindow?.addSubview(editorView)
            currentNewMailEditor = editorView
            MailLogger.info("window is nil: \(businessWindow == nil)")
        }
    }

    func delayReset() {
        MailLogger.log(level: .info, message: "editor pool reset")
        clear()
        // delay a little bit in case 'reset' run into endless loop and occupy too much cpu resource
        guard failRetryCount < 3 else {
            failRetryCount = 0
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.short) {
            self.preloadEditor()
        }
    }
    func preGetDraft(editor: MailSendWebView) {
        //set old signature
        if !FeatureManager.realTimeOpen(.enterpriseSignature) {
            editor.oldSignature = Store.settingData.getCachedCurrentSetting()?.signature
        }
        // get draft
        MailSendDataMananger.shared.createDraft(with: "",
                                            threadID: "",
                                            msgTimestamp: nil,
                                            action: .compose,
                                            languageId: BundleI18n.currentLanguage.languageIdentifier)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (resp) in
            self.preRender(editor: editor, draft: MailDraft(with: resp.draft), isNewDraft: resp.isNew)
        }, onError: { (error) in
            MailLogger.info("pre get draft error \(error)")
        }).disposed(by: disposeBag)
    }
    func preRender(editor: MailSendWebView, draft: MailDraft, isNewDraft: Bool) {
        MailLogger.info("preRender begin")
        editor.isNewDraft = isNewDraft
        editor.draft = draft
        // 业务统计
        MailTracker.log(event: Homeric.EMAIL_EDIT, params: ["type": "compose", "draftid": draft.id])
        let content = draft.content
        var bodyHtml = content.bodyHtml
        if FeatureManager.open(FeatureKey(fgKey: .draftContentHTMLDecode, openInMailClient: true)) {
            bodyHtml = content.bodyHtml.components(separatedBy: .controlCharacters).joined()
        }
        draft.toPBModel().images.forEach { (image) in
            let value = ["imageName": image.imageName, "fileToken": image.fileToken]
            delegate?.getCurrentAccountContext().cacheService.set(object: value as NSCoding, for: image.cid)
        }
        let start = MailTracker.getCurrentTime()
        var renderInfo = bodyHtml
        var isOOO = false
        editor.pluginRender?.originRenderInfo = bodyHtml
        
        let reportParam = ["is_frist": "1", "length": renderInfo.count] as [String: Any]
        MailTracker.startRecordTimeConsuming(event: Homeric.MAIL_DEV_SEND_RENDER_COST_TIME,
                                             params: reportParam)
        
        
        guard let renderStr = renderInfo.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { mailAssertionFailure("fail to encode"); return }
        renderInfo = renderStr
        
        // 如果html为空，需要补充<br/>兜底，否则editor无法渲染签名
        if renderInfo.isEmpty {
            renderInfo = "<br/>"
        }
        var images = draft.content.images.map { $0.toJSONDic() }
        if FeatureManager.realTimeOpen(.enterpriseSignature) {
            let array = genImageDic()
            if !array.isEmpty {
                images.append(contentsOf: array)
            }
        }
        
        var renderParam = ["html": renderInfo,
                           "images": images,
                           "docLinks": draft.content.docsJsonConfigs,
                           "attachments": draft.content.attachments.map { $0.jsonDic },
                           "isEditedDraft": false] as [String: Any]
        if FeatureManager.realTimeOpen(.enterpriseSignature) {
            if let sigData = Store.settingData.getCachedCurrentSigData(),
               let dic =  editor.genSignatureDicByAddres(sigData: sigData,
                                                         draft: draft,
                                                         action: .new,
                                                         address: nil) {
                renderParam["signatures"] = dic
            } else {
                var dic: [String: Any] = [:]
                dic["list"] = []
                renderParam["signatures"] = dic
            }
        }
        guard let data = try? JSONSerialization.data(withJSONObject: renderParam, options: []),
              let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { mailAssertionFailure("fail to serialize json")
            return
        }
        
        let config = getDomainJavaScriptString(isOOO: isOOO, editable: true)
        let script = "window.command.render(\(JSONString), \(config))"
        //MailLogger.debug("render script: \(script)")
        editor.renderCallTime = MailTracker.getCurrentTime()
        editor.evaluateJavaScript(script, completionHandler: { (_, error) in
            MailTracker.endRecordTimeConsuming(event: Homeric.MAIL_DEV_SEND_RENDER_COST_TIME, params: reportParam)
            if let error = error {
                MailLogger.info("preRender error = \(error)")
            } else {
                editor.renderJSCallBackSuccess = true
                MailLogger.log(level: .info, message: "render successed")
            }
        })
    }
}

extension MailEditorLoader: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let body = message.body as? String {
            MailLogger.log(level: .info, message: body)
            if body.contains("js error") && body.contains("Unexpected") {
                MailTracker.log(event: "mail_editor_js_err_dev",
                                params: ["error_type": "UnexpectedEnd",
                                         "sence": "occur"])
                if forceUnziped == false {
                    forceUnziped = true
                    DispatchQueue.global().async {
                        CommonJSUtil.unzipIfNeeded(forceUnzip: true)
                    }
                } else {
                   // 无效
                    MailTracker.log(event: "mail_editor_js_err_dev",
                                    params: ["error_type": "UnexpectedEnd",
                                             "sence": "not_recovered"])
                }
            }
        }
    }
}

extension MailEditorLoader: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        MailLogger.info("editorloader did start provision webview=\(String(format: "%p", webView))")
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let webview = webView as? MailSendWebView else {
            mailAssertionFailure("must be MailNewWebView")
            return
        }
        MailLogger.info("WKWebView, didFinish navigationm webview=\(String(format: "%p", webView))")
        let isBackground = webview.sendVCJSHandlerInited ? false : true
        webview.isReady = true
        if isBackground &&
            webview.canPreRender &&
            FeatureManager.open(.preRender) {
            MailTracker.endRecordTimeConsuming(event: "mail_editor_preload_time", params: nil)
            self.preGetDraft(editor: webview)
        } else {
            webview.cleanEditorReloadTimer()
            MailTracker.endRecordTimeConsuming(event: "mail_editor_vc_load_time", params: nil)
            guard let content = webview.draft?.content else { return }
            webview.pluginRender?.render(mailContent: content, needBlockWebImages: false)
        }
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        guard let webview = webView as? MailSendWebView else {
            mailAssertionFailure("must be MailNewWebView")
            decisionHandler(.allow)
            return
        }

        if url.absoluteString.hasPrefix("http://") || url.absoluteString.hasPrefix("https://") {
            if LarkFoundation.Utils.isSimulator, isEditorDebugMode {
                decisionHandler(.allow)
            } else {
                webview.gotoOtherPage(url: url)
                decisionHandler(.cancel)
            }
        } else if url.absoluteString.hasPrefix("mailto:"),
                  let delegate = delegate,
                  let vc = MailSendController.checkMailTab_makeSendNavController(accountContext: delegate.getCurrentAccountContext(),
                                                                                 action: .fromAddress,
                                                                                 labelId: Mail_LabelId_Inbox,
                                                                                 statInfo: MailSendStatInfo(from: .sendSig, newCoreEventLabelItem: "none"),
                                                                                 trackerSourceType: .mailTo,
                                                                                 sendToAddress: url.absoluteString) {
            webview.presentPage(vc: vc)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard let webview = webView as? MailSendWebView else {
            mailAssertionFailure("must be MailNewWebView")
            return
        }
        mailAssertionFailure("didFail:", error: error)
        let isBackground = webview.sendVCJSHandlerInited ? false : true
        MailTracker.log(event: "mail_editor_render_fail",
                        params: ["error": error.localizedDescription,
                                 "actionType": "fail",
                                 "isBackground" : isBackground,
                                 "url": webView.url?.absoluteString.toBase64() ?? "empty"])
        if isBackground {
            delayReset()
        } else {
            webView.reload()
        }
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard let webview = webView as? MailSendWebView else {
            mailAssertionFailure("must be MailNewWebView")
            return
        }
        mailAssertionFailure("didFailProvisionalNavigation:", error: error)
        let isBackground = webview.sendVCJSHandlerInited ? false : true
        MailTracker.log(event: "mail_editor_render_fail",
                        params: [
                            "error": error.localizedDescription,
                            "actionType": "provisional",
                            "url": webView.url?.absoluteString ?? "empty",
                            "error_code": (error as NSError).code,
                            "retryCount": failRetryCount,
                            "isBackground" : isBackground])
        if isBackground {
            delayReset()
            failRetryCount += 1
        } else {
            webView.reload()
        }
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        let state = UIApplication.shared.applicationState
        let appInbackground = state == .background ? "true" : "false"
        MailLogger.log(level: .info, message: "webViewWebContentProcessDidTerminate in mail pool")
        MailTracker.log(event: "mail_webcontent_process_terminate",
                        params: ["isBackground": "true",
                                 "current": UIViewController.mail.topMost?.tkClassName ?? "nil",
                                 "appInBackground": appInbackground])

        guard let webview = webView as? MailSendWebView else {
            mailAssertionFailure("must be MailNewWebView")
            return
        }
        MailLogger.log(level: .info, message: "webViewWebContentProcessDidTerminate in mail pool")
        let isBackground = webview.sendVCJSHandlerInited ? false : true
        MailTracker.log(event: "mail_webcontent_process_terminate", params: ["isBackground": isBackground, "current": UIViewController.mail.topMost?.tkClassName ?? "nil"])
        if canPreloadEditor() || webview.sendVCJSHandlerInited {
            webview.isReady = false
            webView.reload()
        } else {
            clear()
        }
    }
}
