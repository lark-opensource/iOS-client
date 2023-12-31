//
//  ServiceStatistics.swift
//  SpaceKit
//
//  Created by nine on 2019/2/21.
//

import SKFoundation

/// 提供Service里面的打点所需要的各个参数
public protocol ServiceStatistics: AnyObject {
    var encryptedToken: String { get }
    var fileType: String { get }
    var module: String { get }
    func makeParameters(with action: String) -> [AnyHashable: Any]?
}

// BaseJSService提供基本的参数
extension ServiceStatistics where Self: BaseJSService {
    public var encryptedToken: String {
        return DocsTracker.encrypt(id: model?.browserInfo.docsInfo?.objToken ?? "")
    }

    public var fileType: String {
        return model?.browserInfo.docsInfo?.type.name ?? ""
    }

    public var module: String {
        return fileType // module在未来某些情况会和fileType不同，比如docs里面的sheet插入图片，现在没有这个功能，后续请注意
    }
}
