//
//  CoverSelectPanelViewModel.swift
//  SKDoc
//
//  Created by lizechuang on 2021/1/29.
//

import Foundation
import RxSwift
import RxCocoa
import Photos
import Kingfisher
import ByteWebImage
import UniverseDesignToast

struct CoverPickImagePreInfo {
    let image: UIImage?
    let oriData: Data?
    let picFormat: Kingfisher.ImageFormat
    init(image: UIImage?, oriData: Data?, picFormat: Kingfisher.ImageFormat) {
        self.image = image
        self.oriData = oriData
        self.picFormat = picFormat
    }
}

protocol CoverSelectPanelDelegate: AnyObject {
    func didFailToSelectCover()
    func didRemoveSelectedCover()
    func didSelectLocalCover(info: CoverPickImagePreInfo, source: CoverPhotoSource)
    func didSelectOfficialCover(info: OfficialCoverPhotoInfo, source: CoverPhotoSource)
}

class CoverSelectPanelViewModel {

    struct Input {
        let initialize = PublishRelay<()>() // 加载图片列表token
        let didSelectOfficialCoverPhoto = PublishSubject<(OfficialCoverPhotoInfo?, String?)>()
        let randomSelectOfficialCoverPhoto = PublishSubject<(OfficialCoverPhotosSeries?)>() // 用户主动在封面选择页点击随机按钮
        let autoRandomSelectOfficialCoverPhoto = PublishSubject<(OfficialCoverPhotosSeries?)>() // 用户在正文点击封面选择按钮,自动选择随机封面
//        let didTakeLocalCoverPhoto = PublishSubject<UIImage>()
//        let didSelectLocalCoverPhoto = PublishSubject<(selectedAsset: PHAsset, isOriginal: Bool)>()
    }

    struct Output {
        let initialDataDriver: Driver<OfficialCoverPhotosSeries>
        let submitDataDriver: Driver<()>
        let initialDataFailed: Driver<Error>
    }

    let networkAPI: OfficialCoverPhotosNetWorkAPI

    private var _initialDataDriver: Driver<OfficialCoverPhotosSeries>!
    private var _submitDataDriver = PublishRelay<()>()
    private var _initialDataFailed = PublishRelay<Error>()
    let input: Input
    var output: Output {
        return Output(initialDataDriver: _initialDataDriver,
                      submitDataDriver: _submitDataDriver.asDriver(onErrorJustReturn: ()),
                      initialDataFailed: _initialDataFailed.asDriver(onErrorJustReturn: OfficialCoverPhotosProviderError.fetchOfficialPhotosDataError))
    }

    var selectCoverInfo: SelectCoverInfo?
    let bag = DisposeBag()

    var hadSelectCover: Bool {
        return selectCoverInfo != nil
    }

    var enableSelectFromAlbum: Bool = false

    weak var hostView: UIView?

    var officialSeries: OfficialCoverPhotosSeries?
    var provider: MailSharedServicesProvider?
    private var initialRandomSub: Disposable?
    private(set) weak var delegate: CoverSelectPanelDelegate?

    init(networkAPI: OfficialCoverPhotosNetWorkAPI,
         delegate: CoverSelectPanelDelegate,
         provider: MailSharedServicesProvider?,
         selectCoverInfo: SelectCoverInfo? = nil) {
        self.networkAPI = networkAPI
        self.delegate = delegate
        self.selectCoverInfo = selectCoverInfo
        self.provider = provider
        self.input = Input()
        setupDataStream()
    }

    private func setupDataStream() {
        // 首次进入加载数据
        let initialize = input.initialize.flatMap { [weak self] (_) -> Observable<OfficialCoverPhotosSeries> in
            guard let self = self else { return .empty() }
            let parmas: [String: Any] = [:] // ["obj_token": self.sourceDocumentInfo.objToken, "obj_type": self.sourceDocumentInfo.objType]
            return self.networkAPI.fetchOfficialCoverPhotosTokenWith(parmas).debug("cover - initialize").catchError { [weak self] (error) -> Observable<OfficialCoverPhotosSeries> in
                MailLogger.info("CoverSelectPanelViewModel, 获取图片数据失败")
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
                if let info = info {
                    self.delegate?.didSelectOfficialCover(info: info, source: .gallery)
                    self._submitDataDriver.accept(())
                } else {
                    self.delegate?.didRemoveSelectedCover()
                }
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

//        input.didTakeLocalCoverPhoto
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext: { [weak self] (photo) in
//                guard let self = self else {
//                    return
//                }
//                self.handleTakeLocalCoverPhoto(photo)
//            }).disposed(by: bag)
//
//        input.didSelectLocalCoverPhoto
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext: { [weak self] (result) in
//                guard let self = self else {
//                    return
//                }
//                self.handleSelectLocalCoverPhoto(result)
//            }).disposed(by: bag)

    }
}

// MARK: - Local Select
//extension CoverSelectPanelViewModel {
//
//    func handleTakeLocalCoverPhoto(_ image: UIImage) {
//        let image = image.lu.fixOrientation()
//        let imageInfo = CoverPickImagePreInfo(image: image, oriData: nil, picFormat: .unknown)
//        delegate?.didSelectLocalCover(info: imageInfo, source: .takePhoto)
////        jsInsertImage([imageInfo], isOriginal: false, extraParams: ["coverSource": CoverPhotoSource.takePhoto.rawValue])
//    }
//    func handleSelectLocalCoverPhoto(_ result: (selectedAsset: PHAsset, isOriginal: Bool)) {
//        var reachMaxSize: Bool = false
//        var imageInfos: [CoverPickImagePreInfo] = [CoverPickImagePreInfo]()
//        let options = PHImageRequestOptions()
//        options.isSynchronous = true
//        options.isNetworkAccessAllowed = true
//        let sema = DispatchSemaphore(value: 0)
//        let asset = result.selectedAsset
//        PHImageManager.default().requestImageData(for: asset, options: options) { (data, _, _, _) in
//            guard let data = data else {
//                if #available(iOS 13.0, *) {
//                    sema.signal()
//                }
//                return
//            }
//            if data.count > 20 * 1024 * 1024 {
//                reachMaxSize = true
//            } else {
//                let picFormat = data.kf.imageFormat
//                if let image = asset.editImage ?? DefaultImageProcessor.default.process(item: .data(data), options: [])?.lu.fixOrientation() {
//                    imageInfos.append(CoverPickImagePreInfo(image: image, oriData: picFormat == .GIF ? data : nil, picFormat: picFormat))
//                }
//            }
//            if #available(iOS 13.0, *) {
//                sema.signal()
//            }
//        }
//        if #available(iOS 13.0, *) {
//            sema.wait()
//        }
//        if reachMaxSize {
//            MailLogger.info("pickMedia: cover, reachMaxSize")
//            // TODO: Kubrick
//            self.showFailedTips("封面大小超过最大值")
//        } else if let info = imageInfos.first {
//            delegate?.didSelectLocalCover(info: info, source: .album)
////            jsInsertImage(imageInfos, isOriginal: result.isOriginal, extraParams: ["coverSource": CoverPhotoSource.album.rawValue])
//        }
//    }
//
//    func showFailedTips(_ text: String) {
//        DispatchQueue.main.async {
//            guard let hostView = self.hostView else {
//                return
//            }
//            UDToast.showFailure(with: text, on: hostView)
//        }
//    }
//
//    private func jsInsertImage(_ images: [CoverPickImagePreInfo], isOriginal: Bool, extraParams: [String: Any]? = nil) {
//        //TODO: 后续支持从本地选择自定义封面时支持
////        var imageInfos: [String] = []
////        let queue = DispatchQueue(label: "com.docs.jsinsertImage")
////        queue.async {
////            let transformImageInfos = SKPickImageUtil.getTransformImageInfo(images, isOriginal: isOriginal)
////            guard transformImageInfos.count > 0, let transformInfo = transformImageInfos.first else {
////                MailLogger.info("jsInsertImages, 上传图片信息为空", component: LogComponents.pickImage)
////                return
////            }
////            self.newCacheAPI.storeImage(transformInfo.resultData, token: self.sourceDocumentInfo.objToken, forKey: transformInfo.cacheKey, needSync: true)
////            let assetInfo = SKAssetInfo(objToken: self.sourceDocumentInfo.objToken,
////                                        uuid: transformInfo.uuid, cacheKey: transformInfo.cacheKey,
////                                        fileSize: transformInfo.dataSize,
////                                        assetType: SKPickContentType.image.rawValue)
////            self.newCacheAPI.updateAsset(assetInfo)
////            let infoString = self.makeImageInfoParas(transformInfo)
////            _ = infoString.map { imageInfos.append($0) }
////            DispatchQueue.main.async {
////                if let paramDic = self.makeResJson(images: imageInfos, code: 0, type: 2, extraParams: extraParams) {
////                    self.model?.jsEngine.callFunction(DocsJSCallBack.setCover, params: paramDic, completion: nil)
////                    self._submitDataDriver.accept(())
////                }
////            }
////        }
//    }
//
////    private func makeImageInfoParas(_ transformInfo: SkPickImageTransformInfo) -> String? {
////        let res = ["uuid": transformInfo.uuid,
////                   "contentType": transformInfo.contentType ?? "",
////                   "src": transformInfo.srcUrl,
////                   "width": "\(transformInfo.width)px",
////                   "height": "\(transformInfo.height)px"] as [String: Any]
////        return res.jsonString
////    }
//
//    private func makeResJson(images imageArr: [String], code: Int, type: Int, extraParams: [String: Any]? = nil) -> [String: Any]? {
//        var params = ["code": code,
//                      "thumbs": imageArr,
//                      "type": type] as [String: Any]
//        params.merge(other: extraParams)
//        return params
//    }
//}

// MARK: - Random Select
extension CoverSelectPanelViewModel {
    func randomSelectPublicCoverPhoto() {
        if let series = officialSeries {
            input.autoRandomSelectOfficialCoverPhoto.onNext(series)
        } else {
            initialRandomSub = output.initialDataDriver.drive(onNext: {[weak self] (series) in
                guard let self = self else { return }
                self.officialSeries = series
                self.input.autoRandomSelectOfficialCoverPhoto.onNext(series)
                self.initialRandomSub?.dispose()
            })
            input.initialize.accept(())
        }
    }

    func handleRandomSelectOfficialCoverPhotoWith(series: OfficialCoverPhotosSeries?, isAuto: Bool) {
        guard let officialSeries = series, !officialSeries.isEmpty else {
            MailLogger.info("RandomSelectOfficialCoverPhoto, officialSeries empty")
            return
        }
        let seriesRandomCount = Int.randomIntNumber(lower: 0, upper: officialSeries.count)
        let photoRandomCount = Int.randomIntNumber(lower: 0, upper: officialSeries[seriesRandomCount].infos.count)

        guard let selectPhotoInfo = officialSeries[safe: seriesRandomCount]?.infos[safe: photoRandomCount] else {
            delegate?.didFailToSelectCover()
            mailAssertionFailure("Random cover out of bounds, seriesRandomCount: \(seriesRandomCount), photoRandomCount: \(photoRandomCount)")
            return
        }

        if isAuto {
            delegate?.didSelectOfficialCover(info: selectPhotoInfo, source: .random)
        } else {
            delegate?.didSelectOfficialCover(info: selectPhotoInfo, source: .random)
            _submitDataDriver.accept(())
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
