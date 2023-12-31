//
//  RustStickerAPI.swift
//  Lark
//
//  Created by lichen on 2017/11/14.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkSDKInterface
import LarkModel
import RustPB

final class RustStickerAPI: LarkAPI, StickerAPI {

    func fetchStickers() -> Observable<[RustPB.Im_V1_Sticker]> {
        let request = RustPB.Im_V1_GetCustomizedStickersRequest()
        return client.sendAsyncRequest(request, transform: { (response: RustPB.Im_V1_GetCustomizedStickersResponse) -> [RustPB.Im_V1_Sticker] in
            return response.stickers
        }).subscribeOn(scheduler)
    }

    func addStickerImages(_ imagePaths: [String]) -> Observable<UploadStickerResult> {
        var request = RustPB.Im_V1_CreateCustomizedStickersRequest()
        request.type = .imagePath
        request.imagePaths = imagePaths
        return client.sendAsyncRequest(request, transform: { (response: RustPB.Im_V1_CreateCustomizedStickersResponse) -> UploadStickerResult in
            let succesedPaths = imagePaths.filter { !response.failedPaths.contains($0) }
            return UploadStickerResult(succesedPaths: succesedPaths, failedPaths: response.failedPaths)
        }).subscribeOn(scheduler)
    }

    func addStickers(_ stickers: [RustPB.Im_V1_Sticker]) -> Observable<[RustPB.Im_V1_Sticker]> {
        var request = RustPB.Im_V1_CreateCustomizedStickersRequest()
        request.type = .key
        request.stickers = stickers
        return client.sendAsyncRequest(request, transform: { (_: RustPB.Im_V1_CreateCustomizedStickersResponse) -> [RustPB.Im_V1_Sticker] in
            return stickers
        }).subscribeOn(scheduler)
    }

    func deleteStickers(_ stickers: [RustPB.Im_V1_Sticker]) -> Observable<[RustPB.Im_V1_Sticker]> {
        var request = RustPB.Im_V1_DeleteCustomizedStickersRequest()
        request.stickers = stickers
        return client.sendAsyncRequest(request, transform: { (response: RustPB.Im_V1_DeleteCustomizedStickersResponse) -> [RustPB.Im_V1_Sticker] in
            return response.stickers
        }).subscribeOn(scheduler)
    }

    func patchStickers(_ stickers: [RustPB.Im_V1_Sticker]) -> Observable<[RustPB.Im_V1_Sticker]> {
        var request = RustPB.Im_V1_UpdateCustomizedStickersRequest()
        request.stickers = stickers
        return client.sendAsyncRequest(request, transform: { (response: RustPB.Im_V1_UpdateCustomizedStickersResponse) -> [RustPB.Im_V1_Sticker] in
            return response.stickers
        }).subscribeOn(scheduler)
    }

    func fetchStickerSets(type: RustPB.Im_V1_GetStickerSetsStoreRequest.FilterType, count: Int32, position: Int32) -> Observable<StickerSetResult> {
        var request = RustPB.Im_V1_GetStickerSetsStoreRequest()
        request.type = type
        request.count = count
        request.position = position
        return client.sendAsyncRequest(request, transform: { (response: RustPB.Im_V1_GetStickerSetsStoreResponse) -> StickerSetResult in
            return StickerSetResult(stickerSets: response.stickerSets, hasMore: response.hasMore_p, lastPosition: response.position)
        }).subscribeOn(scheduler)
    }

    func fetchUserStickerSets() -> Observable<[RustPB.Im_V1_StickerSet]> {
        let request = RustPB.Im_V1_GetStickerSetsRequest()
        return client.sendAsyncRequest(request, transform: { (response: RustPB.Im_V1_GetStickerSetsResponse) -> [RustPB.Im_V1_StickerSet] in
            return response.stickerSets
        }).subscribeOn(scheduler)
    }

    func fetchStickerSetsBy(ids: [String]) -> Observable<[String: RustPB.Im_V1_StickerSet]> {
        var request = RustPB.Im_V1_GetStickerSetsByIDRequest()
        request.stickerSetsIds = ids
        return client.sendAsyncRequest(request, transform: { (response: RustPB.Im_V1_GetStickerSetsByIDResponse) -> ([String: RustPB.Im_V1_StickerSet]) in
            var stickerSets: [String: Im_V1_StickerSet] = response.stickerSets
            for item in response.visibility where item.value == false {
                stickerSets.removeValue(forKey: item.key)
            }
            return stickerSets
        }).subscribeOn(scheduler)
    }

    func addStickerSets(ids: [String]) -> Observable<Void> {
        var request = RustPB.Im_V1_PutStickerSetsRequest()
        request.stickerSetIds = ids
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func deleteStickerSets(ids: [String]) -> Observable<Void> {
        var request = RustPB.Im_V1_DeleteStickerSetsRequest()
        request.stickerSetIds = ids
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func patchStickerSets(ids: [String]) -> Observable<Void> {
        var rank = RustPB.Im_V1_PatchStickerSetsRequest.Rank()
        rank.stickerSetIds = ids
        var request = RustPB.Im_V1_PatchStickerSetsRequest()
        request.rank = rank
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func downloadStickerSetArchive(key: String, path: String, url: String) -> Observable<Void> {
        var request = RustPB.Media_V1_DownloadStickerSetArchiveRequest()
        request.key = key
        request.url = url
        request.path = path
        request.unzipPath = path
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func getStickerSetArchiveDownloadState(stickerSetIds: [String], path: String) -> Observable<[String: RustPB.Media_V1_GetStickerSetArchiveDownloadStateResponse.State]> {
        var request = RustPB.Media_V1_GetStickerSetArchiveDownloadStateRequest()
        request.stickerSetIds = stickerSetIds
        request.path = path
        return client.sendAsyncRequest(request, transform: { (response: RustPB.Media_V1_GetStickerSetArchiveDownloadStateResponse)
            -> [String: RustPB.Media_V1_GetStickerSetArchiveDownloadStateResponse.State] in
            return response.states
        }).subscribeOn(scheduler)
    }

    func sendShareStickerSet(stickerSetID: String, chatID: String) -> Observable<Void> {
        var request = RustPB.Im_V1_SendShareStickerSetRequest()
        request.stickerSetID = stickerSetID
        request.chatID = chatID
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }
}
