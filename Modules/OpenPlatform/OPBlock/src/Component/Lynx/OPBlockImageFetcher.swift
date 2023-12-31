//
//  OPBlockImageFetcher.swift
//  Timor
//
//  Created by 武嘉晟 on 2020/5/26.
//

import Foundation
import Lynx
import LarkOPInterface
import LKCommonsLogging
import TTMicroApp
import OPFoundation
import BDWebImage
import ByteWebImage
import LarkFeatureGating
import LarkContainer
import OPBlockInterface
import OPSDK

let ImageFetcherErrorDomain = "CardImageFetcher"
let ImageFetcherErrorcode = -1

/// Lynx Image加载注入对象
@objcMembers
public final class OPBlockImageFetcher: NSObject, LynxImageFetcher {

    private let containerContext: OPContainerContext
    private let userResolver: UserResolver

    private var trace: BlockTrace {
        containerContext.blockTrace
    }

    init(userResolver: UserResolver, containerContext: OPContainerContext) {
        self.userResolver = userResolver
        self.containerContext = containerContext
        super.init()
    }

    /// Load image asynchronously.
    /// - Parameters:
    ///   - url: ui that fires the request.
    ///   - targetSize: the target screen size for showing the image. It is more efficient that UIImage with the same size is returned.
    ///   - contextInfo: extra info needed for image request.
    ///   - completionBlock: the block to provide image fetcher result.
    /// - Returns: A block which can cancel the image request if it is not finished. nil if cancel action is not supported.
    public func loadImage(
        with url: URL?,
        size targetSize: CGSize,
        contextInfo: [AnyHashable : Any]?,
        completion completionBlock: @escaping LynxImageLoadCompletionBlock
    ) -> () -> Void {
        //  校验
        guard OPUnsafeObject(completionBlock) != nil else {
            let msg = "lynx image invoke without completionBlock"
            trace.error("OPBlockImageFetcher.loadImage error: \(msg)")
            return {}
        }
        guard let url = OPUnsafeObject(url) else {
            let msg = "url for lynx card image is nil"
            DispatchQueue.main.async {
                completionBlock(nil, imageFetcherError(with: msg), nil)
            }
            trace.error("OPBlockImageFetcher.loadImage error: \(msg)")
            return {}
        }

        if userResolver.fg.staticFeatureGatingValue(with: BlockFGKey.enableWebImage.key) {
            LarkImageService.shared.setImage(with: .default(key: url.absoluteString), completion:  { [weak self] result in
                switch result {
                case .success(let imageResult):
                    guard let image = imageResult.image else {
                        // 获取图片失败
                        let msg = "data is invaild for image(scpoe: lynx image fetch)"
                        completionBlock(nil, imageFetcherError(with: msg), url)
                        self?.trace.error("OPBlockImageFetcher.loadImage with LarkImageService error: \(msg)")
                        return
                    }
                    // 图片获取成功
                    let from = imageResult.from.rawValue
                    self?.trace.info("OPBlockImageFetcher.loadImage success with LarkImageService, img from \(from)")
                    completionBlock(image, nil, url)
                case .failure(let error):
                    // 获取图片失败
                    completionBlock(nil, error, url)
                    self?.trace.error("OPBlockImageFetcher.loadImage with LarkImageService error: \(error.localizedDescription)")
                    return
                }
            })
        } else {
            BDWebImageManager.shared().requestImage(url, options: .requestPreloadAllFrames) {[weak self] _, img, _, err, from in
                if let error = err {
                    completionBlock(nil, error, url)
                    self?.trace.error("OPBlockImageFetcher.loadImage error: \(error.localizedDescription)")
                    return
                }
                guard let image = img else {
                    let msg = "data is invaild for image(scpoe: lynx image fetch)"
                    completionBlock(nil, imageFetcherError(with: msg), url)
                    self?.trace.error("OPBlockImageFetcher.loadImage error: \(msg)")
                    return
                }
                self?.trace.info("OPBlockImageFetcher.loadImage success, img from \(from.rawValue)")
                completionBlock(image, nil, url)
            }
        }
        return {}
    }
    
}

/// 下载Lynx UIImage
/// - Parameter msg: 错误信息
private func imageFetcherError(with msg: String) -> Error {
    NSError(
        domain: ImageFetcherErrorDomain,
        code: ImageFetcherErrorcode,
        userInfo: [
            NSLocalizedDescriptionKey: msg
        ]
    )
}
