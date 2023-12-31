// 
// Created by duanxiaochen.7 on 2020/7/1.
// Affiliated with SKCommon.
// 
// Description:

import UIKit
import HandyJSON
import SKCommon
import SKFoundation
import LarkWebViewContainer

protocol InsertBlockPluginDelegate: AnyObject {
    var viewDistanceToWindowBottom: CGFloat { get }

    func presentInsertBlockViewController(_: UIViewController)
    func dismissInsertBlockViewController(completion: (() -> Void)?)
    func setAtFinderServiceDelayHandleOnce()
    func noticeWebview(param: [String: Any], callback: DocsJSCallBack, nativeCallback: APICallbackProtocol?)
    func resignFirstResponder()
    ///设置+面板以popover方式弹出时是否屏蔽webview上的点击事件
    func setShouldInterceptEvents(to enable: Bool)
}

extension DocsJSService {
    static let insertBlockJsName = DocsJSService("biz.navigation.setInsertNewBlockPanel")
}

/// PRD: https://bytedance.feishu.cn/docs/doccnE4C0tKAjq52yDsKWkDAXrg
/// 技术文档: https://bytedance.feishu.cn/docs/doccnS9m3t70fqd5QWntIAprpBg#
public final class InsertBlockPlugin: JSServiceHandler {
    weak var delegate: InsertBlockPluginDelegate?
    private(set) var callback: String = ""
    private(set) var nativeCallback: APICallbackProtocol?
    public var handleServices: [DocsJSService] {
        return [.insertBlockJsName]
    }
    public func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol? = nil) {
        if serviceName == DocsJSService.insertBlockJsName.rawValue {
            nativeCallback = callback
            handle(params: params, serviceName: serviceName)
        }
    }

    public func handle(params: [String: Any], serviceName: String) {
        if serviceName == DocsJSService.insertBlockJsName.rawValue {
            handleInsertBlock(params)
        }
    }

    public func canHandle(_ serviceName: String) -> Bool {
        return handleServices.contains { return $0.rawValue == serviceName }
    }

    private func handleInsertBlock(_ params: [String: Any]) {
        guard let model = InsertBlockDataModel.deserialize(from: params) else {
            DocsLogger.error("frontend delivered incorrent params for inserting block", extraInfo: params, component: LogComponents.toolbar)
            return
        }

        let vc = InsertBlockViewController(model: model)
        vc.delegate = self
        vc.viewDistanceToWindowBottom = delegate?.viewDistanceToWindowBottom ?? 0
        callback = model.callback
        delegate?.presentInsertBlockViewController(vc)
        if !vc.isMyWindowCompactSize() {
            //非紧凑视图下，+面板会以popover方式弹出，此时拦截webview上的点击事件
            delegate?.setShouldInterceptEvents(to: true)
        }
    }
}

extension InsertBlockPlugin: InsertBlockDelegate {
    func didSelectBlock(id: String) {
        if id.hasPrefix("mention") { // 如果点击了 at 人、at 群或 at 文件
            delegate?.setAtFinderServiceDelayHandleOnce()
        } else if id == "insertFile" {
            delegate?.resignFirstResponder()
        }
        //注意，+面板关闭时一定需要调用以下方法解除webview上的事件屏蔽
        delegate?.setShouldInterceptEvents(to: false)
        delegate?.dismissInsertBlockViewController(completion: { [weak self] in
            guard let `self` = self else { return }
            self.delegate?.noticeWebview(param: ["id": id], callback: DocsJSCallBack(self.callback), nativeCallback: self.nativeCallback)
        })
    }

    func noticeWebScrollUpHeight(id: String, height: CGFloat) {
        delegate?.noticeWebview(param: ["id": id, "value": height], callback: DocsJSCallBack(callback), nativeCallback: nativeCallback)
    }
}
