//
//  SearchLynxImageFetcher.swift
//  LarkSearch
//
//  Created by bytedance on 2021/7/19.
//

import UIKit
import Foundation
import Lynx
import ByteWebImage
import LKCommonsLogging
import RxSwift
import LarkContainer
import LarkSDKInterface
import LarkStorage

public final class SearchLynxImageFetcher: NSObject, LynxImageFetcher {
    private static let logger = Logger.log(SearchLynxImageFetcher.self, category: "Module.Search.SearchLynxImageFetcher")
    private static let AI_SEARCH_SCHEME = "aisearch"
    private static let AVATAR_HOST = "avatar"
    private static let DRIVE_SOURCE_HOST = "drive_resource"
    var resourceAPI: ResourceAPI?
    var dependency: SearchCoreDependency?
    private let disposeBag = DisposeBag()
    public let userResolver: UserResolver
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.resourceAPI = try? userResolver.resolve(assert: ResourceAPI.self)
        self.dependency = try? userResolver.resolve(assert: SearchCoreDependency.self)
    }

    public func loadImage(with url: URL?, size targetSize: CGSize, contextInfo: [AnyHashable: Any]?, completion completionBlock: @escaping LynxImageLoadCompletionBlock) -> () -> Void {
        if let url = url {
            let scheme = url.scheme
            if scheme == Self.AI_SEARCH_SCHEME {
                guard let host = url.host else {
                    Self.logger.info("【LarkSearch.LynxImageFetcher】- INFO: url invalid:\(url.absoluteString)")
                    completionBlock(nil, nil, nil)
                    return {}
                }
                if host == Self.AVATAR_HOST, let key = url.queryParameters["key"] {
                    let id = url.queryParameters["id"] ?? ""
                    let size: Int32 = 500
                    let dpr: Float = 500
                    self.resourceAPI?.fetchResourcePath(entityID: id, key: key, size: size, dpr: dpr, format: "png")
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { response in
                            let absPathStr = AbsPath(response)
                            if absPathStr.exists,            // 判断文件存在
                               !absPathStr.isDirectory,      // 判断是否是目录
                               let image = try? UIImage.read(from: absPathStr) {
                                completionBlock(image, nil, url)
                                Self.logger.info("【LarkSearch.LynxImageFetcher】- INFO: fetchResourcePath success!")
                            } else {
                                completionBlock(nil, nil, url)
                                Self.logger.error("【LarkSearch.LynxImageFetcher】- ERROR: fetchResourcePath error: \(absPathStr)")
                            }
                        }, onError: { error in
                            completionBlock(nil, error, url)
                            Self.logger.error("【LarkSearch.LynxImageFetcher】- ERROR: fetchResourcePath error: \(error)")
                        }).disposed(by: disposeBag)
                    return {}
                } else if host == Self.DRIVE_SOURCE_HOST, let token = url.queryParameters["token"] {
                    dependency?.getImage(withToken: token)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { (result) in
                            switch result {
                            case .success(let image, _):
                                Self.logger.info("【LarkSearch.LynxImageFetcher】- INFO: fetchResourcePath success! url \(url)")
                                completionBlock(image.image, nil, url)
                            case .failed(let error, _):
                                Self.logger.error("【LarkSearch.LynxImageFetcher】- ERROR: fetchResourcePath error: \(error), url \(url)")
                                completionBlock(nil, error, url)
                            }
                        })
                        .disposed(by: disposeBag)
                    return {}
                } else {
                    Self.logger.info("【LarkSearch.LynxImageFetcher】- INFO: url invalid:\(url.absoluteString)")
                    completionBlock(nil, nil, nil)
                    return {}
                }
            } else {
                let request = ImageManager.default.requestImage(url, completion: { (requestResult) in
                    switch requestResult {
                    case .success(let imageResult):
                        Self.logger.info("【LarkSearch.LynxImageFetcher】loadImage success！")
                        completionBlock(imageResult.image, nil, url)
                    case .failure(let error):
                        Self.logger.error("【LarkSearch.LynxImageFetcher】loadImage error: \(error)")
                        completionBlock(nil, error, url)
                    }
                })
                return {
                    Self.logger.info("【LarkSearch.LynxImageFetcher】loadImage canceled!")
                    ImageManager.default.cancelRequest(request)
                }
            }
        } else {
            Self.logger.info("【LarkSearch.LynxImageFetcher】- INFO: url is null")
            completionBlock(nil, nil, nil)
            return {}
        }
    }
}
