//
//  LKAssetBaseImagePage.swift
//  LKBaseAssetBrowser
//
//  Created by Hayden Wang on 2022/1/25.
//

import UIKit

public typealias LKAssetBaseImagePage = LKAssetBrowserBasicPage<UIImageView>

open class LKAssetBrowserBasicPage<GenericImageView: UIImageView>: UIView, UIScrollViewDelegate, UIGestureRecognizerDelegate, LKGalleryPage, LKZoomTransitionPage {

    public var assetIdentifier: String?

    /// 弱引用 AssetBrowser
    open weak var assetBrowser: LKAssetBrowser?

    public var index: Int = 0

    public var didFinishLoadingImage: (() -> Void)?

    public var scrollDirection: LKAssetBrowser.ScrollDirection = .horizontal {
        didSet {
            if scrollDirection == .horizontal {
                addPanGesture()
            } else if let existed = existedPan {
                scrollView.removeGestureRecognizer(existed)
            }
        }
    }

    open lazy var imageView: GenericImageView = {
        let view = GenericImageView()
        view.clipsToBounds = true
        return view
    }()

    public var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            view.contentInsetAdjustmentBehavior = .never
        }
        return view
    }()

    private lazy var loadingView: LKAssetLoadingView = {
        return LKAssetLoadingView(view: self)
    }()

    private var observation: NSKeyValueObservation?

    deinit {
        observation?.invalidate()
        LKAssetBrowserLogger.debug("deinit - \(self.classForCoder)")
    }

    public required override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    /// 生成实例
    public static func generate(with assetBrowser: LKAssetBrowser) -> Self {
        let cell = Self.init(frame: .zero)
        cell.assetBrowser = assetBrowser
        cell.scrollDirection = assetBrowser.scrollDirection
        return cell
    }

    /// 子类可重写，创建子视图。完全自定义时不必调super。
    public func constructSubviews() {
        scrollView.delegate = self
        addSubview(scrollView)
        scrollView.addSubview(imageView)
        addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    public func setup() {
        backgroundColor = .clear
        constructSubviews()

        /// 拖动手势
        addPanGesture()

        // 双击手势
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)

        // 单击手势
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(onSingleTap(_:)))
        singleTap.require(toFail: doubleTap)
        addGestureRecognizer(singleTap)

        observation = imageView.observe(\.image, options: [.new]) { [weak self] _, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.setNeedsLayout()
                self.didFinishLoadingImage?()
            }
        }
    }

    // 长按事件
    public typealias LongPressAction = (LKAssetBrowserBasicPage, UILongPressGestureRecognizer) -> Void

    /// 长按时回调。赋值时自动添加手势，赋值为nil时移除手势
    public var longPressedAction: LongPressAction? {
        didSet {
            if oldValue != nil && longPressedAction == nil {
                removeGestureRecognizer(longPress)
            } else if oldValue == nil && longPressedAction != nil {
                addGestureRecognizer(longPress)
            }
        }
    }

    /// 已添加的长按手势
    private lazy var longPress: UILongPressGestureRecognizer = {
        UILongPressGestureRecognizer(target: self, action: #selector(onLongPress(_:)))
    }()

    private weak var existedPan: UIPanGestureRecognizer?

    /// 添加拖动手势
    public func addPanGesture() {
        guard existedPan == nil else {
            return
        }
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
        pan.delegate = self
        // 必须加在图片容器上，否则长图下拉不能触发
        scrollView.addGestureRecognizer(pan)
        existedPan = pan
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
        let size = computeImageLayoutSize(for: imageView.image, in: scrollView)
        let origin = computeImageLayoutOrigin(for: size, in: scrollView)
        imageView.transform = .identity
        imageView.frame = CGRect(origin: origin, size: size)
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
        scrollView.lu.scrollToTop(animated: false)
    }

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        imageView.center = computeImageLayoutCenter(in: scrollView)
    }

    public func computeImageLayoutSize(for image: UIImage?, in scrollView: UIScrollView) -> CGSize {
        let containerSize = scrollView.bounds.size
        guard containerSize.width > 0, containerSize.height > 0 else {
            setProperZoomScale(forBounds: scrollView.bounds.size, imageSize: CGSize(width: 100, height: 100))
            return .zero
        }
        guard let imageSize = image?.size, imageSize.width > 0 && imageSize.height > 0 else {
            setProperZoomScale(forBounds: scrollView.bounds.size, imageSize: CGSize(width: 100, height: 100))
            return .zero
        }
        var width: CGFloat
        var height: CGFloat
        if scrollDirection == .horizontal {
            if containerSize.height / containerSize.width > imageSize.height / imageSize.width {
                // 横向撑满
                width = containerSize.width
                height = imageSize.height / imageSize.width * width
            } else {
                // 竖向撑满
                height = containerSize.height
                width = imageSize.width / imageSize.height * height
            }
        } else {
            width = containerSize.width
            height = imageSize.height / imageSize.width * width
            if height > containerSize.height {
                height = containerSize.height
                width = imageSize.width / imageSize.height * height
            }
        }
        setProperZoomScale(forBounds: scrollView.bounds.size, imageSize: imageSize)
        return CGSize(width: width, height: height)
    }

    private var minimumZoomScale: CGFloat {
        get { scrollView.minimumZoomScale }
        set { scrollView.minimumZoomScale = newValue }
    }

    private var maximumZoomScale: CGFloat {
        get { scrollView.maximumZoomScale }
        set { scrollView.maximumZoomScale = newValue }
    }

    private var doubleTapZoomScale: CGFloat = 1.0

    private func setProperZoomScale(forBounds boundsSize: CGSize,
                                    imageSize: CGSize) {
        let imageRatio = imageSize.height / imageSize.width
        let screenRatio = boundsSize.height / boundsSize.width
        // 计算填满屏幕的缩放比例
        if imageRatio > screenRatio {
            // 长图
            /*
            minimumZoomScale = 1.0
            doubleTapZoomScale = imageRatio / screenRatio
             */
            minimumZoomScale = imageRatio / screenRatio
            doubleTapZoomScale = minimumZoomScale * 2
        } else {
            // 宽图 / 方图
            minimumZoomScale = 1.0
            doubleTapZoomScale = screenRatio / imageRatio
        }
        // 设置缩放比例
        maximumZoomScale = max(doubleTapZoomScale, minimumZoomScale * 5)
        // 考虑进去图片本身的大小，调整 maximumZoomScale
        let originalZoomScale = max(imageSize.width / boundsSize.width, imageSize.height / boundsSize.height)
        if originalZoomScale < 1.0 {
            // 如果图片本身非常小（比屏幕还小），应限制 maximumZoomScale，避免不清晰
            maximumZoomScale = doubleTapZoomScale
        } else if originalZoomScale > maximumZoomScale {
            // 如果图片本身非常大（比最大缩放后还大），应增加 maximumZoomScale，避免看不清
            maximumZoomScale = originalZoomScale
        }
    }

    public func computeImageLayoutOrigin(for imageViewSize: CGSize, in scrollView: UIScrollView) -> CGPoint {
        let containerSize = scrollView.bounds.size
        var y = (containerSize.height - imageViewSize.height) * 0.5
        y = max(0, y)
        var x = (containerSize.width - imageViewSize.width) * 0.5
        x = max(0, x)
        return CGPoint(x: x, y: y)
    }

    public func computeImageLayoutCenter(in scrollView: UIScrollView) -> CGPoint {
        var x = scrollView.contentSize.width * 0.5
        var y = scrollView.contentSize.height * 0.5
        let offsetX = (bounds.width - scrollView.contentSize.width) * 0.5
        if offsetX > 0 {
            x += offsetX
        }
        let offsetY = (bounds.height - scrollView.contentSize.height) * 0.5
        if offsetY > 0 {
            y += offsetY
        }
        return CGPoint(x: x, y: y)
    }

    /// 单击
    @objc public func onSingleTap(_ tap: UITapGestureRecognizer) {
        assetBrowser?.dismiss()
    }

    /// 双击
    @objc public func onDoubleTap(_ tap: UITapGestureRecognizer) {
        // 如果当前没有任何缩放，则放大到目标比例，否则重置到原比例
        if scrollView.zoomScale < scrollView.minimumZoomScale * 1.01 {
            // 以点击的位置为中心，放大
            let pointInView = tap.location(in: imageView)
            let width = scrollView.bounds.size.width / doubleTapZoomScale
            let height = scrollView.bounds.size.height / doubleTapZoomScale
            let x = pointInView.x - (width / 2.0)
            let y = pointInView.y - (height / 2.0)
            scrollView.zoom(to: CGRect(x: x, y: y, width: width, height: height), animated: true)
        } else {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }

    /// 长按
    @objc public func onLongPress(_ press: UILongPressGestureRecognizer) {
        if press.state == .began {
            longPressedAction?(self, press)
        }
    }

    /// 记录pan手势开始时imageView的位置
    private var beganFrame = CGRect.zero

    /// 记录pan手势开始时，手势位置
    private var beganTouch = CGPoint.zero

    /// 响应拖动
    @objc public func onPan(_ pan: UIPanGestureRecognizer) {
        guard imageView.image != nil else {
            return
        }
        switch pan.state {
        case .began:
            beganFrame = imageView.frame
            beganTouch = pan.location(in: scrollView)
        case .changed:
            let result = panResult(pan)
            imageView.frame = result.frame
            assetBrowser?.dimmingView.alpha = result.scale * result.scale
            assetBrowser?.setStatusBarHidden(result.scale < 0.99)
            assetBrowser?.pageIndicator?.isHidden = result.scale < 0.99
        case .ended, .cancelled:
            imageView.frame = panResult(pan).frame
            let isDown = pan.velocity(in: self).y > 0
            if isDown {
                assetBrowser?.dismiss()
            } else {
                assetBrowser?.dimmingView.alpha = 1.0
                assetBrowser?.setStatusBarHidden(true)
                assetBrowser?.pageIndicator?.isHidden = false
                resetImageViewPosition()
            }
        default:
            resetImageViewPosition()
        }
    }

    /// 计算拖动时图片应调整的frame和scale值
    private func panResult(_ pan: UIPanGestureRecognizer) -> (frame: CGRect, scale: CGFloat) {
        // 拖动偏移量
        let translation = pan.translation(in: scrollView)
        let currentTouch = pan.location(in: scrollView)

        // 由下拉的偏移值决定缩放比例，越往下偏移，缩得越小。scale值区间[0.3, 1.0]
        let scale = min(1.0, max(0.3, 1 - translation.y / bounds.height))

        let width = beganFrame.size.width * scale
        let height = beganFrame.size.height * scale

        // 计算x和y。保持手指在图片上的相对位置不变。
        // 即如果手势开始时，手指在图片X轴三分之一处，那么在移动图片时，保持手指始终位于图片X轴的三分之一处
        let xRate = (beganTouch.x - beganFrame.origin.x) / beganFrame.size.width
        let currentTouchDeltaX = xRate * width
        let x = currentTouch.x - currentTouchDeltaX

        let yRate = (beganTouch.y - beganFrame.origin.y) / beganFrame.size.height
        let currentTouchDeltaY = yRate * height
        let y = currentTouch.y - currentTouchDeltaY

        return (CGRect(x: x.isNaN ? 0 : x, y: y.isNaN ? 0 : y, width: width, height: height), scale)
    }

    /// 复位ImageView
    private func resetImageViewPosition() {
        // 如果图片当前显示的size小于原size，则重置为原size
        assetBrowser?.setStatusBarHidden(false)
        let size = computeImageLayoutSize(for: imageView.image, in: scrollView)
        let needResetSize = imageView.bounds.size.width < size.width || imageView.bounds.size.height < size.height
        UIView.animate(withDuration: 0.25) {
            self.imageView.center = self.computeImageLayoutCenter(in: self.scrollView)
            if needResetSize {
                self.imageView.bounds.size = size
            }
        }
    }

    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // 只处理pan手势
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        let velocity = pan.velocity(in: self)
        // 向上滑动时，不响应手势
        if velocity.y < 0 {
            return false
        }
        // 横向滑动时，不响应pan手势
        if abs(Int(velocity.x)) > Int(velocity.y) {
            return false
        }
        // 向下滑动，如果图片顶部超出可视区域，不响应手势
        if scrollView.contentOffset.y > 0 {
            return false
        }
        // 响应允许范围内的下滑手势
        return true
    }

    public var showContentView: UIView {
        return imageView
    }

    public func prepareForReuse() {
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 2.0
        scrollView.zoomScale = 1.0
        imageView.transform = .identity
        imageView.image = nil
    }

    public func showLoading() {
        loadingView.show(animated: true)
    }

    public func hideLoading() {
        loadingView.hide(animated: false)
    }
}
