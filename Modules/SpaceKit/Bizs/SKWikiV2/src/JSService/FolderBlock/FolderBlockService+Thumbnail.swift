//
//  FolderBlockService+Thumbnail.swift
//  SKWikiV2
//
//  Created by majie.7 on 2023/7/28.
//

import Foundation
import SKFoundation
import SKCommon
import SKInfra
import RxSwift


extension FolderBlockService {
    
    
    func getThumbnial(params: [String: Any]) {
        guard let callback = params["callback"] as? String,
              let url = params["url"] as? String,
              let encryptKey = params["encryptKey"] as? String,
              let encryptType = params["encryptType"] as? Int,
              let encryptNonce = params["encryptNonce"] as? String else {
            DocsLogger.error("folder block service: get thumbnail data invilid")
            return
        }
        
        let extraInfo: [String: Any] = ["type": encryptType, "secret": encryptKey, "nonce": encryptNonce]
        let thumbnailExtraInfo = SpaceThumbnailInfo.ExtraInfo(urlString: url, encryptInfo: extraInfo)
        guard let info = SpaceThumbnailInfo(unencryptURL: URL(string: url), extraInfo: thumbnailExtraInfo) else {
            DocsLogger.error("folder block service: construct SpaceThumbnailInfo error ")
            return
        }
        
        let manager = DocsContainer.shared.resolve(SpaceThumbnailManager.self)!
        let request = SpaceThumbnailManager.Request(token: docsInfo?.objToken ?? "",
                                                    info: info,
                                                    source: .unknown,
                                                    fileType: .unknownDefaultType,
                                                    placeholderImage: nil,
                                                    failureImage: nil)
        manager.getThumbnailWithType(request: request)
            .observeOn(MainScheduler.instance)
            .takeLast(1)
            .subscribe(onNext: { [weak self] response in
                guard let imageData = response.image.pngData(),
                      let strBase64 = imageData.toBase64Stirng else {
                    return
                }
                let data: [String: Any] = ["isDefault": response.type == .specialImage,
                                           "imgData": strBase64]
                let params: [String: Any] = ["code": 0, "data": data]
                self?.model?.jsEngine.callFunction(DocsJSCallBack(rawValue: callback), params: params, completion: nil)
            }, onError: { [weak self] _ in
                self?.model?.jsEngine.callFunction(DocsJSCallBack(rawValue: callback), params: ["code": -1], completion: nil)
            })
            .disposed(by: disposeBag)
    }
}
