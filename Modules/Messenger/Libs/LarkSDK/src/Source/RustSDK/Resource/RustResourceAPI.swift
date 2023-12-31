//
//  RustResourceAPI.swift
//  Lark-Rust
//
//  Created by Sylar on 2017/12/26.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import RustSDK
import RxSwift
import LarkSDKInterface
import LarkLocalizations
import LarkFeatureGating
import LarkAccountInterface
import ByteWebImage
import LarkContainer

final class RustResourceAPI: LarkAPI, ResourceAPI {
    let userResolver: UserResolver
    init(userResolver: UserResolver, client: SDKRustService, onScheduler: ImmediateSchedulerType? = nil) {
        self.userResolver = userResolver
        super.init(client: client, onScheduler: onScheduler)
    }

    private lazy var concurrentScheduler = ConcurrentDispatchQueueScheduler(queue: DispatchQueue(label: "concurrentScheduler",
                                                                                                 qos: .userInitiated,
                                                                                                 attributes: .concurrent))

    func fetchUploadID(chatID: String, language: Lang) throws -> String {
        var request = GetUploadIdRequest()
        request.chatID = chatID
        request.language = language.localeIdentifier.lowercased()
        let res: GetUploadIdResponse = try self.client.sendSyncRequest(
            request,
            allowOnMainThread: true
        ).response
        return res.uploadID
    }

    let keyPrefix = (origin: "origin:", thumb: "thumb:")

    func computeResourceKey(key: String, isOrigin: Bool = false) -> String {
        let prefix = isOrigin ? keyPrefix.origin : keyPrefix.thumb

        return key.hasPrefix(prefix) ? key : "\(prefix)\(key)"
    }

    func computeKFResourceUrl(key: String) -> String {
        return "rust://image/\(key)"
    }

    func fetchResource(
        key: String,
        path: String?,
        authToken: String?,
        downloadScene: RustPB.Media_V1_DownloadFileScene,
        isReaction: Bool,
        isEmojis: Bool,
        avatarMap: [String: Any]?
    ) -> Observable<ResourceItem> {
        return self.fetchResource(key: key,
                                  path: path,
                                  authToken: authToken,
                                  downloadScene: downloadScene,
                                  isReaction: isReaction,
                                  isEmojis: isEmojis,
                                  avatarMap: avatarMap,
                                  onlyLocalData: false)
                    .compactMap { $0 }
    }

    func fetchResourceOnlyByLocal(key: String, path: String?, downloadScene: RustPB.Media_V1_DownloadFileScene, isReaction: Bool, isEmojis: Bool, avatarMap: [String: Any]?)
        -> Observable<ResourceItem?> {

        return self.fetchResource(key: key,
                                  path: path,
                                  authToken: nil,
                                  downloadScene: downloadScene,
                                  isReaction: isReaction,
                                  isEmojis: isEmojis,
                                  avatarMap: avatarMap,
                                  onlyLocalData: true)
    }

    func fetchResource(
        key: String,
        path: String?,
        authToken: String?,
        downloadScene: RustPB.Media_V1_DownloadFileScene,
        isReaction: Bool,
        isEmojis: Bool,
        avatarMap: [String: Any]?,
        onlyLocalData: Bool
    ) -> Observable<ResourceItem?> {
        var set = RustPB.Media_V1_MGetResourcesRequest.Set()
        set.key = key
        if let authToken = authToken {
            set.options.previewToken = authToken
        }
        if let path = path {
            set.path = path
        }

        var request = RustPB.Media_V1_MGetResourcesRequest()
        request.sets = [set]
        request.isReaction = isReaction
        request.fromLocal = onlyLocalData
        request.scene = downloadScene
        request.isEmojis = isEmojis

        return self.client.sendAsyncRequest(request) { (res: RustPB.Media_V1_MGetResourcesResponse) -> ResourceItem? in
            if let res = res.resources.first?.value {
                return ResourceItem(key: res.key, path: res.path)
            } else {
                if request.fromLocal { return nil }
                throw APIError(type: .noResourcesInServerResponse)
            }
        }
        .subscribeOn(scheduler)
    }

    func fetchResource(entityID: Int64, key: String, size: Int32, dpr: Float, format: String) -> Observable<Data?> {
        return Observable.create { observer -> Disposable in
            guard let keyPointer = (key as NSString).utf8String,
                  let formatPointer = (format as NSString).utf8String else {
                let error = NSError(domain: "convert string to pointer error, for key = \(key), format = \(format)", code: -1, userInfo: nil)
                observer.onError(error)
                observer.onCompleted()
                return Disposables.create()
            }
            var lengthPointer = UnsafeMutablePointer<Int>.allocate(capacity: 1)
            var dataPointerPointer = UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>.allocate(capacity: 1)
            let errorCode = get_avatar(entityID, keyPointer, size, dpr,
                                       formatPointer, lengthPointer, dataPointerPointer)
            let length = lengthPointer.pointee
            if errorCode != 0 {
                let error = NSError(domain: "sdk error, key = \(key), format = \(format)", code: Int(errorCode), userInfo: nil)
                observer.onError(error)
                observer.onCompleted()
            } else {
                if let dataPointer = UnsafeRawPointer(dataPointerPointer.pointee) {
                    let data = Data(bytes: dataPointer, count: length)
                    observer.onNext(data)
                    observer.onCompleted()
                }
            }
            free_rust(dataPointerPointer.pointee, UInt32(length))
            lengthPointer.deallocate()
            dataPointerPointer.deallocate()
            return Disposables.create()
        }
        // 此处需要用concurrentScheduler，因为get_avatar是阻塞的，原scheduler是串行的，大量的头像请求可能会阻塞队列，造成头像加载变慢
        .subscribeOn(concurrentScheduler)
    }

    func fetchFaceResource(key: String, path: String?) -> Observable<ResourceItem> {
        return fetchResource(key: key,
                             path: path,
                             authToken: nil,
                             downloadScene: .chat,
                             isReaction: false,
                             isEmojis: false,
                             avatarMap: AvatarImageParams.faceAvatarImageParams.transformDic())
    }

    func fetchResourceUrl(key: String, avatarMap: [String: Any]?) -> Observable<String> {
        var request = Media_V1_GetResourceUrlsRequest()
        request.key = key
        request.fsUnit = avatarMap?["fsUnit"] as? String ?? ""
        return self.client.sendAsyncRequest(request, transform: { (response: Media_V1_GetResourceUrlsResponse) -> String in
            return response.urls.first ?? ""
        }).subscribeOn(scheduler)
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
        }).subscribeOn(scheduler)
    }

    func deleteResources(keys: [String]) -> Observable<[String]> {
        var request = DeleteResourcesRequest()
        request.keys = keys
        return self.client.sendAsyncRequest(request, transform: { (response: DeleteResourcesResponse) -> [String] in
            return response.successKeys
        }).subscribeOn(scheduler)
    }

    func clearResources() -> Observable<Void> {
        let request = ClearResourcesRequest()
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func getResourcesSize() -> Observable<Float> {
        let request = GetResourcesSizeRequest()
        return client.sendAsyncRequest(request) { (res: GetResourcesSizeResponse) -> Float in
            return res.sizeM
        }
            .subscribeOn(scheduler)
    }

    func sendMetricsToSDK(preloadHit: Bool, loadTime: Float?) {
        var request = SendMetricsRequest()
        if let lt = loadTime {
            request.key2Value = ["small.avatar.cache": lt]
        }
        request.tag2Value = ["preload_hit": preloadHit ? "1" : "0"]
        _ = client.sendAsyncRequest(request)
    }
}
