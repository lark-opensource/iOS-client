//
//  UtilFullscreenService.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/10/9.
//

import Foundation
import SKCommon
import SpaceInterface

// 控制BrowserView 的沉浸式浏览、全屏逻辑
class UtilFullscreenService: BaseJSService {
//    private static let _enabledFullscreenType: Set<DocsType> = [
//        .doc, .mindnote, .docX
//    ]

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
}

extension UtilFullscreenService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return []
    }

    public func handle(params: [String: Any], serviceName: String) {

    }
}

extension UtilFullscreenService: BrowserViewLifeCycleEvent {
    public func browserDidAppear() {
        guard let docsInfo = model?.browserInfo.docsInfo else { return }
        // Don't set any state while result is true, because this will also be setten somewhere (like Open Docs).
        if FullScreenUtil.isFullScreenScrollingEnable(docsInfo: docsInfo) == false {
            model?.setFullscreenScrollingEnabled(false)
        }
    }
}


public final class FullScreenUtil {
    
    private static let _enabledFullscreenType: Set<DocsType> = [
        .doc, .mindnote, .docX, .slides
    ]
    
    public static func isFullScreenScrollingEnable(docsInfo: DocsInfo) -> Bool {
        return _enabledFullscreenType.contains(docsInfo.inherentType)
    }
}
