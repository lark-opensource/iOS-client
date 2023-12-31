//
//  BaseImageView.swift
//  LarkChat
//
//  Created by chengzhipeng-bytedance on 2018/3/22.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import UIKit
import Foundation
import LarkSetting
import ByteWebImage
import UniverseDesignTheme
import UniverseDesignIcon

/// BaseImageView 目前用在RichText中的图片，或者单个消息图片。
/// 里面封装有长图、图片宽高计算，mask蒙层等
open class BaseImageView: ByteImageView {
    public struct Cons {
        public static let failedImageSize = CGSize(width: 100, height: 100)
        public static let stripeImageJudgeWidth: CGFloat = 200
        public static let stripeImageJudgeWHRatio: CGFloat = 1 / 3
        public static let stripeImageDisplaySize = CGSize(width: 150, height: 240)
        public static let imageMaxDisplaySize = CGSize(width: 680, height: 240)
        public static let imageMinDisplaySize = CGSize(width: 40, height: 40)
    }

    var maxSize: CGSize = .zero {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }
    var minSize: CGSize = .zero {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }
    var needMask: Bool = false {
        didSet {
            guard needMask != oldValue else { return }
            if needMask {
                self.ud.setMaskView()
            } else {
                self.ud.removeMaskView()
            }
        }
    }
    var needBackdrop: Bool = false {
        didSet {
            guard needBackdrop != oldValue else { return }
            setBackDropLock.lock()
            if needBackdrop && image != nil {
                self.backgroundColor = UIColor.ud.primaryOnPrimaryFill
            } else {
                self.backgroundColor = .clear
            }
            setBackDropLock.unlock()
        }
    }
    private var setBackDropLock = NSLock()

    open override var image: UIImage? {
        didSet {
            setBackDropLock.lock()
            if needBackdrop && image != nil {
                self.backgroundColor = UIColor.ud.primaryOnPrimaryFill
            } else {
                self.backgroundColor = .clear
            }
            setBackDropLock.unlock()
        }
    }

    /// 根据 origionSize 自适应 contentModel
    public var adaptiveContentModel: Bool = true

    /// 图片原始大小
    open var origionSize: CGSize = .zero {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }

    // 是否按长图模式展示
    var showStripeImage: Bool {
        return Self.showStripeImage(originSize: origionSize, maxSize: maxSize) && adaptiveContentModel
    }

    open override var intrinsicContentSize: CGSize {
        let intrinsicContentSize: CGSize
        if self.adaptiveContentModel {
            let (size, contentMode) = BaseImageView.calculateSizeAndContentMode(
                originSize: self.origionSize,
                maxSize: self.maxSize,
                minSize: self.minSize
            )
            intrinsicContentSize = size
            self.contentMode = contentMode
        } else {
            var size = Self.calcSize(size: self.origionSize, maxSize: self.maxSize, minSize: self.minSize)
            // 超长/宽细图需要补足宽度
            if size.width < minSize.width {
                size.height = minSize.height
            } else if size.height < minSize.height {
                size.width = minSize.width
            }
            intrinsicContentSize = size
        }
        return intrinsicContentSize
    }

    public init(maxSize: CGSize, minSize: CGSize) {
        self.maxSize = maxSize
        self.minSize = minSize

        super.init(image: nil)

        self.animateRunLoopMode = .default
        self.contentMode = .scaleAspectFit
        self.clipsToBounds = true
        self.isUserInteractionEnabled = true
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 计算图片的大小和ContentMode
    ///
    /// - Parameters:
    ///   - originSize: 图片原始大小，没有加载之前的
    ///   - maxSize: 最大显示大小
    ///   - minSize: 最小显示大小
    /// - Returns: 应该显示的大小和图片的ContentMode
    open class func calculateSizeAndContentMode(originSize size: CGSize, maxSize: CGSize, minSize: CGSize) -> (CGSize, UIView.ContentMode) {
        if size == .zero {
            return (BaseImageView.Cons.failedImageSize, .scaleAspectFit)
        }

        let minWidth: CGFloat = minSize.width
        let minHeight: CGFloat = minSize.height
        let minWHRatio: CGFloat = minWidth / minHeight
        let imgWHRatio: CGFloat = size.width / size.height
        // 算出最适合的尺寸
        let fitSize = calcSize(size: size, maxSize: maxSize)
        var newWidth = fitSize.width
        var newHeight = fitSize.height
        if showStripeImage(originSize: size, maxSize: maxSize) { //长图逻辑
            return (CGSize(width: Cons.stripeImageDisplaySize.width,
                           height: size.height / size.width * Cons.stripeImageDisplaySize.width), .scaleAspectFill)
        }
        return (CGSize(width: newWidth, height: newHeight), .scaleAspectFill)
    }

    class func showStripeImage(originSize: CGSize, maxSize: CGSize) -> Bool {
        return originSize.width >= Cons.stripeImageJudgeWidth &&
        originSize.width / originSize.height < Cons.stripeImageJudgeWHRatio &&
        maxSize.width >= Cons.stripeImageDisplaySize.width &&
        maxSize.height >= Cons.stripeImageDisplaySize.height
    }

    // 大了缩小到 aspectScaleFit，小了不放大
    private class func calcSize(size: CGSize, maxSize: CGSize) -> CGSize {
        if size.width <= maxSize.width && size.height <= maxSize.height {
            return size
        }
        let widthScaleRatio: CGFloat = min(1, maxSize.width / size.width)
        let heightScaleRatio: CGFloat = min(1, maxSize.height / size.height)
        let scaleRatio = min(widthScaleRatio, heightScaleRatio)
        return CGSize(width: size.width * scaleRatio, height: size.height * scaleRatio)
    }

    private class func calcSize(size: CGSize, maxSize: CGSize, minSize: CGSize) -> CGSize {
        if size.width == 0 || size.height == 0 {
            return minSize
        }

        //屏幕宽度 - marginLeft - marginRight
        let maxWidth: CGFloat = maxSize.width
        let maxHeight: CGFloat = maxSize.height
        let minWidth: CGFloat = minSize.width
        let minHeight: CGFloat = minSize.height
        let maxWHRatio: CGFloat = maxWidth / maxHeight
        let imgWHRatio: CGFloat = size.width / size.height
        var newWidth = size.width
        var newHeight = size.height

        /// 算出范围在 minSize 和 maxSize 尺寸之间的尺寸
        if size.width > minWidth || size.height > minHeight {
            // 宽高比例超出了气泡最大值，就调整宽度为最大值
            if imgWHRatio > maxWHRatio {
                if size.width > maxWidth {
                    newWidth = maxWidth
                }
                newHeight = newWidth / imgWHRatio
            } else {
                // 高度超过了最大值，就跳转高度为最大值
                if size.height > maxHeight {
                    newHeight = maxHeight
                }
                newWidth = newHeight * imgWHRatio
            }
        } else {
            /// 以宽和高之间的小值设置为最小值
            if imgWHRatio > 1.0 {
                if size.width < minWidth {
                    newWidth = minWidth
                }
                newHeight = newWidth / imgWHRatio
            } else {
                if size.height < minHeight {
                    newHeight = minHeight
                }
                newWidth = newHeight * imgWHRatio
            }
        }
        return CGSize(width: newWidth, height: newHeight)
    }
}

private let downloadFailedLayerTag = 999_999

extension UIImageView {
    public func setImageWithAction(setAction: @escaping BaseImageViewWrapper.SetImageType) {
        hideDownloadFailedLayer()
        setAction(self) { [weak self] (image, error) in
            guard let self = self else { return }
            if error != nil, image == nil {
                self.showDownloadFailedView()
            }
        }
    }

    private func showDownloadFailedView() {
        self.isUserInteractionEnabled = false

        if let view = self.viewWithTag(downloadFailedLayerTag) {
            view.isHidden = false
        } else {
            let image = UDIcon.getIconByKey(.loadfailFilled, size: CGSize(width: 32, height: 32)).ud.withTintColor(UIColor.ud.iconN3)
            let failedLayer = UIImageView(image: image)
            failedLayer.contentMode = .center
            failedLayer.backgroundColor = UIColor.ud.bgBody
            failedLayer.tag = downloadFailedLayerTag
            self.addSubview(failedLayer)
            failedLayer.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }

    private func hideDownloadFailedLayer() {
        self.isUserInteractionEnabled = true

        if let view = self.viewWithTag(downloadFailedLayerTag) {
            view.isHidden = true
        }
    }
}
