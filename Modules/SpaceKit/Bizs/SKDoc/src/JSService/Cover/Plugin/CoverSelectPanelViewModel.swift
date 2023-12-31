//
//  CoverSelectPanelViewModel.swift
//  SKDoc
//
//  Created by lizechuang on 2021/1/29.
//

import Foundation
import SKFoundation
import SKCommon
import RxSwift
import RxCocoa
import Photos
import Kingfisher
import SKResource
import ByteWebImage
import UniverseDesignToast
import SpaceInterface
import SKInfra

public final class CoverSelectPanelViewModel {

    public struct Input {
        public let initialize = PublishRelay<()>() // 加载图片列表token
        public let didSelectOfficialCoverPhoto = PublishSubject<(OfficialCoverPhotoInfo?, String?)>()
        public let randomSelectOfficialCoverPhoto = PublishSubject<(OfficialCoverPhotosSeries?)>() // 用户主动在封面选择页点击随机按钮
        public let autoRandomSelectOfficialCoverPhoto = PublishSubject<(OfficialCoverPhotosSeries?)>() // 用户在正文点击封面选择按钮,自动选择随机封面
        public let didTakeLocalCoverPhoto = PublishSubject<UIImage>()
        public let didSelectLocalCoverPhoto = PublishSubject<(selectedAsset: PHAsset, isOriginal: Bool)>()
    }

    struct Output {
        let initialDataDriver: Driver<OfficialCoverPhotosSeries>
        let submitDataDriver: Driver<()>
        let initialDataFailed: Driver<Error>
    }

    let netWorkAPI: OfficialCoverPhotosNetWorkAPI

    private var _initialDataDriver: Driver<OfficialCoverPhotosSeries>!
    private var _submitDataDriver = PublishRelay<()>()
    private var _initialDataFailed = PublishRelay<Error>()
    public let input: Input
    var output: Output {
        return Output(initialDataDriver: _initialDataDriver,
                      submitDataDriver: _submitDataDriver.asDriver(onErrorJustReturn: ()),
                      initialDataFailed: _initialDataFailed.asDriver(onErrorJustReturn: OfficialCoverPhotosProviderError.fetchOfficialPhotosDataError))
    }

    let sourceDocumentInfo: SourceDocumentInfo
    var selectCoverInfo: SelectCoverInfo?
    weak var model: BrowserModelConfig?
    let bag = DisposeBag()

    var hadSelectCover: Bool {
        return selectCoverInfo != nil
    }

    lazy private var newCacheAPI = DocsContainer.shared.resolve(NewCacheAPI.self)!

    weak var hostView: UIView?

    init(netWorkAPI: OfficialCoverPhotosNetWorkAPI,
         sourceDocumentInfo: SourceDocumentInfo,
         selectCoverInfo: SelectCoverInfo? = nil,
         model: BrowserModelConfig? = nil) {
        self.netWorkAPI = netWorkAPI
        self.sourceDocumentInfo = sourceDocumentInfo
        self.selectCoverInfo = selectCoverInfo
        self.input = Input()
        self.model = model
        setupDataStream()
    }

    private func setupDataStream() {
        // 首次进入加载数据
        let initialize = input.initialize.flatMap { [weak self] (_) -> Observable<OfficialCoverPhotosSeries> in
            guard let self = self else { return .empty() }
            let parmas: [String: Any] = ["obj_token": self.sourceDocumentInfo.objToken, "obj_type": self.sourceDocumentInfo.objType]
            return self.netWorkAPI.fetchOfficialCoverPhotosTokenWith(parmas).debug("cover - initialize").catchError { [weak self] (error) -> Observable<OfficialCoverPhotosSeries> in
                DocsLogger.info("CoverSelectPanelViewModel, 获取图片数据失败")
                self?._initialDataFailed.accept(error)
                return .never()
            }
        }.share()
        
        _initialDataDriver = initialize.asDriver(onErrorJustReturn: OfficialCoverPhotosSeries())

        input.didSelectOfficialCoverPhoto
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (info, sourceSeries) in
                guard let self = self else {
                    return
                }
                var parmas: [String: Any]?
                if let info = info, let sourceSeries = sourceSeries {
                    parmas = ["token": info.token,
                              "type": 1,
                              "coverSource": CoverPhotoSource.gallery.rawValue,
                              "series": sourceSeries,
                              "contentType": info.mimeType]
                }
                self.model?.jsEngine.callFunction(DocsJSCallBack.setCover, params: parmas, completion: nil)
                self._submitDataDriver.accept(())
            }).disposed(by: bag)

        input.randomSelectOfficialCoverPhoto
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (series) in
                guard let self = self else {
                    return
                }
                self.handleRandomSelectOfficialCoverPhotoWith(series: series, isAuto: false)
            }).disposed(by: bag)

        input.autoRandomSelectOfficialCoverPhoto
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (series) in
                guard let self = self else {
                    return
                }
                self.handleRandomSelectOfficialCoverPhotoWith(series: series, isAuto: true)
            }).disposed(by: bag)

        input.didTakeLocalCoverPhoto
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (photo) in
                guard let self = self else {
                    return
                }
                self.handleTakeLocalCoverPhoto(photo)
            }).disposed(by: bag)

        input.didSelectLocalCoverPhoto
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (result) in
                guard let self = self else {
                    return
                }
                self.handleSelectLocalCoverPhoto(result)
            }).disposed(by: bag)
    }
}

// MARK: - Local Select
extension CoverSelectPanelViewModel {
    func handleTakeLocalCoverPhoto(_ image: UIImage) {
        let image = image.sk.fixOrientation()
        let imageInfo = SkPickImagePreInfo(image: image, oriData: nil, picFormat: ImageFormat.unknown)
        jsInsertImage([imageInfo], isOriginal: false, extraParams: ["coverSource": CoverPhotoSource.takePhoto.rawValue])
    }
    func handleSelectLocalCoverPhoto(_ result: (selectedAsset: PHAsset, isOriginal: Bool)) {
        SKPickImageUtil.handleImageAsset(assets: [result.selectedAsset], original: result.isOriginal, token: PSDATokens.DocX.cover_replace_image_click_upload) { [weak self] info in
            if let info {
                self?.jsInsertImage(info, isOriginal: result.isOriginal)
            } else {
                DocsLogger.info("pickMedia: cover, reachMaxSize")
                self?.showFailedTips(BundleI18n.SKResource.CreationMobile_Docs_DocCover_ExceedFileSize_Toast)
            }
        }
    }

    func showFailedTips(_ text: String) {
        DispatchQueue.main.async {
            guard let hostView = self.hostView else {
                return
            }
            UDToast.showFailure(with: text, on: hostView)
        }
    }

    private func jsInsertImage(_ images: [SkPickImagePreInfo], isOriginal: Bool, extraParams: [String: Any]? = nil) {
        var imageInfos: [String] = []
        let queue = DispatchQueue(label: "com.docs.jsinsertImage")
        queue.async {
            let transformImageInfos = SKPickImageUtil.getTransformImageInfo(images, isOriginal: isOriginal)
            guard transformImageInfos.count > 0, let transformInfo = transformImageInfos.first else {
                DocsLogger.info("jsInsertImages, 上传图片信息为空", component: LogComponents.pickImage)
                return
            }
            self.newCacheAPI.storeImage(transformInfo.resultData, token: self.sourceDocumentInfo.objToken, forKey: transformInfo.cacheKey, needSync: true)
            let assetInfo = SKAssetInfo(objToken: self.sourceDocumentInfo.objToken,
                                        uuid: transformInfo.uuid, cacheKey: transformInfo.cacheKey,
                                        fileSize: transformInfo.dataSize,
                                        assetType: SKPickContentType.image.rawValue)
            self.newCacheAPI.updateAsset(assetInfo)
            let infoString = self.makeImageInfoParas(transformInfo)
            _ = infoString.map { imageInfos.append($0) }
            DispatchQueue.main.async {
                if let paramDic = self.makeResJson(images: imageInfos, code: 0, type: 2, extraParams: extraParams) {
                    self.model?.jsEngine.callFunction(DocsJSCallBack.setCover, params: paramDic, completion: nil)
                    self._submitDataDriver.accept(())
                }
            }
        }
    }

    private func makeImageInfoParas(_ transformInfo: SkPickImageTransformInfo) -> String? {
        let res = ["uuid": transformInfo.uuid,
                   "contentType": transformInfo.contentType ?? "",
                   "src": transformInfo.srcUrl,
                   "width": "\(transformInfo.width)px",
                   "height": "\(transformInfo.height)px"] as [String: Any]
        return res.jsonString
    }

    private func makeResJson(images imageArr: [String], code: Int, type: Int, extraParams: [String: Any]? = nil) -> [String: Any]? {
        var params = ["code": code,
                      "thumbs": imageArr,
                      "type": type] as [String: Any]
        params.merge(other: extraParams)
        return params
    }
}

// MARK: - Random Select
extension CoverSelectPanelViewModel {
    func handleRandomSelectOfficialCoverPhotoWith(series: OfficialCoverPhotosSeries?, isAuto: Bool) {
        guard let officialSeries = series, !officialSeries.isEmpty else {
            DocsLogger.info("RandomSelectOfficialCoverPhoto, officialSeries empty")
            return
        }
        let seriesRandomCount = Int.randomIntNumber(lower: 0, upper: officialSeries.count)
        let photoRandomCount = Int.randomIntNumber(lower: 0, upper: officialSeries[seriesRandomCount].infos.count)
        let selectPhotoInfo = officialSeries[seriesRandomCount].infos[photoRandomCount]
        let sourceSeries = officialSeries[seriesRandomCount].display.seriesId
        let parmas: [String: Any] = ["token": selectPhotoInfo.token,
                                     "type": 1,
                                     "coverSource": CoverPhotoSource.random.rawValue,
                                     "series": sourceSeries,
                                     "contentType": selectPhotoInfo.mimeType]
        if isAuto {
            self.model?.jsEngine.callFunction(DocsJSCallBack.autoSetRandomCover, params: parmas, completion: nil)
        } else {
            self.model?.jsEngine.callFunction(DocsJSCallBack.setCover, params: parmas, completion: nil)
            self._submitDataDriver.accept(())
        }
        
    }
}


// swiftlint:disable legacy_random
private extension Int {
    /// Int类型随机函数
    /// - Parameters:
    ///   - lower: 内置为 0，可根据自己要获取的随机数进行修改。
    ///   - upper: 内置为 UInt32.max 的最大值，这里防止转化越界，造成的崩溃。
    static func randomIntNumber(lower: Int = 0, upper: Int = Int(UInt32.max)) -> Int {
        return lower + Int(arc4random_uniform(UInt32(upper - lower)))
    }
}
