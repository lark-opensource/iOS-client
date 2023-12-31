//
//  StickerServiceImpl.swift
//  Lark
//
//  Created by lichen on 2017/11/20.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkFoundation
import LarkModel
import LKCommonsLogging
import EENavigator
import LarkAlertController
import Reachability
import LarkSDKInterface
import LarkSendMessage
import LarkMessengerInterface
import ThreadSafeDataStructure
import LarkContainer
import LarkFeatureGating
import LarkAccountInterface
import LarkStorage
import RustPB
import ByteWebImage
import LarkRustClient
import LarkEmotion
import LarkSetting

final class StickerServiceImpl: StickerService, UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(StickerServiceImpl.self, category: "Module.Sticker")

    let scheduler = SerialDispatchQueueScheduler(qos: .background)

    /// 权限管控服务
    @ScopedInjectedLazy var chatSecurityControlService: ChatSecurityControlService?

    func checkNewStickerEnable(newCount: Int) -> UnableResult? {
        if self.stickers.count + newCount > 1000 {
            return BundleI18n.LarkChat.Lark_Legacy_StickerNumberLimit
        }

        return nil
    }

    func checkNewStickerEnable(datas: [Data]) -> UnableResult? {
        if let error = self.checkNewStickerEnable(newCount: datas.count) {
            return error
        }

        for data in datas {
            if data.count > 5 * 1024 * 1024 {
                return BundleI18n.LarkChat.Lark_Legacy_StickerDataSizeLimit
            }

            var i: UIImage?
            switch data.lf.fileFormat() {
            case FileFormat.image(.gif):
                i = UIImage.lu.animated(with: data, scale: UIScreen.main.scale)
            default:
                i = UIImage(data: data, scale: UIScreen.main.scale)
            }

            guard let image = i else { return BundleI18n.LarkChat.Lark_Legacy_StickerImageTypeLimit }

            if (image.size.width * image.size.height) > (2000 * 2000) {
                return BundleI18n.LarkChat.Lark_Legacy_StickerImageSizeLimit
            }
        }

        return nil
    }

    func checkNewStickerEnable(keys newAddedKeys: [String]) -> UnableResult? {
        if let error = self.checkNewStickerEnable(newCount: newAddedKeys.count) {
            return error
        }
        let stickerKeys = self.stickers.map({ (sticker) -> String in
            return sticker.image.origin.key
        })
        let stickerKeySet = Set(stickerKeys)
        let newAddedKeySet = Set(newAddedKeys)
        if !stickerKeySet.isDisjoint(with: newAddedKeySet) {
            return BundleI18n.LarkChat.Lark_Legacy_StickerStickerHasAdded
        }
        return nil
    }

    private let disposeBag = DisposeBag()
    private var isStickerLoading: Bool = false
    private var isStickerLoadError: Bool = true
    private var isStickerSetLoading: Bool = false
    private var isStickerSetLoadError: Bool = true

    @ScopedInjectedLazy private var fgService: FeatureGatingService?
    private lazy var optimizeEnable: Bool = fgService?.staticFeatureGatingValue(with: "messenger.sticker.api_optimize") ?? false

    private var stickerLoading: Bool = false
    private var stickerLoaded: Bool = false

    var stickersObserver: BehaviorRelay<[RustPB.Im_V1_Sticker]> = BehaviorRelay<[RustPB.Im_V1_Sticker]>(value: [])
    var stickers: [RustPB.Im_V1_Sticker] {
        if self.optimizeEnable {
            self.fetchStickerIfNeeded()
        } else {
            if !self.stickerLoaded {
                self.fetchStickers()
            }
        }
        return stickersObserver.value
    }

    var stickerSetsObserver: BehaviorRelay<[RustPB.Im_V1_StickerSet]> = BehaviorRelay<[RustPB.Im_V1_StickerSet]>(value: [])
    var stickerSets: [RustPB.Im_V1_StickerSet] {
        if self.optimizeEnable {
            self.fetchStickerSetIfNeeded()
        } else {
            if !self.stickerLoaded {
                self.fetchStickers()
            }
        }
        return stickerSetsObserver.value
    }

    private let stickerAPI: StickerAPI
    @ScopedInjectedLazy private var progressService: ProgressService?
    private let pushCenter: PushNotificationCenter

    private var stateDict: SafeDictionary<String, BehaviorSubject<EmotionStickerSetState>> = [:] + .readWriteLock
    private var stickerSetPath = LarkImageService.shared.stickerSetDownloadPath
    let sendImageProcessor: SendImageProcessor
    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        sendImageProcessor = try userResolver.resolve(assert: SendImageProcessor.self)
        stickerAPI = try userResolver.resolve(assert: StickerAPI.self)
        pushCenter = try userResolver.userPushCenter
        // 监听push
        pushCenter.observable(for: PushStickers.self)
        .map({ [weak self] (push) -> [RustPB.Im_V1_Sticker] in
            var stickers = self?.stickers ?? []

            //log
            let message = "stickermanager receive pushStickers: operation:\(push.operation.rawValue),content:\(push.stickers.map { $0.stickerID })"
            StickerServiceImpl.logger.info(message)

            switch push.operation {
            case .add:
                let newStickers = push.stickers.filter { (sticker) -> Bool in
                    return !stickers.contains(where: { $0.stickerID == sticker.stickerID })
                }
                switch push.addDirection {
                case .head:
                    stickers.insert(contentsOf: newStickers, at: 0)
                case .tail:
                    stickers.append(contentsOf: newStickers)
                @unknown default:
                    break
                }
            case .delete:
                for sticker in push.stickers {
                    if let index = stickers.firstIndex(where: { (model) -> Bool in
                        return model.stickerID == sticker.stickerID
                    }) {
                        stickers.remove(at: index)
                    }
                }
            case .modify:
                stickers = push.stickers
            @unknown default:
                assert(false, "new value")
                break
            }
            return stickers
        })
        .subscribe(onNext: { [weak self] (stickers) in
            self?.stickersObserver.accept(stickers)

            //log
            let logMessage = "stickermanager refresh Data stickers: content:\(stickers.map { $0.stickerID })"
            StickerServiceImpl.logger.info(logMessage)

        }).disposed(by: disposeBag)

        pushCenter.observable(for: PushStickerSets.self)
            .map({ [weak self] (push) -> [RustPB.Im_V1_StickerSet] in
                var stickerSets = self?.stickerSets ?? []

                //log
                StickerServiceImpl.logger.info("stickermanager receive pushStickerSets: operation:\(push.operation.rawValue),content:\(stickerSets.map { $0.stickerSetID })")

                switch push.operation {
                case .add:
                    for pushStickerSet in push.stickerSets {
                        if !stickerSets.contains(where: { $0.stickerSetID == pushStickerSet.stickerSetID }) {
                            stickerSets.insert(pushStickerSet, at: 0)
                            StickerServiceImpl.logger.info("添加stickerSet:\(pushStickerSet.stickerSetID)")
                        }
                    }
                case .delete:
                    for set in push.stickerSets {
                        if let index = stickerSets.firstIndex(where: { (model) -> Bool in
                            return model.stickerSetID == set.stickerSetID
                        }) {
                            StickerServiceImpl.logger.info("删除stickerSet:\(stickerSets[index].stickerSetID)")
                            stickerSets.remove(at: index)
                        }
                    }
                case .reorder:
                    stickerSets = push.stickerSets
                case .unknown:
                    break
                @unknown default:
                    assert(false, "new value")
                    break
                }
                return stickerSets
            })
            .subscribe(onNext: { [weak self] (stickers) in
                self?.stickerSetsObserver.accept(stickers)
                //log
                StickerServiceImpl.logger.info("stickermanager refresh Data stickerSets, content:\(stickers.map { $0.stickerSetID })")
            }).disposed(by: disposeBag)

        // 目前已经没有预加载任务，所以第一次调用时加载表情包状态
        self.donwnloadEmotionPackageNeeded()

        listenStickerSetPush(with: pushCenter.observable(for: PushStickerSets.self))
    }

    func stickerSetDownloadPath() -> String {
        return self.stickerSetPath
    }

    func fetchStickers() {
        if self.stickerLoading {
            return
        }
        self.stickerLoading = true

        Observable.combineLatest(self.loadSticker(), self.loadStickerSets())
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.stickerLoaded = true
                self?.stickerLoading = false
            }, onError: { [weak self] (_) in
                self?.stickerLoading = false
            }).disposed(by: self.disposeBag)
    }

    private func fetchStickerIfNeeded() {
        if self.isStickerLoading || !self.isStickerLoadError {
            return
        }
        self.isStickerLoading = true
        self.loadSticker().subscribe { [weak self] stickers in
            self?.isStickerLoadError = stickers.isEmpty
            self?.isStickerLoading = false
            if stickers.isEmpty {
                StickerServiceImpl.logger.info("stickermanager, fetchStickers, stickers data is empty")
            }
        } onError: { [weak self] _ in
            self?.isStickerLoadError = true
            self?.isStickerLoading = false
        }.disposed(by: self.disposeBag)
    }

    private func fetchStickerSetIfNeeded() {
        if self.isStickerSetLoading || !self.isStickerSetLoadError {
            return
        }
        self.isStickerSetLoading = true
        self.loadStickerSets().subscribe { [weak self] _ in
            self?.isStickerSetLoadError = false
            self?.isStickerSetLoading = false
        } onError: { [weak self] _ in
            self?.isStickerSetLoadError = true
            self?.isStickerSetLoading = false
        }.disposed(by: self.disposeBag)
    }

    // nolint: duplicated_code - 非重复代码
    private func loadSticker() -> Observable<[RustPB.Im_V1_Sticker]> {
        let beginTime = CACurrentMediaTime()
        return stickerAPI.fetchStickers()
            .do(onNext: { [weak self] (stickers) in
                // 转成ms
                let time = (CACurrentMediaTime() - beginTime) * 1000
                // 获取自定义贴图表情
                EmotionTracker.trackerSlardar(event: "sticker_get_customized_stickers", time: time, category: [:], metric: [:], error: nil)
                EmotionTracker.trackerTea(event: Const.getCustomizedStickersEvent, time: time, extraParams: [Const.local: true], error: nil)
                self?.stickersObserver.accept(stickers)
                //log
                StickerServiceImpl.logger.info("stickermanager,fetchStickers,\(stickers.map { $0.stickerID })")
            }, onError: { (error) in
                // 转成ms
                let time = (CACurrentMediaTime() - beginTime) * 1000
                // 获取自定义贴图表情
                EmotionTracker.trackerSlardar(event: "sticker_get_customized_stickers", time: time, category: [:], metric: [:], error: error)
                EmotionTracker.trackerTea(event: Const.getCustomizedStickersEvent, time: time, extraParams: [Const.local: true], error: error)
                StickerServiceImpl.logger.error("加载服务端 sticker 失败", error: error)
            })
    }

    private func loadStickerSets() -> Observable<[RustPB.Im_V1_StickerSet]> {
        let beginTime = CACurrentMediaTime()
        return stickerAPI
            .fetchUserStickerSets()
            .do(onNext: { [weak self] (stickerSets) in
                // 转成ms
                let time = (CACurrentMediaTime() - beginTime) * 1000
                // 获取从商店下载的贴图表情
                EmotionTracker.trackerSlardar(event: "sticker_get_sticker_sets", time: time, category: [:], metric: [:], error: nil)
                EmotionTracker.trackerTea(event: Const.getStickersSetsEvent, time: time, extraParams: [:], error: nil)
                // log
                StickerServiceImpl.logger.info("stickermanager,loadStickerSets,\(stickerSets.map { $0.stickerSetID })")
                self?.stickerSetsObserver.accept(stickerSets)
            }, onError: { (error) in
                // 转成ms
                let time = (CACurrentMediaTime() - beginTime) * 1000
                // 获取从商店下载的贴图表情
                EmotionTracker.trackerSlardar(event: "sticker_get_sticker_sets", time: time, category: [:], metric: [:], error: error)
                EmotionTracker.trackerTea(event: Const.getStickersSetsEvent, time: time, extraParams: [:], error: error)
                StickerServiceImpl.logger.error("加载服务端 sticker set 失败", error: error)
            })
    }
    // enable-lint: duplicated_code

    func uploadStickers(imageDatas: [Data], from vc: UIViewController?) -> Observable<Void> {
        ChatTracker.trackAddSticker()

        return Observable<[String]>.create({ (observer) -> Disposable in
            // 把 image data 缓存在 沙盒
            let dir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "sticker"
            try? dir.createDirectoryIfNeeded()

            let imagePaths: [String] = imageDatas.compactMap({ (data) -> String? in
                let filePath = dir + UUID().uuidString
                do {
                    try filePath.createFile(with: data)
                    return filePath.absoluteString
                } catch {
                    StickerServiceImpl.logger.error("创建临时图片文件失败")
                    return nil
                }
            })
            observer.onNext(imagePaths)
            observer.onCompleted()
            return Disposables.create()
        })
        .observeOn(MainScheduler.instance)
        .flatMap({ (imagePaths) -> Observable<Void> in
            return self.uploadStickers(imagePaths: imagePaths, from: vc)
        })
    }

    func uploadStickers(_ stickers: [RustPB.Im_V1_Sticker]) -> Observable<[RustPB.Im_V1_Sticker]> {
        ChatTracker.trackAddSticker()
        // Slardar表情监控埋点
        let metric: [String: Any] = [
            "count": stickers.count
        ]
        let category: [String: Any] = [
            "source": "key"
        ]
        let beginTime = CACurrentMediaTime()
        return self.stickerAPI.addStickers(stickers)
            .observeOn(MainScheduler.instance)
            .do(onNext: { _ in
                // 转成ms
                let time = (CACurrentMediaTime() - beginTime) * 1000
                // 添加自定义贴图
                EmotionTracker.trackerSlardar(event: "sticker_add_customized_sticker", time: time, category: category, metric: metric, error: nil)
                EmotionTracker.trackerTea(event: Const.addCustomizedStickerEvent, time: time, extraParams: [Const.count: stickers.count, Const.source: Const.keySource], error: nil)
            }, onError: { [weak self] error in
                // 转成ms
                let time = (CACurrentMediaTime() - beginTime) * 1000
                // 添加自定义贴图
                EmotionTracker.trackerSlardar(event: "sticker_add_customized_sticker", time: time, category: category, metric: metric, error: error)
                EmotionTracker.trackerTea(event: Const.addCustomizedStickerEvent, time: time, extraParams: [Const.count: stickers.count, Const.source: Const.keySource], error: error)
                StickerServiceImpl.logger.error("upload stickers failed!!! error: \(error)")
                guard let self = self else { return }
                self.showAlertView(error: error)
            })
    }

    func patchStickers(stickers: [RustPB.Im_V1_Sticker]) -> Observable<[RustPB.Im_V1_Sticker]> {
        return self.stickerAPI.patchStickers(stickers)
            .observeOn(MainScheduler.instance)
            .do(onError: { (error) in
                StickerServiceImpl.logger.error("Patch stickers failed.", error: error)
            })
    }

    func deleteStickers(stickers: [RustPB.Im_V1_Sticker]) -> Observable<[RustPB.Im_V1_Sticker]> {
        ChatTracker.trackDeleteSticker()
        return self.stickerAPI.deleteStickers(stickers)
            .observeOn(MainScheduler.instance)
            .do(onError: { (error) in
                StickerServiceImpl.logger.error("Delete stickers failed.", error: error)
            })
    }

    func fetchStickerSets(type: RustPB.Im_V1_GetStickerSetsStoreRequest.FilterType, count: Int32, position: Int32) -> Observable<StickerSetResult> {
        return self.stickerAPI
            .fetchStickerSets(type: type, count: count, position: position)
            .observeOn(MainScheduler.instance)
            .do(onError: { (error) in
                StickerServiceImpl.logger.error(
                    "fetch stickers set failed.",
                    additionalData: ["type": "\(type)"],
                    error: error
                )
            })
    }

    func fetchStickerSetsBy(ids: [String]) -> Observable<[String: RustPB.Im_V1_StickerSet]> {
        return self.stickerAPI
            .fetchStickerSetsBy(ids: ids)
            .observeOn(MainScheduler.instance)
            .do(onError: { (error) in
                StickerServiceImpl.logger.error(
                    "fetch stickers set by id failed.",
                    error: error
                )
            })
    }

    func addStickerSets(sets: [RustPB.Im_V1_StickerSet]) -> Observable<Void> {
        return self.stickerAPI
            .addStickerSets(ids: sets.map { $0.stickerSetID })
            .observeOn(MainScheduler.instance)
            .do(onError: { (error) in
                StickerServiceImpl.logger.error("Add stickers set failed.", error: error)
            })
    }

    func deleteStickerSet(stickerSetID: String) -> Observable<Void> {
        return self.stickerAPI.deleteStickerSets(ids: [stickerSetID])
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] (_) in
                guard let self = self else { return }
                let stateSubject = self.stateDict[stickerSetID]
                if var state = try? stateSubject?.value(), let stateSubject = stateSubject {
                    state.hasAdd = false
                    stateSubject.onNext(state)
                }
            }, onError: { (error) in
                StickerServiceImpl.logger.error("Delete stickers set failed.", error: error)
            })
    }

    func patchStickerSets(ids: [String]) -> Observable<Void> {
        return self.stickerAPI
            .patchStickerSets(ids: ids)
            .observeOn(MainScheduler.instance)
            .do(onError: { (error) in
                StickerServiceImpl.logger.error("Patch stickers set failed.", error: error)
            })
    }

    func downloadStickerSetArchive(key: String, path: String, url: String) -> Observable<Void> {
        return self.stickerAPI.downloadStickerSetArchive(key: key, path: path, url: url)
            .observeOn(MainScheduler.instance)
            .do(onError: { (error) in
                StickerServiceImpl.logger.error("Patch stickers set failed.", error: error)
        })
    }

    func getStickerSetArchiveDownloadState(stickerSetIds: [String], path: String) -> Observable<[String: RustPB.Media_V1_GetStickerSetArchiveDownloadStateResponse.State]> {
        return self.stickerAPI.getStickerSetArchiveDownloadState(stickerSetIds: stickerSetIds, path: path)
              .observeOn(MainScheduler.instance)
              .do(onError: { (error) in
                  StickerServiceImpl.logger.error("get StickerSetArchiveDownloadState failed.", error: error)
          })
    }

    func sendShareStickerSet(stickerSetID: String, chatID: String) -> Observable<Void> {
        return self.stickerAPI.sendShareStickerSet(stickerSetID: stickerSetID, chatID: chatID)
              .observeOn(MainScheduler.instance)
              .do(onError: { (error) in
                  StickerServiceImpl.logger.error("Send ShareStickerSet failed.", error: error)
          })
    }

    private func uploadStickers(imagePaths: [String], from vc: UIViewController?) -> Observable<Void> {
        // Slardar表情监控埋点
        let metric: [String: Any] = [
            "count": imagePaths.count
        ]
        let category: [String: Any] = [
            "source": "imagePath"
        ]
        let beginTime = CACurrentMediaTime()
        return self.stickerAPI.addStickerImages(imagePaths)
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] (result) in
                // 转成ms
                let time = (CACurrentMediaTime() - beginTime) * 1000
                // 添加自定义贴图
                EmotionTracker.trackerSlardar(event: "sticker_add_customized_sticker", time: time, category: category, metric: metric, error: nil)
                EmotionTracker.trackerTea(event: Const.addCustomizedStickerEvent, time: time, extraParams: [Const.count: imagePaths.count, Const.source: Const.imagePathSource], error: nil)
                if !result.failedPaths.isEmpty {
                    self?.showAlertView(success: result.succesedPaths, failed: result.failedPaths, from: vc)
                }
            }, onError: { [weak self] (error) in
                // 转成ms
                let time = (CACurrentMediaTime() - beginTime) * 1000
                // 添加自定义贴图
                EmotionTracker.trackerSlardar(event: "sticker_add_customized_sticker", time: time, category: category, metric: metric, error: error)
                EmotionTracker.trackerTea(event: Const.addCustomizedStickerEvent, time: time, extraParams: [Const.count: imagePaths.count, Const.source: Const.imagePathSource], error: error)
                StickerServiceImpl.logger.error("upload stickers image failed.", error: error)

                guard let self = self,
                      let error = error.underlyingError as? APIError,
                      let interceptViewController = vc else { return }

                switch error.type {
                case .securityControlDeny(let message):
                    self.chatSecurityControlService?.authorityErrorHandler(event: .addSticker,
                                                                          authResult: nil,
                                                                          from: interceptViewController,
                                                                          errorMessage: message)
                case .strategyControlDeny: // 鉴权的策略引擎返回的报错，安全侧弹出弹框，端上做静默处理
                    break
                default: self.showAlertView(success: [], failed: imagePaths, from: interceptViewController)
                }
            }).flatMap({ (result) -> Observable<Void> in
                if result.succesedPaths.isEmpty {
                    return Observable<Void>.empty()
                } else {
                    return self.loadSticker()
                        .observeOn(MainScheduler.instance)
                        .map({ (_) -> Void in
                            return Void()
                        })
                }
            })
    }

    private func showAlertView(success: [String], failed: [String], from vc: UIViewController?) {
        guard let window = navigator.mainSceneWindow else {
            assertionFailure()
            return
        }

        if success.isEmpty && failed.count == 1 {
            self.showAlertView()
            return
        }
        let message = BundleI18n.LarkChat.Lark_Legacy_StickerUploadFailedMessage(success.count + failed.count, failed.count)
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkChat.Lark_Legacy_Hint)
        alertController.setContent(text: message)
        alertController.addCancelButton()
        alertController.addPrimaryButton(text: BundleI18n.LarkChat.Lark_Legacy_Retry, dismissCompletion: {
            [weak self] in
            self?.retryUpload(imagePaths: failed, from: vc)
        })
        navigator.present(alertController, from: window)
    }

    private func showAlertView(error: Error) {
        guard let window = navigator.mainSceneWindow else {
            assertionFailure()
            return
        }
        var errorMessage = BundleI18n.LarkChat.Lark_Legacy_StickerUploadNetErrorTip
        // rust给的error没有走transformToAPIError，导致这里的error不是APIError类型，应该在RustClient层统一进行处理
        if let wrappedError = error.transformToAPIError() as? WrappedError,
           let rcError = wrappedError.metaErrorStack.first(where: { $0 is RCError }) as? RCError {
            switch rcError {
            case .businessFailure(let errorInfo):
                errorMessage = errorInfo.displayMessage
            default:
                errorMessage = BundleI18n.LarkChat.Lark_Legacy_StickerUploadNetErrorTip
            }
        }
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkChat.Lark_Legacy_Hint)
        alertController.setContent(text: errorMessage)
        alertController.addPrimaryButton(text: BundleI18n.LarkChat.Lark_Legacy_LarkConfirm)
        navigator.present(alertController, from: window)
    }

    private func showAlertView() {
        guard let window = navigator.mainSceneWindow else {
            assertionFailure()
            return
        }
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkChat.Lark_Legacy_Hint)
        alertController.setContent(text: BundleI18n.LarkChat.Lark_Legacy_StickerUploadNetErrorTip)
        alertController.addPrimaryButton(text: BundleI18n.LarkChat.Lark_Legacy_LarkConfirm)
        navigator.present(alertController, from: window)
    }

    private func retryUpload(imagePaths: [String], from vc: UIViewController?) {
        self.uploadStickers(imagePaths: imagePaths, from: vc).subscribe().disposed(by: self.disposeBag)
    }

    //外部触发下载,会触发addStickerSets,然后根据本地文件状态决定是否触发下载文件逻辑
    func addEmotionPackage(for stickerSet: RustPB.Im_V1_StickerSet) {
        let downloadStateSubject = self.getDownloadStateSubject(for: stickerSet.stickerSetID)
        let state = EmotionStickerSetState(hasAdd: false, downloadState: .userTrigerDownload)
        downloadStateSubject.onNext(state)
        self.addStickerSets(sets: [stickerSet]).subscribe(onError: { (_) in
            let state = EmotionStickerSetState(hasAdd: false, downloadState: .fail)
            downloadStateSubject.onNext(state)
        }).disposed(by: self.disposeBag)
    }

    func getDownloadState(for stickerSet: RustPB.Im_V1_StickerSet) -> Observable<EmotionStickerSetState> {
        let stateSubject = self.getDownloadStateSubject(for: stickerSet.stickerSetID)
        return stateSubject.asObserver()
    }

    var disposeDict: SafeDictionary<String, DisposeBag> = [:] + .readWriteLock
    var reachability = Reachability()
}

// MARK: - 处理商店表情包下载逻辑
extension StickerServiceImpl {
    var isNetworkWift: Bool {
        switch reachability?.connection {
        case .wifi:
            return true
        default:
            return false
        }
    }

    //用户已经添加过,但是本地没有该表情包,开启自动刚下载,
    private func donwnloadEmotionPackageNeeded() {
        let stickerSetSubject = BehaviorSubject(value: [RustPB.Im_V1_StickerSet]())
        self.stickerAPI.fetchUserStickerSets()
            .subscribe(onNext: { [weak self] (sets) in
                guard let self = self else { return }
                stickerSetSubject.onNext(sets)
            }).disposed(by: self.disposeBag)

        stickerSetSubject.map { $0.map { $0.stickerSetID } }
        .flatMap({ [weak self] (ids) -> Observable<[String: RustPB.Media_V1_GetStickerSetArchiveDownloadStateResponse.State]> in
            guard let self = self else { return Observable.empty() }
            return self.getStickerSetArchiveDownloadState(stickerSetIds: ids, path: self.stickerSetPath)
        }).map { [weak self] (dicts) -> [String] in
            guard let self = self else { return [String]() }
            var ids = [String]()
            for dict in dicts {
                //在这里更新一下表情包的本地状态
                let state = EmotionStickerSetState(hasAdd: true, downloadState: (dict.value == .downloaded ? .downloaded : .notDownload))
                let stateSubject = self.getDownloadStateSubject(for: dict.key)
                stateSubject.onNext(state)
                if dict.value == .notDownloaded || dict.value == .partDownloaded {
                    ids.append(dict.key)
                }
            }
            return ids
        }.map { (ids) -> [RustPB.Im_V1_StickerSet] in
            guard let sets = try? stickerSetSubject.value() else { return [] }
            var list = [RustPB.Im_V1_StickerSet]()
            for id in ids {
                for set in sets where set.stickerSetID == id {
                    list.append(set)
                }
            }
            return list
        }.filter {
            !$0.isEmpty
        }.subscribe(onNext: { [weak self] (sets) in
            guard let self = self else { return }
            self.serialDownloadSets(with: sets)
        }).disposed(by: self.disposeBag)
    }

    func listenStickerSetPush(with pushStickerSets: Observable<PushStickerSets>) {
        pushStickerSets.subscribe(onNext: { [weak self] (push) in
            guard let self = self else { return }
            switch push.operation {
            case .add:
                for set in push.stickerSets {
                    self.downloadEmotionAfterAdded(with: set)
                }
            case .delete:
                for set in push.stickerSets {
                    self.disposeDict.removeValue(forKey: set.stickerSetID)
                    let stateSubject = self.stateDict[set.stickerSetID]
                    if var state = try? stateSubject?.value(), let stateSubject = stateSubject {
                        state.hasAdd = false
                        stateSubject.onNext(state)
                        self.stateDict[set.stickerSetID] = stateSubject
                    }
                }
            @unknown default:
                break
            }

        }).disposed(by: self.disposeBag)
    }

    //串行下载stickerSets,内部会递归调用
    private func serialDownloadSets(with stickerSets: [RustPB.Im_V1_StickerSet]) {
        guard !stickerSets.isEmpty else {
            return
        }
        // 并行下载最大数量
        let maxCount = 10
        // 记录表情包下载状态
        var stickerSetDownloadStateList: SafeArray<EmotionDownloadState> = [EmotionDownloadState](repeating: .notDownload, count: stickerSets.count) + .readWriteLock
        // 下载指定的stickerSet
        func downloadStickerSet(index: Int) {
            guard index < stickerSets.count, self.isNetworkWift else { return }
            let stickerSet = stickerSets[index]
            stickerSetDownloadStateList[index] = .downloading(percent: 0)
            self.downloadEmotionAfterAdded(with: stickerSet)
            let downloadStateSubject = self.getDownloadStateSubject(for: stickerSet.stickerSetID)
            downloadStateSubject.observeOn(self.scheduler)
                .filter { state in
                    // 上一个表情包完成或者失败才开启新的下载任务
                    switch state.downloadState {
                    case .downloaded, .fail:
                        // 由于同一个表情包下载完成回调可能出现多次，仅第一次才回开启新的下载任务
                        switch stickerSetDownloadStateList[index] {
                        case .downloading(percent: 0):
                            stickerSetDownloadStateList[index] = state.downloadState
                            return true
                        default:
                            return false
                        }
                    default:
                        return false
                    }
                }
                .subscribe(onNext: { _ in
                    // 找到下一个还未开始下载的stickerSet
                    for idx in index ..< stickerSetDownloadStateList.count {
                        switch stickerSetDownloadStateList[idx] {
                        case .notDownload:
                            if idx >= maxCount {
                                downloadStickerSet(index: idx)
                                return
                            }
                        default:
                            continue
                        }
                    }
            }).disposed(by: self.disposeBag)
        }
        // 开启下载
        for index in 0 ..< min(maxCount, stickerSets.count) {
            downloadStickerSet(index: index)
        }
    }

    //用户已经添加表情包后调用
    func downloadEmotionAfterAdded(with stickerSet: RustPB.Im_V1_StickerSet) {
        let downloadStateSubject = self.getDownloadStateSubject(for: stickerSet.stickerSetID)
        //根据状态返回是否存在磁盘
        let isExistInDisk: ([String: RustPB.Media_V1_GetStickerSetArchiveDownloadStateResponse.State]) -> Bool = { dicts in
            for dict in dicts where (dict.key == stickerSet.stickerSetID && dict.value == .downloaded) {
                return true
            }
            return false
        }

        self.getStickerSetArchiveDownloadState(stickerSetIds: [stickerSet.stickerSetID], path: self.stickerSetPath)
            .map(isExistInDisk)
            .flatMap { [weak self] (isExist) -> Observable<Void> in
                guard let self = self else { return Observable.empty() }
                if isExist {
                    let state = EmotionStickerSetState(hasAdd: true, downloadState: .downloaded)
                    downloadStateSubject.onNext(state)
                    return Observable.empty()
                } else {
                    //防止服务返回数据为空,记录一下
                    //prevent empty server data
                    //jira:https://jira.bytedance.com/browse/SUITE-55112
                    guard !stickerSet.archive.urls.isEmpty else {
                        StickerServiceImpl.logger.error("urls为空")
                        return Observable.empty()
                    }
                    return self.downloadStickerSetArchive(key: stickerSet.stickerSetID,
                                                          path: self.stickerSetPath,
                                                          url: stickerSet.archive.urls[0])
                }
            }.subscribe(onError: { (_) in
                downloadStateSubject.onNext(EmotionStickerSetState(hasAdd: true, downloadState: .fail))
            }, onCompleted: { [weak self] in
                guard let self = self else { return }
                self.subcribeDownloadProgress(with: stickerSet)
            }).disposed(by: self.disposeBag)
    }

    //订阅进度
    private func subcribeDownloadProgress(with stickerSet: RustPB.Im_V1_StickerSet) {
        let downloadStateSubject = self.getDownloadStateSubject(for: stickerSet.stickerSetID)
        let archiveDisposeBag = DisposeBag()
        disposeDict[stickerSet.stickerSetID] = archiveDisposeBag
        self.progressService?.value(key: stickerSet.stickerSetID).subscribe(onNext: { (progress) in
               if progress.fractionCompleted >= 1 {
                   downloadStateSubject.onNext(EmotionStickerSetState(hasAdd: true, downloadState: .downloaded))
               } else {
                   downloadStateSubject.onNext(EmotionStickerSetState(hasAdd: true, downloadState: .downloading(percent: progress.fractionCompleted)))
               }
        }).disposed(by: archiveDisposeBag)
    }

    private func getDownloadStateSubject(for stickerSetID: String) -> BehaviorSubject<EmotionStickerSetState> {
        if let stateSubject = stateDict[stickerSetID] {
            return stateSubject
        }
        let stateSubject = BehaviorSubject(value: EmotionStickerSetState(hasAdd: false, downloadState: .notDownload))
        stateDict[stickerSetID] = stateSubject
        return stateSubject
    }

    func getStickerSet(stickerSetID: String) -> Observable<RustPB.Im_V1_StickerSet?> {
        return self.fetchStickerSetsBy(ids: [stickerSetID]).map { (sets: [String: RustPB.Im_V1_StickerSet]) -> RustPB.Im_V1_StickerSet? in
            let set = sets.first(where: { (key: String, _: RustPB.Im_V1_StickerSet) -> Bool in
                key == stickerSetID
            })
            return set?.1
        }
    }
}

extension StickerServiceImpl {
    enum Const {
        static let getCustomizedStickersEvent: String = "sticker_get_customized_stickers"
        static let getStickersSetsEvent: String = "sticker_get_sticker_sets"
        static let addCustomizedStickerEvent: String = "sticker_add_customized_sticker"
        static let local: String = "local"
        static let source: String = "source"
        static let keySource: String = "key"
        static let imagePathSource: String = "imagePath"
        static let count: String = "count"
    }
}
