//
//  BTFilterPanelDataService.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/25.
//  

import SKFoundation
import SKResource
import SKCommon
import RxSwift


enum BTSetFilterType: String {
    case AddCondition
    case DeleteCondition
    case UpdateCondition
    case ReloadCondition
    case SetConjunction
}

protocol BTFilterPanelDataServiceType {
    func updateFilterInfo(type: BTSetFilterType, value: Any, callback: String) -> Single<Bool>
}

final class BTFilterPanelDataService: BTFilterPanelDataServiceType {

    private var jsService: SKExecJSFuncService

    init(jsService: SKExecJSFuncService) {
        self.jsService = jsService
    }
    
    func updateFilterInfo(type: BTSetFilterType, value: Any, callback: String) -> Single<Bool> {
        var payload: [String: Any] = ["type": type.rawValue]
        switch type {
        case .UpdateCondition, .AddCondition:
            payload.updateValue(value, forKey: "condition")
        case .DeleteCondition:
            payload.updateValue(value, forKey: "conditionId")
        case .SetConjunction:
            payload.updateValue(value, forKey: "conjunction")
        case .ReloadCondition:
            break
        }
        let params: [String: Any] = [
            "action": "SetFilter",
            "payload": payload
        ]
        return jsService.rxCallFuction(DocsJSCallBack(callback),
                                       params: params,
                                       parseData: { _ in true },
                                       defaultValueWhenDataNil: true).asSingle()
    }
}
