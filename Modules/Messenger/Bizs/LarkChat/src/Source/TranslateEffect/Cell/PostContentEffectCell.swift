//
//  PostContentEffectCell.swift
//  LarkChat
//
//  Created by 李勇 on 2019/5/31.
//

import UIKit
import Foundation
import LarkUIKit
import LarkCore
import LarkRichTextCore
import LarkModel
import RichLabel
import EENavigator
import LarkFoundation
import LarkMessengerInterface
import LarkSDKInterface
import LarkContainer

/// 普通文本消息内容
final class PostContentEffectCell: UITableViewCell {
    /// 标题
    private lazy var titleLabel = UILabel()
    /// 富文本消息视图
    private lazy var postView = PostView(numberOfLines: 0, delegate: self, isReply: false)
    /// 显示内容
    private var parseRichTextResult: ParseRichTextResult?
    var userResolver: UserResolver? // foregroundUser

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        /// 标题
        self.titleLabel.textColor = UIColor.ud.N500
        self.titleLabel.font = UIFont.systemFont(ofSize: 14)
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.top.left.equalTo(16)
        }

        /// 边框
        let bottomContentView = UIView()
        bottomContentView.layer.cornerRadius = 10
        bottomContentView.clipsToBounds = true
        bottomContentView.layer.borderColor = UIColor.ud.N300.cgColor
        bottomContentView.layer.borderWidth = 1
        self.contentView.addSubview(bottomContentView)
        bottomContentView.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(8)
            make.bottom.equalToSuperview()
        }
        /// 普通文本消息视图
        bottomContentView.addSubview(self.postView)
        self.postView.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12))
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTranslateInfo(userResolver: UserResolver, translateInfo: MessageTranslateInfo, parseRichTextResult: ParseRichTextResult?) {
        self.userResolver = userResolver
        self.parseRichTextResult = parseRichTextResult
        /// 设置标题
        self.titleLabel.text = translateInfo.languageValue + "："
        /// 设置内容
        guard let postContent = translateInfo.content as? PostContent else {
            return
        }
        guard let parseResult = self.parseRichTextResult else {
            return
        }
        /// 来自chat中post的显示逻辑
        self.postView.setContentLabel(
            contentMaxWidth: UIScreen.main.bounds.size.width - 56,
            titleText: postContent.title,
            isUntitledPost: postContent.isUntitledPost,
            attributedText: parseResult.attriubuteText,
            rangeLinkMap: parseResult.urlRangeMap,
            tapableRangeList: parseResult.atRangeMap.flatMap({ $0.value }),
            textLinkMap: parseResult.textUrlRangeMap
        ) { [weak self] (link) in
            guard let self, let window = self.window, let userResolver = self.userResolver else {
                assertionFailure()
                return
            }
            if let url = URL(string: link)?.lf.toHttpUrl() {
                userResolver.navigator.push(url, context: ["from": "translateEffect"], from: window)
            }
        }
    }
}

extension PostContentEffectCell: LKLabelDelegate {
    public func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        guard let window, let userResolver else {
            assertionFailure()
            return
        }
        if let httpUrl = url.lf.toHttpUrl() {
            userResolver.navigator.push(httpUrl, context: ["from": "translateEffect"], from: window)
        }
    }

    public func attributedLabel(_ label: LKLabel, didSelectPhoneNumber phoneNumber: String) {
        guard !phoneNumber.isEmpty, !Utils.isSimulator else { return }
        Utils.telecall(phoneNumber: phoneNumber)
    }

    public func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        guard let parseResult = self.parseRichTextResult else { return true }
        guard let window, let userResolver else {
            assertionFailure()
            return true
        }
        for (userId, ranges) in parseResult.atRangeMap where ranges.contains(range) && userId != "all" {
            let body = PersonCardBody(chatterId: userId)
            if Display.phone {
                userResolver.navigator.push(body: body, from: window)
            } else {
                userResolver.navigator.present(
                    body: body,
                    wrap: LkNavigationController.self,
                    from: window,
                    prepare: { vc in
                        vc.modalPresentationStyle = .formSheet
                    })
            }
            return false
        }
        return true
    }
}
