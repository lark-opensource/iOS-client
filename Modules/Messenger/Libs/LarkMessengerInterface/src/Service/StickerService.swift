//
//  StickerService.swift
//  LarkInterface
//
//  Created by lichen on 2018/8/7.
//

import Foundation
import UIKit
import LarkModel
import RxCocoa
import RxSwift
import LarkSDKInterface
import RustPB
import ByteWebImage

//描述表情包的本地下载状态
public enum EmotionDownloadState {
    case notDownload
    case userTrigerDownload
    case readyDownload
    case downloading(percent: Double)
    case downloaded
    case fail
}
//描述表情包的状态
public struct EmotionStickerSetState {
    public var hasAdd: Bool //表示当前用户是否添加到该表情
    public var downloadState: EmotionDownloadState
    public init(hasAdd: Bool, downloadState: EmotionDownloadState) {
        self.hasAdd = hasAdd
        self.downloadState = downloadState
    }
}

public protocol StickerService {
    typealias UnableResult = String

    var stickersObserver: BehaviorRelay<[RustPB.Im_V1_Sticker]> { get }
    var stickers: [RustPB.Im_V1_Sticker] { get }

    var stickerSetsObserver: BehaviorRelay<[RustPB.Im_V1_StickerSet]> { get }
    var stickerSets: [RustPB.Im_V1_StickerSet] { get }

    var sendImageProcessor: SendImageProcessor { get }

    func checkNewStickerEnable(newCount: Int) -> UnableResult?
    func checkNewStickerEnable(datas: [Data]) -> UnableResult?
    func checkNewStickerEnable(keys newAddedKeys: [String]) -> UnableResult?

    func stickerSetDownloadPath() -> String

    func uploadStickers(imageDatas: [Data], from vc: UIViewController?) -> Observable<Void>
    func uploadStickers(_ stickers: [RustPB.Im_V1_Sticker]) -> Observable<[RustPB.Im_V1_Sticker]>
    func patchStickers(stickers: [RustPB.Im_V1_Sticker]) -> Observable<[RustPB.Im_V1_Sticker]>
    func deleteStickers(stickers: [RustPB.Im_V1_Sticker]) -> Observable<[RustPB.Im_V1_Sticker]>

    func fetchStickerSets(type: RustPB.Im_V1_GetStickerSetsStoreRequest.FilterType, count: Int32, position: Int32) -> Observable<StickerSetResult>
    func addStickerSets(sets: [RustPB.Im_V1_StickerSet]) -> Observable<Void>
    func deleteStickerSet(stickerSetID: String) -> Observable<Void>
    func patchStickerSets(ids: [String]) -> Observable<Void>
    func downloadStickerSetArchive(key: String, path: String, url: String) -> Observable<Void>
    func getStickerSetArchiveDownloadState(stickerSetIds: [String], path: String) -> Observable<[String: RustPB.Media_V1_GetStickerSetArchiveDownloadStateResponse.State]>
    func sendShareStickerSet(stickerSetID: String, chatID: String) -> Observable<Void>

    func getDownloadState(for stickerSet: RustPB.Im_V1_StickerSet) -> Observable<EmotionStickerSetState>
    func addEmotionPackage(for stickerSet: RustPB.Im_V1_StickerSet)
    func getStickerSet(stickerSetID: String) -> Observable<RustPB.Im_V1_StickerSet?>
}
