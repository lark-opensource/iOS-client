//
//  MailFeedCardDigestVM.swift
//  LarkMail
//
//  Created by ByteDance on 2023/9/19.
//

import Foundation
import LarkOpenFeed
import LarkModel
import UniverseDesignColor
import RustPB
import LarkFeedBase
import LarkTimeFormatUtils
import LarkLocalizations
import MailSDK

// MARK: - ViewModel
final class MailFeedCardDigestVM: FeedCardDigestVM {
    // 组件类别
    var type: FeedCardComponentType {
        return .digest
    }
    // VM 数据
    let digestContent: FeedCardDigestVMType

    // 在子线程生成view data
    required init(feedPreview: FeedPreview) {
        guard let originData = try? Email_Client_V1_FeedCardExtra(serializedData: feedPreview.extraMeta.bizPb.extraData) else {
            self.digestContent = .text(feedPreview.uiMeta.digestText)
            return
        }        
        let feedCardProvider = FeedCardProvider()
        if originData.hasDraft_p {
            let textAttachment = NSTextAttachment()
            textAttachment.image = feedCardProvider.editIcon
            let font = UIFont.systemFont(ofSize: 16)
            let imageSize = CGSize(width: 16, height: 16)
            textAttachment.bounds = CGRect(origin:CGPoint(x: 0, y: -2), size: imageSize)
            // 创建包含图标的富文本
            let attributedString = NSMutableAttributedString(string: "")
            let imageString = NSAttributedString(attachment: textAttachment)
            attributedString.append(imageString)
            attributedString.append(NSMutableAttributedString(string: " "))
            let content = originData.isEmptySubject ? feedCardProvider.noSubjectStr : feedPreview.uiMeta.digestText
            attributedString.append(NSAttributedString(string: content))
            self.digestContent = .attributedText(attributedString)
        } else if originData.isEmpty {
            self.digestContent = .text(feedCardProvider.noContent)
        } else if originData.isEmptySubject {
            self.digestContent = .text(feedCardProvider.noSubjectStr)
        } else {
            self.digestContent = .text(feedPreview.uiMeta.digestText)
        }
    }
}
