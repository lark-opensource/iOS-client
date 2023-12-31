//
//  LKPhotoZoomingScrollView.swift
//  LarkUIKit
//
//  Created by Yuguo on 2017/4/12.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LarkSetting
import LKCommonsLogging
import LarkUIKit
import ByteWebImage
import AppReciableSDK
import UniverseDesignColor
import UniverseDesignToast
import LarkStorage

public final class LKPhotoZoomingScrollView: UIScrollView {
    private static let logger = Logger.log(LKPhotoZoomingScrollView.self,
                                           category: "LarkUIKit.LKPhotoZoomingScrollView")

    public var displayIndex: Int = Int.max
    public var displayAsset: LKDisplayAsset?
    // 配置图片加载额外的ImageRequestOptions，与内部策略归并
    public var additonImageRequestOptions: ImageRequestOptions?

    /// 当图片宽高比例小于屏幕宽高比例时(长图)，优先横向全屏占满显示
    lazy var priorityHorizontalFullScreen: Bool = { LKPhotoZoomingScrollView.preferHorizontalFullScreen
    }()

    public var dismissCallback: (() -> Void)?
    public var longPressCallback: ((UIImage?, LKDisplayAsset, UIView?) -> Void)?
    public var moreButtonClickedCallback: ((UIImage?, LKDisplayAsset, UIView?) -> Void)?

    // 图片设置结束回调
    public var setImageFinishedCallback: ((UIImage?, LKDisplayAsset) -> Void)?

    public var image: UIImage? {
        return useTiledImageView ? tiledImageView.image : photoImageView.image
    }

    public var originalImageData: Data? {
        if let savePath, let data = try? Data.read(from: savePath.asAbsPath()) {
            return data
        }
        Self.logger.info("return nil originalImageData")
        return nil
    }

    public var imageViewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private var useTiledImageView = false

    /// 展示小图的组件
    /// TODO: Make it private
    public lazy var photoImageView: ByteImageView = {
        let photoImageView = ByteImageView()
        photoImageView.isUserInteractionEnabled = true
        photoImageView.contentMode = .scaleAspectFill
        photoImageView.backgroundColor = UIColor.ud.primaryOnPrimaryFill // 图片背景透明时垫一层白底
        photoImageView.animateRunLoopMode = .default
        return photoImageView
    }()

    /// 展示大图的组件
    public lazy var tiledImageView: TiledImageView = {
        let tiledImageView = TiledImageView()
        tiledImageView.isUserInteractionEnabled = true
        tiledImageView.contentMode = .scaleAspectFill
        return tiledImageView
    }()

    private lazy var progressView: LarkProgressHUD = {
        return LarkProgressHUD(view: self)
    }()

    public var getExistedImageBlock: GetExistedImageBlock?
    public var setImageBlock: SetImageBlock?
    public var handleLoadCompletion: ((AssetLoadCompletionInfo) -> Void)?
    public var prepareAssetInfo: PrepareAssetInfo?
    public var setSVGBlock: SetSVGBlock?

    /// 通知业务方，该页面的图片加载已被取消
    private var cancelImageBlock: CancelImageBlock?

    public private(set) var singleTap = UITapGestureRecognizer()
    public private(set) var doubleTap = UITapGestureRecognizer()
    public private(set) var longGesture = UILongPressGestureRecognizer()

    /// 图片适应屏幕（scaleAspectFit）的缩放倍率
    private var aspectFitZoomScale: CGFloat = 1
    /// 图片填满屏幕（scaleAspectFill）的缩放倍率
    private var aspectFillZoomScale: CGFloat = 1

    private var savePath: String?

    private var decodeQueue = DispatchQueue(label: "com.assetbrowser.scrollview.image.decode", attributes: .concurrent)

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(imageViewContainer)
        imageViewContainer.addSubview(photoImageView)
        imageViewContainer.addSubview(tiledImageView)
        photoImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tiledImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.addSubview(progressView)

        self.delegate = self
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.contentInsetAdjustmentBehavior = .never
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        doubleTap.addTarget(self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTap)

        singleTap.addTarget(self, action: #selector(handleSingleTap(_:)))
        singleTap.require(toFail: doubleTap)
        self.addGestureRecognizer(singleTap)

        longGesture.addTarget(self, action: #selector(handleLongPress(_:)))
        self.addGestureRecognizer(longGesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func prepareForReuse() {
        displayAsset = nil
        displayIndex = Int.max
        photoImageView.image = nil
        dismissCallback = nil
        cancelImageBlock?()
        cancelImageBlock = nil
        resetScale()
        tiledImageView.reset()
    }

    public func recoverToInitialState() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.zoomScale = self.minimumZoomScale
        }
    }

    public func setMaxMinZoomScalesForCurrentBounds(_ size: CGSize) {
        var imageSize = size
        if imageSize == .zero {
            if useTiledImageView {
                imageSize = tiledImageView.imageSize
            } else {
                imageSize = photoImageView.image?.size ?? .zero
            }
        }
        guard imageSize != .zero else { return }
        // Set min & max zoom scale
        setProperZoomScale(
            forBounds: bounds.size,
            imageSize: imageSize,
            preferHorizontalFullScreen: priorityHorizontalFullScreen
        )
        // Set initial zoom scale
        self.zoomScale = minimumZoomScale

        // 更新zoom后如果是分片加载，那么需要更新tile的参数
        if useTiledImageView {
            tiledImageView.update(maxScale: maximumZoomScale, minScale: minimumZoomScale)
        }

        performLayoutSubviews()
        self.lu.scrollToTop(animated: false)
    }
}

extension LKPhotoZoomingScrollView: UIScrollViewDelegate {

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageViewContainer
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        performLayoutSubviews()
    }

//    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
//        if scale < minimumZoomScale {
//            setZoomScale(minimumZoomScale, animated: true)
//        }
//    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 0 {
            self.panGestureRecognizer.isEnabled = false
        } else {
            self.panGestureRecognizer.isEnabled = true
        }
    }
}

private extension LKPhotoZoomingScrollView {
    private func resetScale() {
        minimumZoomScale = 1
        maximumZoomScale = 1
        zoomScale = 1
    }

    /// 图片居中
    private func performLayoutSubviews() {
        var imageView = imageViewContainer
        let newFrame = LKPhotoZoomingScrollView.getCentralizedFrame(
            size: imageView.frame.size,
            boundsSize: bounds.size)
        if !imageView.frame.equalTo(newFrame) {
            imageView.frame = newFrame
        }
    }

    public func updateNotUseHugeImage() {
        useTiledImageView = false
    }

    /// 根据图片、尺寸来调整视图布局
    /// - Parameters:
    ///   - photoImage: 如果只有图片，根据图片 size 确定布局
    ///   - tiledImageSize: 如果有 size，说明为大图加载，使用 size 确定布局
    private func setUpPhotoImageView(_ photoImage: UIImage?, tiledImageSize: CGSize? = nil) {
        // Fix https://jira.bytedance.com/browse/SUITE-68204
        // System wont reset zoomScale when set content size or viewForZooming() frame.
        // Updating zoom scale will change content size and viewForZooming() frame.
        // Reset zoomScale before set frame and contentSize.
        resetScale()
        if let size = tiledImageSize {
            tiledImageView.isHidden = false
            useTiledImageView = true
            imageViewContainer.frame = CGRect(origin: .zero, size: size)
            photoImageView.image = photoImage // 分片也有可能有缩略预览图
            contentSize = size
            // Set zoom to minimum zoom
            setMaxMinZoomScalesForCurrentBounds(size)
        } else if let photoImage = photoImage {
            tiledImageView.isHidden = true
            useTiledImageView = false
            imageViewContainer.frame = CGRect(origin: .zero, size: photoImage.size)
            photoImageView.image = photoImage
            photoImageView.startAnimating()
            contentSize = photoImage.size
            // Set zoom to minimum zoom
            setMaxMinZoomScalesForCurrentBounds(photoImage.size)
        }
        guard let image = self.image, let asset = self.displayAsset else {
            return
        }
        self.setImageFinishedCallback?(image, asset)
    }
}

// MARK: - Photo Zooming

extension LKPhotoZoomingScrollView {

    /// 双击放大时使用的的缩放倍率
    private var naturalZoomScale: CGFloat {
        if minimumZoomScale == aspectFillZoomScale {
            // 初始填满屏幕的情况时
            return minimumZoomScale * 2.5
        } else {
            // 正常情况时，优先填满屏幕，如果缩放比例不够，则放大 2.5 倍
            return max(aspectFitZoomScale * 2.5, aspectFillZoomScale)
        }
    }

    private func setProperZoomScale(forBounds boundsSize: CGSize,
                                    imageSize: CGSize,
                                    preferHorizontalFullScreen: Bool = false) {

        let widthRatio = boundsSize.width / imageSize.width
        let heightRatio = boundsSize.height / imageSize.height
        self.aspectFitZoomScale = min(widthRatio, heightRatio)
        self.aspectFillZoomScale = max(widthRatio, heightRatio)

        let isPortrait = boundsSize.width < boundsSize.height
        // 比屏幕尺寸长的图定义为超长图，以填满屏幕的初始缩放比例显示
        let isLongImage = imageSize.height / imageSize.width > boundsSize.height / boundsSize.width

        if isPortrait, isLongImage, preferHorizontalFullScreen {
            self.minimumZoomScale = aspectFillZoomScale
        } else {
            self.minimumZoomScale = aspectFitZoomScale
        }

        let naturalZoomScale = max(minimumZoomScale * 2.5, aspectFillZoomScale)
        self.maximumZoomScale = max(2.0 * UIScreen.main.scale, naturalZoomScale)
    }

    // 放大图片到自然尺寸（naturalZoomScale）
    private func zoomInPhotoView(from touchPoint: CGPoint) {
        let newZoomScale = naturalZoomScale
        let xsize = bounds.size.width / newZoomScale
        let ysize = bounds.size.height / newZoomScale
        let newRect = CGRect(
            x: touchPoint.x - xsize / 2,
            y: touchPoint.y - ysize / 2,
            width: xsize,
            height: ysize
        )
        self.zoom(to: newRect, animated: true)
    }

    /// 对于超长图，iPad 端优先展示全图，iPhone 端优先满屏展示
    static var preferHorizontalFullScreen: Bool {
        Display.pad ? false : true
    }

    class func getMinimumZoomScale(forBounds boundsSize: CGSize,
                                   imageSize: CGSize,
                                   preferHorizontalFullScreen: Bool) -> CGFloat {
        let widthRatio = boundsSize.width / imageSize.width
        let heightRatio = boundsSize.height / imageSize.height
        var aspectFitZoomScale = min(widthRatio, heightRatio)
        var aspectFillZoomScale = max(widthRatio, heightRatio)

        let isPortrait = boundsSize.width < boundsSize.height
        // 比屏幕尺寸长的图定义为超长图，以填满屏幕的初始缩放比例显示
        let isLongImage = imageSize.height / imageSize.width > boundsSize.height / boundsSize.width

        if isPortrait, isLongImage, preferHorizontalFullScreen {
            return aspectFillZoomScale
        } else {
            return aspectFitZoomScale
        }
    }

    class func getCentralizedFrame(size: CGSize, boundsSize: CGSize) -> CGRect {
        // Center the image as it becomes smaller than the size of the screen
        var frameToCenter = CGRect(origin: .zero, size: size)

        // Horizontally
        if frameToCenter.width < boundsSize.width {
            let newX = floor((boundsSize.width - frameToCenter.width) / CGFloat(2))
            frameToCenter.origin.x = newX
        } else {
            frameToCenter.origin.x = 0
        }

        // Vertically
        if frameToCenter.height < boundsSize.height {
            let newY = floor((boundsSize.height - frameToCenter.height) / CGFloat(2))
            frameToCenter.origin.y = newY
        } else {
            frameToCenter.origin.y = 0
        }

        return frameToCenter
    }
}

// MARK: - Handle Gesture

extension LKPhotoZoomingScrollView {

    private func setOperationGestureEnabled(_ isEnabled: Bool) {
        doubleTap.isEnabled = isEnabled
        longGesture.isEnabled = isEnabled
    }

    @objc
    private func handleSingleTap(_ gesture: UITapGestureRecognizer) {
        if dismissCallback == nil {
            LKPhotoZoomingScrollView.logger.info("handleSingleTap, dismissCallback is nil")
        } else {
            LKPhotoZoomingScrollView.logger.info("handleSingleTap, dismissCallback")
        }
        dismissCallback?()
    }

    @objc
    private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if self.zoomScale != self.minimumZoomScale {
            // 缩小
            self.setZoomScale(self.minimumZoomScale, animated: true)
        } else {
            // 放大
//            let imageView = useTiledImageView ? tiledImageView : photoImageView
            let touchPoint = gesture.location(in: imageViewContainer)
            zoomInPhotoView(from: touchPoint)
        }
    }

    @objc
    private func handleLongPress(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .began {
            guard let image = self.image, let asset = self.displayAsset else {
                return
            }
            self.longPressCallback?(image, asset, nil)
        }
    }
}

// MARK: - LKAssetPageView Protocol

extension LKPhotoZoomingScrollView: LKAssetPageView {

    public var dismissFrame: CGRect {
        return self.convert(imageViewContainer.frame, to: self.window)
    }

    public var dismissImage: UIImage? {
        // TODO: 不知道为什么用 tiledImageView 的图片，会导致 dismiss 动画异常
        return photoImageView.image
    }

    public var saveImage: UIImage? {
        if useTiledImageView {
            return tiledImageView.image
        } else if let path = savePath {
            do {
                let data = try? Data.read(from: path.asAbsPath())
                let image = try ByteImage(
                    data,
                    scale: UIScreen.main.scale,
                    decodeForDisplay: false,
                    downsampleSize: .zero,
                    cropRect: .zero
                )
                return image
            } catch {
                return photoImageView.image
            }
        } else {
            return photoImageView.image
        }
    }

    public func handleSwipeDown() {}

    public func prepareDisplayAsset(completion: @escaping () -> Void) {
        self.displayImage(progressCallback: nil, completionCallback: { _ in completion() })
    }

    public func handleCurrentDisplayAsset() {}

    public func handleTranslateProcess(baseView: UIView,
                                       cancelHandler: @escaping () -> Void,
                                       processHandler: @escaping (@escaping () -> Void, @escaping (Bool, LKDisplayAsset?) -> Void) -> Void,
                                       dataSourceUpdater: @escaping (LKDisplayAsset) -> Void) {
        let completion: (Bool, LKDisplayAsset?) -> Void = { [weak self] (isSuccess, asset) in
            guard let `self` = self else { return }
            if isSuccess, let newAsset = asset {
                if let setImageBlock = self.setImageBlock {
                    self.cancelImageBlock = setImageBlock(newAsset, self.photoImageView, nil) { (_, _, error) in
                        if let err = error {
                            LKPhotoZoomingScrollView.logger.error("handleTranslateProcess.setImageBlock.error >> \(err.localizedDescription)")
                            UDToast.showTipsOnScreenCenter(
                                with: BundleI18n.LarkAssetsBrowser.Lark_Chat_ImageTextUnsupportTranslate,
                                on: self)
                        } else {
                            dataSourceUpdater(newAsset)
                        }
                        baseView.stopImageTranslateAnimation()
                    }
                } else if let prepareAssetInfo = self.prepareAssetInfo {
                    let (resource, passThrough, trackInfo) = prepareAssetInfo(newAsset)
                    self.setImage(resource: resource.getImageKeyResource(),
                                  passThrough: passThrough,
                                  trackInfo: trackInfo,
                                  progressBlock: { (_, _) in },
                                  resultCompletionHandler: { [weak self] result, error in
                        guard let self = self else { return }
                        if let result = result {
                            if let image = result.image {
                                self.setUpPhotoImageView(image)
                            } else if result.data == nil { // 既没有 image，又没有 data，认为下载失败
                                if let placeHolder = newAsset.placeHolder ??
                                            newAsset.visibleThumbnail?.image // 临时兼容老逻辑，之后删
                                { // 下载不成功，但有 placeHolder
                                    self.setUpPhotoImageView(placeHolder)
                                }
                            }
                        }
                        if let err = error {
                            LKPhotoZoomingScrollView.logger.error("handleTranslateProcess.setImageBlock.error >> \(err.localizedDescription)")
                            UDToast.showTipsOnScreenCenter(
                                with: BundleI18n.LarkAssetsBrowser.Lark_Chat_ImageTextUnsupportTranslate,
                                on: self)
                        } else {
                            dataSourceUpdater(newAsset)
                        }
                        baseView.stopImageTranslateAnimation()
                    })
                }
            } else {
                baseView.stopImageTranslateAnimation()
            }
        }

        let languageConflictSideEffect = {
            baseView.startImageTranslateAnimation(cancelBlock: cancelHandler)
        }

        baseView.startImageTranslateAnimation(cancelBlock: cancelHandler)
        processHandler(languageConflictSideEffect, completion)
    }
}

extension LKPhotoZoomingScrollView: LKAssetMultiQRCodeScannablePage {

    public var visibleRect: CGRect? {
        if let originalImageData {
            let pixelSize = originalImageData.bt.imageSize
            let imageScale = pixelSize.width / imageViewContainer.bounds.width
            let visibleRectPt = self.convert(self.bounds, to: imageViewContainer)
                .intersection(imageViewContainer.bounds)
            let visibleRectPx = CGRect(x: visibleRectPt.minX * imageScale,
                                       y: visibleRectPt.minY * imageScale,
                                       width: visibleRectPt.width * imageScale,
                                       height: visibleRectPt.height * imageScale)
            return visibleRectPx
        }
        return nil
    }

    public var visibleImage: UIImage? {
        guard photoImageView.image != nil, imageViewContainer.bounds != .zero else {
            return nil
        }
        let visibleImageRect = self.convert(self.bounds, to: imageViewContainer)
            .intersection(imageViewContainer.bounds)
        print(visibleImageRect)
        let imageRectInScrollView = imageViewContainer.convert(imageViewContainer.bounds, to: self)
            .intersection(self.bounds)
        // 使用 cgContext.translatedBy 的方法绘制 imageContainer 局部不可行的原因是：
        // 如果展示整张图，就会把整个图按原大小画一遍，既会爆内存，也会画不出来
        // 所以这里直接画 scrollView 中的图片区域
        let image = UIGraphicsImageRenderer(bounds: imageRectInScrollView).image { context in
            context.cgContext.setFillColor(UIColor.systemRed.cgColor)
            context.cgContext.fill(imageRectInScrollView)
            self.layer.render(in: context.cgContext)
        }
        return image
    }

    public var currentImageScale: Double {
        zoomScale / minimumZoomScale
    }
}

// MARK: - Displaying Image

extension LKPhotoZoomingScrollView {

    func getPlaceholderImage(asset: LKDisplayAsset, cacheImage: (() -> UIImage?)?) -> UIImage? {
        // 业务方定义的占位图
        if let messageView = asset.visibleThumbnail?.image {
            Self.logger.info("displayAsset visible thumbnail not nil")
            return messageView
        }

        // 图片消息和富文本图片，如果在缓存中找不到要展示的图片，则在缓存中找placeholder图片
        // 如果在缓存中可以找到要展示的图片，这里的cacheImage为nil
        if let cacheImageCompletion = cacheImage, let image = cacheImageCompletion() {
            Self.logger.info("displayAsset cache key not nil")
            return image
        }

        // 都找不到使用inline占位
        if let inline = asset.placeHolder {
            Self.logger.info("displayAsset inline not nil")
            return inline
        }
        return nil
    }

    // swiftlint:disable function_body_length
    func displayImage(progressCallback: ((Float) -> Void)?,
                      completionCallback: ((Bool) -> Void)?) {
        guard let displayAsset = displayAsset else { return }
        var key = displayAsset.key
        var shouldDisplayLoading = true
        var (dataProvider, passThrough, trackInfo): (ImageDisplayDataProvider?, ImagePassThrough?, TrackInfo?)
        if let prepareAssetInfo = self.prepareAssetInfo { // 需要 Biz 和 Scene，在此提前获取信息
            (dataProvider, passThrough, trackInfo) = prepareAssetInfo(displayAsset)
            if let dataProvider = dataProvider {
                key = dataProvider.getImageKeyResource().cacheKey // 实际加载的图可能与 displayAsset.key 不一样，需要替换为真实加载的 key
            }
            if trackInfo != nil {
                if trackInfo?.extra != nil {
                    displayAsset.trackExtraInfo.forEach { key, value in
                        trackInfo?.extra?[key] = value
                    }
                } else {
                    trackInfo?.extra = displayAsset.trackExtraInfo
                }
            }
        }
        let isOrigin = displayAsset.originalImageKey == key
        Monitor.shared.start(with: key, biz: trackInfo?.biz, scene: trackInfo?.scene)
        if let placeHolder = getPlaceholderImage(asset: displayAsset, cacheImage: dataProvider?.getImagePlaceholder()) {
            Monitor.shared.thumStart(with: key)
            setUpPhotoImageView(placeHolder)
            Monitor.shared.thumbEnd(with: key)
            shouldDisplayLoading = false
        }

        if let existedImage = self.getExistedImageBlock?(displayAsset) {
            progressView.hide(animated: true)
            photoImageView.image = existedImage
            setUpPhotoImageView(existedImage)
            shouldDisplayLoading = false
            let (category, metric) = getLogContent(
                forImage: existedImage, key: key, isOrigin: isOrigin, loadType: .memoryCache,
                fromType: displayAsset.extraInfo[ImageAssetFromTypeKey] as? TrackInfo.FromType,
                sdkCost: [:]
            )
            Monitor.shared.finish(with: key, metric: metric, category: category)
        } else {
            setOperationGestureEnabled(false)
            if shouldDisplayLoading {
                progressView.show(animated: true)
            }
            Monitor.shared.downloadStart(with: key)
            let progressBlock: DownloadProgressBlock = { (receivedSize, totalSize) in
                let progress = Float(receivedSize) / Float(totalSize)
                if progress >= 1.0 {
                    Monitor.shared.downloadEnd(with: key)
                }
                progressCallback?(progress)
            }

            // 内部尽量不要调这个闭包，因为无法记录 sdk cost，尽量用 resultCompletionHandler
            let completionHandler: CompletionHandler = { [weak self] (image, info, error) in
                guard let self = self else { return }
                self.progressView.hide(animated: true)
                if let photoImage = image {
                    self.setOperationGestureEnabled(true)
                    self.setUpPhotoImageView(photoImage)
                    let (category, metric) = self.getLogContent(
                        forImage: photoImage, key: info?.imageKey ?? "", isOrigin: isOrigin, loadType: info?.loadType ?? .none,
                        fromType: self.displayAsset?.extraInfo[ImageAssetFromTypeKey] as? TrackInfo.FromType,
                        sdkCost: [:]
                    )
                    Monitor.shared.finish(with: key, metric: metric, category: category)
                    completionCallback?(true)
                } else if let error = error as? ByteWebImageError {
                    let status = Int(error.userInfo[ByteWebImageError.UserInfoKey.errorStatus] ?? "") ?? 0
                    Monitor.shared.error(with: key, code: error.code, status: status, message: error.localizedDescription)
                    completionCallback?(false)
                } else {
                    Monitor.shared.error(with: key, code: ByteWebImageErrorUnkown, status: 0,
                                         message: "display image failed due to: \(String(describing: error))")
                    completionCallback?(false)
                }
            }
            let resultCompletionHandler: ResultCompletionHandler = { [weak self] (result, error) in
                if let error = error as? ByteWebImageError {
                    let status = Int(error.userInfo[ByteWebImageError.UserInfoKey.errorStatus] ?? "") ?? 0
                    Monitor.shared.error(with: key, code: error.code, status: status, message: error.localizedDescription)
                    if let displayIndex = self?.displayIndex {
                        self?.handleLoadCompletion?(AssetLoadCompletionInfo(index: displayIndex,
                                                                            data: .image(nil),
                                                                            error: error))
                    }
                    completionCallback?(false)
                } else if let result = result, let self = self {
                    self.handleLoadCompletion?(AssetLoadCompletionInfo(index: self.displayIndex,
                                                                        data: .image(result),
                                                                        error: nil))

                    if let data = result.data { // 分片加载时有原图 data，可能有缩略图 image
                        self.progressView.hide(animated: true)
                        let size = CGSize(width: self.tiledImageView.imageSize.width,
                                          height: self.tiledImageView.imageSize.height)
                        self.setUpPhotoImageView(result.image, tiledImageSize: size)
                        let (category, metric) = self.getLogContent(
                            forData: data, key: result.request.requestKey, isOrigin: isOrigin, loadType: result.from,
                            fromType: self.displayAsset?.extraInfo[ImageAssetFromTypeKey] as? TrackInfo.FromType,
                            sdkCost: result.request.rustCost ?? [:]
                        )
                        Monitor.shared.finish(with: key, metric: metric, category: category)
                    } else if let image = result.image {
                        self.progressView.hide(animated: true)
                        self.setUpPhotoImageView(image)
                        let (category, metric) = self.getLogContent(
                            forImage: image, key: result.request.requestKey, isOrigin: isOrigin, loadType: result.from,
                            fromType: self.displayAsset?.extraInfo[ImageAssetFromTypeKey] as? TrackInfo.FromType,
                            sdkCost: result.request.rustCost ?? [:]
                        )
                        Monitor.shared.finish(with: key, metric: metric, category: category)
                    }
                    completionCallback?(true)
                }
                self?.setOperationGestureEnabled(true)
            }
            // prepareAssetInfo 优先级高于 setImageBlock
            if let resource = dataProvider?.getImageKeyResource(), let trackInfo = trackInfo {
                self.setImage(resource: resource,
                              passThrough: passThrough,
                              trackInfo: trackInfo,
                              progressBlock: progressBlock,
                              resultCompletionHandler: resultCompletionHandler)
            } else if let setImageBlock = self.setImageBlock {
                cancelImageBlock = setImageBlock(displayAsset, photoImageView, progressBlock, completionHandler)
            }
        }
    }

    // swiftlint:disable function_body_length
    /// 使用 LarkImageService 加载图片
    /// - Note: resultCompletionHandler 在加载普通图片时, result.image 非空；加载超大图时，result.data 非空，result.image 可能不为空（缩略图）
    private func setImage(resource: LarkImageResource,
                          passThrough: ImagePassThrough?,
                          trackInfo: TrackInfo,
                          progressBlock: @escaping DownloadProgressBlock,
                          resultCompletionHandler: @escaping ResultCompletionHandler) {
        let key = resource.cacheKey
        let resource = resource
        var trackInfo = trackInfo
        trackInfo.scene = .ImageViewer // image_load 埋点的 scene 应该是 .ImageViewer
        let tracker = ImageTracker()
        tracker.start(with: resource, trackInfo: trackInfo)
        func notTile(result: ImageResult) {
            self.tiledImageView.reset()
            self.decodeQueue.async {
                do {
                    Monitor.shared.decodeStart(with: key)
                    let imageDownsampleSize = LarkImageService.shared.imageSetting.downsample.image.pxSize
                    let image = try ByteImage(result.data, downsampleSize: imageDownsampleSize)
                    image.bt.webURL = URL(string: key)
                    Monitor.shared.decodeEnd(with: key)
                    let resourceWithSuffix = Self.imageResource(resource, withSizeSuffix: imageDownsampleSize)
                    if !LarkImageService.shared.isCached(resource: resourceWithSuffix, options: .memory) { // 非超大图手动存进内存缓存
                        LarkImageService.shared.cacheImage(image: image, resource: resourceWithSuffix, cacheOptions: .memory)
                    }
                    let result = ImageResult(request: result.request,
                                             image: image, // 把 image 放进 result，方便后续埋点上报获取信息
                                             data: nil, // 非分片时，不返回 data 以与分片区分
                                             from: result.from,
                                             savePath: result.savePath)
                    tracker.send(.success(result.from),
                                 imageSize: image.bt.destPixelSize,
                                 originSize: image.bt.pixelSize,
                                 decryptCost: result.request.decryptCost,
                                 rustCost: result.request.rustCost ?? [:],
                                 dataLength: image.bt.dataCount,
                                 imageCount: Int(image.frameCount),
                                 imageType: image.bt.imageFileFormat)
                    DispatchQueue.main.async {
                        resultCompletionHandler(result, nil)
                    }
                } catch {
                    var error = error as? ByteWebImageError ??
                    ByteWebImageError(ByteWebImageErrorInternalError,
                                      userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
                    if let data = result.data {
                        error.addDecodeFailedInfoIfNeeded(data: data)
                    }
                    tracker.send(.failure(error))
                    DispatchQueue.main.async {
                        resultCompletionHandler(nil, error)
                    }
                }
            }
        }
        // 先尝试获取内存缓存当中有没有图片，分片超大图是不会在内存中的，但非超大图可能在内存中
        let resourceWithSuffix = Self.imageResource(resource, withSizeSuffix: LarkImageService.shared.imageSetting.downsample.image.pxSize)
        if let image = LarkImageService.shared.image(with: resourceWithSuffix, cacheOptions: .memory) {
            tracker.send(.success(.memoryCache),
                         imageSize: image.bt.destPixelSize,
                         originSize: image.bt.pixelSize,
                         decryptCost: 0, decodeCost: 0, rustCost: [:],
                         dataLength: image.bt.dataCount,
                         imageCount: Int((image as? ByteImage)?.frameCount ?? UInt(image.images?.count ?? 1)),
                         imageType: image.bt.imageFileFormat)
            do {
                let request = try LarkImageRequest(resource: resource) // 手动构建一个 request
                let result = ImageResult(request: request,
                                         image: image,
                                         data: nil,
                                         from: .memoryCache,
                                         savePath: nil)
                resultCompletionHandler(result, nil)
            } catch {
                resultCompletionHandler(nil, error)
            }
            LarkImageService.shared.setImage(
                with: resource,
                options: [.onlyQueryCache, .ignoreImage, .needCachePath],
                completion:  { result in
                    if case .success(let imageResult) = result {
                        self.savePath = imageResult.savePath
                    }
                })
        } else {
            // 内存没有，去磁盘/网络取吧
            var imageRequeseOptions: ImageRequestOptions = [.notCache(.memory), .ignoreImage,
                                                            .needCachePath, .ignoreCache(.memory)]
            imageRequeseOptions.append(self.additonImageRequestOptions ?? [])
            LarkImageService.shared.setImage(
                with: resource,
                passThrough: passThrough,
                options: imageRequeseOptions,
                progress: { _, rSize, eSize in
                    progressBlock(Int64(rSize), Int64(eSize))
            }, completion: { [weak self] result in
                guard let `self` = self else { return }
                switch result {
                case var .success(imageResult):
                    self.savePath = imageResult.savePath
                    if let data = imageResult.data {
                        do {
                            let imageSize = data.bt.imageSize
                            let size = LarkImageService.shared.imageSetting.downsample.image.pxValue
                            if ImageConfiguration.enableTile,
                               imageSize.width * imageSize.height > CGFloat(size) {
                                try self.tiledImageView.set(with: data)
                                let tileCallback = { (image: UIImage?, data: Data) in
                                    if let image = image {
                                        imageResult = ImageResult(request: imageResult.request,
                                                                  image: image,
                                                                  data: data,
                                                                  from: imageResult.from,
                                                                  savePath: imageResult.savePath)
                                    }
                                    tracker.send(.success(imageResult.from),
                                                 imageSize: self.tiledImageView.imageSize,
                                                 originSize: self.tiledImageView.imageSize,
                                                 decryptCost: imageResult.request.decryptCost,
                                                 rustCost: imageResult.request.rustCost ?? [:],
                                                 dataLength: data.count,
                                                 imageCount: data.bt.imageCount,
                                                 imageType: data.bt.imageFileFormat)
                                    Self.execInMainThread {
                                        /// 大图瓦片加载情况下不会生成UIImage对象回去
                                        resultCompletionHandler(imageResult, nil)
                                    }
                                }
                                let previewSize = LarkImageService.shared.imageSetting.downsample.tilePreviewImage.pxSize
                                let resourceWithPreviewSuffix = Self.imageResource(resource, withSizeSuffix: previewSize)
                                if let tilePreviewImage = LarkImageService.shared.image(with: resourceWithPreviewSuffix, cacheOptions: .memory) {
                                    tileCallback(tilePreviewImage, data)
                                } else {
                                    let tilePreviewImageSize = LarkImageService.shared.imageSetting.downsample.tilePreviewImage.pxSize
                                    self.decodeQueue.async {
                                        var previewImage: ByteImage?
                                        do {
                                            previewImage = try ByteImage(data, downsampleSize: tilePreviewImageSize)
                                            previewImage?.bt.webURL = resource.generateURL()
                                        } catch {
                                            Self.logger.error("[Tile] preview image generate failed: \(error)")
                                        }
                                        if let previewImage = previewImage {
                                            // 分片预览图也存进内存缓存
                                            LarkImageService.shared.cacheImage(image: previewImage,
                                                                               resource: resourceWithPreviewSuffix,
                                                                               cacheOptions: .memory)
                                        }
                                        tileCallback(previewImage, data)
                                    }
                                }
                            } else {
                                notTile(result: imageResult)
                            }
                        } catch {
                            notTile(result: imageResult)
                        }
                    }
                case let .failure(error):
                    tracker.send(.failure(error))
                    resultCompletionHandler(nil, error)
                }
            })
        }
    }
    // swiftlint:enable function_body_length

    // MARK: Utils
    private static func imageResource(_ resource: LarkImageResource, withSizeSuffix size: CGSize) -> LarkImageResource {
        func imageKey(_ key: String, withSizeSuffix size: CGSize) -> String {
            ByteWebImage.ImageCache.default.targetImageCacheKey(with: key, options: [], size: size)
        }
        switch resource {
        case .default(let key):
            return .default(key: imageKey(key, withSizeSuffix: size))
        case .sticker(let key, let stickerSetID, let downloadDirectory):
            return .sticker(key: imageKey(key, withSizeSuffix: size), stickerSetID: stickerSetID, downloadDirectory: downloadDirectory)
        case .reaction(let key, let isEmojis):
            return .reaction(key: imageKey(key, withSizeSuffix: size), isEmojis: isEmojis)
        case .avatar(let key, let entityID, let params):
            return .avatar(key: imageKey(key, withSizeSuffix: size), entityID: entityID, params: params)
        case .rustImage(let key, let fsUnit, let crypto):
            return .rustImage(key: imageKey(key, withSizeSuffix: size), fsUnit: fsUnit, crypto: crypto)
        @unknown default:
            assertionFailure("should handle unknown case!!")
            return .default(key: "")
        }
    }

    private static func execInMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}

// MARK: - Analytics & Monitoring

// swiftlint:disable identifier_name
public let ImageAssetFromTypeKey = "ImageAssetFromTypeKey"
public let ImageShowOcrButtonKey = "ImageShowOcrButtonKey"
public let ImageShowOcrButtonSizeKey = "ImageShowOcrButtonSizeKey"
// swiftlint:enable identifier_name

private extension LKPhotoZoomingScrollView {

    private func getLogContent(forImage image: UIImage, key: String, isOrigin: Bool,
                               loadType: ImageResultFrom, fromType: TrackInfo.FromType?,
                               sdkCost: [String: UInt64]) -> (Category, Metric) {
        let category = Category(isOrigin: isOrigin,
                                imageType: image.bt.imageFileFormat.description,
                                fromType: (fromType ?? .unknown).rawValue,
                                colorSpace: image.bt.colorSpaceName ?? "",
                                loadType: loadType.rawValue,
                                isTiled: false)
        let metric = Metric(imageKey: key,
                            contentLength: image.bt.dataCount,
                            resourceWidth: Float(image.size.width * image.scale),
                            resourceHeight: Float(image.size.height * image.scale),
                            resourceFrames: Int((image as? ByteImage)?.frameCount ?? 1),
                            sdkCost: sdkCost)
        return (category, metric)
    }
    private func getLogContent(forData data: Data, key: String, isOrigin: Bool,
                               loadType: ImageResultFrom, fromType: TrackInfo.FromType?,
                               sdkCost: [String: UInt64]) -> (Category, Metric) {
        let colorSpace = UIImage(data: data)?.cgImage?.colorSpace?.name as? String // 方便获取 colorSpace，只要不渲染，就不会有性能问题
        let category = Category(isOrigin: isOrigin,
                                imageType: data.bt.imageFileFormat.description,
                                fromType: (fromType ?? .unknown).rawValue,
                                colorSpace: colorSpace ?? "",
                                loadType: loadType.rawValue,
                                isTiled: true) // 目前只有分片加载会走这个接口
        let size = data.bt.imageSize
        let metric = Metric(imageKey: key,
                            contentLength: data.count,
                            resourceWidth: Float(size.width),
                            resourceHeight: Float(size.height),
                            resourceFrames: data.bt.imageCount,
                            sdkCost: sdkCost)
        return (category, metric)
    }
}
