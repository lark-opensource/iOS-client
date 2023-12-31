//
//  CardImageFetcher.swift
//  Timor
//
//  Created by 武嘉晟 on 2020/5/26.
//

import Foundation
import Lynx

let ImageFetcherErrorDomain = "CardImageFetcher"
let ImageFetcherErrorcode = -1

/// Lynx Image加载注入对象
@objcMembers
final class CardImageFetcher: NSObject, LynxImageFetcher {

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
        guard completionBlock != nil else {
            let msg = "lynx image invoke without completionBlock"
            BDPLogError(tag: .cardImageFetcher, msg)
            return {}
        }
        guard let url = url else {
            let msg = "url for lynx card image is nil"
            DispatchQueue.main.async {
                completionBlock(nil, imageFetcherError(with: msg), nil)
            }
            BDPLogError(tag: .cardImageFetcher, msg)
            return {}
        }
        let session = BDPNetworking.sharedSession()
        let task = session.dataTask(with: url) { (data, _, error) in
            if let error = error {
                //  网络请求失败
                DispatchQueue.main.async {
                    completionBlock(nil, error, url)
                }
                BDPLogError(tag: .cardImageFetcher, error.localizedDescription)
                return
            }
            guard let data = data else {
                //  没有回包数据
                let msg = "response data for lynx image is nil"
                DispatchQueue.main.async {
                    completionBlock(nil, imageFetcherError(with: msg), url)
                }
                BDPLogError(tag: .cardImageFetcher, msg)
                return
            }
            guard let image = UIImage(data: data) else {
                let msg = "data is invaild for image(scpoe: lynx image fetch)"
                DispatchQueue.main.async {
                    completionBlock(nil, imageFetcherError(with: msg), url)
                }
                BDPLogError(tag: .cardImageFetcher, msg)
                return
            }
            DispatchQueue.main.async {
                completionBlock(image, nil, url)
            }
        }
        task.resume()
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
