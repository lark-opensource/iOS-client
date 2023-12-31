//
//  StickerAPI.swift
//  Lark
//
//  Created by lichen on 2017/11/14.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkModel
import RustPB

public struct UploadStickerResult {
    public let succesedPaths: [String]
    public let failedPaths: [String]

    public init(succesedPaths: [String], failedPaths: [String]) {
        self.succesedPaths = succesedPaths
        self.failedPaths = failedPaths
    }
}

public struct StickerSetResult {
    public var stickerSets: [RustPB.Im_V1_StickerSet]
    public var hasMore: Bool
    public let lastPosition: Int32

    public init(stickerSets: [RustPB.Im_V1_StickerSet], hasMore: Bool, lastPosition: Int32   ) {
        self.stickerSets = stickerSets
        self.hasMore = hasMore
        self.lastPosition = lastPosition
    }
}

public protocol StickerAPI {
    func fetchStickers() -> Observable<[RustPB.Im_V1_Sticker]>
    func addStickerImages(_ imagePaths: [String]) -> Observable<UploadStickerResult>
    func addStickers(_ stickers: [RustPB.Im_V1_Sticker]) -> Observable<[RustPB.Im_V1_Sticker]>
    func deleteStickers(_ stickers: [RustPB.Im_V1_Sticker]) -> Observable<[RustPB.Im_V1_Sticker]>
    func patchStickers(_ stickers: [RustPB.Im_V1_Sticker]) -> Observable<[RustPB.Im_V1_Sticker]>

    func fetchStickerSets(type: RustPB.Im_V1_GetStickerSetsStoreRequest.FilterType, count: Int32, position: Int32) -> Observable<StickerSetResult>
    func fetchUserStickerSets() -> Observable<[RustPB.Im_V1_StickerSet]>
    func fetchStickerSetsBy(ids: [String]) -> Observable<[String: RustPB.Im_V1_StickerSet]>
    func addStickerSets(ids: [String]) -> Observable<Void>
    func deleteStickerSets(ids: [String]) -> Observable<Void>
    func patchStickerSets(ids: [String]) -> Observable<Void>
    func downloadStickerSetArchive(key: String, path: String, url: String) -> Observable<Void>
    func getStickerSetArchiveDownloadState(stickerSetIds: [String], path: String) -> Observable<[String: RustPB.Media_V1_GetStickerSetArchiveDownloadStateResponse.State]>
    func sendShareStickerSet(stickerSetID: String, chatID: String) -> Observable<Void>
}

public typealias StickerAPIProvider = () -> StickerAPI
