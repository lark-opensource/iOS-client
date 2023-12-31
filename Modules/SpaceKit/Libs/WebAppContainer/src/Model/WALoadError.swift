//
//  WALoadError.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/12/2.
//

import Foundation
import SKResource
import UniverseDesignEmpty

public enum WALoadError: Error {
    case blank
    case overtime
    case webError(showPage: Bool, err: Error)
    
    // 供兜底页展示使用
    var emptyConfig: UDEmptyConfig {
        switch self {
        case .blank:
            let config = UDEmptyConfig(description: .init(descriptionText: BundleI18n.SKResource.Doc_Facade_LoadFailed),
                                       type: .loadingFailure)
            return config
        case .overtime:
            let config = UDEmptyConfig(description: .init(descriptionText: BundleI18n.SKResource.Doc_Facade_LoadOverTime),
                                       type: .loadingFailure)
            return config
        case let .webError(_, err):
            let msg = "\(BundleI18n.SKResource.Doc_Facade_LoadFailed)(\((err as NSError).code))"
            let config = UDEmptyConfig(description: .init(descriptionText: msg),
                                       type: .loadingFailure)
            return config
        }
    }
    
    var errorCode: Int {
        switch self {
        case .blank: 
            return LoadErrorCode.blank.rawValue
        case .overtime:
            return LoadErrorCode.overtime.rawValue
        case let .webError(_, err):
            let errCode = (err as NSError).code
            return LoadErrorCode.webError.rawValue + errCode //web错误统一偏移-10000
        }
    }
}

enum LoadErrorCode: Int {
    case blank = -1
    case overtime = -2
    case cancel = -3
    case webError = -10000
}
