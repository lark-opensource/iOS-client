//
//  VCFollowService.swift
//  SpaceKit
//
//  Created by nine on 2019/9/6.
//

import Foundation
import SpaceInterface
import RxSwift
import RxCocoa
import SwiftyJSON
import SKCommon
import SKFoundation

class VCFollowService: BaseJSService {
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
    }
}

extension VCFollowService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.vcFollowOn, .followReady, .exitFile, .exitAttachFile, .sendToNative]
    }

    public func handle(params: [String: Any], serviceName: String) {
        // 过滤 sendToNative 是因为太频繁了。
        if serviceName != DocsJSService.sendToNative.rawValue {
            DocsLogger.info("VCFollowService handle \(serviceName)", component: LogComponents.vcFollow, traceId: self.browserTrace?.traceRootId)
        }
        if serviceName == DocsJSService.vcFollowOn.rawValue {
            //handVCFollowOn(params: params, serviceName: serviceName)
            DocsLogger.error("vcFollowOn has been remove!")
        } else if serviceName == DocsJSService.followReady.rawValue {
            model?.vcFollowDelegate?.followDidReady()
        } else if serviceName == DocsJSService.exitFile.rawValue ||
                    serviceName == DocsJSService.exitAttachFile.rawValue {
            
            model?.vcFollowDelegate?.follow(onOperate: .exitAttachFile)
        } else if serviceName == DocsJSService.sendToNative.rawValue {
            model?.vcFollowDelegate?.didReceivedJSData(data: params)
        }
    }
}
