//
//  PostPinConfirmView.swift
//  LarkChat
//
//  Created by chengzhipeng-bytedance on 2018/9/13.
//

import Foundation
import UIKit
import LarkCore
import LarkRichTextCore
import LarkUIKit
import LarkModel
import RichLabel
import LarkContainer
import LarkAccountInterface

// MARK: - PostPinConfirmView
final class PostPinConfirmView: PinConfirmContainerView, LKLabelDelegate {
    lazy var postView = PostView(numberOfLines: 3, delegate: self, isReply: false, tapHandler: nil)

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(postView)
        postView.snp.makeConstraints { (make) in
            make.top.left.equalTo(BubbleLayout.commonInset.top)
            make.right.equalTo(-BubbleLayout.commonInset.right)
            make.bottom.equalTo(self.nameLabel.snp.top).offset(-BubbleLayout.commonInset.bottom)
        }
        self.postView = postView
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setPinConfirmContentView(_ contentVM: PinAlertViewModel) {
        super.setPinConfirmContentView(contentVM)

        guard let contentVM = contentVM as? PostPinConfirmViewModel, let richTextResult = contentVM.richTextResult else {
            return
        }

        let title = contentVM.content.title.isEmpty ? BundleI18n.LarkChat.Lark_Legacy_PostNoTitleTip : contentVM.content.title
        let maxWidth = LarkChatUtils.pinAlertConfirmMaxWidth - 2 * BubbleLayout.commonInset.left
        self.postView.setContentLabel(
            contentMaxWidth: maxWidth,
            titleText: title,
            isUntitledPost: contentVM.content.isUntitledPost,
            attributedText: contentVM.attributeText,
            rangeLinkMap: richTextResult.urlRangeMap,
            tapableRangeList: richTextResult.atRangeMap.flatMap({ $0.value }),
            textLinkMap: richTextResult.textUrlRangeMap,
            linkAttributes: [.foregroundColor: UIColor.ud.textLinkNormal],
            textLinkBlock: nil
        )
    }
}

// MARK: - PostPinConfirmViewModel
final class PostPinConfirmViewModel: PinAlertViewModel, TruncateLongText {
    let userResolver: UserResolver
    var attributeText: NSAttributedString = NSAttributedString(string: "")
    var richTextResult: ParseRichTextResult?
    var content: PostContent!

    init?(userResolver: UserResolver, message: Message, checkIsMe: @escaping (String) -> Bool, abbreviationEnable: Bool, getSenderName: @escaping (Chatter) -> String) {
        self.userResolver = userResolver
        super.init(message: message, getSenderName: getSenderName)

        guard let content = message.content as? PostContent else {
            return nil
        }

        self.content = content

        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.ud.N900,
            .font: UIFont.systemFont(ofSize: 16)
        ]

        let fixRichText = content.richText.lc.convertText(tags: [.img, .media])
        let textDocsVM = TextDocsViewModel(userResolver: userResolver, richText: fixRichText, docEntity: content.docEntity)
        let passportUserService = try? userResolver.resolver.resolve(assert: PassportUserService.self)
        self.richTextResult = textDocsVM.parseRichText(
            isShowReadStatus: false,
            checkIsMe: checkIsMe,
            maxLines: PinListUtils.maxLines,
            maxCharLine: PinListUtils.maxCharOfLine,
            needNewLine: false,
            iconColor: UIColor.ud.textLinkNormal,
            customAttributes: attributes,
            abbreviationInfo: abbreviationEnable ? content.getAbbreviationWrapper(currentUserId: userResolver.userID,
                                                                                  tenantId: passportUserService?.userTenant.tenantID ?? "") : nil
        )

        self.attributeText = self.genAttributeText()
    }

    func genAttributeText() -> NSAttributedString {
        if PinListUtils.maxLines > 0, let attributeText = self.richTextResult?.attriubuteText {
            let maxLength = PinListUtils.maxLines * LarkChatUtils.maxCharCountAtOneLine
            return self.truncateAttributeText(attributeText, maxLength: maxLength)
        }
        return attributeText
    }
}
