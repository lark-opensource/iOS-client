//
//  ImagePreView.swift
//  LarkUIKit
//
//  Created by Yuguo on 2017/4/12.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import ByteWebImage
import UniverseDesignColor
import UniverseDesignShadow

final class ImagePreView: UIScrollView {
    func setImage(image: UIImage?) {
        setupAppearance(image: image)
    }
    private var normalImageView: ByteImageView = {
        let normalImageView = ByteImageView()
        normalImageView.isUserInteractionEnabled = true
        normalImageView.contentMode = .scaleAspectFill
        normalImageView.backgroundColor = .clear
        return normalImageView
    }()
    private var fitScale: CGFloat = 0
    private var imageSize: CGSize = .zero
    /// 当图片宽高比例小于屏幕宽高比例时(长图)，优先横向全屏占满显示
    let priorityHorizontalFullScreen: Bool = Display.pad ? false : true
    private var maxVisibleHeight: CGFloat {
        let baseHeight: CGFloat = 6000
        return UIDevice.current.userInterfaceIdiom == .pad ? baseHeight * 1.5 : baseHeight
    }

    public init() {
        super.init(frame: .zero)
        setup()
    }
    private func setup() {
        setupSubViews()
    }
    private func setupSubViews() {
        self.addSubview(normalImageView)
    }

    private func setupAppearance(image: UIImage?) {
        guard let image = image else {
            assertionFailure("image is not exist")
            return
        }
        normalImageView.isHidden = false
        normalImageView.image = image
        if let size = normalImageView.image?.size {
            self.imageSize = size
        }
        self.contentSize = self.imageSize
        normalImageView.frame = CGRect(origin: .zero, size: self.imageSize)
        normalImageView.layer.ud.setShadow(type: .s2Down)
        setMaxMinZoomScalesForCurrentBounds(self.imageSize)
        self.delegate = self
        self.bounces = false
        self.bouncesZoom = false
        self.backgroundColor = ShareColor.panelBackgroundColor
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        normalImageView.setNeedsDisplay()
    }
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateDefaultScale()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// 手势处理

extension ImagePreView: UIScrollViewDelegate {

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return normalImageView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        performLayoutSubviews()
    }

    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        performLayoutSubviews()
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 0 {
            self.panGestureRecognizer.isEnabled = false
        } else {
            self.panGestureRecognizer.isEnabled = true
        }
    }

    public func setMaxMinZoomScalesForCurrentBounds(_ size: CGSize) {
        guard size != .zero else { return }
        // Set min/max zoom
        self.minimumZoomScale = ImagePreView.minZoomScaleFor(
            boundsSize: self.bounds.size,
            imageSize: size,
            priorityHorizontalFullScreen: priorityHorizontalFullScreen
        )

        self.maximumZoomScale = ImagePreView.maxZoomScaleFor(
            boundsSize: self.bounds.size,
            imageSize: size,
            priorityHorizontalFullScreen: priorityHorizontalFullScreen)

        // Initial zoom
        self.zoomScale = minimumZoomScale
        performLayoutSubviews()

        self.lu.scrollToTop(animated: false)
    }

    class func minZoomScaleFor(boundsSize: CGSize, imageSize: CGSize, priorityHorizontalFullScreen: Bool) -> CGFloat {
        let xScale = boundsSize.width / imageSize.width
        let yScale = boundsSize.height / imageSize.height

        let minScale = min(xScale, yScale)
        if imageSize.width < imageSize.height { // 图片的宽小于高时
            // 有于屏幕存在转屏情况，我们取 UIScreen 短边除以长边得到屏幕比例
            let screenRatio: CGFloat = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) /
                max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
            if (imageSize.width / imageSize.height) < screenRatio && priorityHorizontalFullScreen { // 长图
                return xScale
            } else {
                return minScale
            }
        } else {
            return minScale
        }
    }

    class func maxZoomScaleFor(boundsSize: CGSize, imageSize: CGSize, priorityHorizontalFullScreen: Bool) -> CGFloat {
        if imageSize.width > imageSize.height { // 图片的宽大于高时
            let xScale = boundsSize.width / imageSize.width
            let yScale = boundsSize.height / imageSize.height
            return max(max(xScale, yScale), 2)
        }

        let minScale = ImagePreView.minZoomScaleFor(
            boundsSize: boundsSize,
            imageSize: imageSize,
            priorityHorizontalFullScreen: priorityHorizontalFullScreen)
        return max(minScale, 2)
    }

    func performLayoutSubviews() {
        let newFrame = ImagePreView.layout(
            size: normalImageView.frame.size,
            boundsSize: bounds.size)
        if !normalImageView.frame.equalTo(newFrame) {
            normalImageView.frame = newFrame
        }
    }

    class func layout(size: CGSize, boundsSize: CGSize) -> CGRect {
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

    private func updateDefaultScale() {
        self.zoomScale = bounds.width / imageSize.width
        fitScale = self.zoomScale
    }
}
