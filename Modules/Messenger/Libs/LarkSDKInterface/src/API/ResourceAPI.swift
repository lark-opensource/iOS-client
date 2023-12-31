//
//  ResourceAPI.swift
//  LarkSDKInterface
//
//  Created by liuwanlin on 2018/6/5.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RxSwift
import LarkModel
import LarkLocalizations
import RustPB
import LarkContainer

public struct ResourceItem {
    public let key: String
    public let path: String // absolute path

    public init(key: String, path: String) {
        self.key = key
        self.path = path
    }
}

public protocol ResourceAPI: UserResolverWrapper {

    var keyPrefix: (origin: String, thumb: String) { get }

    func computeResourceKey(key: String, isOrigin: Bool) -> String

    func computeKFResourceUrl(key: String) -> String

    func fetchResource(key: String, path: String?, authToken: String?, downloadScene: RustPB.Media_V1_DownloadFileScene, isReaction: Bool, isEmojis: Bool, avatarMap: [String: Any]?)
         -> Observable<ResourceItem>

    func fetchResourceOnlyByLocal(key: String, path: String?, downloadScene: RustPB.Media_V1_DownloadFileScene, isReaction: Bool, isEmojis: Bool, avatarMap: [String: Any]?)
         -> Observable<ResourceItem?>

    /// - Parameters:
    ///   - entityID: chatID/chatterID/tenantID
    ///   - key: avatarKey
    ///   - size: avatar view dp size: max(width, height)
    ///   - dpr: UIScreen.main.scale
    ///   - format: only: ["webp", "jpeg"]
    /// - Return: raw image data
    func fetchResource(entityID: Int64, key: String, size: Int32, dpr: Float, format: String) -> Observable<Data?>

    func fetchFaceResource(key: String, path: String?) -> Observable<ResourceItem>

    func fetchResourceUrl(key: String, avatarMap: [String: Any]?) -> Observable<String>

    /// - Parameters:
    ///   - entityID: chatID/chatterID/tenantID
    ///   - key: avatarKey
    ///   - size: avatar view dp size: max(width, height)
    ///   - dpr: UIScreen.main.scale
    ///   - format: ["webp", "jpeg", ...]
    /// - Return: image path
    func fetchResourcePath(entityID: String, key: String, size: Int32, dpr: Float, format: String) -> Observable<String>

    func deleteResources(keys: [String]) -> Observable<[String]>

    func clearResources() -> Observable<Void>

    func getResourcesSize() -> Observable<Float>

    func fetchUploadID(chatID: String, language: Lang) throws -> String

    func sendMetricsToSDK(preloadHit: Bool, loadTime: Float?)
}

public typealias ResourceAPIProvider = () -> ResourceAPI
