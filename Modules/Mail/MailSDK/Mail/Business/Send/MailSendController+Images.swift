//
//  MailSendController+Images.swift
//  MailSDK
//
//  Created by majx on 2020/7/11.
//

import Foundation

extension MailSendController {
    func hasFailedOrUploadingImages() -> Bool {
        guard let imageHandler = pluginRender?.imageHandler else { return false }
        return imageHandler.isContainsUploadingImg || imageHandler.isContainsErrorImg
    }
}
