//
//  DocsAvatarImageView+Ext.swift
//  SKUIKit
//
//  Created by lijuyou on 2020/5/26.
//  


import SKFoundation
import ByteWebImage
import SKUIKit
import SKResource

extension DocsAvatarImageView {
//    public func configure(_ iconInfo: DocsIconInfo?, trigger: String) {
//        configureCore(key: iconInfo?.key,
//                      type: iconInfo?.type,
//                      trigger: trigger)
//    }

    public func configure(_ iconInfo: IconSelectionInfo?, trigger: String) {
        configureCore(key: iconInfo?.key,
                      type: iconInfo == nil ? nil : SpaceEntry.IconType(rawValue: iconInfo!.type),
                      trigger: trigger)
    }

    private func configureCore(key: String?, type: SpaceEntry.IconType?, trigger: String) {
        if let key = key, let type = type {
            let errCallback: ByteWebImage.ImageRequestCompletion = { result in
                switch result {
                case .success(let imageResult):
                    break
                case .failure(let error):
                    DocsLogger.error("Load avatar failed", extraInfo: ["trigger": trigger,
                                                                       "type": type.rawValue,
                                                                       "key": key], error: error)
                }
                
            }

            switch type {
            case .unknow, .emoji:
                DocsLogger.info("Unsupported avatar type", extraInfo: ["trigger": trigger,
                                                                       "type": type.rawValue,
                                                                       "key": key])
            case .image, .custom:
                set(avatarKey: key,
                    placeholder: BundleResources.SKResource.Common.Icon.icon_doc_addicon_placeholder,
                    completion: errCallback)
            case .remove:
                set(image: BundleResources.SKResource.Common.Icon.icon_doc_removeicon_nor)
            }
        } else {
            set(image: nil)
        }
    }
}
