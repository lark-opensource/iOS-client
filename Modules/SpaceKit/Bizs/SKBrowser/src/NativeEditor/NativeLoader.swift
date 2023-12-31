//
//  NativeLoader.swift
//  SKBrowser
//
//  Created by chenhuaguan on 2021/7/8.
//

import SKFoundation
import SKUIKit
import SKCommon
import ThreadSafeDataStructure
import SKEditor

protocol NativeLoaderDelegate: SKExecJSFuncService {
    func requestShowLoadingFor(_ url: URL)
    func didUpdateLoadStatus(_ status: NativeLoaderStatus)
    func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?)
    var editorIdentity: String { get }
}

final public class NativeLoader: NSObject, DocsLoader {
    weak var delegate: NativeLoaderDelegate?
    private var clientInfos = SafeDictionary<String, String>()
    public var naviHeight: CGFloat = 0

    private(set) public var docsInfo: DocsInfo?
    public var currentUrl: URL?
    public var openSessionID: String?
    private var hadRequestShowLoading: Bool = false
    private(set) var editorView: NativeEditorView?
    private(set) var resolver: DocsResolver
    lazy private var newCache: NewCacheAPI = resolver.resolve(NewCacheAPI.self)!
    public var loadStatus: NativeLoaderStatus = .unknown {
        didSet {
            DocsLogger.info("\(delegate?.editorIdentity ?? "") loadStatus become \(loadStatus)", component: LogComponents.fileOpen + LogComponents.nativeEditor)
            delegate?.didUpdateLoadStatus(loadStatus)
        }
    }
    
    public init(editorView: NativeEditorView?,
                resolver: DocsResolver = DocsContainer.shared) {
        self.editorView = editorView
        self.resolver = resolver
    }

    public func load(url: URL) {
        DocsLogger.info("Docsloader load url", component: LogComponents.nativeEditor)
        resetDocsInfo(url)
        DispatchQueue.main.async {
            self.cancleDeferringOvertimeTip()
            self.loadStatus = .loading
            self.delayShowOvertimeTip()
            self.editorView?.load("testToken")
        }
    }

    public func resetDocsInfo(_ url: URL) {
        if let type = DocsType(url: url),
            let token = DocsUrlUtil.getFileToken(from: url, with: type), token.isEmpty == false {
            let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
            let spaceEntry = dataCenterAPI?.spaceEntry(objToken: token)
            self.docsInfo = spaceEntry?.transform() ?? DocsInfo(type: type, objToken: token)
            if type == .wiki {
                if let wikiInfo = resolver.resolve(SKBrowserDependency.self)!.getWikiInfo(by: token) {
                    self.docsInfo?.wikiInfo = wikiInfo
                } else {
                    spaceAssertionFailure("nativeEditor, wiki no realtype @peipei")
                }
            }
            if let from = url.docs.queryParams?["from"], from == DocsVCFollowFactory.fromKey {
                self.docsInfo?.isInVideoConference = true
            }
        } else {
            DocsLogger.info("\(self.delegate?.editorIdentity ?? "") can not get docInfo from url", component: LogComponents.fileOpen + LogComponents.nativeEditor)
            self.docsInfo = nil
        }
    }

    public func updateClientInfo(_ newInfos: [String: String]) {
        newInfos.forEach { (key, value) in
            clientInfos[key] = value
        }
    }

    public func removeContentIfNeed() {
    }

    public func setNavibarHeight(naviHeight: CGFloat) {
        self.naviHeight = naviHeight
    }

    public func delayShowLoading() {
        if hadRequestShowLoading {
            return
        }
        hadRequestShowLoading = true
        let delay = loadingDelayInSecond
        self.perform(#selector(type(of: self).showLoading), with: nil, afterDelay: delay)
    }

    @objc
    func showLoading() {
        spaceAssert(Thread.isMainThread)

        guard isLoading else {
            DocsLogger.info("\(delegate?.editorIdentity ?? "") no need show loading isLoading:\(isLoading)", component: LogComponents.fileOpen)
            return
        }
        currentUrl.map {
            DocsLogger.info("\(delegate?.editorIdentity ?? "") requestShowlarkLoadingFor", component: LogComponents.fileOpen + LogComponents.nativeEditor)
            delegate?.requestShowLoadingFor($0)
        }
    }

    var loadingDelayInSecond: Double {
        return OpenAPI.browserLoadingDelayInSeconds
    }

    private var isLoading: Bool {
        return loadStatus.isLoading
    }

    public func browserWillClear() {
        hadRequestShowLoading = false
        removeContentIfNeed()
        clientInfos["feedID"] = nil
        cancleDeferringOvertimeTip()
    }

    public func reloadWhenFail() {
        if let url = currentUrl {
            DocsLogger.info("reload url", extraInfo: ["browserView": "\(delegate?.editorIdentity ?? "")"], error: nil, component: LogComponents.nativeEditor)
            //每次reloadURL，是一次新的打开过程
            openSessionID = OpenFileRecord.generateNewOpenSession()
            load(url: url)
        } else {
            DocsLogger.error("can not reload url", extraInfo: ["browserView": "\(delegate?.editorIdentity ?? "")"], error: nil, component: LogComponents.nativeEditor)
        }
    }

    public func browserDidGetWikiInfo(error: Error?) {

    }
}

extension NativeLoader: EditorConfigDelegate {
    public var editorRequestHeaders: [String: String] {
        var userAgent = UserAgent.defaultNativeApiUA
        let language = (Locale.preferredLanguages.first ?? Locale.current.identifier).hasPrefix("zh") ? "zh" : "en"
        userAgent +=  " [\(language)] Bytedance"
        userAgent += " \("DocsSDK")/\(SpaceKit.version)"
        clientInfos.forEach({ (key, value) in
            userAgent += " \(key)/\(value)"
        })
        var dict = requestHeader
        dict["User-Agent"] = userAgent
        return dict
    }

    public var netRequestHeaders: [String: String] {
        var dict = requestHeader
        dict["User-Agent"] = UserAgent.defaultNativeApiUA
        return dict
    }

    private var requestHeader: [String: String] {
        return SpaceHttpHeaders()
            .addLanguage()
            .addCookieString()
            .merge(clientInfos.getImmutableCopy())
            .merge(SpaceHttpHeaders.common)
            .dictValue
    }
}

extension NativeLoader {

    func delayShowOvertimeTip() {
        let openDocTimeout = (DocsNetStateMonitor.shared.accessType == .wifi) ? OpenAPI.docs.wifiOpenDocTimeout : OpenAPI.docs.noWifiOpenDocTimeout
        self.perform(#selector(type(of: self).becomeOverTime), with: nil, afterDelay: openDocTimeout)
    }

    public func resetShowOverTimeTip() {
        //进入后台时修改超时逻辑
        switch loadStatus {
        case .loading:
            guard  OpenAPI.docs.backGroundOpenDocTimeout > 0 else { return }
            DocsLogger.info("resetShowOverTimeTip loading")
            cancleDeferringOvertimeTip()
            self.perform(#selector(type(of: self).becomeOverTime), with: nil, afterDelay: OpenAPI.docs.backGroundOpenDocTimeout)
        default:
            DocsLogger.info("resetShowOverTimeTip defaultValue")
        }
    }

    private func cancleDeferringOvertimeTip() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(becomeOverTime), object: nil)
    }

    @objc
    func becomeOverTime() {
        loadStatus = .overtime
    }
}

extension NativeLoader: BrowserLoadingReporter {
    public func didHideLoading() {
        DocsLogger.info("didHideLoading, isLoading=\(isLoading)", component: LogComponents.nativeEditor)
        if isLoading {
            self.loadStatus = .success
        }
        cancleDeferringOvertimeTip()
    }

    public func failWithError(_ error: Error?) {
        DocsLogger.info("\(delegate?.editorIdentity ?? "") , error)", component: LogComponents.nativeEditor)
        loadStatus = .fail(error: error)
    }
}
