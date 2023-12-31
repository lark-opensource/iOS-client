//
//  BTCommonUtils.swift
//  SKBitable
//
//  Created by X-MAN on 2023/3/9.
//

import Foundation
import SKFoundation
import SKCommon
import HandyJSON
import SKInfra

extension SKFastDecodable where Self: HandyJSON {
    /// 一级模型使用该方法
    public static func desrializedGlobalAsync(with dictionary: [String: Any],
                                       callbackInMainQueue: Bool,
                                       callback: @escaping (Self?) -> Void) {
        if UserScopeNoChangeFG.XM.ccmBitableCardOptimized {
            executeGlobalAsync {
                var model = Self.convert(from: dictionary)
                if callbackInMainQueue {
                    DispatchQueue.main.async {
                        callback(model)
                    }
                } else {
                    callback(model)
                }
            }
        } else {
            // 调用HandyJSON方法
            callback(Self.deserialize(from: dictionary))
        }
    }
}

func executeGlobalAsync(workItem: @escaping () -> Void) {
    if UserScopeNoChangeFG.XM.ccmBitableCardOptimized {
        if Thread.isMainThread {
            DispatchQueue.global().async {
                workItem()
            }
        } else {
            workItem()
        }
    } else {
        workItem()
    }
}
