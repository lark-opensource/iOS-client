//
//  SpaceThumbnailManager+Template.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/5/22.
//  

import Foundation
import RxSwift
import SwiftyJSON
import SKFoundation

extension SpaceThumbnailManager {

    public func getThumbnail(template: Template, placeHolderImage: UIImage? = nil, failureImage: UIImage? = nil, processer: SpaceThumbnailProcesser = SpaceDefaultProcesser()) -> Observable<UIImage> {
        if let decryptKey = template.secretKey,
            let urlString = template.secretCoverUrl,
            let url = URL(string: urlString) {
            let encryptInfo = Info.ExtraInfo(url: url, encryptType: .CBC(secret: decryptKey))
            let request = Request(token: template.objToken ?? "template-thumbnail-token",
                                  info: .encryptedOnly(encryptInfo: encryptInfo),
                                  source: .template,
                                  fileType: template.objType,
                                  placeholderImage: placeHolderImage,
                                  failureImage: failureImage,
                                  processer: processer)
            return getThumbnail(request: request)
        }
        guard let token = template.objToken else {
            DocsLogger.error("space.thumbnail.manager --- failed to get objToken when fatching template thumbnail url")
            if let failureImage = failureImage {
                return .just(failureImage)
            } else {
                return .error(ThumbnailError.thumbnailUnavailable)
            }
        }
        return downloader.getThumbnailURL(objType: template.objType, objToken: token).asObservable()
            .flatMap({ (extraInfo) -> Observable<UIImage> in
                if case let .CBC(secret) = extraInfo.encryptType {
                    // 模板的封面目前都是用 CBC 加密，因此仅在解析结果为 CBC 时才保存加密信息
                    template.secretKey = secret
                    template.secretCoverUrl = extraInfo.url.absoluteString
                }
                let request = Request(token: token,
                                      info: .encryptedOnly(encryptInfo: extraInfo),
                                      source: .template,
                                      fileType: template.objType,
                                      placeholderImage: placeHolderImage,
                                      failureImage: failureImage,
                                      processer: processer)
                return self.getThumbnail(request: request)
            })
    }

//    func getThumbnail(templateModel: TemplateModel,
//                      placeHolderImage: UIImage? = nil,
//                      failureImage: UIImage? = nil,
//                      processer: SpaceThumbnailProcesser = SpaceDefaultProcesser()) -> Observable<UIImage> {
//        if let decryptKey = templateModel.secretKey,
//            let urlString = templateModel.secretCoverUrl,
//            let url = URL(string: urlString) {
//            let encryptInfo = Info.ExtraInfo(url: url, encryptType: .CBC(secret: decryptKey))
//            let request = Request(token: templateModel.objToken,
//                                  info: .encryptedOnly(encryptInfo: encryptInfo),
//                                  source: .template,
//                                  fileType: templateModel.docsType,
//                                  placeholderImage: placeHolderImage,
//                                  failureImage: failureImage,
//                                  processer: processer)
//            return getThumbnail(request: request)
//        }
//        let token = templateModel.objToken
//        return downloader.getThumbnailURL(objType: templateModel.docsType, objToken: token).asObservable()
//            .flatMap({ (extraInfo) -> Observable<UIImage> in
//                if case let .CBC(secret) = extraInfo.encryptType {
//                    // 模板的封面目前都是用 CBC 加密，因此仅在解析结果为 CBC 时才保存加密信息
//                    DocsLogger.debug("👀save success: \(templateModel.objToken) - \(secret)")
//                    templateModel.saveAndUpdateCoverUrl(secret, extraInfo.url.absoluteString)
//                }
//                let request = Request(token: token,
//                                      info: .encryptedOnly(encryptInfo: extraInfo),
//                                      source: .template,
//                                      fileType: templateModel.docsType,
//                                      placeholderImage: placeHolderImage,
//                                      failureImage: failureImage,
//                                      processer: processer)
//                return self.getThumbnail(request: request)
//            })
//    }

    func getThumbnailV41(templateModel: TemplateModel,
                         placeHolderImage: UIImage? = nil,
                         failureImage: UIImage? = nil,
                         processer: SpaceThumbnailProcesser = SpaceDefaultProcesser()) -> Observable<UIImage> {

        guard let thumbnailInfo = templateModel.thumbnailExtra, thumbnailInfo.isAvailable else {
            return .just(failureImage ?? UIImage())
        }

        let urlString = thumbnailInfo.thumbnailUrl
        guard let url = URL(string: urlString) else { return .just(failureImage ?? UIImage()) }

        let encryptInfo = Info.ExtraInfo(url: url, encryptType: .CBC(secret: thumbnailInfo.decryptKey))
        let request = Request(token: templateModel.objToken,
                              info: .encryptedOnly(encryptInfo: encryptInfo),
                              source: .template,
                              fileType: templateModel.docsType,
                              placeholderImage: placeHolderImage,
                              failureImage: failureImage,
                              processer: processer)
        return getThumbnail(request: request)
    }

}
