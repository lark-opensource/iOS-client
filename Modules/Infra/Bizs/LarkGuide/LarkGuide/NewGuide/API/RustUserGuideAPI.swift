//
//  RustUserGuideAPI.swift
//  LarkGuide
//
//  Created by zhenning on 2020/08/03.
//

import UIKit
import Foundation
import RustPB
import ServerPB
import RxSwift
import LKCommonsLogging
import LarkRustClient

final class RustUserGuideAPI: UserGuideAPI {

    private static let logger = Logger.log(RustUserGuideAPI.self, category: "RustSDK.UserGuide")
    private let client: RustService

    init(client: RustService) {
        self.client = client
    }

    /// 获取用户引导配置列表
    ///
    /// - Returns: 用户引导可视区域配置列表
    func fetchUserGuide() -> Observable<[UserGuideViewAreaPair]> {
        let request = GetUserGuideRequest()
        var pack = RequestPacket(message: request)
        pack.enableStartUpControl = true
        let result: Observable<GetUserGuideResponse> = client.async(pack)
        let startTime = CACurrentMediaTime()
        let serverOrderedPairs = result.map({ (response) -> [UserGuideViewAreaPair] in
            return response.orderedPairs
        }).do(onNext: { (data) in
            let cost = Tracer.calculateCostTime(startTime: startTime)
            Tracer.trackGuideFetchInfo(succeed: true, cost: cost)
            Self.logger.debug("[LarkGuide]: get UserGuide success \(data)")
        }, onError: { [weak self] (error) in
            if let error = error.underlyingError as? RCError {
                let errorCode = self?.getRCErrorCode(rcError: error)
                Tracer.trackGuideFetchInfo(succeed: false,
                                           trackError: LarkGuideTrackError(errorCode: errorCode,
                                                                           errorMsg: error.debugDescription)
                )
            }
            Self.logger.error("[LarkGuide]: get UserGuide error", error: error)
        })
        Self.logger.debug("[LarkGuide]: send request GetUserGuideRequest")
        return serverOrderedPairs
    }

    /// 获取CCM用户引导信息
    func getCCMUserGuide() -> Observable<[ServerPB_Guide_UserGuideViewAreaPair]> {
        var request = ServerPB.ServerPB_Guide_GetUserGuideRequest()
        request.scene = .ccm
        let result: Observable<ServerPB_Guide_GetUserGuideResponse> = self.client.sendPassThroughAsyncRequest(request, serCommand: .getUserGuideRequest)

        return result.map({ (resp) -> [ServerPB_Guide_UserGuideViewAreaPair] in
            return resp.pairs
        }).do(onNext: { _ in
            Self.logger.info("[LarkGuide]: fetch ccm user guide success!!!")
        }, onError: { error in
            Self.logger.error("[LarkGuide]: fetch ccm user guide failed!!!, error: \(error)")
        }).catchErrorJustReturn([ServerPB_Guide_UserGuideViewAreaPair]())
    }

    /// 同步用户引导状态
    ///
    /// - Parameter guideKeys: 同步server已展示的用户引导list
    /// - Returns: void
    func postUserConsumingGuide(guideKeys: [String]) -> Observable<Void> {
        var request = PostUserConsumingGuideRequest()
        request.keys = guideKeys
        let startTime = CACurrentMediaTime()
        let result: Observable<PostUserConsumingGuideResponse> = client.sendAsyncRequest(request)
        return result.map { _ in return }
            .do(onNext: { _ in
                let cost = Tracer.calculateCostTime(startTime: startTime)
                Tracer.trackGuidePostConsuming(succeed: true, guideKeys: guideKeys, cost: cost)
                Self.logger.debug("[LarkGuide]: post user comsuming guide success",
                                              additionalData: ["consumingKeys": "\(guideKeys)"])
            }, onError: { [weak self] (error) in
                if let error = error.underlyingError as? RCError {
                    let errorCode = self?.getRCErrorCode(rcError: error)
                    Tracer.trackGuidePostConsuming(succeed: false,
                                                   guideKeys: guideKeys,
                                                   trackError: LarkGuideTrackError(errorCode: errorCode,
                                                                                   errorMsg: error.debugDescription)
                    )
                }
                Self.logger.error("[LarkGuide]: post user comsuming guide error",
                                              additionalData: ["consumingKeys": "\(guideKeys)"],
                                              error: error)
            })
    }
}

extension RustUserGuideAPI {
    func getRCErrorCode(rcError: RCError) -> Int32? {
        switch rcError {
        case .businessFailure(let errorInfo):
            return errorInfo.code
        default:
            return nil
        }
    }
}
