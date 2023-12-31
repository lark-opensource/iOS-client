//
//  ReadEditModeService.swift
//  SpaceKit
//
//  Created by 边俊林 on 2020/2/17.
//

import Foundation
import SKCommon
import SKUIKit
import SKFoundation

class ReadEditModeService: BaseJSService {

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
    }

}

extension ReadEditModeService: DocsJSServiceHandler {

    var handleServices: [DocsJSService] {
        return [.editButtonSetVisible, .togglgEditMode, .completeButtonSetVisible, .simulateCommentInputViewHeight]
    }

    func handle(params: [String: Any], serviceName: String) {
        
        DocsLogger.info("ReadEditModeService handle \(serviceName)",
                        extraInfo: params,
                        traceId: browserTrace?.traceRootId)
        
        if serviceName == DocsJSService.editButtonSetVisible.rawValue {
            guard let visible = params["visible"] as? Bool else { return }
            ui?.displayConfig.setEditButtonVisible(visible)
        } else if serviceName == DocsJSService.togglgEditMode.rawValue {
            ui?.displayConfig.toggleEditMode()
        } else if serviceName == DocsJSService.completeButtonSetVisible.rawValue {
            guard let visible = params["visible"] as? Bool else { return }
            ui?.displayConfig.setCompleteButtonVisible(visible)
        } else if serviceName == DocsJSService.simulateCommentInputViewHeight.rawValue {
            guard let height = params["height"] as? CGFloat else { return }
            ui?.displayConfig.modifyEditButtonBottomOffset(height: height)
        }
    }
}
