//
//  ImageEditCropperViewController.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/7/8.
//

import Foundation
import UIKit
import LarkUIKit

open class ImageEditCropperViewController: UIViewController, CropViewController {
    public override var prefersStatusBarHidden: Bool {
        return true
    }

    public override var shouldAutorotate: Bool {
        return false
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    public override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    public override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.top]
    }

    private let bottomFunctionView: CropperFunctionView
    private let upContainerView = UIView()

    private(set) var scrollView: CropperScrollView!
    private(set) var overlayView: CropperOverlayView!

    // 可以操作区域的inset
    private let inset = CGFloat(30)
    // 可操作区域移除顶部statusbar和底部操作区域的insets
    private lazy var insets: UIEdgeInsets = {
        let iPhoneXSeries = Display.iPhoneXSeries
        return UIEdgeInsets(
            top: (iPhoneXSeries ? 24 : 0) + inset,
            left: inset,
            bottom: bottomHeight + inset,
            right: inset
        )
    }()

    private let image: UIImage
    private let config: CropperConfigure
    private var bottomHeight: CGFloat { config.style == .more ? 146 : 96 }
    private var toolbarTitle: String?
    private var maxCropRect = CGRect.zero

    private var croppedImageView: UIImageView?

    public var eventBlock: ((ImageEditEvent) -> Void)?
    public var successCallback: ((UIImage, CropViewController, CGRect) -> Void)?
    public var failureCallback: ((UIImage, CropViewController, CGRect) -> Void)?
    public var cancelCallback: ((CropViewController) -> Void)?

    private var imageEdited: Bool = false

    private(set) var direction = ImageDirection.up

    public init(image: UIImage, config: CropperConfigure, toolBarTitle: String?) {
        self.image = image.lu.fixOrientation()
        self.config = config
        self.bottomFunctionView = CropperFunctionView(supportMoreRatio: config.style,
                                                      supportRotate: config.supportRotate)
        self.toolbarTitle = toolBarTitle
        super.init(nibName: nil, bundle: nil)
        bottomFunctionView.delegate = self
    }

    public convenience init(image: UIImage, config: CropperConfigure = .default) {
        self.init(image: image, config: config, toolBarTitle: nil)
    }

    public required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(upContainerView)
        upContainerView.backgroundColor = .ud.staticBlack
        upContainerView.clipsToBounds = true
        upContainerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(bottomHeight)
        }

        let scrollFrame = getScrollFrame(view.bounds.size, currentSize: image.size)

        layoutScrollView(scrollFrame)
        layoutOverlayView(scrollFrame)

        view.addSubview(bottomFunctionView)
        bottomFunctionView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(bottomHeight)
        }

        if let initialRect = config.initialRect {
            // 自动调整图片偏移和scrollview的大小，调用reset之后自动调整到对应位置
            let scale = scrollView.scollView.frame.width / image.size.width
            let scaledRect = initialRect.applying(CGAffineTransform(scaleX: scale, y: scale))
            scrollView.scollView.setContentOffset(scaledRect.topLeft, animated: false)
            scrollView.scollView.frame = scrollView.scollView.convert(scaledRect, to: view)
            reset(animated: false)
        }

        maxCropRect = overlayView.hollow.rect

        if case .custom(let ratio) = config.style {
            setupCropRatio(ratio)
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private var preViewBounds: CGRect?
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let currentViewBounds = view.bounds
        if let preBounds = preViewBounds, preBounds != currentViewBounds {
            reset()
        }
        preViewBounds = currentViewBounds
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        DispatchQueue.main.async {
            self.reset()
        }
    }

    private func layoutScrollView(_ scrollFrame: CGRect) {
        scrollView = CropperScrollView(
            image: image,
            scrollFrame: scrollFrame,
            containerSize: view.bounds.size,
            isSquare: config.squareScale
        )
        scrollView.delegate = self
        upContainerView.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func layoutOverlayView(_ scrollFrame: CGRect) {
        overlayView = CropperOverlayView(
            frame: view.bounds,
            hollowFrame: scrollFrame,
            insets: insets,
            config: config
        )
        overlayView.delegate = self
        view.addSubview(overlayView)
        overlayView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func getScrollFrame(_ targetSize: CGSize, currentSize: CGSize) -> CGRect {
        if config.squareScale {
            return ScrollUtils.getSquareScrollFrame(targetSize: targetSize, insets: insets)
        } else {
            return ScrollUtils.getRectScrollFrame(targetSize: targetSize, currentSize: currentSize, insets: insets)
        }
    }

    private func resetRect() {
        clearResetRect()
        setComponents(enable: false)
        perform(#selector(restRectAction), with: nil, afterDelay: config.zoomingToFitDelay)
    }

    private func clearResetRect() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(restRectAction), object: nil)
    }

    @objc
    private func restRectAction() { reset() }

    private func reset(animated: Bool = true) {
        let scrollFrame = getScrollFrame(view.bounds.size, currentSize: scrollView.scollView.frame.size)
        overlayView.hollow.update(rect: scrollFrame)

        let duration = animated ? 0.25 : 0
        UIView.animate(
            withDuration: duration,
            animations: {
                self.overlayView.hollow.layoutIfNeeded()

                self.scrollView.zoomAndSroll(frame: scrollFrame)
            },
            completion: { (_) in
                self.setComponents(enable: true)
            })
    }

    private func setComponents(enable: Bool) {
        overlayView.upateMask(isShow: enable)
        scrollView.isEnabled = enable
        overlayView.isEnabled = enable
        bottomFunctionView.setButtonEnable(enable)
    }

    private func animationRotate(with direction: ImageDirection,
                                 and scale: CGFloat,
                                 isReset: Bool = false) {
        let transform = CGAffineTransform(scaleX: scale, y: scale)
            .concatenating(CGAffineTransform(rotationAngle: direction.radian))
        // 旋转、确认等功能关闭
        setComponents(enable: false)

        UIView.animate(
            withDuration: 0.25,
            animations: {
                self.overlayView.hollow.rectView.alpha = 0

                self.overlayView.hollow.rectView.transform = transform
                self.scrollView.scollView.transform = transform
            },
            completion: { (_) in
                // 重置overlay
                var frame = self.overlayView.hollow.rectView.frame
                self.overlayView.hollow.rectView.transform = .identity
                self.overlayView.hollow.update(rect: frame)
                // 重置scroll
                frame = self.scrollView.scollView.frame
                self.scrollView.scollView.transform = .identity
                self.scrollView.rotate(with: direction, and: scale, frame: frame)
                // 旋转、确认等功能打开
                self.setComponents(enable: true)
                if isReset {
                    self.scrollView.resetScale()
                }
                UIView.animate(withDuration: 0.25, animations: {
                    self.overlayView.hollow.rectView.alpha = 1
                })
                self.maxCropRect = self.overlayView.hollow.rect
            })
    }

    private func getFixCropRectWithRatio(_ ratio: CGFloat) -> CGRect {
        let size = ScrollUtils.lvLimitMaxSize(.init(width: ratio, height: 1), maxCropRect.size)
        return CGRect(
            x: maxCropRect.origin.x + (maxCropRect.size.width - size.width) / 2,
            y: maxCropRect.origin.y + (maxCropRect.size.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }

    private func fixToCropRect(cropRect: CGRect, animated: Bool = true) {
        scrollView.stopScrolling()
        overlayView.upateMask(isShow: false)
        clearResetRect()
        overlayView.hollow.update(rect: cropRect)
        if animated {
            UIView.animate(withDuration: 0.25, animations: { [weak self] in
                self?.view.layoutIfNeeded()
            })
        }
        scrollView.update(scrollFrame: cropRect)
        if !scrollView.isMoving {
            resetRect()
        }
    }

    private func animateReset(swapWidthHeight: Bool, revertedDirection: ImageDirection) {
        if direction == .up {
            // 已经是up
            UIView.animate(withDuration: 0.25, animations: { [weak self] in
                self?.overlayView.hollow.rectView.alpha = 0
            }, completion: { [weak self] _ in
                UIView.animate(withDuration: 0.25, animations: {
                    self?.overlayView.hollow.rectView.alpha = 1
                })
            })
        } else {
            // 动画回滚
            let scale = swapWidthHeight ? ScrollUtils.getScale(
                targetSize: view.bounds.size,
                currentSize: scrollView.scollView.frame.size,
                insets: insets
                ) : 1
            animationRotate(with: revertedDirection, and: scale, isReset: true)
        }
    }
}

extension ImageEditCropperViewController: CropperScrollViewDelegate {
    func cropperScrollViewWillBeginMoving(_ view: CropperScrollView) {
        // 拖动期间如果双指碰到剪裁框，触发 didPan 会造成界面卡死，因此禁用剪裁框交互。
        overlayView.isEnabled = false
        imageEdited = true
        overlayView.upateMask(isShow: false)
        clearResetRect()
    }

    func cropperScrollViewDidEndMoving(_ view: CropperScrollView) {
        overlayView.isEnabled = true
        if !overlayView.isDragging {
            resetRect()
        }
    }
}

extension ImageEditCropperViewController: CropperOverlayViewDelegate {
    func cropperOverlayViewBeginDragging(_ view: CropperOverlayView) {
        imageEdited = true
        scrollView.stopScrolling()
        overlayView.upateMask(isShow: false)
        clearResetRect()
    }

    func cropperOverlayViewDragging(_ view: CropperOverlayView, frame: CGRect) {
        scrollView.update(scrollFrame: frame)
    }

    func cropperOverlayViewEndDragging(_ view: CropperOverlayView, frame: CGRect) {
        scrollView.update(scrollFrame: frame)
        if !scrollView.isMoving {
            resetRect()
        }
    }
}

extension ImageEditCropperViewController: CropperFunctionViewDelegate {

    private func setupCropRatio(_ ratio: CGFloat?) {
        guard let ratio = ratio else { return }
        overlayView.enableRatioDragging(ratio)
        let fixCropRect = getFixCropRectWithRatio(ratio)
        fixToCropRect(cropRect: fixCropRect, animated: false)
    }

    func ratioButtonDidClicked(_ ratio: CGFloat?) {
        overlayView.enableRatioDragging(ratio)
        guard let ratio = ratio else { return }

        eventBlock?(.init(event: "public_pic_edit_crop_click",
                          params: ["click": "crop_style", "target": "none"]))
        imageEdited = true
        let fixCropRect = getFixCropRectWithRatio(ratio)
        fixToCropRect(cropRect: fixCropRect)
    }

    func rotateButtonDidClicked() {
        eventBlock?(.init(event: "public_pic_edit_crop_click",
                          params: ["click": "rotation", "target": "none"]))
        let scale: CGFloat = ScrollUtils.getScale(
            targetSize: view.bounds.size,
            currentSize: scrollView.scollView.frame.size,
            insets: insets
        )
        direction = direction.antiClockwiseRotate()
        animationRotate(with: .left, and: scale)
    }

    func cancelButtonDidClicked() {
        eventBlock?(.init(event: "public_pic_edit_crop_click",
                          params: ["click": "cancel", "target": "none"]))
        clearResetRect()
        cancelCallback?(self)
    }

    func finishButtonDidClicked() {
        guard let image = scrollView.imageView.image else {
            return
        }
        eventBlock?(.init(event: "public_pic_edit_crop_click",
                          params: ["click": "confirm", "target": "public_pic_edit_view"]))
        let hollowRect = overlayView.hollow.rect
        let rect = overlayView.hollow.convert(hollowRect, to: scrollView.imageView)
        let factor = image.scale
        let scaledRect = CGRect(
            x: (rect.minX * factor).rounded(),
            y: (rect.minY * factor).rounded(),
            width: max(1, (rect.width * factor).rounded()),
            height: max(1, (rect.height * factor).rounded())
        )
        if let croppedCGImage = image.cgImage?.cropping(to: scaledRect) {
            let croppedImage = UIImage(cgImage: croppedCGImage,
                                       scale: image.scale,
                                       orientation: image.imageOrientation)
            croppedImageView = UIImageView(image: croppedImage)
            croppedImageView?.frame = hollowRect
            successCallback?(croppedImage, self, rect)
        } else {
            failureCallback?(image, self, rect)
        }
    }

    func resetButtonDidClicked() {
        eventBlock?(.init(event: "public_pic_edit_crop_click",
                          params: ["click": "undo", "target": "none"]))
        let swapWidthHeight = direction.widthHeightSwapped
        let revertedDirection = direction.reverted

        if !imageEdited {
            animateReset(swapWidthHeight: swapWidthHeight, revertedDirection: revertedDirection)
        } else {
            bottomFunctionView.setToFree()
            overlayView.enableRatioDragging(nil)
            // 还原图片
            if direction != .up {
                scrollView.rotateImage(with: revertedDirection)
            }
            // 还原原始frame
            let scrollFrame = getScrollFrame(view.bounds.size, currentSize: image.size)
            scrollView.configScrollView(
                scrollFrame: scrollFrame,
                imageSize: image.size,
                isSquare: config.squareScale
            )
            bottomFunctionView.setButtonEnable(true)
            switch config.style {
            case .custom(let ratio):
                overlayView.upateMask(isShow: false)
                let fixCropRect = getFixCropRectWithRatio(ratio)
                overlayView.hollow.update(rect: fixCropRect)
                maxCropRect = overlayView.hollow.rect

                scrollView.update(scrollFrame: fixCropRect)
                if !scrollView.isMoving {
                    reset(animated: false)
                }
                overlayView.enableRatioDragging(ratio)
            case .more, .single:
                overlayView.hollow.update(rect: scrollFrame)
                maxCropRect = overlayView.hollow.rect
            }
        }

        imageEdited = false
        direction = .up
    }
}
