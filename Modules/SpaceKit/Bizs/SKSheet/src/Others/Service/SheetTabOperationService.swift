//
// Created by duanxiaochen.7 on 2020/07/23.
// Affiliated with SKBrowser.
//
// Description: Sheet 工作表栏 —— 新增、编辑工作表的 JS Bridge
//

import SKCommon
import SKBrowser
import HandyJSON
import SKFoundation
import UniverseDesignColor
import UniverseDesignIcon

class SheetTabOperationService: BaseJSService, DocsJSServiceHandler {
    var callback = ""
    weak var operationVC: SheetTabOperationViewController?

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }

    var handleServices: [DocsJSService] {
        return [.sheetTabOperation]
    }

    func handle(params: [String: Any], serviceName: String) {
        guard let json = SheetTabOperationParams.deserialize(from: params) else {
            DocsLogger.error("\(serviceName) 前端传过来的参数格式不对", extraInfo: params, component: LogComponents.sheetTab)
            operationVC?.dismiss(animated: true, completion: nil)
            operationVC = nil
            return
        }

        if json.items.isEmpty {
            operationVC?.dismiss(animated: true, completion: nil)
            operationVC = nil
            return
        }

        if let operationVC = operationVC { // 用户手速很快+机器性能差=前端可能在短时间内多次调用该接口->需要清理
            operationVC.dismiss(animated: false, completion: nil)
            self.operationVC = nil
        }

        callback = json.callback
        if navigator?.preferredModalPresentationStyle == .popover, let tabSwitcher = tabSwitcher {
            
            func setupNewVC(newVC: SheetTabOperationViewController, tabSwitcher: SheetTabSwitcherView) {
                newVC.modalPresentationStyle = .popover
                newVC.popoverPresentationController?.backgroundColor = UDColor.bgFloat
                newVC.popoverPresentationController?.sourceView = tabSwitcher
                newVC.popoverPresentationController?.permittedArrowDirections = .up
                newVC.popoverPresentationController?.popoverLayoutMargins.left = tabSwitcher.convert(tabSwitcher.bounds, to: nil).minX + 4
                newVC.popoverPresentationController?.popoverLayoutMargins.right = 4
            }
            
            
            if let source = json.source {
                // 由于目标 view 可能并不是完全露在外面的，所以需要等到 collection view 将其完全展示出来，再拿到它的 rect，进行 present
                tabSwitcher.getSubviewRect(source: source)
                    .subscribe(onNext: { [weak self, weak navigator] (rect) in
                        guard let self = self else {
                            DocsLogger.warning("SheetTabOperationService relesed", component: LogComponents.sheetTab)
                            return
                        }
                        
                        guard let tabSwitcher = self.tabSwitcher else {
                            DocsLogger.warning("tabSwitcher is nil", component: LogComponents.sheetTab)
                            return
                        }
                        
                        // bugfix: 在异步回调内部创建新VC，外部创建如果不强引用在 iOS 16 上会立即释放导致无法显示
                        let newVC = SheetTabOperationViewController(params: json, delegate: self)
                        self.operationVC = newVC
                        
                        setupNewVC(newVC: newVC, tabSwitcher: tabSwitcher)
                        
                        guard let rect = rect else {
                            DocsLogger.info("cannot get sheet operation vc source rect", component: LogComponents.sheetTab)
                            newVC.modalPresentationStyle = .overCurrentContext
                            DocsLogger.info("tab operation vc will be presented over current context because cannot get rect", component: LogComponents.sheetTab)
                            navigator?.presentViewController(newVC, animated: true, completion: nil)
                            return
                        }
                        DocsLogger.info("got sheet operation vc source rect: \(rect)", component: LogComponents.sheetTab)
                        newVC.popoverPresentationController?.sourceRect = rect
                        DocsLogger.info("tab operation vc will be presented in popover", component: LogComponents.sheetTab)
                        navigator?.presentViewController(newVC, animated: true, completion: nil)
                    })
                    .disposed(by: tabSwitcher.disposeBag)
            } else {
                let newVC = SheetTabOperationViewController(params: json, delegate: self)
                operationVC = newVC
                setupNewVC(newVC: newVC, tabSwitcher: tabSwitcher)
                newVC.modalPresentationStyle = .overCurrentContext
                DocsLogger.info("tab operation vc will be presented over current context because there is no source", component: LogComponents.sheetTab)
                navigator?.presentViewController(newVC, animated: true, completion: nil)
            }
        } else {
            let newVC = SheetTabOperationViewController(params: json, delegate: self)
            operationVC = newVC
            newVC.modalPresentationStyle = .overCurrentContext
            DocsLogger.info("tab operation vc will be presented over current context because of compact mode", component: LogComponents.sheetTab)
            navigator?.presentViewController(newVC, animated: true, completion: nil)
        }
        SheetTracker.report(event: .sheetAddExpose, docsInfo: self.model?.browserInfo.docsInfo)
    }

}

extension SheetTabOperationService: SheetTabOperationDelegate {
    var hostView: UIView? {
        return registeredVC?.view
    }

    var tabSwitcher: SheetTabSwitcherView? {
        guard let sheetBrowserVC = registeredVC as? SheetBrowserViewController else { return nil }
        return sheetBrowserVC.tabSwitcher
    }

    func didClickBackgroundToDismiss() {
        operationVC?.hasNoticedDismissal = true
        model?.jsEngine.callFunction(DocsJSCallBack(callback), params: ["itemId": "exit"], completion: { (_, error) in
            guard error == nil else {
                DocsLogger.error("\(DocsJSService.sheetTabOperation.rawValue) 执行 JS 回调失败：", error: error, component: LogComponents.sheetTab)
                return
            }
        })
    }

    func didClickOperation(identifier: String, tableID: String?, rightIconID: String?) {
        operationVC?.hasNoticedDismissal = true
        model?.jsEngine.callFunction(DocsJSCallBack(callback), params: [
            "itemId": identifier,
            "tableId": tableID as Any,
            "iconId": rightIconID as Any
        ], completion: { (_, error) in
            guard error == nil else {
                DocsLogger.error("\(DocsJSService.sheetTabOperation.rawValue) 执行 JS 回调失败：", error: error, component: LogComponents.sheetTab)
                return
            }
        })
    }
}

extension SheetTabOperationService: BrowserViewLifeCycleEvent {
    func browserWillTransition(from: CGSize, to: CGSize) {
        if let presentedVC = operationVC, presentedVC.modalPresentationStyle == .popover {
            didClickBackgroundToDismiss()
        }
    }
}

struct SheetTabOperationParams: HandyJSON {
    var title: String?
    var items: [SheetTabOperation] = []
    var source: SheetTabOperationSource?
    var callback: String = ""

    func toolbarItemInfos() -> [[ToolBarItemInfo]] {
        let groupItems = items
            .map { (operation) -> ToolBarItemInfo in
                let info = ToolBarItemInfo(identifier: operation.id.rawValue)
                let groupID = operation.groupId ?? operation.id.rawValue
                info.parentIdentifier = groupID
                info.title = operation.title
                info.isEnable = operation.enable
                info.jsMethod = callback

//                if let buttonId = BarButtonIdentifier(rawValue: info.identifier),
//                      let iconType = buttonId.sheetToolboxIconType {
//                    info.image = UDIcon.getIconByKey(iconType, renderingMode: .alwaysTemplate, size: CGSize(width: 20, height: 20)).ud.withTintColor(UDColor.iconN1)
//                }
                return info
            }

        guard let aggregatedResult = groupItems.aggregateByGroupID() as? [[ToolBarItemInfo]] else { return [] }
        return aggregatedResult
    }
}

struct SheetTabOperation: HandyJSON {
    var enable: Bool = false
    var id: BarButtonIdentifier = .createSheet
    var groupId: String?
    var title: String = ""
    var tableId: String?
    var isShowLeftIcon: Bool = false
    var rightIcons: [RightIconItem]?
}

struct RightIconItem: HandyJSON {
    var id: String = ""
    var enable: Bool = true
}

struct SheetTabOperationSource: HandyJSON {
    var eventId: SheetTabOperationType = .unknown
    var sheetId: String?
}

enum SheetTabOperationType: String, HandyJSONEnum {
    case unknown
    case add
    case operate
    case reorder
}
