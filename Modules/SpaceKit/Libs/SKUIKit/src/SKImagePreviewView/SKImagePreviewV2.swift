//
//  SKImagePreviewV2.swift
//  SKUIKit
//
//  Created by tanyunpeng on 2023/6/16.
//

import UIKit
import SnapKit
import SKFoundation
import RxSwift
import RxCocoa
import ByteWebImage

public final class SKImagePreviewViewV2: UIView, BaseSKImageView {
    public struct PreviewConfiguration {
        public var originScale: CGFloat
        public var fillScale: CGFloat
        public var maxScale: CGFloat

        public init(originScale: CGFloat = 1.0, fillScale: CGFloat = 1.0, maxScale: CGFloat = 5.0) {
            self.originScale = originScale
            self.fillScale = fillScale
            self.maxScale = maxScale
        }
    }

    private let processQueue: DispatchQueue = DispatchQueue(label: "SKImagePreviewView.processor")
    private var previewStratery: SKImagePreviewStrategy
    private var config: PreviewConfiguration
    private var openScaleToFill: Bool = false // 打开后自动填充屏幕，docs长图支持
    private var tileSize: CGSize? // 指定tileSize， 长图tileSize为一个一屏

    // MARK: UI
    private var tileImageView: DriveTileImageView?
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView(frame: CGRect(origin: .zero, size: frame.size))
        view.clipsToBounds = true
        view.minimumZoomScale = config.originScale
        view.maximumZoomScale = config.maxScale
        view.backgroundColor = .clear
        view.delegate = self
        return view
    }()
    private lazy var imageView: ByteImageView = {
        let view = ByteImageView()
        view.backgroundColor = UIColor.clear
        view.contentMode = .center
        view.isUserInteractionEnabled = true
        view.center = CGPoint(x: self.bounds.size.width / 2, y: self.bounds.size.height / 2)
        return view
    }()

    private var loadingIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .gray)
        view.isHidden = true
        return view
    }()

    // MARK: Gesture
    private lazy var singleTap: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(gesture:)))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        tap.delegate = self
        return tap
    }()
    private lazy var doubleTap: UITapGestureRecognizer = {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(gesture:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 1
        doubleTap.delegate = self
        return doubleTap
    }()
    private lazy var longPress: UILongPressGestureRecognizer = {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(gesture:)))
        longPress.delegate = self
        return longPress
    }()


    private var imageDidLoad: Bool = false

    private var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            if let image = newValue {
                if let imagePath = path {
                    resize(with: SKImagePreviewUtils.originSizeOfImage(path: imagePath) ?? image.size)
                } else {
                    resize(with: image.size)
                }
            }
        }
    }

    /// 封装ImageView，避免业务直接使用imageView
    public var contentView: UIView {
        return imageView
    }
    public weak var delegate: SKImagePreviewViewDelegate?
    public var currentZoomScale = BehaviorRelay<CGFloat>(value: 1)

    private var isFirstLoad = true
    /// 用于同一张图片多次更新，渐进式图片需要设置多次，第一次设置需要resize，后续不需要resize避免闪动
    public func updateImage(_ image: UIImage?) {
        imageView.image = image
        if let newImage = image, isFirstLoad {
            isFirstLoad = false
            resize(with: newImage.size)
            // 第一次设置图片标识预览成功
            self.delegate?.imagePreviewViewSuccess(self)
        }
    }

    public var path: SKFilePath? {
        didSet {
            if let image = imageView.image, let imagePath = path , oldValue == path, imageDidLoad {
                resize(with: SKImagePreviewUtils.originSizeOfImage(path: imagePath) ?? image.size)
                return
            }
            imageDidLoad = false
            imageView.contentMode = .scaleAspectFit
            loadImage()
        }
    }

    // 提供给docs长图预览的接口，打开后自动填充
    // tileSize: 设置分块大小
    public func loadImageScaleToFill(path: SKFilePath, tileSize: CGSize? = nil) {
        self.path = path
        self.tileSize = tileSize
        openScaleToFill = true
    }

    public var bounces: Bool {
        get {
            return scrollView.bounces
        }
        set {
            scrollView.bounces = newValue
        }
    }

    public var isScrollEnabled: Bool {
        get {
            return scrollView.isScrollEnabled
        }
        set {
            scrollView.isScrollEnabled = newValue
        }
    }

    public func setZoomScale(_ scale: CGFloat, animated: Bool) {
        scrollView.setZoomScale(scale, animated: animated)
    }

    public func scale(to point: CGPoint, scale: CGFloat, animated: Bool = true) {
        let xsize = self.frame.width / scale
        let ysize = self.frame.height / scale
        let rectToZoom = CGRect(x: point.x / scrollView.zoomScale - xsize / 2,
                                y: point.y / scrollView.zoomScale - ysize / 2,
                                width: xsize,
                                height: ysize)
        scrollView.zoom(to: rectToZoom, animated: animated)
    }

    /// 禁用/开启 手势交互
    public var enableGuesture: Bool = true

    public init(frame: CGRect,
         config: PreviewConfiguration = PreviewConfiguration(),
         previewStratery: SKImagePreviewStrategy = SKImagePreviewDefaultStrategy()) {
        self.config = config
        self.previewStratery = previewStratery
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        self.previewStratery = SKImagePreviewDefaultStrategy()
        self.config = PreviewConfiguration()
        super.init(coder: aDecoder)
        commonInit()
    }

    public func updatePreviewStratery(_ stratery: SKImagePreviewStrategy) {
        self.previewStratery = stratery
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        guard !scrollView.frame.equalTo(bounds) else { return }
        scrollView.frame = bounds
        resetScrollView()
    }

    private func commonInit() {
        backgroundColor = .clear
        addSubview(scrollView)
        scrollView.addSubview(loadingIndicatorView)
        loadingIndicatorView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }

        scrollView.addSubview(imageView)
        setupGestures()
        bounces = true
        isScrollEnabled = true
    }

    private func resetScrollView() {
        scrollView.zoomScale = config.originScale
        scrollView.contentSize = .zero
        scrollView.contentOffset = .zero
        if let img = imageView.image {
            if let imagePath = path {
                resize(with: SKImagePreviewUtils.originSizeOfImage(path: imagePath) ?? img.size)
            } else {
                resize(with: img.size)
            }
            self.scaleToFillIfNeed()
        }
    }
}

// MARK: - Gestures
extension SKImagePreviewViewV2 {
    private func setupGestures() {
        addGestureRecognizer(singleTap)
        addGestureRecognizer(doubleTap)
        addGestureRecognizer(longPress)
        // 单击等待双击和长按检测失败后触发
        singleTap.require(toFail: doubleTap)
        singleTap.require(toFail: longPress)
    }

    @objc
    private func handleSingleTap(gesture: UITapGestureRecognizer) {
        delegate?.imagePreviewViewDidTap(self, location: gesture.location(in: self))
    }

    /// 双击放大缩小
    @objc
    private func handleDoubleTap(gesture: UITapGestureRecognizer) {
        let zoomScale = max(2, config.fillScale)
        if scrollView.zoomScale == zoomScale {
            scrollView.setZoomScale(config.originScale, animated: true)
        } else {
            scale(to: gesture.location(in: imageView), scale: zoomScale)
        }
    }

    /// 长按进入选区编辑状态
    @objc
    private func didLongPress(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            // long press
            delegate?.imagePreviewDidLongPress(self, location: gesture.location(in: self), zoomScale: scrollView.zoomScale)
        default:
            // do nothing
            DocsLogger.debug("long press default：\(gesture.state)")
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension SKImagePreviewViewV2: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    /// 如果正在编辑选区状态，不响应单击、双击、长按手势
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return enableGuesture
    }
}

// MARK: - Helpers
extension SKImagePreviewViewV2 {
    private func resize(with imageSize: CGSize) {
        tileImageView?.isHidden = true
        imageView.contentMode = .scaleAspectFit
        let imageRatio = imageSize.width / imageSize.height
        let size: CGSize
        let imageScale: CGFloat // 如果是长图，保证图片可以放大到原始大小查看
        if imageRatio < (frame.width / frame.height) {
            // 图片宽高比小于屏幕宽高比，即长图
            size = CGSize(width: frame.size.height * imageRatio, height: frame.size.height)
            config.fillScale = frame.width / size.width
            imageScale = max(config.maxScale, imageSize.width / size.width, config.fillScale)
        } else {
            // 图片宽高比小于屏幕宽高比，即横向长图
            size = CGSize(width: frame.size.width, height: frame.size.width / imageRatio)
            config.fillScale = frame.height / size.height
            imageScale = max(config.maxScale, imageSize.height / size.height, config.fillScale)
        }
        self.scrollView.maximumZoomScale = imageScale
        imageView.frame = CGRect(origin: .zero, size: size)
        imageView.center = CGPoint(x: bounds.size.width / 2,
                                   y: bounds.size.height / 2)

        imageViewFrameChanged()
    }
    
    private func loadImage() {
        defer {
            self.loadingIndicatorView.isHidden = true
            self.loadingIndicatorView.stopAnimating()
        }
        guard let path = self.path else { return }
        loadingIndicatorView.isHidden = false
        loadingIndicatorView.startAnimating()

        guard let data = try? Data.read(from: path),
              let image = try? ByteImage(data) else {
            DocsLogger.error("can not load image data from path: \(path)")
            self.delegate?.imagePreviewViewFailed(self)
            return
        }
        if self.isFirstLoad {
            self.resize(with: data.bt.imageSize)
        }
        self.imageDidLoad = true
        self.setupTileViewIfNeed()
        self.scaleToFillIfNeed()
        UIView.transition(with: self.imageView,
                          duration: 0.25,
                          options: [.curveEaseOut, .transitionCrossDissolve],
                          animations: {
            self.imageView.image = image
        })
        self.delegate?.imagePreviewViewSuccess(self)
    }

    private func setupTileViewIfNeed() {
        guard let imagePath = path else {
            DocsLogger.warning("path is nil")
            return
        }
        processQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.previewStratery.needTileImage(imagePath: imagePath) else {
                DocsLogger.info("no need to tile")
                return
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.tileImageView == nil {
                    let tileView = DriveTileImageView(imagePath: imagePath,
                                                      frame: self.imageView.bounds,
                                                      tileSize: self.tileSize)
                    self.tileImageView = tileView
                    self.imageView.insertSubview(tileView, at: 0)
                    self.tileImageView?.snp.makeConstraints({ (make) in
                        make.edges.equalToSuperview()
                    })
                    self.tileImageView?.isHidden = true
                }
            }
        }
    }

    private func scaleToFillIfNeed() {
        if openScaleToFill && config.fillScale > 1 {
            DocsLogger.info("scaleToFill")
            scale(to: .zero, scale: config.fillScale, animated: false)
            showTileImageViewIfNeed(scale: config.fillScale)
            openScaleToFill = false
        }
    }

    private func showTileImageViewIfNeed(scale: CGFloat) {
        if scale >= config.fillScale - 1 {
            tileImageView?.isHidden = false
        } else {
            tileImageView?.isHidden = true
        }
    }

    /// imageView frame相对 self发生变化
    private func imageViewFrameChanged() {
        DocsLogger.debug("edit area view rect2: \(scrollView.convert(imageView.frame, to: self))")
        delegate?.imagePreviewViewUpdated(self, imagviewFrame: scrollView.convert(imageView.frame, to: self))
    }
}

// MARK: - UIScrollViewDelegate
extension SKImagePreviewViewV2: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        var offsetX = (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5
        offsetX = offsetX > 0 ? offsetX : 0
        var offsetY = (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5
        offsetY = offsetY > 0 ? offsetY : 0
        imageView.center = CGPoint(x: offsetX + scrollView.contentSize.width * 0.5,
                                   y: offsetY + scrollView.contentSize.height * 0.5)
        imageViewFrameChanged()
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        DocsLogger.debug("didscroll contentOffset: \(scrollView.contentOffset)")
        imageViewFrameChanged()
    }
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        currentZoomScale.accept(scrollView.zoomScale)
        imageViewFrameChanged()
        DocsLogger.debug("tileView scroll scale: \(scale)")
        showTileImageViewIfNeed(scale: scale)
    }
}

public protocol BaseSKImageView: UIView {
    
    var contentView: UIView { get  }

    var bounces: Bool { get set }

    var isScrollEnabled: Bool { get set }

    var enableGuesture: Bool { get set }

    var path: SKFilePath? { get set }

    var currentZoomScale: BehaviorRelay<CGFloat> { get set }

    func setZoomScale(_ scale: CGFloat, animated: Bool)

    func scale(to point: CGPoint, scale: CGFloat, animated: Bool)

    func updatePreviewStratery(_ stratery: SKImagePreviewStrategy)
}
