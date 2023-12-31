//
//  OpenPluginCommentComponent.swift
//  OPPlugin
//
//  Created by laisanpin on 2021/7/14.
//  评论组件API

import Foundation
import LarkOpenAPIModel
import LarkOpenPluginManager
import ECOProbe
import OPPluginManagerAdapter
import TTMicroApp
import LarkContainer

final class OpenPluginCommentComponent: OpenBasePlugin {

    private var menuManger: OpenPluginMenuManager?

    /// 显示UIMenuController
    func showPopoverMenu(params: OpenPluginShowMenuPopoverParams, context: OpenAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let controller = (context.gadgetContext)?.controller else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("host controller is nil, has gadgetContext? \(context.gadgetContext != nil)")
            callback(.failure(error: error))
            return
        }

        // 这边评论组件是针对小程序开发, 这边对BDPAppPageController进行了拓展;
        guard let container = controller as? OpenPluginMenuProtocol else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError).setMonitorMessage("UIMenuController target container did not confirm OpenPluginMenuProtocol")
            callback(.failure(error: error))
            return
        }

        let manager = getMenuManger(trace: context.apiTrace, view: controller.view, responder: container)
        var menuItems = [UIMenuItem]()

        params.items.forEach {itemInfo in
            guard let id = itemInfo["id"] as? String else { return }
            guard let title = itemInfo["text"] as? String else { return }

            let item = manager.makeMenuItem(id: id, title: title) {
                context.apiTrace.info("PopoverMenu click button:\(id)")
                let dic = ["id" : id,
                           "tag": params.tag]
                do {
                    let fireEvent = try OpenAPIFireEventParams(event: "popoverMenuSelected",
                                                               sourceID: NSNotFound,
                                                               data: dic,
                                                               preCheckType: .none,
                                                               sceneType: .normal)
                    let _ = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context)
                } catch {
                    context.apiTrace.error("syncCall fireEvent popoverMenuSelected error:\(error)")
                }
            }

            guard let menuItem = item else {
                context.apiTrace.error("config menuItem failed")
                return
            }

            menuItems.append(menuItem)
        }

        manager.menuStateChangeCallback = {(state) in
            switch state {
            case .didHide:
                context.apiTrace.info("PopoverMenu didHide tag:\(params.tag)")
                let dic = ["tag": params.tag]
                do {
                    let fireEvent = try OpenAPIFireEventParams(event: "popoverMenuDismiss",
                                                               sourceID: NSNotFound,
                                                               data: dic,
                                                               preCheckType: .none,
                                                               sceneType: .normal)
                    let _ = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context)
                } catch {
                    context.apiTrace.error("syncCall fireEvent popoverMenuDismiss error:\(error)")
                }
            default:
                //其他状态暂时不需要处理
                break
            }
        }

        let result = manager.showMenu(in: params.frame, items: menuItems, offsetTop: params.offsetTop, offsetBottom: params.offsetBottom)

        guard result else {
            let error = OpenAPIError(code:OpenAPICommonErrorCode.internalError).setMonitorMessage("OpenPluginMenuManager show menu failed")
            callback(.failure(error: error))
            return
        }

        callback(.success(data: nil))
    }

    func hidePopoverMenu(params: OpenAPIBaseParams, context: OpenAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {

        // 调用隐藏Menu时需要之前调用过showPopoverMenu
        guard let manager = menuManger else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError).setMonitorMessage("OpenPluginMenuManager not exsit")
            callback(.failure(error: error))
            return
        }

        let result = manager.hideMenu()

        guard result else {
            let error = OpenAPIError(code:OpenAPICommonErrorCode.internalError).setMonitorMessage("OpenPluginMenuManager hide menu failed")
            callback(.failure(error: error))
            return
        }

        callback(.success(data: nil))
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "showPopoverMenu", pluginType: Self.self, paramsType: OpenPluginShowMenuPopoverParams.self) { (this, params, context, callback) in
            
            this.showPopoverMenu(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandler(for: "hidePopoverMenu", pluginType: Self.self, paramsType: OpenAPIBaseParams.self) { (this, params, context, callback) in
            
            this.hidePopoverMenu(params: params, context: context, callback: callback)
        }
    }

}

extension OpenPluginCommentComponent {
    private func getMenuManger(trace: OPTrace, view: UIView, responder: OpenPluginMenuProtocol) -> OpenPluginMenuManager {
        let config = OpenPluginMenuMangerConfig(targetView: view, container: responder)

        let manager = OpenPluginMenuManager(config, trace)
        menuManger = manager

        return manager
    }
}


extension BDPAppPageController: OpenPluginMenuProtocol {
    public func opMenuItem(uid: String, title: String, action: @escaping () -> Void) -> UIMenuItem {
        let targetClasses = [type(of: self)]
        let aSelector = createSelector(uid: uid, classes: targetClasses, block: action)
        
        return UIMenuItem(title: title, action: aSelector)
    }

    public override var canBecomeFirstResponder: Bool {
        return true
    }

    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return actionHelper.contains(action)
    }
}

extension BDPAppPageController {
    private static var _kActionHelperKey: UInt8 = 1

    public var actionHelper: [Selector] {
        get {
            guard let helper = objc_getAssociatedObject(self, &BDPAppPageController._kActionHelperKey) as? [Selector] else {
                let obj = [Selector]()
                self.actionHelper = obj
                return obj
            }
            return helper
        }
        set {
            objc_setAssociatedObject(self, &BDPAppPageController._kActionHelperKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}


