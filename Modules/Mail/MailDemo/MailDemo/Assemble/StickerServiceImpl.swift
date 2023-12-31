//
//  StickerServiceImpl.swift
//  MailDemo
//
//  Created by tanghaojin on 2021/8/17.
//

//import Foundation
//import ByteWebImage
//import RxSwift
//import LarkSDKInterface
//import RustPB
//import LarkCore
//import LarkMessengerInterface
//import RxCocoa
//import AppReciableSDK

//class SendImageProcessorImp : SendImageProcessor {
//    func resultFormat(sourceFormat: ImageCodeType, useOrigin: Bool) -> ImageCodeType {
//        return sourceFormat
//    }
//
//    func process(source: ImageProcessSourceType, destPixel: Int, compressRate: Float, scene: Scene) -> ImageProcessResult? {
//        return nil
//    }
//
//    func process(source: ImageProcessSourceType, useOrigin justTranscode: Bool) -> ImageProcessResult? {
//        return nil
//    }
//    func process(source: ImageProcessSourceType, useOrigin: Bool, scene: Scene) -> ImageProcessResult? {
//        return nil
//    }
//
//    // 压缩+转码
//    func process(source: ImageProcessSourceType, option: ImageProcessOptions, scene: Scene) -> ImageProcessResult? {
//        return nil
//    }
//
//    func resultFormat(sourceFormat: ImageCodeType, option: ImageProcessOptions) -> ImageCodeType {
//        return sourceFormat
//    }
//}

//class StickerServiceImpl {
//    typealias UnableResult = String
//
//    var stickersObserver: BehaviorRelay<[RustPB.Im_V1_Sticker]> = BehaviorRelay<[RustPB.Im_V1_Sticker]>(value: [])
//    var stickers: [RustPB.Im_V1_Sticker] = []
//
//    var stickerSetsObserver: BehaviorRelay<[RustPB.Im_V1_StickerSet]> = BehaviorRelay<[RustPB.Im_V1_StickerSet]>(value: [])
//    var stickerSets: [RustPB.Im_V1_StickerSet] = []
//
////    var sendImageProcessor: SendImageProcessor = SendImageProcessorImp()
//
//    func checkNewStickerEnable(newCount: Int) -> UnableResult? {
//        return nil
//    }
//    func checkNewStickerEnable(datas: [Data]) -> UnableResult? {
//        return nil
//    }
//    func checkNewStickerEnable(keys newAddedKeys: [String]) -> UnableResult? {
//        return nil
//    }
//
//    func stickerSetDownloadPath() -> String {
//        return ""
//    }
//
//    func fetchStickers() {}
//
//    func uploadStickers(imageDatas: [Data], from vc: UIViewController?) -> Observable<Void> {
//        return Observable.empty()
//    }
//    func uploadStickers(_ stickers: [RustPB.Im_V1_Sticker]) -> Observable<[RustPB.Im_V1_Sticker]> {
//        return Observable.empty()
//    }
//    func patchStickers(stickers: [RustPB.Im_V1_Sticker]) -> Observable<[RustPB.Im_V1_Sticker]> {
//        return Observable.empty()
//    }
//    func deleteStickers(stickers: [RustPB.Im_V1_Sticker]) -> Observable<[RustPB.Im_V1_Sticker]> {
//        return Observable.empty()
//    }
//
//    func fetchStickerSets(type: RustPB.Im_V1_GetStickerSetsStoreRequest.FilterType, count: Int32, position: Int32) -> Observable<StickerSetResult> {
//        return Observable.empty()
//    }
//    func addStickerSets(sets: [RustPB.Im_V1_StickerSet]) -> Observable<Void> {
//        return Observable.empty()
//    }
//    func deleteStickerSet(stickerSetID: String) -> Observable<Void> {
//        return Observable.empty()
//    }
//    func patchStickerSets(ids: [String]) -> Observable<Void> {
//        return Observable.empty()
//    }
//    func downloadStickerSetArchive(key: String, path: String, url: String) -> Observable<Void> {
//        return Observable.empty()
//    }
//    func getStickerSetArchiveDownloadState(stickerSetIds: [String], path: String) -> Observable<[String: RustPB.Media_V1_GetStickerSetArchiveDownloadStateResponse.State]> {
//        return Observable.empty()
//    }
//    func sendShareStickerSet(stickerSetID: String, chatID: String) -> Observable<Void> {
//        return Observable.empty()
//    }
//
//    func getDownloadState(for stickerSet: RustPB.Im_V1_StickerSet) -> Observable<EmotionStickerSetState> {
//        return Observable.empty()
//    }
//    func addEmotionPackage(for stickerSet: RustPB.Im_V1_StickerSet) {
//
//    }
//    func getStickerSet(stickerSetID: String) -> Observable<RustPB.Im_V1_StickerSet?> {
//        return Observable.empty()
//    }
//}
