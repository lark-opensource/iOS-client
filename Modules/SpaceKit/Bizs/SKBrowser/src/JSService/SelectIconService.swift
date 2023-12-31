//
//  SelectIconService.swift
//  SpaceKit
//
//  Created by 边俊林 on 2020/2/12.
//

import Foundation
import SKCommon

public final class SelectIconService: BaseJSService {

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
    }

}

extension SelectIconService: DocsJSServiceHandler {

    public var handleServices: [DocsJSService] {
        return [.selectIcon]
    }

    public func handle(params: [String: Any], serviceName: String) {

//        if serviceName == DocsJSService.selectIcon.rawValue {
//            _handleSelectIcon(params: params)
//        }

    }

    /*
    private func _handleSelectIcon(params: [String: Any]) {
        guard IconPickerViewController.canOpenIconPicker() else {
            IconPickerViewController.showErrorIfExist()
            return
        }

        guard let model = model, let docsInfo = model.browserInfo.docsInfo else { return }
        var iconData: IconData?
        if let key = params["key"] as? String,
            let typeNum = params["type"] as? Int,
            let type = SpaceEntry.IconType(rawValue: typeNum) {
            iconData = (key, type)
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let viewController = IconPickerViewController(token: docsInfo.objToken, iconData: iconData, model: model)
            // let navigationController = LkNavigationController(rootViewController: viewController)
            self.navigator?.presentViewController(viewController, animated: true, completion: nil)
        }
    }
    */
}
