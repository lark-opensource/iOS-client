//
//  ZoomView.swift
//  ByteView
//
//  Created by LUNNER on 2019/4/1.
//

import UIKit
import SnapKit
import RxRelay
import ByteViewSetting

protocol ZoomViewZoomscaleObserver: AnyObject {
    func zoomScaleDidChanged(_ scale: CGFloat)
    func zoomScaleChangeEvent(_ scale: CGFloat, oldValue: CGFloat, type: ZoomView.ZoomScaleChangeType)
}

extension ZoomViewZoomscaleObserver {
    func zoomScaleDidChanged(_ scale: CGFloat) {}
    func zoomScaleChangeEvent(_ scale: CGFloat, oldValue: CGFloat, type: ZoomView.ZoomScaleChangeType) {}
}

final class ZoomView: UIView, ScrollViewDelegateTransferDelegate {

    enum ZoomScaleChangeType {
        case doubleTap
        case pinch
    }

    let zoomScaleRelay = BehaviorRelay<CGFloat>(value: 1.0)

    private let containerView: UIView = UIView(frame: .zero)
    private let scrollView: UIScrollView = UIScrollView(frame: .zero)
    private let fullScreenIfNeeded: Bool // 如果是竖屏内容则全屏
    private(set) weak var doubleTapGestureRecognizer: UIShortTapGestureRecognizer?

    var observers = Listeners<ZoomViewZoomscaleObserver>()

    func addListener(_ observer: ZoomViewZoomscaleObserver) {
        observers.addListener(observer)
    }

    func removeListener(_ observer: ZoomViewZoomscaleObserver) {
        observers.removeListener(observer)
    }

    func notifyListeners() {
        observers.forEach { $0.zoomScaleDidChanged(scrollView.zoomScale) }
    }

    func removeAllListeners() {
        observers.removeAllListeners()
    }

    var zoomScale: CGFloat {
        get {
            return scrollView.zoomScale
        }
        set {
            scrollView.zoomScale = newValue
        }
    }

    var doubleTapZoomScale: CGFloat = 2.0

    private(set) var contentSize: CGSize {
        didSet {
            guard contentSize != oldValue else {
                return
            }
            setNeedsLayout()
        }
    }

    var delegate: UIScrollViewDelegate? {
        get {
            return scrollView.delegate
        }
        set {
            scrollView.delegate = newValue
        }
    }

    // swiftlint:disable weak_delegate
    private let zoomDelegate = ScrollViewDelegateTransfer()
    // swiftlint:enable weak_delegate

    var blockSelfDoubleTapAction: (() -> Bool)?

    var autoHideToolbarConfig: AutoHideToolbarConfig? {
        didSet {
            if let config = autoHideToolbarConfig, let tap = self.doubleTapGestureRecognizer {
                tap.autoHideToolbarConfig = config
            }
        }
    }

    init(contentView: UIView,
         contentSize: CGSize,
         fullScreenIfNeeded: Bool = false,
         doubleTapEnable: Bool = true) {
        self.contentSize = contentSize
        self.fullScreenIfNeeded = fullScreenIfNeeded
        super.init(frame: .zero)
        addSubview(scrollView)
        scrollView.addSubview(containerView)
        containerView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }


        zoomDelegate.delegate = self
        scrollView.delegate = zoomDelegate
        scrollView.bounces = false
        scrollView.contentSize = contentSize
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(ZoomView.handlePinch(sender:)))
        pinch.delegate = self
        addGestureRecognizer(pinch)

        if doubleTapEnable {
            let doubleTap = UIShortTapGestureRecognizer(target: self, action: #selector(ZoomView.handleDoubleTap(sender:)))
            doubleTap.numberOfTapsRequired = 2
            addGestureRecognizer(doubleTap)
            self.doubleTapGestureRecognizer = doubleTap
        }
    }

    private var cachedScrollViewSize: CGSize = .zero
    private var cachedCotentSize: CGSize = .zero

    private var fullScreenContentSize: CGSize?

    override func layoutSubviews() {
        super.layoutSubviews()
        self.scrollView.frame = self.bounds
        if (cachedScrollViewSize != self.scrollView.bounds.size || cachedCotentSize != self.contentSize)
            && self.contentSize.width >= 1.0
            && self.contentSize.height >= 1.0 {
            self.cachedScrollViewSize = self.scrollView.bounds.size
            self.cachedCotentSize = self.contentSize
            if fullScreenIfNeeded && self.contentSize.height > self.contentSize.width && self.bounds.height > self.bounds.width {
                self.fullScreenContentSize = cachedScrollViewSize
                containerView.bounds = CGRect(origin: .zero, size: cachedScrollViewSize)
                self.scrollView.contentSize = cachedScrollViewSize
                self.scrollView.minimumZoomScale = 1.0
            } else {
                self.fullScreenContentSize = nil
                containerView.bounds = CGRect(origin: .zero, size: self.contentSize)
                self.scrollView.contentSize = self.contentSize
                self.scrollView.minimumZoomScale = min(cachedScrollViewSize.width / self.contentSize.width,
                                                       cachedScrollViewSize.height / self.contentSize.height)
            }
            self.scrollView.maximumZoomScale = self.scrollView.minimumZoomScale * 5
            scrollView.zoomScale = scrollView.minimumZoomScale
        }
        let contentSize = self.scrollView.contentSize

        let offsetX: CGFloat = max((self.bounds.width - contentSize.width) * 0.5, 0)
        let offsetY: CGFloat = max((self.bounds.height - contentSize.height) * 0.5, 0)
        containerView.center = CGPoint(x: contentSize.width * 0.5 + offsetX,
                                       y: contentSize.height * 0.5 + offsetY)
        notifyListeners()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func handleDoubleTap(sender: UITapGestureRecognizer) {
        if blockSelfDoubleTapAction?() == true {
            return
        }
        let contentSize = self.fullScreenContentSize ?? self.contentSize
        guard contentSize.width >= 1.0 && contentSize.height >= 1.0
                && self.scrollView.bounds.width >= 1.0 && self.scrollView.bounds.height >= 1.0 else {
            return
        }
        let oldScale = scrollView.zoomScale
        let aspectFillZoomScale = max(self.scrollView.bounds.width / contentSize.width, self.scrollView.bounds.height / contentSize.height)

        if scrollView.zoomScale > scrollView.minimumZoomScale {
            // 缩小到1.0
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            if aspectFillZoomScale > 2 * scrollView.minimumZoomScale {
                // AspectFill
                scrollView.setZoomScale(aspectFillZoomScale, animated: true)
            } else {
                // 放大到doubleTapZoomScale
                scrollView.setZoomScale(doubleTapZoomScale * scrollView.minimumZoomScale / aspectFillZoomScale, animated: true)
            }
        }
        observers.forEach {
            $0.zoomScaleChangeEvent(scrollView.zoomScale, oldValue: oldScale, type: .doubleTap)
        }
    }

    private var lastZoomScale: CGFloat?
    @objc func handlePinch(sender: UIPinchGestureRecognizer) {
        if sender.state == .began {
            lastZoomScale = zoomScaleRelay.value
        }
        guard sender.state == .ended else { return }
        observers.forEach {
            $0.zoomScaleChangeEvent(scrollView.zoomScale, oldValue: lastZoomScale ?? zoomScaleRelay.value, type: .pinch)
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        containerView.center = CGPoint(x: max(scrollView.bounds.width, scrollView.contentSize.width) * 0.5,
                                       y: max(scrollView.bounds.height, scrollView.contentSize.height) * 0.5)
        zoomScaleRelay.accept(scrollView.zoomScale)
    }

    deinit {
        removeAllListeners()
    }
    /*
    var currentContentRect: CGRect? {
        guard self.scrollView.zoomScale > 0 else {
            return nil
        }
        let offset = self.scrollView.contentOffset
        let invScale = 1 / self.scrollView.zoomScale
        let visibleContentRect = CGRect(x: offset.x * invScale,
                                        y: offset.y * invScale,
                                        width: self.scrollView.bounds.width * invScale,
                                        height: self.scrollView.bounds.height * invScale)
        return visibleContentRect
    }

    var currentUnitContentRect: CGRect? {
        return self.currentContentRect.flatMap(contentRectToUnitRect(_:))
    }

    func contentRectToUnitRect(_ contentRect: CGRect) -> CGRect? {
        guard contentSize.height >= 1.0, contentSize.width >= 1.0 else {
            return nil
        }
        return CGRect(x: contentRect.origin.x / contentSize.width,
                      y: contentRect.origin.y / contentSize.height,
                      width: contentRect.width / contentSize.width,
                      height: contentRect.height / contentSize.height)

    }

    func unitRectToContentRect(unitRect: CGRect) -> CGRect {
        return CGRect(x: unitRect.origin.x * self.contentSize.width,
                      y: unitRect.origin.y * self.contentSize.height,
                      width: unitRect.width * self.contentSize.width,
                      height: unitRect.height * self.contentSize.height)
    }

    func zoomToUnitRect(_ rect: CGRect, animated: Bool) {
        var contentRect = unitRectToContentRect(unitRect: rect)
        self.scrollView.zoom(to: contentRect, animated: animated)
        var contentOffset = self.scrollView.contentOffset
        if rect.width > 1.0 {
            contentOffset.x = 0.0
        }
        if rect.height > 1.0 {
            contentOffset.y = 0.0
        }

        self.scrollView.setContentOffset(contentOffset, animated: animated)
    }
     */

    // 更新 contentSize，并尝试恢复缩放区域
    func updateContentSize(_ contentSize: CGSize) {
        let oldContentSize = self.contentSize

        let newScale: CGFloat
        if self.fullScreenContentSize == nil && contentSize.width >= 1.0 {
            newScale = self.scrollView.zoomScale * self.contentSize.width / contentSize.width
        } else {
            newScale = self.scrollView.zoomScale
        }
        let offset = self.scrollView.contentOffset

        self.contentSize = contentSize
        self.layoutIfNeeded()

        if (oldContentSize.width >= oldContentSize.height) == (contentSize.width >= contentSize.height) {
            self.scrollView.setZoomScale(newScale, animated: false)
            self.scrollView.setContentOffset(offset, animated: false)
        }
    }
}

extension ZoomView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

protocol ScrollViewDelegateTransferDelegate: AnyObject {
    func viewForZooming(in scrollView: UIScrollView) -> UIView?
    func scrollViewDidZoom(_ scrollView: UIScrollView)
}

class ScrollViewDelegateTransfer: NSObject, UIScrollViewDelegate {
    weak var delegate: ScrollViewDelegateTransferDelegate?

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return delegate?.viewForZooming(in: scrollView)
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidZoom(scrollView)
    }
}
