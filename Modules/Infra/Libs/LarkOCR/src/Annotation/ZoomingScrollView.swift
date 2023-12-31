//
//  ZoomingScrollView.swift
//  LarkOCR
//
//  Created by 李晨 on 2022/8/24.
//

import Foundation
import UIKit
import SnapKit
import ByteWebImage
import LKCommonsLogging

public final class ZoomingScrollView: UIScrollView {

    static let logger = Logger.log(ZoomingScrollView.self, category: "LarkOCR")

    /// 对于超长图，iPad 端优先展示全图，iPhone 端优先满屏展示
    static var preferHorizontalFullScreen: Bool {
        UIDevice.current.userInterfaceIdiom == .pad ? false : true
    }

    var priorityHorizontalFullScreen: Bool = ZoomingScrollView.preferHorizontalFullScreen

    public var image: UIImage? {
        return photoImageView.image
    }

    public var imageViewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    public lazy var photoImageView: OCRImageView = {
        let photoImageView = OCRImageView(frame: .zero)
        photoImageView.isUserInteractionEnabled = false
        photoImageView.contentMode = .scaleAspectFill
        photoImageView.backgroundColor = UIColor.ud.primaryOnPrimaryFill // 图片背景透明时垫一层白底
        photoImageView.animateRunLoopMode = .default
        return photoImageView
    }()

    public private(set) var doubleTap = UITapGestureRecognizer()

    public var zoomingEndBlock: (() -> Void)?

    public var layoutSubviewsBlock: (() -> Void)?

    /// 图片适应屏幕（scaleAspectFit）的缩放倍率
    private var aspectFitZoomScale: CGFloat = 1
    /// 图片填满屏幕（scaleAspectFill）的缩放倍率
    private var aspectFillZoomScale: CGFloat = 1

    private var setupIfNeeded: Bool = true

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(imageViewContainer)
        imageViewContainer.addSubview(photoImageView)
        self.panGestureRecognizer.isEnabled = false

        self.delegate = self
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.contentInsetAdjustmentBehavior = .never
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        doubleTap.addTarget(self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTap)

        self.photoImageView.addGestureTo(view: self.imageViewContainer)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var oldSize: CGSize = .zero
    public override func layoutSubviews() {
        super.layoutSubviews()
        if self.bounds.size != .zero && setupIfNeeded {
            setupIfNeeded = false
            oldSize = self.bounds.size
            self.setMaxMinZoomScalesForCurrentBounds(.zero)
        }
        if self.bounds.size != self.oldSize {
            oldSize = self.bounds.size
            self.setMaxMinZoomScalesForCurrentBounds(.zero)
        }
        self.layoutSubviewsBlock?()
    }

    public func setUpPhotoImageView(_ photoImage: UIImage) {
        let showImage = self.downsample(image: photoImage)
        resetScale()
        imageViewContainer.frame = CGRect(origin: .zero, size: showImage.size)
        photoImageView.frame = CGRect(origin: .zero, size: showImage.size)
        photoImageView.image = showImage
        contentSize = showImage.size
        // Set zoom to minimum zoom
        setMaxMinZoomScalesForCurrentBounds(showImage.size)
    }

    private func downsample(image: UIImage) -> UIImage {
        Self.logger.info("set image to scroll view \(image.size)")
        let maxSizeCount: CGFloat = 1_000_000 * UIScreen.main.scale * UIScreen.main.scale
        guard image.size.width * image.size.height >= maxSizeCount else {
            return image
        }
        let rate: CGFloat = image.size.width / image.size.height
        let height = floor(sqrt(maxSizeCount / rate))
        let size = CGSize(width: floor(height * rate), height: height)
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        image.draw(in:  CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        Self.logger.info("resize image from \(image.size) to \(resizedImage?.size) targetSize \(size)")
        guard let resizedImage = resizedImage,
              resizedImage.size != .zero else {
            return image
        }
        return resizedImage
    }

    private func setMaxMinZoomScalesForCurrentBounds(_ size: CGSize) {
        var imageSize = size
        if imageSize == .zero {
            imageSize = photoImageView.image?.size ?? .zero
        }
        guard imageSize != .zero, bounds != .zero else { return }
        // Set min & max zoom scale
        setProperZoomScale(
            forBounds: bounds.size,
            imageSize: imageSize,
            preferHorizontalFullScreen: priorityHorizontalFullScreen
        )
        // Set initial zoom scale
        self.zoomScale = minimumZoomScale
        performLayoutSubviews()
        self.setContentOffset(CGPoint(x: 0, y: -self.contentInset.top), animated: false)
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
        let screenBounds = UIScreen.main.bounds
        let isLongImage = imageSize.height / imageSize.width > screenBounds.height / screenBounds.width

        if isPortrait, isLongImage, preferHorizontalFullScreen {
            self.minimumZoomScale = aspectFillZoomScale
        } else {
            self.minimumZoomScale = aspectFitZoomScale
        }

        let naturalZoomScale = max(minimumZoomScale * 2.5, aspectFillZoomScale)
        self.maximumZoomScale = max(2.0 * UIScreen.main.scale, naturalZoomScale)
    }

    /// 图片居中
    private func performLayoutSubviews() {
        guard self.bounds != .zero else {
            return
        }
        var imageView = imageViewContainer
        let newFrame = ZoomingScrollView.getCentralizedFrame(
            size: imageView.frame.size,
            boundsSize: bounds.size)
        if !imageView.frame.equalTo(newFrame) {
            imageView.frame = newFrame
        }
    }

    private func resetScale() {
        minimumZoomScale = 1
        maximumZoomScale = 1
        zoomScale = 1
    }
}

extension ZoomingScrollView: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageViewContainer
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        performLayoutSubviews()
    }

    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        self.zoomingEndBlock?()
    }
}

// MARK: - Photo Zooming
extension ZoomingScrollView {
    public class func getMinimumZoomScale(forBounds boundsSize: CGSize,
                                   imageSize: CGSize,
                                   preferHorizontalFullScreen: Bool) -> CGFloat {
        let widthRatio = boundsSize.width / imageSize.width
        let heightRatio = boundsSize.height / imageSize.height
        var aspectFitZoomScale = min(widthRatio, heightRatio)
        var aspectFillZoomScale = max(widthRatio, heightRatio)

        let isPortrait = boundsSize.width < boundsSize.height
        // 比屏幕尺寸长的图定义为超长图，以填满屏幕的初始缩放比例显示
        let screenBounds = UIScreen.main.bounds
        let isLongImage = imageSize.height / imageSize.width > screenBounds.height / screenBounds.width

        if isPortrait, isLongImage, preferHorizontalFullScreen {
            return aspectFillZoomScale
        } else {
            return aspectFitZoomScale
        }
    }

    public class func getCentralizedFrame(size: CGSize, boundsSize: CGSize) -> CGRect {
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

extension ZoomingScrollView {
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

    @objc
    private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if self.zoomScale != self.minimumZoomScale {
            // 缩小
            self.setZoomScale(self.minimumZoomScale, animated: true)
        } else {
            // 放大
            let touchPoint = gesture.location(in: imageViewContainer)
            zoomInPhotoView(from: touchPoint)
        }
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
}
