//
//  TextPinConfirmViewv.swift
//  LarkChat
//
//  Created by zc09v on 2019/10/5.
//

import Foundation
import UIKit
import LarkCore
import LarkRichTextCore
import LarkUIKit
import LarkModel
import RichLabel
import LarkAccountInterface
import LarkContainer

final class TextPinConfirmView: PinConfirmContainerView, LKLabelDelegate {
    private let contentView: TextPinConfirmContentView = TextPinConfirmContentView(frame: .zero)
    private let urlPreView: TextPinConfirmUrlPreview = TextPinConfirmUrlPreview(frame: .zero)
    private let docPreView: TextPinConfirmDocPreview = TextPinConfirmDocPreview(frame: .zero)

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(contentView)
        self.addSubview(urlPreView)
        self.addSubview(docPreView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setPinConfirmContentView(_ contentVM: PinAlertViewModel) {
        super.setPinConfirmContentView(contentVM)

        guard let contentVM = contentVM as? TextPinConfirmViewModel, let richTextResult = contentVM.richTextResult else {
            return
        }
        // 先判断doc预览，有doc预览就不会显示url预览
        if contentVM.message.hasDocsPreview(currentChatterId: contentVM.userResolver.userID) {
            self.docPreView.set(
                title: contentVM.message.docTitle,
                owner: contentVM.message.docOwner,
                docIcon: contentVM.message.docIcon
            )
            // 内容只有一个doc则只显示预览
            if contentVM.message.onlyHasDocLink() {
                docPreView.snp.makeConstraints { (make) in
                    make.top.equalTo(BubbleLayout.commonInset.top)
                    make.left.equalTo(BubbleLayout.commonInset.left)
                    make.right.equalTo(-BubbleLayout.commonInset.right)
                    make.bottom.equalTo(self.nameLabel.snp.top).offset(-BubbleLayout.commonInset.bottom)
                }
            } else {
                self.contentView.numberOfLine = 1
                self.contentView.set(attributeText: contentVM.attributeText, richTextResult: richTextResult)
                // 显示内容+doc预览
                contentView.snp.makeConstraints { (make) in
                    make.top.equalTo(BubbleLayout.commonInset.top)
                    make.left.equalTo(BubbleLayout.commonInset.left)
                    make.right.equalTo(-BubbleLayout.commonInset.right)
                }
                docPreView.snp.makeConstraints { (make) in
                    make.top.equalTo(contentView.snp.bottom).offset(8)
                    make.left.equalTo(BubbleLayout.commonInset.left)
                    make.right.equalTo(-BubbleLayout.commonInset.right)
                    make.bottom.equalTo(self.nameLabel.snp.top).offset(-BubbleLayout.commonInset.bottom)
                }
            }
        } else if contentVM.message.hasUrlPreview {
            self.urlPreView.set(
                iconURL: contentVM.message.iconURL,
                iconKey: contentVM.message.iconKey,
                title: contentVM.message.urlTitle,
                content: contentVM.message.urlContent(textColor: UIColor.ud.N900)
            )
             // 内容只有一个url则只显示预览
            if contentVM.message.onlyHasURLLink() {
                urlPreView.snp.makeConstraints { (make) in
                    make.top.equalTo(BubbleLayout.commonInset.top)
                    make.left.equalTo(BubbleLayout.commonInset.left)
                    make.right.equalTo(-BubbleLayout.commonInset.right)
                    make.bottom.equalTo(self.nameLabel.snp.top).offset(-BubbleLayout.commonInset.bottom)
                }
            } else {
                // 显示内容+预览
                self.contentView.numberOfLine = 1
                self.contentView.set(attributeText: contentVM.attributeText, richTextResult: richTextResult)
                contentView.snp.makeConstraints { (make) in
                    make.top.equalTo(BubbleLayout.commonInset.top)
                    make.left.equalTo(BubbleLayout.commonInset.left)
                    make.right.equalTo(-BubbleLayout.commonInset.right)
                }
                urlPreView.snp.makeConstraints { (make) in
                    make.top.equalTo(contentView.snp.bottom).offset(8)
                    make.left.equalTo(BubbleLayout.commonInset.left)
                    make.right.equalTo(-BubbleLayout.commonInset.right)
                    make.bottom.equalTo(self.nameLabel.snp.top).offset(-BubbleLayout.commonInset.bottom)
                }
            }
        } else {
            // 只显示内容
            self.contentView.numberOfLine = 3
            self.contentView.set(attributeText: contentVM.attributeText, richTextResult: richTextResult)
            contentView.snp.makeConstraints { (make) in
                make.top.equalTo(BubbleLayout.commonInset.top)
                make.left.equalTo(BubbleLayout.commonInset.left)
                make.right.equalTo(-BubbleLayout.commonInset.right)
                make.bottom.equalTo(self.nameLabel.snp.top).offset(-BubbleLayout.commonInset.bottom)
            }
        }
    }
}

final class TextPinConfirmViewModel: PinAlertViewModel, TruncateLongText, UserResolverWrapper {
    var attributeText: NSAttributedString = NSAttributedString(string: "")
    var richTextResult: ParseRichTextResult?
    var checkIsMe: (String) -> Bool
    private(set) var textDocsVM: TextDocsViewModel
    public let userResolver: UserResolver
    init?(userResolver: UserResolver,
          message: Message,
          checkIsMe: @escaping (String) -> Bool,
          abbreviationEnable: Bool,
          getSenderName: @escaping (Chatter) -> String) {
        guard let content = message.content as? TextContent else {
            return nil
        }
        self.userResolver = userResolver
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.ud.N900,
            .font: UIFont.systemFont(ofSize: 16)
        ]
        textDocsVM = TextDocsViewModel(userResolver: userResolver, richText: content.richText, docEntity: content.docEntity)
        self.checkIsMe = checkIsMe
        super.init(message: message, getSenderName: getSenderName)

        var atColor = AtColor()
        atColor.UnReadRadiusColor = UIColor.ud.N600
        atColor.MeForegroundColor = UIColor.ud.primaryOnPrimaryFill
        atColor.MeAttributeNameColor = UIColor.ud.functionInfoContentDefault
        atColor.OtherForegroundColor = UIColor.ud.textLinkNormal
        atColor.AllForegroundColor = UIColor.ud.textLinkNormal
        atColor.OuterForegroundColor = UIColor.ud.textCaption
        atColor.AnonymousForegroundColor = UIColor.ud.N900
        let passportUserService = try? userResolver.resolver.resolve(assert: PassportUserService.self)
        self.richTextResult = textDocsVM.parseRichText(
            isShowReadStatus: false,
            checkIsMe: checkIsMe,
            maxLines: PinListUtils.maxLines,
            maxCharLine: PinListUtils.maxCharOfLine,
            atColor: atColor,
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

private final class TextPinConfirmContentView: UIView, LKLabelDelegate {
    var textView: TextView!
    var numberOfLine: Int = 3 {
        didSet {
            self.textView.numberOfLines = numberOfLine
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        let textView = TextView(numberOfLines: 3, delegate: self)
        self.addSubview(textView)
        textView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.textView = textView
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(attributeText: NSAttributedString, richTextResult: ParseRichTextResult) {
        let maxWidth = LarkChatUtils.pinAlertConfirmMaxWidth - 2 * BubbleLayout.commonInset.left
        self.textView.setContentLabel(
            contentMaxWidth: maxWidth,
            attributedText: attributeText,
            rangeLinkMap: richTextResult.urlRangeMap,
            tapableRangeList: richTextResult.atRangeMap.flatMap({ $0.value }),
            textLinkMap: richTextResult.textUrlRangeMap,
            linkAttributes: [.foregroundColor: UIColor.ud.textLinkNormal],
            textLinkBlock: nil
        )
    }
}

private final class TextPinConfirmUrlPreview: UIView {
    let favicon: UIImageView = UIImageView(frame: .zero)
    let titleLabel: UILabel = UILabel(frame: .zero)
    let contentLabel: UILabel = UILabel(frame: .zero)
    let iconSize = CGSize(width: 16, height: 16)
    override init(frame: CGRect) {
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = UIColor.ud.N900
        titleLabel.textAlignment = .left
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.numberOfLines = 1

        contentLabel.font = .systemFont(ofSize: 12)
        contentLabel.numberOfLines = 2
        contentLabel.textAlignment = .left
        contentLabel.textColor = UIColor.ud.N900

        super.init(frame: frame)
        self.addSubview(favicon)
        favicon.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.width.equalTo(iconSize.width)
            make.height.equalTo(iconSize.height)
        }
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalTo(favicon.snp.right).offset(4)
            make.right.lessThanOrEqualToSuperview()
        }
        self.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(iconURL: String, iconKey: String, title: String, content: NSAttributedString) {
        if iconURL.isEmpty {
            favicon.image = Resources.pinUrlPreviewIcon
        } else {
            favicon.bt.setLarkImage(with: .default(key: iconURL),
                                    placeholder: Resources.pinUrlPreviewIcon,
                                    completion: { [weak self] result in
                                        guard let self = self,
                                              let image = try? result.get().image else {
                                            return
                                        }
                                        let scale = UIScreen.main.scale
                                        if image.size.width * scale < self.iconSize.width
                                            || image.size.height * scale < self.iconSize.height {
                                            self.favicon.image = Resources.pinUrlPreviewIcon
                                        }
                                    })
        }
        self.titleLabel.text = title
        self.contentLabel.attributedText = content
    }
}

private final class TextPinConfirmDocPreview: UIView {
    let docIcon: UIImageView = UIImageView(frame: .zero)
    let titleLabel: UILabel = UILabel(frame: .zero)
    let owenerLabel: UILabel = UILabel(frame: .zero)
    override init(frame: CGRect) {
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.N900
        titleLabel.textAlignment = .left
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.numberOfLines = 1

        owenerLabel.font = .systemFont(ofSize: 14)
        owenerLabel.numberOfLines = 1
        owenerLabel.textAlignment = .left
        owenerLabel.textColor = UIColor.ud.N900

        super.init(frame: frame)
        self.addSubview(docIcon)
        docIcon.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.width.height.equalTo(48)
        }
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalTo(docIcon.snp.right).offset(8)
            make.right.lessThanOrEqualToSuperview()
        }
        self.addSubview(owenerLabel)
        owenerLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.equalTo(docIcon.snp.right).offset(8)
            make.right.lessThanOrEqualToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(title: String, owner: String, docIcon: UIImage?) {
        self.titleLabel.text = title
        self.owenerLabel.text = owner
        self.docIcon.image = docIcon
    }
}
