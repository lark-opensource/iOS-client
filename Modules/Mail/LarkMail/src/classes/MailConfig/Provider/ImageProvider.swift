//
//  ImageProvider.swift
//  Action
//
//  Created by tefeng liu on 2019/6/23.
//

import Foundation
import MailSDK
import SwiftProtobuf
import Swinject
import ByteWebImage

class SetImageTaskWrapper: MailSDK.SetImageTask {
    let base: ByteWebImage.ImageRequest

    init(_ base: ByteWebImage.ImageRequest) {
        self.base = base
    }

    func cancel() {
        base.cancel()
    }
}

class ImageProvider: ImageProxy {
    func setAvatar(_ imageView: UIImageView,
                   key: String,
                   entityId: String,
                   avatarImageParams: MailSDK.SetAvatarImageParams?,
                   placeholder: UIImage?,
                   progress: MailSDK.ProgressCallback?,
                   completion: MailSDK.CompletionCallback?) -> MailSDK.SetImageTask? {
        let task = imageView.bt.setLarkImage(with: .avatar(key: key, entityID: entityId, params: .init(sizeType: .size(imageView.bounds.width))),
                                             placeholder: placeholder,
                                             progress: { (_, rSize, eSize) in
                                                progress?(Int64(rSize), Int64(eSize))
                                             },
                                             completion: { [weak imageView] result in
                                                switch result {
                                                case .success(let imageResult):
                                                    imageView?.backgroundColor = UIColor.clear
                                                    completion?(imageResult.image, nil)
                                                case .failure(let error):
                                                    imageView?.backgroundColor = UIColor.ud.N300
                                                    completion?(nil, error)
                                                }
                                             })

        if let task = task {
            return SetImageTaskWrapper(task)
        } else {
            return nil
        }
    }

    func setExternalImage(_ imageView: UIImageView,
                          key: String,
                          url: String,
                          placeholder: UIImage?,
                          progress: MailSDK.ProgressCallback?,
                          completion: MailSDK.CompletionCallback?) -> MailSDK.SetImageTask? {
        let resourceKey = key.isEmpty ? url : key
        let task = imageView.bt.setLarkImage(with: .default(key: resourceKey),
                                             placeholder: placeholder,
                                             progress: { (_, rSize, eSize) in
                                                progress?(Int64(rSize), Int64(eSize))
                                             },
                                             completion: { result in
                                                switch result {
                                                case .success(let imageResult):
                                                    completion?(imageResult.image, nil)
                                                case .failure(let error):
                                                    completion?(nil, error)
                                                }
                                             })
        if let task = task {
            return SetImageTaskWrapper(task)
        } else {
            return nil
        }
    }
}
