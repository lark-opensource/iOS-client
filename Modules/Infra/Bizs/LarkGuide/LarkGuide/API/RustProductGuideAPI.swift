//
//  RustProductGuideAPI.swift
//  LarkSDK
//
//  Created by sniperj on 2018/12/11.
//

import Foundation
import RustPB
import RxSwift
import LKCommonsLogging
import LarkRustClient

typealias GetProductGuideRequest = RustPB.Onboarding_V1_GetProductGuideRequest
typealias GetProductGuideResponse = RustPB.Onboarding_V1_GetProductGuideResponse
typealias DeleteProductGuideRequest = RustPB.Onboarding_V1_DeleteProductGuideRequest
typealias DeleteProductGuideResponse = RustPB.Onboarding_V1_DeleteProductGuideResponse

final class RustProductGuideAPI: ProductGuideAPI {

    private let client: RustService
    init(client: RustService) {
        self.client = client
    }

    private static let logger = Logger.log(RustProductGuideAPI.self, category: "RustSDK.ProductGuide")

    /// 获取用户引导状态列表
    ///
    /// - Returns: 用户引导状态列表
    func getProductGuide() -> Observable<[String: Bool]> {
        let request = GetProductGuideRequest()
        var pack = RequestPacket(message: request)
        pack.enableStartUpControl = true
        let result: Observable<GetProductGuideResponse> = client.async(pack)
        return result.map({ (GetProductGuideResponse) -> [String: Bool] in
            return GetProductGuideResponse.guides
        }).do(onNext: { (dic) in
            RustProductGuideAPI.logger.info("Get ProductGuide success" + "\(dic)")
        }, onError: { (error) in
            RustProductGuideAPI.logger.error("Get ProductGuide error", error: error)
        })
    }

    func deleteProductGuide(guides: [String]) -> Observable<Void> {
        var request = DeleteProductGuideRequest()
        request.guides = guides
        let result: Observable<DeleteProductGuideResponse> = client.sendAsyncRequest(request)
        return result.map { _ in return }
            .do(onNext: { _ in
                RustProductGuideAPI.logger.info("delete productGuide success")
            }, onError: { (error) in
                RustProductGuideAPI.logger.error("delete productGuide error", error: error)
            })
    }
}
