//
//  RustResourceAPI.swift
//  Lark-Rust
//
//  Created by Sylar on 2017/12/26.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import RxSwift
import LarkSDKInterface
import LarkLocalizations
import LarkFeatureGating
import LarkAccountInterface
import ByteWebImage

final class RustResourceAPI: LarkAPI, ResourceAPI {
    private lazy var concurrentScheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue(label: "concurrentScheduler",
                                                                                                 qos: .userInitiated,
                                                                                                 attributes: .concurrent))

    func fetchUploadID(chatID: String, language: Lang) throws -> String {
        return ""
    }

    let keyPrefix = (origin: "origin:", thumb: "thumb:")

    func computeResourceKey(key: String, isOrigin: Bool = false) -> String {
        let prefix = isOrigin ? keyPrefix.origin : keyPrefix.thumb

        return key.hasPrefix(prefix) ? key : "\(prefix)\(key)"
    }

    func computeKFResourceUrl(key: String) -> String {
        return "rust://image/\(key)"
    }

    private func genAvatarParams(avatarMap: [String: Any]) -> RustPB.Media_V1_AvatarResourceParams {
        return RustPB.Media_V1_AvatarResourceParams()
    }

    private func genAvatarFsUnitParams(avatarMap: [String: Any]) -> RustPB.Media_V1_AvatarFsUnitParams {
        return RustPB.Media_V1_AvatarFsUnitParams()
    }

    func fetchResource(key: String, path: String?, downloadScene: RustPB.Media_V1_DownloadFileScene, isReaction: Bool, isEmojis: Bool, avatarMap: [String: Any]?) -> Observable<ResourceItem> {
        return self.fetchResource(key: key,
                                  path: path,
                                  downloadScene: downloadScene,
                                  isReaction: isReaction,
                                  isEmojis: isEmojis,
                                  avatarMap: avatarMap,
                                  onlyLocalData: false)
                    .map { $0! }
    }

    func fetchResourceOnlyByLocal(key: String, path: String?, downloadScene: RustPB.Media_V1_DownloadFileScene, isReaction: Bool, isEmojis: Bool, avatarMap: [String: Any]?)
        -> Observable<ResourceItem?> {

        return self.fetchResource(key: key,
                                  path: path,
                                  downloadScene: downloadScene,
                                  isReaction: isReaction,
                                  isEmojis: isEmojis,
                                  avatarMap: avatarMap,
                                  onlyLocalData: true)
    }

    func fetchResource(key: String, path: String?, downloadScene: RustPB.Media_V1_DownloadFileScene, isReaction: Bool, isEmojis: Bool, avatarMap: [String: Any]?, onlyLocalData: Bool)
         -> Observable<ResourceItem?> {
        return Observable.empty()
    }

    func fetchResource(entityID: Int64, key: String, size: Int32, dpr: Float, format: String) -> Observable<Data?> {
        return Observable.empty()
    }

    func fetchFaceResource(key: String, path: String?) -> Observable<ResourceItem> {
        return Observable.empty()
    }

    func fetchResourceUrl(key: String, avatarMap: [String: Any]?) -> Observable<String> {
        return Observable.empty()
    }

    func fetchResourcePath(entityID: String, key: String, size: Int32, dpr: Float, format: String) -> Observable<String> {
        var request = Media_V1_GetAvatarPathRequest()
        request.entityID = entityID
        request.key = key
        request.dpSize = size
        request.dpr = dpr
        request.format = format
        return self.client.sendAsyncRequest(request, transform: { (response: Media_V1_GetAvatarPathResponse) -> String in
            return response.path
        }).subscribeOn(scheduler!)
    }

    func deleteResources(keys: [String]) -> Observable<[String]> {
        return Observable.empty()
    }

    func clearResources() -> Observable<Void> {
        return Observable.empty()
    }

    func getResourcesSize() -> Observable<Float> {
        return Observable.empty()
    }

    func sendMetricsToSDK(preloadHit: Bool, loadTime: Float?) {
    }
}
