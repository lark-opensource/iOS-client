//
//  BaseImageViewWrapper.swift
//  LarkUIKit
//
//  Created by wangwanxin on 2023/3/20.
//

import Foundation
import ByteWebImage
import SnapKit

/// BaseImageViewWrapper 目前用在RichText中的图片，或者单个消息图片。
/// 里面封装有长图、图片宽高计算，mask蒙层，GIF，图片loading, progress等
open class BaseImageViewWrapper: UIView {
    
    public typealias ImageViewCompletion = (UIImage?, Error?) -> Void
    public typealias ImageViewTappedCallback = (BaseImageViewWrapper) -> Void
    public typealias DownloadFailedLayerProvider = (Error) -> UIView?
    public typealias SetImageType = ((UIImageView, @escaping ImageViewCompletion) -> Void)

    enum ImageLoadState {
        case none
        case loading
        case success
        case fail
    }

    public enum DownloadFailureViewType {
        case image
        case placeholderColor
    }
    
    // 为了不引用LarkSDKInterface->UserGeneralSettings->GIFLoadConfig定义的变量
    public struct GIFLoadConfig {
        /// 文件大小超过此值，不自动播放
        public var size: Int = 0
        /// GIF 宽高乘积超过此阈值，不自动播放
        public var width: Int = 0
        /// GIF 宽高乘积超过此阈值，不自动播放
        public var height: Int = 0
        
        public init() {}
    }


    /// 显示图片的view
    public let imageView: BaseImageView

    private var setImageAction: SetImageType?
    
    private var tapGestureAdded: Bool = false

    private var imageLoadState: ImageLoadState = .none

    private var shouldGifAnamated: Bool = true

    // 避免访问 lazy 属性导致初始化
    private weak var _tipView: UILabel?
    private lazy var tipView: UILabel = { [weak self] in
        let label = UILabel()
        label.numberOfLines = 2
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.5)
        label.layer.cornerRadius = 2
        label.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        label.textAlignment = .center
        self?.addSubview(label)
        label.isHidden = true
        self?._tipView = label
        return label
    }()

    public var imageTappedCallback: ImageViewTappedCallback? {
        didSet {
            if !tapGestureAdded {
                self.lu.addTapGestureRecognizer(action: #selector(imageViewDidTapped(_:)), target: self)
                tapGestureAdded = true
            }
        }
    }

    private var originSize: CGSize = .zero {
        didSet {
            guard originSize != oldValue else { return }
            self.imageView.origionSize = originSize
            self.invalidateIntrinsicContentSize()
        }
    }

    private var minSize: CGSize = .zero {
        didSet {
            guard minSize != oldValue else { return }
            self.imageView.minSize = minSize
            self.invalidateIntrinsicContentSize()
        }
    }
    private var maxSize: CGSize = .zero {
        didSet {
            guard maxSize != oldValue else { return }
            self.imageView.maxSize = maxSize
            self.invalidateIntrinsicContentSize()
        }
    }

    public let centerYOffset: CGFloat
    public let failureViewType: DownloadFailureViewType
    public let gifLoadConfig: GIFLoadConfig

    public override var intrinsicContentSize: CGSize {
        Self.calculateSize(originSize: originSize, maxSize: maxSize, minSize: minSize)
    }

    /// 自定义下载失败提示 layer, 用于根据 error 特化错误展示，自定义 layer 不会被复用
    public var downloadFailedLayerProvider: DownloadFailedLayerProvider?
    /// 是否使用自定义下载失败 layer
    private var useCustomDownloadFailedLayer: Bool = false

    /// needMask: 在DM下，是否给图片加蒙层，默认情况下是有的，表情需要特化，不加蒙层
    public init(maxSize: CGSize,
                minSize: CGSize,
                failureViewType: DownloadFailureViewType = .image,
                centerYOffset: CGFloat = 0,
                gifLoadConig: GIFLoadConfig = .init()
    ) {
        imageView = BaseImageView(maxSize: maxSize, minSize: minSize)
        self.minSize = minSize
        self.maxSize = maxSize
        self.centerYOffset = centerYOffset
        self.failureViewType = failureViewType
        self.gifLoadConfig = gifLoadConig
        super.init(frame: .zero)
        self.addSubview(imageView)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    public func imageViewDidTapped(_ gesture: UIGestureRecognizer) {
        self.imageTappedCallback?(self)
    }

    /// 设置图片原始大小和图片设置回调
    ///
    /// - Parameters:
    ///   - originSize: 图片原始大小
    ///   - imageTappedCallback: 图片点击回调
    ///   - setImageAction: 设置图片回调
    public func set(
        originSize: CGSize,
        maxSize: CGSize? = nil,
        minSize: CGSize? = nil,
        needLoading: Bool,
        needMask: Bool = true,
        needBackdrop: Bool = true,
        animatedDelegate: AnimatedViewDelegate?,
        forceStartIndex: Int,
        forceStartFrame: UIImage?,
        imageTappedCallback: @escaping ImageViewTappedCallback,
        setImageAction: @escaping SetImageType,
        downloadFailedLayerProvider: DownloadFailedLayerProvider? = nil
    ) {
        self.imageTappedCallback = imageTappedCallback
        self.setImageAction = setImageAction
        self.downloadFailedLayerProvider = downloadFailedLayerProvider

        self.originSize = originSize

        if let maxSize = maxSize {
            self.maxSize = maxSize
        }
        if let minSize = minSize {
            self.minSize = minSize
        }
        imageView.needMask = needMask
        imageView.needBackdrop = needBackdrop

        // layout
        let imageSize = imageView.intrinsicContentSize
        if imageView.showStripeImage {
            imageView.snp.remakeConstraints {
                $0.top.width.equalToSuperview()
                $0.height.equalTo(imageView.snp.width).multipliedBy(imageSize.height / imageSize.width)
            }
        } else if (imageSize.width < self.minSize.width || imageSize.height < self.minSize.height) &&
                    imageView.adaptiveContentModel {
            imageView.snp.remakeConstraints {
                $0.center.equalToSuperview()
                $0.size.equalTo(imageSize)
            }
        } else {
            imageView.snp.remakeConstraints {
                $0.edges.equalToSuperview()
            }
        }
        self.showImage(
            needLoading: needLoading,
            animatedDelegate: animatedDelegate,
            forceStartIndex: forceStartIndex,
            forceStartFrame: forceStartFrame
        )
    }

    /// 当图片设置失败时重试
    public func retryIfNeed(needLoading: Bool, animatedDelegate: AnimatedViewDelegate?, forceStartIndex: Int, forceStartFrame: UIImage?) {
        guard imageLoadState == .fail else { return }
        showImage(needLoading: needLoading, animatedDelegate: animatedDelegate, forceStartIndex: forceStartIndex, forceStartFrame: forceStartFrame)
    }

    /// 针对gif提供的停止动画和开始动画的接口
    ///
    /// - Parameter animated: 是否开启动画
    public func toggleAnimation(_ animated: Bool) {
        if self.shouldGifAnamated {
            if animated {
                self.imageView.startAnimating()
            } else {
                self.imageView.stopAnimating()
            }
        }
    }
    
    open func getGIFLoadConfig() -> GIFLoadConfig {
        return gifLoadConfig
    }
    
    private func showGifTipsIfNeeded(_ image: UIImage?, gifPlayView: ByteImageView) -> Bool {
        if let byteImage = image as? ByteImage,
           byteImage.bt.isAnimatedImage {
            let config = getGIFLoadConfig()
            let dataCount = byteImage.bt.dataCount
            let imagePixels = CGFloat(byteImage.bt.destPixelSize.width * byteImage.bt.destPixelSize.height)
            let configPixels = CGFloat(config.width * config.height)
            if config.size != 0 && dataCount > config.size || configPixels != 0 && imagePixels > configPixels {
                self.showGifTips()
                self.shouldGifAnamated = false
                return true
            }
        }
        self.shouldGifAnamated = true
        gifPlayView.play()
        return false
    }

    @discardableResult
    private func showStripeTipIfNeeded(showGIF: Bool) -> Bool {
        guard !showGIF && imageView.showStripeImage else { return false }
        showTip(BundleI18n.LarkUIKit.Lark_Groups_PostPhotostrip)
        return true
    }

    /// 计算图片应该显示的大小
    ///
    /// - Parameters:
    ///   - originSize: 原始大小
    ///   - maxSize: 最大显示大小
    ///   - minSize: 最小显示大小
    /// - Returns: 应该显示的大小
    public static func calculateSize(originSize: CGSize, maxSize: CGSize, minSize: CGSize) -> CGSize {
        if BaseImageView.showStripeImage(originSize: originSize, maxSize: maxSize) {
            return BaseImageView.Cons.stripeImageDisplaySize
        }
        let imageSize = BaseImageView.calculateSizeAndContentMode(originSize: originSize,
                                                                  maxSize: maxSize,
                                                                  minSize: minSize).0
        return CGSize(width: max(imageSize.width, minSize.width), height: max(imageSize.height, minSize.height))
    }

    public func showLoadingIfNeeded() {
        if self.imageLoadState == .loading {
            self.showDownloadProgressLayer()
        }
    }
}

extension BaseImageViewWrapper {
    
    private static let downloadProgressLayerTag = 889_988
    private static let downloadFailedLayerTag = 779_977

    /// 大GIF不播放标志
    ///
    private func showGifTips() {
        showTip("GIF")
    }

    func showTip(_ tip: String) {
        tipView.text = tip
        // layout
        let paddingSize = CGSize(width: 6 * 2, height: 2 * 2)
        let sizeToFit = self.imageView.bounds.size - paddingSize
        let sizeWithPadding = tipView.sizeThatFits(sizeToFit) + paddingSize
        let boundsWithPadding = CGRect(origin: .zero, size: sizeWithPadding)
        let path = UIBezierPath(roundedRect: boundsWithPadding,
                                byRoundingCorners: .topLeft,
                                cornerRadii: CGSize(width: 2, height: 2))
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = boundsWithPadding
        shapeLayer.path = path.cgPath
        tipView.layer.mask = shapeLayer
        tipView.snp.remakeConstraints({ (make) in
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(sizeWithPadding.width)
            make.height.equalTo(sizeWithPadding.height)
        })
        tipView.isHidden = false
    }
    func hideTip() {
        _tipView?.text = ""
        _tipView?.isHidden = true
    }

    private func showImage(needLoading: Bool, animatedDelegate: AnimatedViewDelegate?, forceStartIndex: Int, forceStartFrame: UIImage?) {
        /// 自定义表情
        self.hideDownloadFailedLayer()
        self.hideTip()
        if needLoading {
            self.imageLoadState = .loading
            self.showDownloadProgressLayer()
        } else {
            if self.imageLoadState == .loading {
                self.imageLoadState = .none
            }
            self.hideDownloadProgressLayer()
        }
        self.imageView.animatedDelegate = animatedDelegate
        self.imageView.forceStartIndex = forceStartIndex
        self.imageView.forceStartFrame = forceStartFrame
        self.imageView.autoPlayAnimatedImage = false
        // 这里的image指当前view上贴的image，可能是请求成功得到的图片，也可能是placeholder的inline图
        self.setImageAction?(self.imageView, { [weak self] (image, error) in
            guard let `self` = self else { return }
            if let error = error {
                // 请求失败后，会返回占位的inline图。但inline能力的FG还在灰度中，此处需要判断
                self.imageLoadState = .fail
                self.hideDownloadProgressLayer()
                if image == nil {
                    self.showDownloadFailedLayer(error: error)
                }
            } else {
                // 多次重复请求时，前面的请求结果不作为error，因此这里判断image != nil视为请求成功去掉loading态
                if self.imageView.image == nil {
                    return
                }
                self.imageLoadState = .success
                let showGIF = self.showGifTipsIfNeeded(image, gifPlayView: self.imageView)
                self.showStripeTipIfNeeded(showGIF: showGIF)
                self.hideDownloadProgressLayer()
                self.hideDownloadFailedLayer()
            }
        })
    }

    /// show loading animation
    private func showDownloadProgressLayer() {
        if let view = self.viewWithTag(Self.downloadProgressLayerTag) {
            view.isHidden = false
            view.lu.addRotateAnimation()
        } else {
            let loadingView = UIImageView(image: Resources.imageLoading)
            loadingView.tag = Self.downloadProgressLayerTag
            self.addSubview(loadingView)
            loadingView.snp.makeConstraints({ (make) in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview().offset(self.centerYOffset)
                make.width.height.equalTo(30)
            })
            loadingView.lu.addRotateAnimation()
        }
    }

    /// hide loading animation
    private func hideDownloadProgressLayer() {
        if let view = self.viewWithTag(Self.downloadProgressLayerTag) {
            view.lu.removeRotateAnimation()
            view.isHidden = true
        }
    }

    private func showDownloadFailedLayer(error: Error) {
        if let view = self.viewWithTag(Self.downloadFailedLayerTag) {
            view.isHidden = false
        } else {
            var customFailedLayer = downloadFailedLayerProvider?(error)
            self.useCustomDownloadFailedLayer = customFailedLayer != nil
            let failedLayer = customFailedLayer ?? DownloadFailedView(frame: .zero, failureViewType: self.failureViewType)
            failedLayer.tag = Self.downloadFailedLayerTag
            self.addSubview(failedLayer)
            failedLayer.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
        self.gestureRecognizers?.forEach({ (gesture) in
            if let tap = gesture as? UITapGestureRecognizer {
                tap.isEnabled = false
            }
        })
    }

    private func hideDownloadFailedLayer() {
        if let view = self.viewWithTag(Self.downloadFailedLayerTag) {
            if self.useCustomDownloadFailedLayer {
                /// 如何是自定义失败 layer，则删除 view 并且恢复 useCustomDownloadFailedLayer
                view.removeFromSuperview()
                self.useCustomDownloadFailedLayer = false
            } else {
                view.isHidden = true
            }
        }
        self.gestureRecognizers?.forEach({ (gesture) in
            if let tap = gesture as? UITapGestureRecognizer {
                tap.isEnabled = true
            }
        })
    }
}

extension CGSize {
    static func - (_ lhs: CGSize, _ rhs: CGSize) -> CGSize {
        return CGSize(width: lhs.width - rhs.width,
                      height: lhs.height - rhs.height)
    }
    static func + (_ lhs: CGSize, _ rhs: CGSize) -> CGSize {
        return CGSize(width: lhs.width + rhs.width,
                      height: lhs.height + rhs.height)
    }
}

