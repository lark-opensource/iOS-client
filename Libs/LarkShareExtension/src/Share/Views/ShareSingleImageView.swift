//
//  ShareSingleImageView.swift
//  ShareExtension
//
//  Created by K3 on 2018/7/4.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import LarkExtensionCommon
import MobileCoreServices

final class ShareSingleImageView: UIView, ShareTableHeaderProtocol {
    //ShareExtension内存限制为120MB，若位图超过120MB会OOM，所以根据RGBA图片换算得到图片最大分辨率做预览限制
    private let limitResizeImageResolution: CGFloat = 115 * 1024 * 1024 / 4
    var viewHeight: CGFloat = 252
    private var item: ShareImageItem
    private var imageView: UIImageView
    private let verticalInset: CGFloat = 16
    private let horizontalInset: CGFloat = 48
    private let stripeImageJudgeWidth: CGFloat = 200
    private let stripeImageJudgeWHRatio: CGFloat = 1 / 3

    init(item: ShareImageItem, availableWidth: CGFloat) {
        self.item = item
        self.imageView = UIImageView()
        super.init(frame: .zero)
        imageView.contentMode = .scaleAspectFit

        if let image = item.previewMaps.values.first {
            if image.size.height * image.size.width > limitResizeImageResolution {
                imageView.image = Resources.unknownFile
                LarkShareExtensionLogger.shared.error("imageSize larger than limitResizeImageResolution,width: \(image.size.width), height: \(image.size.height)")
            } else if image.size.height != 0 &&
                        image.size.width / image.size.height < stripeImageJudgeWHRatio &&
                        image.size.width >= stripeImageJudgeWidth {
                // 长图
                let ratio = max(
                    image.size.height / (viewHeight - verticalInset * 2),
                    image.size.width / (availableWidth - horizontalInset * 2)
                )

                let newSize = CGSize(width: image.size.width / ratio, height: image.size.height / ratio)
                imageView.image = image.resize(with: newSize, radius: 2)
            } else {
                imageView.image = image
            }
        }

        addSubview(imageView)
    }

    override var frame: CGRect {
        didSet {
            let frame = self.bounds
            imageView.frame = CGRect(
                x: horizontalInset,
                y: verticalInset,
                width: frame.size.width - horizontalInset * 2,
                height: viewHeight - verticalInset * 2
            )
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension UIImage {
    func resize(with newSize: CGSize, radius: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)

        let rect = CGRect(origin: .zero, size: newSize)

        UIBezierPath(roundedRect: rect, cornerRadius: radius).addClip()
        draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image ?? self
    }
}
