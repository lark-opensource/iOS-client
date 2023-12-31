//
//  MailSendController+Uploader.swift
//  MailSDK
//
//  Created by majx on 2020/6/18.
//

import Foundation

extension MailSendController: MailUploaderDelegate {
    var threadID: String? {
        get {
            return baseInfo.threadID
        }
        set (newValue) {
            scrollContainer.attachmentsContainer.threadID = newValue
        }
    }

    func isSharedAccount() -> Bool {
        return baseInfo.isSharedAccount()
    }

    var sharedAccountId: String? {
        return baseInfo.sharedAccountId
    }

    var draftID: String? {
        get {
            return draft?.id
        }
    }

    var uploaderProvider: AttachmentUploadProxy? {
        accountContext.provider.attachmentUploader
    }

    var configProvider: ConfigurationProxy? {
        accountContext.provider.configurationProvider
    }
}
