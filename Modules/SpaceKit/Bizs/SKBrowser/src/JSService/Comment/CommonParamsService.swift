//
//  CommonParamsService.swift
//  SKBrowser
//
//  Created by huayufan on 2021/6/1.
//  

import SKCommon
import SKFoundation
import HandyJSON
import SpaceInterface
import SKInfra

class CommonParamsService: BaseJSService {
    
    var tracker: CommentTrackerInterface? {
        return DocsContainer.shared.resolve(CommentTrackerInterface.self)
    }
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        tracker?.update(baseParams: [:])
        SheetTracker.commonParams = [:]
    }
}

extension CommonParamsService: DocsJSServiceHandler {
    
    enum Tag: String, HandyJSONEnum {
        case sheetCommonParams
    }
    
    struct CommonParamsModel: HandyJSON {
        var params: [String: Any] = [:]
        /// 标记是什么埋点业务的公参
        var tag: Tag?
    }
    
    var handleServices: [DocsJSService] {
        return [.setCommonParams]
    }
    
    func handle(params: [String: Any], serviceName: String) {
        let service = DocsJSService(rawValue: serviceName)
        switch service {
        case .setCommonParams:
            if let model = CommonParamsModel.deserialize(from: params) {
                if model.tag == .sheetCommonParams {
                    SheetTracker.commonParams = model.params
                } else {
                    tracker?.update(baseParams: model.params)
                }
            }
        default:
            break
            
        }
    }
}
