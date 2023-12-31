//
//  DocComponentAPIImpl.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/5/18.
//  


import SKFoundation
import SpaceInterface
import SKCommon
import LarkWebViewContainer

class DocComponentAPIImpl {
    
    let url: URL
    let config: DocComponentConfig
    var containerHost: DocComponentContainerHost? {
        didSet {
            if let host = containerHost {
                setupHost(host)
                if let contentHost = host.contentHost {
                    setupHost(contentHost)
                }
            }
        }
    }
    private var _status: DocComponentStatus = .start
    weak var delegate: DocComponentAPIDelegate?
    
    init(url: URL,
         config: DocComponentConfig) {
        self.url = url
        self.config = config
    }
    
    deinit {
        DocsLogger.info("DocComponentAPIImpl deinit", component: LogComponents.docComponent)
    }
    
    private func setupHost(_ host: DocComponentHost) {
        host.onSetup(hostDelegate: self)
    }
}

extension DocComponentAPIImpl: DocComponentAPI {
    var status: DocComponentStatus {
        _status
    }
    
    var docVC: UIViewController {
        guard let vc = containerHost else {
            spaceAssertionFailure()
            return UIViewController()
        }
        return vc
    }
    
    func setDelegate(_ delegate: DocComponentAPIDelegate) {
        self.delegate = delegate
    }

    func invoke(command: String,
                payload: [String: Any]?,
                callback: DocComponentInvokeCallBack?) {
        spaceAssert(callback == nil, "callback is not support now")
        
        var data = [String: Any]()
        data["module"] = self.config.module
        data["command"] = command
        data["payload"] = payload
        DocsLogger.info("invokeToWeb: \(self.config.module).\(command)", component: LogComponents.docComponent)
        containerHost?.invokeDCCommand(function: DocsJSCallBack.invokeWebForDC.rawValue, params: data)
    }
    
    func updateSettingConfig(_ settingConfig: [String: Any]) {
        DocsLogger.info("updateSettingConfig: \(settingConfig)", component: LogComponents.docComponent)
        containerHost?.invokeDCCommand(function: DocsJSCallBack.configChangeForDC.rawValue, params: settingConfig)
    }
}

extension DocComponentAPIImpl: DocComponentHostDelegate {

    
    func docComponentHost(_ host: DocComponentHost?, onOperation opeartion: DocComponentOperation) -> Bool {
        let intercept = self.delegate?.docComponent(self, onOperation: opeartion) ?? false
        DocsLogger.info("onOperation:\(opeartion), intercept：\(intercept)", component: LogComponents.docComponent)
        return intercept
    }
    
    func docComponentHost(_ host: DocComponentHost?,
                          onReceiveWebInvoke params: [String: Any],
                          callback: APICallbackProtocol?) {
        guard let module = params["module"],
        let command = params["command"] else {
            spaceAssertionFailure("must have module & command")
            return
        }
        DocsLogger.info("receive web invoke:\(module).\(command)", component: LogComponents.docComponent)
        self.delegate?.docComponent(self, onInvoke: params, callback: { data, error in
            if let error = error {
                DocsLogger.error("receive biz native callback error", error: error, component: LogComponents.docComponent)
                callback?.callbackFailure(param: data)
            } else {
                callback?.callbackSuccess(param: data)
            }
        })
    }
    
    func docComponentHost(_ host: DocComponentHost?, onEvent event: DocComponentEvent) {
        DocsLogger.info("onEvent:\(event)", component: LogComponents.docComponent)
        self.delegate?.docComponent(self, onEvent: event)
    }
    
    func docComponentHost(_ host: DocComponentHost?, onMoveToWiki wikiUrl: String, originUrl: String) {
        DocsLogger.info("onMoveToWiki", component: LogComponents.docComponent)
        guard let newUrl = URL(string: wikiUrl) else {
            return
        }
        let docsUrl = DocComponentSDKImpl.shared.fixDocComponentURL(newUrl)
        guard let componentHost = DocComponentSDKImpl.shared.createDocComponentHost(docsUrl) else {
            return
        }
        setupHost(componentHost)
        self.containerHost?.changeContentHost(componentHost)
    }
    
    func docComponentHostLoaded(_ host: DocComponentHost?) {
        DocsLogger.info("docComponentHostLoaded, host: \(String(describing: type(of: host)))", component: LogComponents.docComponent)
    }
    
    func docComponentHostWillClose(_ host: DocComponentHost?) {
        DocsLogger.info("docComponentHostWillClose, host: \(String(describing: type(of: host)))", component: LogComponents.docComponent)
        if host is DocComponentContainerHost {
            self.delegate?.docComponent(self, onEvent: .willClose)
        }
    }
}

extension DocComponentAPIImpl: BrowserViewLifeCycleEvent {
    
    func browserLoadStatusChange(_ status: LoadStatus) {
        switch status {
        case .loading:
            _status = .loading
        case .success:
            _status = .success
        case .unknown:
            _status = .fail(error: NSError(domain: "unknown", code: DocComponentStatusErrorCode.unknown.rawValue, userInfo: nil))
        case .cancel:
            _status = .fail(error: NSError(domain: "cancel", code: DocComponentStatusErrorCode.cancel.rawValue, userInfo: nil))
        case .overtime:
            _status = .fail(error: NSError(domain: "timeout", code: DocComponentStatusErrorCode.timeout.rawValue, userInfo: nil))
        case .fail(let error):
            _status = .fail(error: error)
        }
        self.delegate?.docComponent(self, onEvent: .statusChange(status: _status))
    }
}


enum DocComponentStatusErrorCode: Int {
    case timeout = -1
    case cancel = -2
    case unknown = -3
}
