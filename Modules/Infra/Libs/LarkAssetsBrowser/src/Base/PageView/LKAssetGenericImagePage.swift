//
//  LKAssetGenericImagePage.swift
//  LarkAssetsBrowser
//
//  Created by Hayden on 2023/5/22.
//

import UIKit

open class LKAssetImagePage<GenericImageView: UIImageView>: UIView, UIGestureRecognizerDelegate {

    public var assetIdentifier: String?

    /// 弱引用 AssetBrowser
    open weak var assetBrowser: LKAssetBrowser?

    public var index: Int = 0

    public var scrollDirection: LKAssetBrowser.ScrollDirection = .horizontal {
        didSet {
            if scrollDirection == .horizontal {
                addPanGesture()
            } else if let existed = existedPan {
                scrollView.removeGestureRecognizer(existed)
            }
        }
    }

    var didFinishLoadingImage: (() -> Void)?

    open lazy var imageView: GenericImageView = {
        let view = GenericImageView()
        view.clipsToBounds = true
        return view
    }()

    private var observation: NSKeyValueObservation?

    public var scrollView = ImageScrollView()

    private lazy var loadingView: LKAssetLoadingView = {
        return LKAssetLoadingView(view: self)
    }()

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

    /// 子类可重写，创建子视图。完全自定义时不必调super。
    public func constructSubviews() {
        addSubview(scrollView)
        addSubview(loadingView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        observation = imageView.observe(\.image, options: [.new]) { [weak self] imageView, _ in
            guard let self = self else { return }
            /* 根据图片大小设置 contentMode
            if let image = imageView.image {
                if self.bounds.width > self.bounds.height {
                    self.scrollView.imageContentMode = .heightFill
                } else {
                    self.scrollView.imageContentMode = .widthFill
                }
            }
            */
            self.scrollView.imageView = self.imageView
            self.didFinishLoadingImage?()
        }
    }

    public func setup() {
        backgroundColor = .clear
        constructSubviews()

        /// 拖动手势
        addPanGesture()

        // 单击手势
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(onSingleTap(_:)))
        singleTap.require(toFail: scrollView.doubleTapGesture)
        addGestureRecognizer(singleTap)

        scrollView.setup()
    }

    // 长按事件
    public typealias LongPressAction = (LKAssetImagePage, UILongPressGestureRecognizer) -> Void

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

    private var beganTransform: CGAffineTransform = .identity

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

    /// 单击
    @objc
    public func onSingleTap(_ tap: UITapGestureRecognizer) {
        assetBrowser?.dismiss()
    }

    /// 长按
    @objc
    public func onLongPress(_ press: UILongPressGestureRecognizer) {
        if press.state == .began {
            longPressedAction?(self, press)
        }
    }

    public func showLoading() {
        loadingView.show(animated: true)
    }

    public func hideLoading() {
        loadingView.hide(animated: false)
    }

    // MARK: 处理下滑手势

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

    /// 响应拖动
    @objc public func onPan(_ pan: UIPanGestureRecognizer) {
        guard imageView.image != nil else {
            return
        }
        switch pan.state {
        case .began:
            beganTransform = imageView.transform
        case .changed:
            let result = getPanTransformResult(pan)
            let trans = result.translation
            if beganTransform.isIdentity {
                imageView.transform = beganTransform.translatedBy(x: trans.x, y: trans.y)
            } else {
                let scaleX = beganTransform.a
                let scaleY = beganTransform.d
                // 跟随 UIScrollView 的 zoom 只会影响到 scale，如果有 rotation 则要用以下计算方式
                // let scaleX = sqrt(pow(beganTransform.a, 2) + pow(beganTransform.c, 2))
                // let scaleY = sqrt(pow(beganTransform.b, 2) + pow(beganTransform.d, 2))
                imageView.transform = beganTransform.translatedBy(x: trans.x / scaleX, y: trans.y / scaleY)
            }
            assetBrowser?.dimmingView.alpha = result.scale * result.scale
            assetBrowser?.setStatusBarHidden(result.scale > 0.99)
            if let pageIndicator = assetBrowser?.pageIndicator, !pageIndicator.isHidden {
                pageIndicator.isHidden = result.scale < 0.99
            }
        case .ended, .cancelled:
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
    private func getPanTransformResult(_ pan: UIPanGestureRecognizer) -> (translation: CGPoint, scale: CGFloat) {
        // 拖动偏移量
        let translation = pan.translation(in: scrollView)
        // 由下拉的偏移值决定缩放比例，越往下偏移，缩得越小。scale值区间[0.3, 1.0]
        let scale = min(1.0, max(0.3, 1 - translation.y / bounds.height))
        return (translation, scale)
    }

    /// 复位ImageView
    private func resetImageViewPosition() {
        UIView.animate(withDuration: 0.25) {
            self.imageView.transform = self.beganTransform
        }
    }
}

// MARK: - 实现 LKZoomTransitionPage 协议

extension LKAssetImagePage: LKZoomTransitionPage {

    public var showContentView: UIView {
        return imageView
    }
}

// MARK: - 实现 LKAssetBrowserPage 协议

extension LKAssetImagePage: LKAssetBrowserPage {

    /// 生成实例
    public static func generate(with assetBrowser: LKAssetBrowser) -> Self {
        let cell = Self.init(frame: .zero)
        cell.assetBrowser = assetBrowser
        cell.scrollDirection = assetBrowser.scrollDirection
        return cell
    }

    public func prepareForReuse() {
        imageView.image = nil
    }
}

