//
//  CropperViewController.swift
//  LarkUIKit
//
//  Created by liuwanlin on 2017/12/5.
//  Copyright © 2017年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit

open class CropperViewController: UIViewController, CropViewController {
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

    private let actionContainer = UIView()

    private lazy var toolbar: ImageEditToolBar = {
        let toolbar = ImageEditToolBar(title: self.toolbarTitle ??
                                        BundleI18n.LarkImageEditor.Lark_Legacy_ImageEditCropper)
        toolbar.delegate = self
        return toolbar
    }()

    private lazy var editView: CropperEditView = {
        let view = CropperEditView(frame: .zero)
        view.delegate = self
        return view
    }()

    private(set) var scrollView: CropperScrollView!
    private(set) var overlayView: CropperOverlayView!

    // 可以操作区域的inset
    private let inset: CGFloat = 10
    // 可操作区域移除顶部statusbar和底部操作区域的insets
    private lazy var insets: UIEdgeInsets = {
        let iPhoneXSeries = Display.iPhoneXSeries
        return UIEdgeInsets(
            top: (iPhoneXSeries ? 44 : 20) + inset,
            left: inset,
            bottom: 96 + (iPhoneXSeries ? 34 : 0) + inset,
            right: inset
        )
    }()

    private let image: UIImage
    private let config: CropperConfigure
    private var toolbarTitle: String?

    public var croppedImageView: UIImageView?

    public var successCallback: ((UIImage, CropViewController, CGRect) -> Void)?
    public var failureCallback: ((UIImage, CropViewController, CGRect) -> Void)?
    public var cancelCallback: ((CropViewController) -> Void)?
    public var eventBlock: ((ImageEditEvent) -> Void)?

    private var imageEdited: Bool = false {
        didSet {
            self.editView.showRevert = imageEdited || direction != .up
        }
    }

    private(set) var direction: ImageDirection = .up {
        didSet {
            self.editView.showRevert = imageEdited || direction != .up
        }
    }

    public init(image: UIImage, config: CropperConfigure, toolBarTitle: String?) {
        self.image = image.lu.fixOrientation()
        self.config = config
        self.toolbarTitle = toolBarTitle
        super.init(nibName: nil, bundle: nil)
        if #available(iOS 13.0, *) {
            view.overrideUserInterfaceStyle = .light
        }
    }

    public convenience init(image: UIImage, config: CropperConfigure = .default) {
        self.init(image: image, config: config, toolBarTitle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print("CropperViewController deinit")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.black
        self.view.clipsToBounds = true

        let scrollFrame = getScrollFrame(view.bounds.size, currentSize: image.size)

        layoutScrollView(scrollFrame)
        layoutOverlayView(scrollFrame)
        layoutActionArea()

        if let initialRect = config.initialRect {
            // 自动调整图片偏移和scrollview的大小，调用reset之后自动调整到对应位置
            let scale = scrollView.scollView.frame.width / image.size.width
            let scaledRect = initialRect.applying(CGAffineTransform(scaleX: scale, y: scale))
            scrollView.scollView.setContentOffset(scaledRect.topLeft, animated: false)
            scrollView.scollView.frame = scrollView.scollView.convert(scaledRect, to: view)
            reset(animated: false)
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private var preViewBounds: CGRect?
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let currentViewBounds = view.bounds
        if let preBounds = preViewBounds, preBounds != currentViewBounds {
            self.reset()
        }
        self.preViewBounds = currentViewBounds
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
            containerSize: self.view.bounds.size,
            isSquare: config.squareScale
        )
        scrollView.delegate = self
        self.view.addSubview(scrollView)
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
        self.view.addSubview(overlayView)
        overlayView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func layoutActionArea() {
        self.view.addSubview(actionContainer)
        actionContainer.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(insets.bottom - inset)
        }

        self.actionContainer.addSubview(editView)
        editView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
        }

        self.actionContainer.addSubview(toolbar)
        toolbar.snp.makeConstraints { (make) in
            make.top.equalTo(editView.snp.bottom)
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
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
        self.perform(#selector(restRectAction), with: nil, afterDelay: config.zoomingToFitDelay)
    }

    private func clearResetRect() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(restRectAction), object: nil)
    }

    @objc
    private func restRectAction() {
        reset()
    }

    private func reset(animated: Bool = true) {
        let scrollFrame = getScrollFrame(view.bounds.size, currentSize: scrollView.scollView.frame.size)
        overlayView.hollow.update(rect: scrollFrame)

        setComponents(enable: false)

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
        editView.isEnabled = enable
    }
}

extension CropperViewController: CropperScrollViewDelegate {
    func cropperScrollViewWillBeginMoving(_ view: CropperScrollView) {
        overlayView.upateMask(isShow: false)
        editView.isEnabled = false

        clearResetRect()
    }

    func cropperScrollViewDidEndMoving(_ view: CropperScrollView) {
        if !overlayView.isDragging {
            resetRect()
        }
    }
}

extension CropperViewController: CropperOverlayViewDelegate {
    func cropperOverlayViewBeginDragging(_ view: CropperOverlayView) {
        self.imageEdited = true
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

extension CropperViewController: ImageEditToolBarDelegate {
    func toolBarDidClickCancel(toolBar: ImageEditToolBar) {
        clearResetRect()
        cancelCallback?(self)
    }

    func toolBarDidClickFinish(toolBar: ImageEditToolBar) {
        guard let image = scrollView.imageView.image else {
            return
        }
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
}

extension CropperViewController: CropperEditViewDelegate {
    func animationRotate(with direction: ImageDirection,
                         and scale: CGFloat,
                         isReset: Bool = false) {
        let transform = CGAffineTransform(scaleX: scale, y: scale)
            .concatenating(CGAffineTransform(rotationAngle: direction.radian))
        // 旋转、确认等功能关闭
        self.setComponents(enable: false)

        UIView.animate(
            withDuration: 0.25,
            animations: {
                self.overlayView.hollow.rectView.isHidden = true

                self.overlayView.hollow.rectView.transform = transform
                self.scrollView.scollView.transform = transform
            },
            completion: { (_) in
                // 重置overlay
                self.overlayView.hollow.rectView.isHidden = false
                var frame = self.overlayView.hollow.rectView.frame
                self.overlayView.hollow.rectView.transform = CGAffineTransform.identity
                self.overlayView.hollow.update(rect: frame)
                // 重置scroll
                frame = self.scrollView.scollView.frame
                self.scrollView.scollView.transform = CGAffineTransform.identity
                self.scrollView.rotate(with: direction, and: scale, frame: frame)
                // 旋转、确认等功能打开
                self.setComponents(enable: true)

                if isReset {
                    self.scrollView.resetScale()
                }
            })
    }

    @objc
    func editViewDidTapRotate(_ view: CropperEditView) {
        let scale: CGFloat = ScrollUtils.getScale(
            targetSize: self.view.bounds.size,
            currentSize: scrollView.scollView.frame.size,
            insets: insets
        )
        self.direction = self.direction.antiClockwiseRotate()
        animationRotate(with: .left, and: scale)
    }

    func editViewDidTapRevert(_ view: CropperEditView) {
        let swapWidthHeight = self.direction.widthHeightSwapped
        let revertedDirection = self.direction.reverted

        // 没有编辑过，动画回滚
        if !self.imageEdited {
            let scale = swapWidthHeight ? ScrollUtils.getScale(
                targetSize: self.view.bounds.size,
                currentSize: scrollView.scollView.frame.size,
                insets: insets
                ) : 1
            animationRotate(with: revertedDirection, and: scale, isReset: true)
        } else {
            // 还原图片
            if self.direction != .up {
                self.scrollView.rotateImage(with: revertedDirection)
            }
            // 还原原始frame
            let scrollFrame = self.getScrollFrame(self.view.bounds.size, currentSize: image.size)
            self.overlayView.hollow.update(rect: scrollFrame)
            self.scrollView.configScrollView(
                scrollFrame: scrollFrame,
                imageSize: image.size,
                isSquare: config.squareScale
            )
        }

        self.imageEdited = false
        self.direction = .up
    }
}
