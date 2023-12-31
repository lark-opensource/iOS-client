//
//  BaseJSONReachPoint.swift
//  UGContainer
//
//  Created by mochangxing on 2021/2/2.
//

import Foundation

public protocol BaseJSONReachPoint: HideableReachPoint where ReachPointModel: Decodable {}

extension BaseJSONReachPoint {

    /// 反序列化，从二进制数据反序列化为对象
    public static func decode(payload: Data) -> ReachPointModel? {
        do {
            return try JSONDecoder().decode(ReachPointModel.self, from: payload)
        } catch {

        }
        return nil
    }
}
