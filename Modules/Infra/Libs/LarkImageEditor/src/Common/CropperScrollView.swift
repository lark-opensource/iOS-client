//
//  CropperScrollView.swift
//  LarkUIKit
//
//  Created by liuwanlin on 2017/12/5.
//  Copyright © 2017年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

protocol CropperScrollViewDelegate: AnyObject {
    func cropperScrollViewWillBeginMoving(_ view: CropperScrollView)
    func cropperScrollViewDidEndMoving(_ view: CropperScrollView)
}

final class CropperScrollView: UIView {
    weak var delegate: CropperScrollViewDelegate?

    let imageView: UIImageView
    let scollView: ImageScrollView
    var imageSize: CGSize
    let containerSize: CGSize

    private let initialScale: CGFloat = .zero

    var isEnabled: Bool = true {
        didSet {
            self.scollView.isUserInteractionEnabled = isEnabled
        }
    }

    var isMoving: Bool {
        return scollView.isDragging || scollView.isZooming || scollView.isDecelerating
    }

    init(image: UIImage, scrollFrame: CGRect, containerSize: CGSize, isSquare: Bool) {
        self.containerSize = containerSize
        imageView = UIImageView(image: image)
        scollView = ImageScrollView(imageView: imageView)
        self.imageSize = image.size

        super.init(frame: .zero)

        self.addSubview(scollView)

        scollView.addSubview(imageView)

        configScrollView(
            scrollFrame: scrollFrame,
            imageSize: image.size,
            isSquare: isSquare
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configScrollView(scrollFrame: CGRect, imageSize: CGSize, isSquare: Bool) {
        self.imageSize = imageSize

        // 如果是方形图，需要填满，取max，长方形的时候防止超出，取min
        let ratio: CGFloat
        if isSquare {
            ratio = max(
                scrollFrame.width / imageSize.width,
                scrollFrame.height / imageSize.height
            )
        } else {
            ratio = min(
                scrollFrame.width / imageSize.width,
                scrollFrame.height / imageSize.height
            )
        }

        let scaledImageSize = CGSize(
            width: imageSize.width * ratio,
            height: imageSize.height * ratio
        )

        // 超宽或超长的图，最大超过屏幕高度或宽度两倍
        let maxRatio = max(
            ratio * 5,
            containerSize.width / imageSize.width * 2,
            containerSize.height / imageSize.height * 2
        )

        scollView.frame = scrollFrame
        scollView.clipsToBounds = false
        scollView.maximumZoomScale = maxRatio
        scollView.minimumZoomScale = ratio
        scollView.zoomScale = ratio
        scollView.bouncesZoom = true
        scollView.alwaysBounceVertical = true
        scollView.alwaysBounceHorizontal = true
        scollView.showsVerticalScrollIndicator = false
        scollView.showsHorizontalScrollIndicator = false
        scollView.delegate = self

        scollView.setZoomScale(ratio, animated: false)
        scollView.setContentOffset(
            CGPoint(
                x: scaledImageSize.width / 2 - scollView.frame.width / 2,
                y: scaledImageSize.height / 2 - scollView.frame.height / 2
            ),
            animated: false
        )
    }

    private func scale(ratio: CGFloat) -> CGFloat {
        var scale = scollView.zoomScale * ratio
        if scale > scollView.maximumZoomScale {
            scale = scollView.maximumZoomScale
        }
        return scale
    }

    func zoomAndSroll(frame: CGRect) {
        let currentFrame = scollView.frame
        let ratio = frame.width / currentFrame.width

        let scale = self.scale(ratio: ratio)

        let realRatio = scale / scollView.zoomScale
        var offset = CGPoint(
            x: scollView.contentOffset.x * realRatio,
            y: scollView.contentOffset.y * realRatio
        )

        let maxX = scollView.contentSize.width * realRatio - frame.width
        let maxY = scollView.contentSize.height * realRatio - frame.height

        offset.x = min(offset.x, maxX)
        offset.x = max(0, offset.x)
        offset.y = min(offset.y, maxY)
        offset.y = max(0, offset.y)

        scollView.frame = frame
        let minimumZoomScale = max(
            frame.width / imageSize.width,
            frame.height / imageSize.height
        )
        scollView.minimumZoomScale = minimumZoomScale
        scollView.setZoomScale(scale, animated: false)
        scollView.setContentOffset(offset, animated: false)
    }

    func rotate(with direction: ImageDirection, and ratio: CGFloat, frame: CGRect) {
        let currentFrame = scollView.frame
        let imageSize = imageView.frame.size
        let contentOffset = scollView.contentOffset

        // 计算新的offset，原来top为现在的left，原来的right为现在的top
        let scale = self.scale(ratio: ratio)
        let realRatio = scale / scollView.zoomScale
        let newOffset: CGPoint
        if direction == .left || direction == .right {
            newOffset = CGPoint(
                x: contentOffset.y * realRatio,
                y: (imageSize.width - currentFrame.width - contentOffset.x) * realRatio
            )
        } else {
            newOffset = scollView.contentOffset
        }

        if direction.widthHeightSwapped {
            self.imageSize = CGSize(width: self.imageSize.height, height: self.imageSize.width)
        }

        self.rotateImage(with: direction)

        scollView.frame = frame
        let minimumZoomScale = max(
            frame.width / self.imageSize.width,
            frame.height / self.imageSize.height
        )
        scollView.minimumZoomScale = minimumZoomScale
        scollView.setZoomScale(scale, animated: false)
        scollView.setContentOffset(newOffset, animated: false)
    }

    func rotateImage(with direction: ImageDirection) {
        let imageSize = imageView.frame.size
        // 旋转后交换图片宽高
        if direction.widthHeightSwapped {
            imageView.frame = CGRect(x: 0, y: 0, width: imageSize.height, height: imageSize.width)
        }
        // 图片内容旋转重绘
        imageView.image = imageView.image?.lu.rotate(by: direction.radian)
    }

    func stopScrolling() {
        scollView.isScrollEnabled = false
        scollView.isScrollEnabled = true
    }

    func update(scrollFrame: CGRect) {
        // 需要调整图片放大
        let needScale = scrollFrame.width > ceil(scollView.contentSize.width)
            || scrollFrame.height > ceil(scollView.contentSize.height)
        if needScale {
            let ratio = max(
                scrollFrame.width / scollView.contentSize.width,
                scrollFrame.height / scollView.contentSize.height
            )
            let scale = self.scale(ratio: ratio)

            scollView.frame = scrollFrame
            let minimumZoomScale = max(
                scrollFrame.width / imageSize.width,
                scrollFrame.height / imageSize.height
            )
            scollView.minimumZoomScale = minimumZoomScale
            scollView.setZoomScale(scale, animated: false)
            return
        }

        // 只是移动，也需要设置minimumZoomScale
        var offset = scollView.contentOffset
        offset.x += (scrollFrame.minX - scollView.frame.minX)
        offset.y += (scrollFrame.minY - scollView.frame.minY)

        let maxX = scollView.contentSize.width - scrollFrame.width
        let maxY = scollView.contentSize.height - scrollFrame.height

        offset.x = min(offset.x, maxX)
        offset.x = max(0, offset.x)
        offset.y = min(offset.y, maxY)
        offset.y = max(0, offset.y)

        scollView.frame = scrollFrame
        let minimumZoomScale = max(
            scrollFrame.width / imageSize.width,
            scrollFrame.height / imageSize.height
        )
        scollView.minimumZoomScale = minimumZoomScale
        scollView.setContentOffset(offset, animated: false)
    }

    func resetScale() { scollView.setZoomScale(scollView.minimumZoomScale, animated: true) }
}

extension CropperScrollView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        if !scrollView.isDecelerating && !scrollView.isDragging {
            delegate?.cropperScrollViewWillBeginMoving(self)
        }
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if !scrollView.isDecelerating && !scrollView.isDragging {
            delegate?.cropperScrollViewDidEndMoving(self)
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if !scrollView.isDecelerating && !scrollView.isZooming {
            delegate?.cropperScrollViewWillBeginMoving(self)
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !scrollView.isDecelerating && !scrollView.isZooming {
            delegate?.cropperScrollViewDidEndMoving(self)
        }
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        if !scrollView.isZooming && !scrollView.isDragging {
            delegate?.cropperScrollViewWillBeginMoving(self)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !scrollView.isZooming && !scrollView.isDragging {
            delegate?.cropperScrollViewDidEndMoving(self)
        }
    }
}
