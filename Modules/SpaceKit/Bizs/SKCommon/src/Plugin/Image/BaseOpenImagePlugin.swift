//
//  BaseOpenImagePlugin.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/17.
//
// 图片查看器功能，仅支持查看/refresh，不支持评论

import SKFoundation
import LarkUIKit
import SpaceInterface
import RxSwift
import LarkAssetsBrowser
import SKUIKit
import ByteWebImage
import SKInfra

public struct SKBaseOpenImagePluginConfig {
    //swiftlint:disable identifier_name
    /// 图片查看器 VC 的type
    public var AssetBrowserVCType: SKAssetBrowserViewController.Type = SKAssetBrowserViewController.self
    //swiftlint:enable
    
    /// 处理图片查看器的动作
    public var actionHandlerGenerator: () -> SKAssetBrowserActionHandler = {
        return SKAssetBrowserActionHandler()
    }
    
    public let cacheService: SKImageCacheService
    
    public let fromSource: OpenImageFromSource
    
    public init(cacheServce: SKImageCacheService, from: OpenImageFromSource) {
        self.cacheService = cacheServce
        self.fromSource = from
    }
}

public enum OpenImageFromSource: String {
    case webBridge
    case comment
}

public protocol BaseOpenImagePluginProtocol: AnyObject {
    func pluginWillRefreshImage(_ plugin: BaseOpenImagePlugin, type: SKPhotoType)
    func pluginWillOpenImage(_ plugin: BaseOpenImagePlugin, type: SKPhotoType, showImageData: ShowPositionData?)
    func didCreateAssetBrowerVC(_ assertBrowserVC: SKAssetBrowserViewController, openImageData: OpenImageData)
    /// 返回更新以后的图片url
    func realImageUrlStrFor(_ url: String) -> String
    /// 通知图片已经被删除了
    func currentImageHasBeenDeletedWhenRefresh(assects: [LKDisplayAsset], imgList: [PhotoImageData])
    ///
    func refreshSuccFor(assects: [LKDisplayAsset], imgList: [PhotoImageData])
    /// 向后台请求图片时，需要更改request
    var imageRequesetModifier: RequestModifier? { get }
    /// presentVC
    func presentClearViewController(_ v: SKAssetBrowserViewController, animated: Bool)
    
    /// 获取BrowserModelConfig
    var modelConfig: BrowserModelConfig? { get }
}

public final class BaseOpenImagePlugin: JSServiceHandler {
    
    // 处理图片偏移量 屏幕高度-WebView高度
    public var imageOffset: CGPoint = .zero
    // 每张图片最大的内存占用100M
    private let maxMemorySizeForPic: Int = 30 * 1024 * 1024
    
    public var logPrefix: String = ""
    private let config: SKBaseOpenImagePluginConfig
    public weak var pluginProtocol: BaseOpenImagePluginProtocol?
    public weak var assetBrowserVC: SKAssetBrowserViewController?
    private var downloader: DocCommonDownloadProtocol = DocsContainer.shared.resolve(DocCommonDownloadProtocol.self)!
    private var downloadCacheServive: SpaceDownloadCacheProtocol = DocsContainer.shared.resolve(SpaceDownloadCacheProtocol.self)!
    private let disposeBag = DisposeBag()
    
    public var hostDocsInfo: DocsInfo?
    
    public private(set) var openImageData: OpenImageData?
    ///  是否支持横屏展示评论
    private var supportCommentWhenLandscape: Bool {
        return hostDocsInfo?.inherentType.supportCommentWhenLandscape ?? false
    }
    
    public init(_ config: SKBaseOpenImagePluginConfig) {
        self.config = config
    }
    
    public var handleServices: [DocsJSService] {
        return [.utilOpenImage, .closeImageViewer]
    }
    
    public func handle(params: [String: Any], serviceName: String) {
        let service = DocsJSService(serviceName)
        switch service {
        case .utilOpenImage:
            guard let data = try? JSONSerialization.data(withJSONObject: params, options: []), let openImageData = try? JSONDecoder().decode(OpenImageData.self, from: data) else {
                DocsLogger.error("serialization data fail", component: LogComponents.commentPic)
                return
            }
            openImage(openImageData: openImageData)
        case .closeImageViewer:
            closeImage()
        default:
            skAssertionFailure("can not handle \(serviceName)")
        }
    }
    
    public func closeImage() {
        DocsLogger.info("closeImage assetBrowserVC", component: LogComponents.comment)
        if let vc = assetBrowserVC {
            DocsLogger.info("closeImage assetBrowserVC:\(vc)", component: LogComponents.commentPic)
            assetBrowserVC?.representEnable = false
            assetBrowserVC?.dismiss(animated: false, completion: nil)
            assetBrowserVC = nil
        }
    }
    
    func openImage(openImageData: OpenImageData) {
        if let assetVC = assetBrowserVC, let showingUUID = assetVC.currentPhotoUdid(),
           showingUUID == openImageData.showImageData?.uuid,
           self.openImageData?.equalsTo(openImageData) ?? false {
            //增加重复调用检测，避免闪烁
            DocsLogger.warning("openImage with same data, do nothing", component: LogComponents.imgPreview)
            return
        }
        
        self.openImageData = openImageData
        var currentImageFrame: CGRect = .zero
        var currentToken: String?
        if let imagePosition = openImageData.showImageData?.position, let showToken = openImageData.showImageData?.uuid {
            currentImageFrame = CGRect(
                x: imagePosition.x + imageOffset.x,
                y: imagePosition.y + imageOffset.y,
                width: imagePosition.width,
                height: imagePosition.height)
            currentToken = showToken
        }
        
        var showPhotoType: SKPhotoType = .normal
        if let image = openImageData.showImageData,
           let currentUUID = image.uuid,
           currentUUID.contains(SKPhotoType.diagramSVG.rawValue) {
            showPhotoType = .diagramSVG
        }
        
        let assects = openImageData.imageList.map { [weak self] (imageData) -> LKDisplayAsset in
            let imageKey = imageData.uuid ?? ""
            let asset: LKDisplayAsset = LKDisplayAsset()
            asset.isSVG = imageKey.contains(SKPhotoType.diagramSVG.rawValue)
            if let originalSrc = imageData.originalSrc, !originalSrc.isEmpty {
                asset.originalUrl = originalSrc
            } else {
                asset.originalUrl = imageData.src
            }
            asset.key = imageKey
            asset.imageDocsInfo = imageData.imageDocsInfo ?? self?.hostDocsInfo
            if let crop = imageData.crop { asset.crop = crop }
            if currentImageFrame != .zero,
               imageKey == currentToken,
               let thumbnail = self?.getImageFromCustomCacheService(for: imageData.src, origin: false, asset: asset) {
                let imageView = UIImageView(image: thumbnail)
                imageView.frame = currentImageFrame
                asset.visibleThumbnail = imageView
                asset.placeHolder = thumbnail
            }
            return asset
        }
        
        if let assetVC = assetBrowserVC, !assetVC.isBeingDismissed {
            DocsLogger.info("update assetBrowserVC:\(ObjectIdentifier(assetVC))", component: LogComponents.commentPic)
            if let assetView = assetVC.view {
                let presenting = assetVC.presentingViewController
                DocsLogger.info("assetBrowserVC presentingVC:\(presenting) parent:\(assetVC.parent) viewIsHidden:\(assetView.isHidden) bounds:\(assetView.bounds)", component: LogComponents.commentPic)
            }
            
            pluginProtocol?.pluginWillRefreshImage(self, type: showPhotoType)
            var reloadIndex: Int?
            if let currentUUID = openImageData.showImageData?.uuid {
                if let firstIndex = openImageData.imageList.firstIndex(where: { $0.uuid == currentUUID }) {
                    reloadIndex = firstIndex
                }
            }
            reloadAssets(assetVC: assetVC, assects: assects, imgList: openImageData.imageList, newIndex: reloadIndex)
        } else {
            DocsLogger.info("init assetBrowserVC", component: LogComponents.comment)
            pluginProtocol?.pluginWillOpenImage(self, type: showPhotoType, showImageData: openImageData.showImageData)
            let vc = createDocsAssetBrowserVC(assects: assects, openImageData: openImageData)
            vc.supportCommentWhenLandscape = supportCommentWhenLandscape
            assetBrowserVC = vc
            vc.willDismissCallback = { [weak self, weak vc] in
                // 防止其他地方引用没有释放，影响文档业务判断
                if self?.assetBrowserVC == vc {
                    self?.assetBrowserVC = nil
                } else {
                    //在其它抢共享人时，如果正在打开图片，会马上调用close再open，会出现vc不一致的情况，加上判断
                    DocsLogger.warning("assetBrowserVC is not same")
                }
            }
            vc.hierarchyPriority = (config.fromSource == .comment) ? .comment : .docImage
            DocsLogger.info("new assetBrowserVC:\(ObjectIdentifier(vc))", component: LogComponents.commentPic)
            skInfo(logPrefix + "will present image")
            if let pluginProtocol = pluginProtocol {
                pluginProtocol.presentClearViewController(vc, animated: true)
                skInfo(logPrefix + "pluginProtocol did present image")
            } else {
                skInfo(logPrefix + "pluginProtocol is nil")
            }
        }
    }
    
    func isOfflineToken(srcObjToken: String?) -> Bool {
        guard let token = srcObjToken else {
            return false
        }
        guard let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self) else {
            return false
        }
        let manuOfflineTokens = dataCenterAPI.manualOfflineTokens
        let isOfflined = manuOfflineTokens.contain(objToken: token)
        return isOfflined
    }
    
    private func createDocsAssetBrowserVC(assects: [LKDisplayAsset],
                                          openImageData: OpenImageData) -> SKAssetBrowserViewController {
        var index = 0
        let imgList = openImageData.imageList
        let currentUUID = openImageData.showImageData?.uuid
        if let firstIndex = imgList.firstIndex(where: { $0.uuid == currentUUID }) {
            index = firstIndex
        }
        
        let actionHandler = config.actionHandlerGenerator()
        let vc = config.AssetBrowserVCType.init(assets: assects, pageIndex: index, actionHandler: actionHandler)
        vc.photoImageDatas = imgList
        vc.isPhotoIndexLabelHidden = false
        
        vc.setImageBlock = { [weak self] (asset, view, progress, complete) -> CancelImageBlock? in
            
            guard let self = self, let originalSrc = self.pluginProtocol?.realImageUrlStrFor(asset.originalUrl) else {
                DocsLogger.info("缺少原图地址")
                return nil
            }
            DispatchQueue.global().async {
                let srcObjToken = asset.imageDocsInfo?.token
                let srcObjType = asset.imageDocsInfo?.type.rawValue
                // 查找是否有已经缓存的图片
                // 从 CacheService 里面读取, 我们拦截前端下载图片请求的时候, 就是用 url.path 作为 key.
                if let imageData = self.getImageDataFromCache(for: asset.originalUrl, origin: true, srcObjToken: srcObjToken) {
                    let image = self.createImageWithData(imageData, asset: asset)
                    DispatchQueue.main.async {
                        complete?(image, nil, nil)
                    }
                    DocsLogger.info("get image from cache")
                    return
                }

                // drive图片走drive通道下载，以前的docs图片走原来的下载逻辑
                if DocsUrlUtil.isDriveImageUrlV2(asset.originalUrl), let token = DocsUrlUtil.getTokenFromDriveImageUrlV2(URL(string: asset.originalUrl)) {
                    DocsLogger.info("download drive pic, token=\(DocsTracker.encrypt(id: token)), hascache=false")
                    let beginTime = Date.timeIntervalSinceReferenceDate
                    let drivePicType = DocCommonDownloadType.image
                    var srcObjTypeInt: Int32?
                    if let srcObjType {
                        srcObjTypeInt =  Int32(srcObjType)
                    }
                    let context = DocCommonDownloadRequestContext(fileToken: token,
                                                                  docToken: srcObjToken ?? "",
                                                                  docType: srcObjTypeInt,
                                                                  mountNodePoint: "",
                                                                  mountPoint: "doc_image",
                                                                  priority: .default,
                                                                  downloadType: drivePicType,
                                                                  localPath: nil,
                                                                  isManualOffline: self.isOfflineToken(srcObjToken: srcObjToken),
                                                                  dataVersion: nil,
                                                                  originFileSize: nil,
                                                                  fileName: nil)
                    self.downloader.download(with: context)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] (context) in
                            let status = context.downloadStatus
                            if status == .inflight {
                                progress?(Int64(context.downloadProgress.0), Int64(context.downloadProgress.1))
                            } else if status == .success || status == .failed {
                                var picSize: Int = -1
                                
                                if status == .success, let data = self?.downloadCacheServive.data(key: token, type: drivePicType) {
                                    picSize = data.count
                                    let srcObjToken = context.requestContext.docToken
                                    self?.config.cacheService.mapTokenAndPicKey(token: srcObjToken, picKey: token, picType: drivePicType.rawValue, needSync: false, isDrivePic: true)
                                    DocsLogger.info("download drive pic, token=\(DocsTracker.encrypt(id: token)), result=success")
                                    DispatchQueue.global().async {
                                        // 可能存在降采样的操作放在子线程进行操作
                                        let resultImage = self?.createImageWithData(data, asset: asset)
                                        DispatchQueue.main.async {
                                            complete?(resultImage, nil, nil)
                                        }
                                    }
                                } else {
                                    DocsLogger.error("download drive pic, token=\(DocsTracker.encrypt(id: token)), result=\(status)")
                                    if view.image == nil {
                                        view.image = asset.visibleThumbnail?.image
                                    }
                                    complete?(nil, nil, nil)
                                }
                                
                                //上报
                                let costTime = Date.timeIntervalSinceReferenceDate - beginTime
                                let from: SKPicStatisticsDownloadFrom = self?.config.fromSource == .comment ? .picOpenPluginComment : .picOpenPluginOthers
                                let errorCode: Int = (status == .success) ? 0 : context.errorCode
                                SKDownloadPicStatistics.downloadPicReport(errorCode, type: drivePicType.rawValue, from: from, picSize: picSize, cost: Int(costTime * 1000))
                            }
                        })
                        .disposed(by: self.disposeBag)
                    
                } else {
                    DispatchQueue.main.async {
                        // BytedWebImage会做缓存，异步读取就行
                        DocsLogger.info("download docs pic, token=\(DocsTracker.encrypt(id: asset.originalUrl)), hascache=false")
                        view.bt.setLarkImage(with: .default(key: originalSrc),
                                             placeholder: asset.visibleThumbnail?.image,
                                             cacheName: asset.originalUrl,
                                             modifier: self.pluginProtocol?.imageRequesetModifier,
                                             completion: { [weak view] result in
                            switch result {
                            case .success:
                                complete?(view?.image, nil, nil)
                            case .failure(let error):
                                if view?.image == nil {
                                    view?.image = asset.visibleThumbnail?.image //下载原图失败后显示缩略图
                                }
                                DocsLogger.error("download docs pic, token=\(DocsTracker.encrypt(id: asset.originalUrl)), result=failure")
                                complete?(nil, nil, error)
                            }
                        })
                    }
                }
            }
            return nil
        }
        
        vc.setSVGBlock = { [weak self] (asset, complete) -> CancelImageBlock? in
            self?.pluginProtocol?.modelConfig?.jsEngine.callFunction(.requestDiagramSVGData, params: ["uuid": asset.key], completion: { (data, error) in
                guard error == nil else {
                    DocsLogger.error("obtian SVG, token=\(DocsTracker.encrypt(id: asset.key)), result=failure")
                    complete?(nil, error)
                    return
                }
                guard let dataDict = data as? [String: Any], let result = dataDict["result"] as? String, let svgString = dataDict["svgString"] as? String else {
                    DocsLogger.error("obtian SVG, token=\(DocsTracker.encrypt(id: asset.key)), data empty")
                    complete?(nil, error)
                    return
                }
                if result == "0" {
                    DocsLogger.error("obtian SVG, token=\(DocsTracker.encrypt(id: asset.key)), result=failure")
                    complete?(svgString, error)
                } else {
                    DocsLogger.info("obtian SVG, token=\(DocsTracker.encrypt(id: asset.key)), result=success")
                    complete?(svgString, error)
                }
            })
            return nil
        }
        pluginProtocol?.didCreateAssetBrowerVC(vc, openImageData: openImageData)
        return vc
    }
    
    // 通过Data生成UIImage
    private func createImageWithData(_ imageData: Data?, with key: String = "", asset: LKDisplayAsset? = nil) -> UIImage? {
        guard let imageData = imageData else {
            return nil
        }
        
        var cacheImage: UIImage?
        let imageFormat = imageData.kf.imageFormat
        asset?.isGif = imageFormat == .GIF
        //targetSize为（-1，-1）ByteImage将不会做降采样操作
        var (_, targetSize) = (false, CGSize(width: -1, height: -1))
        let orignalSize = SKImagePreviewUtils.originSizeOfImage(data: imageData) ?? .zero
        if imageFormat != .GIF {
            (_, targetSize) = SKImagePreviewUtils.isOverSizeAndSampleSize(orignalSize: orignalSize, maxMemoryBytes: maxMemorySizeForPic)
        }
        let cropData = asset?.crop
        let (needCrop, cropRect) = SKImagePreviewUtils.cropRect(cropScale: cropData, originalSize: orignalSize)
        let gifCropEnable = needCrop && UserScopeNoChangeFG.LJW.gifCropEnable
        cacheImage = try? ByteImage(imageData, downsampleSize: targetSize, cropRect: cropRect, enableAnimatedDownsample: gifCropEnable)
        return cacheImage
    }
    
    // 从自定义的缓存里面找图片
    private func getImageFromCustomCacheService(for url: String, origin: Bool, asset: LKDisplayAsset?) -> UIImage? {
        let srcObjToken = asset?.imageDocsInfo?.token
        let imageData = getImageDataFromCache(for: url, origin: origin, srcObjToken: srcObjToken)
        let image = createImageWithData(imageData, asset: asset)
        return image
    }
    
    // 从自定义的缓存里面找图片Data
    private func getImageDataFromCache(for url: String, origin: Bool, srcObjToken: String?) -> Data? {
        var imageData: Data?
        DocsLogger.info("getImageDataFromCache", component: LogComponents.imgPreview)
        if DocsUrlUtil.isDriveImageUrl(url), let token = DocsUrlUtil.getTokenFromDriveImageUrl(URL(string: url)) {
            //如果是本地上传的图片，本地可能有缓存，所以先查下本地(本地是原图)
            let assetInfo = DocsContainer.shared.resolve(CommentImageCacheInterface.self)?.getAssetWith(fileTokens: [token]).first
            if assetInfo?.cacheKey != nil,
               let data = self.downloadCacheServive.data(key: token, type: .image) {
                DocsLogger.info("getImageDataFromCache downloadCacheServive get cache data success: \(data != nil)", component: LogComponents.imgPreview)
                imageData = data
            } else {
                imageData = downloadCacheServive.data(key: token, type: origin ? .image : .defaultCover)
                DocsLogger.info("getImageDataFromCache downloadCacheServive get cache origin: \(origin) success: \(imageData != nil)", component: LogComponents.imgPreview)
            }
        } else if let key = URL(string: url)?.path {
            let objToken = srcObjToken ?? self.hostDocsInfo?.objToken
            imageData = config.cacheService.getImage(byKey: key, token: objToken) as? Data
            DocsLogger.info("getImageDataFromCache cacheService get cache success: \(imageData != nil)", component: LogComponents.imgPreview)
        }
        return imageData
    }
    
    private func reloadAssets(assetVC: SKAssetBrowserViewController,
                              assects: [LKDisplayAsset],
                              imgList: [PhotoImageData],
                              newIndex: Int?) {
        /// 需要记录上一次的展示图片下标，找到对应的图片id
        /// 两种情况
        /// 1.VCFollow NewIndex被指定了 (回调参数image有值)3.20新增
        /// 直接更新到对应的Index
        /// 2.文档中更新操作  (回调参数image没有值，newIndex 为nil)
        /// 发现被删除的case:
        /// 没有下一张图片，则跳转到上一张
        /// 有下一张，则跳转到下一张
        /// 若当前图片被删除，让外部处理
        
        let lastCurrentPageIndex = assetVC.currentPageIndex
        let lastCurrentImgID = assetVC.currentPhotoUdid()
        var newCurrentPageIndex = lastCurrentPageIndex
        var currentImgHasBeenDeleted = true
        if let showNewIndex = newIndex {
            newCurrentPageIndex = showNewIndex
            currentImgHasBeenDeleted = false
        } else {
            for (index, img) in imgList.enumerated() where img.uuid == lastCurrentImgID {
                newCurrentPageIndex = index
                currentImgHasBeenDeleted = false
            }
        }
        
        if currentImgHasBeenDeleted {
            pluginProtocol?.currentImageHasBeenDeletedWhenRefresh(assects: assects, imgList: imgList)
        } else {
            // 不是当前图片被删除，前面被删除的时候，下标也要改变 【包含增加的情况】
            pluginProtocol?.refreshSuccFor(assects: assects, imgList: imgList)
            assetVC.reloadAssets(assects, newCurrentPageIndex: min(imgList.count - 1, newCurrentPageIndex))
            assetVC.photoImageDatas = imgList
        }
    }
}
