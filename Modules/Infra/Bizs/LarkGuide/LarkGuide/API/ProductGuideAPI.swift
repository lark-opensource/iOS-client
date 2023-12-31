//
//  ProductGuideAPI.swift
//  LarkSDKInterface
//
//  Created by sniperj on 2018/12/11.
//

import Foundation
import RxSwift

public protocol ProductGuideAPI {

    /// 获取用户引导状态列表
    ///
    /// - Returns: 用户引导状态列表
    func getProductGuide() -> Observable<[String: Bool]>

    /// 删除用户引导状态
    ///
    /// - Parameter guides: 需要删除的用户引导list
    /// - Returns: void
    func deleteProductGuide(guides: [String]) -> Observable<Void>
}
