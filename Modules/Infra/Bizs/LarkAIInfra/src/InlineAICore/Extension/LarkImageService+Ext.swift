//
//  LarkImageService+Ext.swift
//  LarkAIInfra
//
//  Created by huayufan on 2023/11/27.
//  

import ByteWebImage

protocol DownloadAIImageAPI: AnyObject {
    func requestImageURL(urlString: String, callback: @escaping (ImageRequestResult) -> Void)
}


extension LarkImageService: DownloadAIImageAPI {
    func requestImageURL(urlString: String, callback: @escaping (ImageRequestResult) -> Void) {
        LarkImageService.shared.setImage(with: .default(key: urlString), completion:  { imageResult in
            callback(imageResult)
        })
    }
}
