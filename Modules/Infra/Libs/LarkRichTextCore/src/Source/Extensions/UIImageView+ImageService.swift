//
//  UIImageView+ImageService.swift
//  LarkRichTextCore
//
//  Created by zc09v on 2018/7/27.
//

import UIKit
import Foundation
import LarkModel
import RustPB
import ByteWebImage
import LarkFeatureGating
import LKCommonsTracker
import LKCommonsLogging

public extension UIImageView {
    @discardableResult
    func setPostMessage(imageSet: ImageItemSet,
                        placeholder: UIImage? = nil,
                        forceOrigin: Bool = false,
                        progress: ImageRequestProgress? = nil,
                        completion: ImageRequestCompletion? = nil) -> ImageRequest? {
        if let originKey = imageSet.origin?.key,
           let result = self.setLocalImage(originKey:
                                            originKey,
                                           placeholder: placeholder,
                                           completion: completion),
           result.0 {
            return result.1
        }
        let key = imageSet.generatePostMessageKey(forceOrigin: forceOrigin)
        if let token = imageSet.token, !token.isEmpty {
            let resource = LarkImageResource.default(key: key)
            return self.bt.setLarkImage(with: resource,
                                 placeholder: placeholder,
                                 trackStart: {
                                    return TrackInfo(scene: .Chat, fromType: .post)
                                 },
                                 progress: progress,
                                 completion: completion)
        } else if let url = imageSet.urls?.first,
                  !url.isEmpty {
            let resource = LarkImageResource.default(key: url)
            return self.bt.setLarkImage(with: resource,
                                               placeholder: placeholder,
                                               progress: progress,
                                               completion: completion)
        }
        return nil
    }

    private func setLocalImage(originKey: String,
                               placeholder: UIImage?,
                               completion: ImageRequestCompletion?) -> (Bool, ImageRequest?)? {
        let isLocal = originKey.hasPrefix(Resources.localDocsPrefix)
        if !isLocal {
            return (isLocal, nil)
        }
        // TODO: 目前，只针对DocIcon的情况
        if let url = URL(string: originKey) {
            let array = ["/", "localResouces", "docs", "docType"]
            for (index, pathComponent) in url.pathComponents.enumerated() where index < array.count {
                guard array[index] == pathComponent else {
                    return (isLocal, nil)
                }
            }
            guard let pathComponent = url.pathComponents.last else {
                return (isLocal, nil)
            }
            // 单独针对DocIcon的情况处理
            guard let docsIconType = DocsIconType(rawValue: pathComponent) else {
                assertionFailure("doctype not found")
                return (isLocal, nil)
            }
            let docType = RustPB.Basic_V1_Doc.TypeEnum(docsIconType: docsIconType)
            let image = LarkRichTextCoreUtils.docUrlIcon(docType: docType)
            if let customKey = url.queryParameters["customKey"],
               !customKey.isEmpty {
                var imageSet = ImageItemSet()
                // doc token占位，方便debug。用来达到走正常走SDK图片的逻辑
                imageSet.token = "doctoken"
                let imageItem = ImageItem(key: customKey)
                imageSet.origin = imageItem
                imageSet.middle = imageItem
                imageSet.thumbnail = imageItem
                self.setPostMessage(imageSet: imageSet,
                                    placeholder: image,
                                    forceOrigin: false,
                                    progress: nil,
                                    completion: completion)
            } else {
                self.image = image
                let request = ImageRequest(url: URL(fileURLWithPath: ""))
                let result = ImageRequestResult.success(ImageResult(request: request, image: image, data: nil, from: .none, savePath: nil))
                completion?(result)
            }
        } else {
            let error = ByteWebImageError(ByteWebImageErrorUnkown, userInfo: [NSLocalizedDescriptionKey: "set local post image error"])
            let result = ImageRequestResult.failure(error)
            completion?(result)
        }
        return (isLocal, nil)
    }
}

public extension ImageSet {
    public var intactSize: CGSize {
        // origin 的数据可能不是不准确的，有intact优先用intact，并根据exifOrientation决定宽高
        if hasIntact &&
            intact.hasExifOrientation &&
            intact.exifOrientation != 0 {
            let width = intact.width
            let height = intact.height
            if intact.exifOrientation > 4 {
                return CGSize(width: CGFloat(height), height: CGFloat(width))
            } else {
                return CGSize(width: CGFloat(width), height: CGFloat(height))
            }
        } else {
            return CGSize(
                width: CGFloat(origin.width),
                height: CGFloat(origin.height)
            )
        }
    }
}
