//
//  GetBrowserVCLayoutInfoService.swift
//  SKBrowser
//
//  Created by chenhuaguan on 2021/3/23.
//

import SKCommon
import SKFoundation
import SKUIKit
import RxSwift
import SKInfra

// https://bytedance.feishu.cn/wiki/wikcnB7SZcoUcKKopcyLFSH4QVh#
class GetBrowserVCLayoutInfoService: BaseJSService {
    private var callback: String?
    private var disposeBag = DisposeBag()


    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
}

extension GetBrowserVCLayoutInfoService: BrowserViewLifeCycleEvent {
    public func browserDidTransition(from: CGSize, to: CGSize) {
        callBackLayoutInfo()
    }
    func browserDidSplitModeChange() {
        callBackLayoutInfo()
    }
}

extension GetBrowserVCLayoutInfoService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.getIpadLayoutInfo, .getIPadInitialStatus]
    }

    public func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.getIpadLayoutInfo.rawValue:
            handleGetIpadLayoutInfoAction(params: params)
        case DocsJSService.getIPadInitialStatus.rawValue:
            handleGetIPadInitialStatusAction(params: params)
        default:
            return
        }

    }

    private func handleGetIpadLayoutInfoAction(params: [String: Any]) {
        DocsLogger.info("GetBrowserVCLayoutInfoService handle=getIpadLayoutInfo")
        if let callback = params["callback"] as? String {
            self.callback = callback
            callBackLayoutInfo()
        }
    }

    private func handleGetIPadInitialStatusAction(params: [String: Any]) {
        guard SKDisplay.pad else { // iPad场景下才有意义
            return
        }
        DocsLogger.info("GetBrowserVCLayoutInfoService handle=getIPadInitialStatus")
        if let callback = params["callback"] as? String, let catalogIsOpen = ui?.displayConfig.obtianIPadCatalogState() {
            var params: [String: Any] = [:]
            if let mode = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.widescreenModeLastSelected), !mode.isEmpty {
                params["widthMode"] = mode
            } else {
                params["widthMode"] = WidescreenMode.fullwidth.rawValue //默认值为true
            }
            params["isCatalogOpen"] = catalogIsOpen
            model?.jsEngine.callFunction(DocsJSCallBack(callback), params: params, completion: nil)
        }
    }
}

extension GetBrowserVCLayoutInfoService {
    func callBackLayoutInfo() {
        if let browserVC = registeredVC {
            let params = ["width": browserVC.view.frame.size.width,
                          "height": browserVC.view.frame.size.height
            ]
            DocsLogger.info("GetBrowserVCLayoutInfoService callback=\(callback != nil), params=\(params)")
            if let callback = callback {
                self.model?.jsEngine.callFunction(
                    DocsJSCallBack(callback),
                    params: params,
                    completion: nil
                )
            }
        }
    }
}
