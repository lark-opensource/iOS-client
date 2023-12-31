//
// Created by duanxiaochen.7 on 2019/8/19.
// Affiliated with SpaceKit.
//
// Description: Sheet Redesign - SheetDropdown List - JS Bridge

import Foundation
import SKCommon
import SKBrowser
import SKFoundation
import SKUIKit

class SheetDropdownService: BaseJSService {
    weak var dropdownVC: SheetDropdownViewController?

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
    }
}

extension SheetDropdownService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.sheetShowDropdown, .sheetHideDropdown]
    }

    func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.sheetShowDropdown.rawValue:
            showDropdown(params: params)
        case DocsJSService.sheetHideDropdown.rawValue:
            hideDropdown()
        default: ()
        }
    }

    func showDropdown(params: [String: Any]) {
        var usesColor = false
        var isMultipleSelection = false
        var cellValues: [String] = []
        var dropdownInfos: [SheetDropdownInfo] = []
        var optionBackgroundColorMap: [String: String] = [:]
        var optionTextColor: String = ""

        guard let callback = params["callback"] as? String,
              let optionValues = params["options"] as? [String] else {
            DocsLogger.info("前端没有传正确的 callback、选项数组过来", component: LogComponents.sheetDropdown)
            return
        }
        if let values = params["values"] as? [String] {
            cellValues = values
        }
        if let isMulti = params["isMulti"] as? Bool {
            isMultipleSelection = isMulti
        }
        if let textColor = params["textColor"] as? String {
            optionTextColor = textColor
        }
        if let hasColor = params["isEnableOptionColor"] as? Bool {
            usesColor = hasColor
            if usesColor {
                guard let map = params["colorMap"] as? [String: String] else {
                    DocsLogger.info("前端没有传过来颜色字典", component: LogComponents.sheetDropdown)
                    return
                }
                optionBackgroundColorMap = map
            }
        }
        guard let presentingVC = navigator?.currentBrowserVC as? BrowserViewController else {
            DocsLogger.debug("🙃presenting delegate 设置失败")
            return
        }
        let newDropdownVC = SheetDropdownViewController(delegate: presentingVC, isMultipleSelection: isMultipleSelection)
        newDropdownVC.selectionCallback = callback
        dropdownInfos = []
        for (ind, option) in optionValues.enumerated() {
            if usesColor, let colorHex = optionBackgroundColorMap[option] {
                let info = SheetDropdownInfo(index: ind,
                                             value: option,
                                             bgColorHex: colorHex,
                                             textColorHex: optionTextColor,
                                             selected: cellValues.contains(option))
                dropdownInfos.append(info)
            } else {
                let info = SheetDropdownInfo(index: ind,
                                             value: option,
                                             textColorHex: optionTextColor,
                                             selected: cellValues.contains(option))
                dropdownInfos.append(info)
            }
        }
        newDropdownVC.update(info: dropdownInfos)
        dropdownVC = newDropdownVC
        let viewportHeight = presentingVC.webviewHeight - newDropdownVC.visualHeight
        presentingVC.presentDropdownVC(newDropdownVC) { [weak model] in
            let info = BrowserKeyboard(height: viewportHeight,
                                       isShow: true,
                                       trigger: "dropdown")
            let params: [String: Any] = [SimulateKeyboardInfo.key: info]
            model?.jsEngine.simulateJSMessage(DocsJSService.simulateKeyboardChange.rawValue, params: params)
        }
    }

    func hideDropdown() { // 所有 dismiss 逻辑都会走这里
        guard dropdownVC != nil else {
            DocsLogger.info("别催了，dropdownVC 已经没了", component: LogComponents.sheetDropdown)
            return
        }
        dropdownVC?.dismiss(animated: true, completion: nil)
    }
}

extension BrowserViewController: SheetDropdownDelegate {

    var browserBounds: CGRect { view.bounds }

    var webviewHeight: CGFloat { editor.bounds.height }

    func requestToSwitchToKeyboard(currentDropdownVC: SheetDropdownViewController?) {
        currentDropdownVC?.dismiss(animated: true, completion: { [weak self] in
            self?.editor.jsEngine.callFunction(DocsJSCallBack.switchToKeyboardFromDropdown, params: nil, completion: { (_, error) in
                guard error == nil else {
                    DocsLogger.error("[切换键盘]\(String(describing: error))", component: LogComponents.sheetDropdown)
                    return
                }
            })
        })
    }

    func didSelectOption(value: String, shouldDismiss: Bool, callback: String) {
        let params = ["val": value] as [String: Any]
        editor.jsEngine.callFunction(DocsJSCallBack(callback), params: params, completion: { (_, error) in
            guard error == nil else {
                DocsLogger.error("[选择选项]\(String(describing: error))", component: LogComponents.sheetDropdown)
                return
            }
        })
        if shouldDismiss {
            notifyH5ToDismissDropdownVC()
        }
    }

    func presentDropdownVC(_ vc: SheetDropdownViewController, completion: @escaping () -> Void) {
        present(vc, animated: true, completion: completion)
    }

    func notifyH5ToDismissDropdownVC() {
        editor.jsEngine.callFunction(DocsJSCallBack.notifyH5ToHideDropdown, params: nil, completion: { (_, error) in
            guard error == nil else {
                DocsLogger.error("[通知前端隐藏]\(String(describing: error))", component: LogComponents.sheetDropdown)
                return
            }
        })
        let info = BrowserKeyboard(height: webviewHeight, isShow: false, trigger: "dropdown")
        let params: [String: Any] = [SimulateKeyboardInfo.key: info]
        editor.jsEngine.simulateJSMessage(DocsJSService.simulateKeyboardChange.rawValue, params: params)
    }
}
