//
//  MinutesNoticeView.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/12.
//  Copyright © 2021年 wangcong. All rights reserved.
//

import UIKit
import SnapKit
import MinutesFoundation
import MinutesNetwork
import UniverseDesignToast
import UniverseDesignIcon
import LarkContainer
import YYText

protocol MinutesNoticeViewDelegate: AnyObject {
    func handleReviewAppealFinished()
}

class MinutesNoticeView: UIView {
    private struct LayoutConfig {
        static let topBottomMargin: CGFloat = 12
        static let iconTopBottomMargin: CGFloat = 12
        static let leftMargin: CGFloat = 16
        static let rightMargin: CGFloat = 16
        static let iconWidth: CGFloat = 16
        static let iconMargin: CGFloat = 8
    }
    public var viewHeight: CGFloat {
        var frameHeight = LayoutConfig.topBottomMargin * 2
        var widthLimit = self.bounds.size.width
        widthLimit -= LayoutConfig.leftMargin
        widthLimit -= LayoutConfig.rightMargin
        widthLimit -= LayoutConfig.iconWidth
        widthLimit -= LayoutConfig.iconMargin

        let textViewSize = textView.sizeThatFits(CGSize(width: widthLimit, height: CGFloat.greatestFiniteMagnitude))
        var maximumHeight = textViewSize.height
        frameHeight += maximumHeight

        return max(40, frameHeight)
    }

    private var minutes: Minutes

    lazy var tracker: MinutesTracker = {
        return MinutesTracker(minutes: minutes)
    }()

    let userResolver: UserResolver
    private var viewModel: MinutesNoticeViewModel

    public weak var delegate: MinutesNoticeViewDelegate?

    private(set) lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.warningColorful
        imageView.frame = CGRect(x: 0, y: 0, width: LayoutConfig.iconWidth, height: LayoutConfig.iconWidth)
        return imageView
    }()

    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.textContainer.lineFragmentPadding = 0
        textView.textAlignment = .natural
        textView.textContainerInset = .zero
        textView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.primaryContentDefault]
        textView.delegate = self
        return textView
    }()

    init(frame: CGRect, minutes: Minutes, resolver: UserResolver) {
        self.minutes = minutes
        self.userResolver = resolver
        viewModel = MinutesNoticeViewModel(minutes: minutes)
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.functionWarningFillSolid02

        self.addSubview(iconView)
        iconView.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().offset(LayoutConfig.leftMargin)
            maker.width.equalTo(LayoutConfig.iconWidth)
            maker.height.equalTo(LayoutConfig.iconWidth)
            maker.top.equalTo(LayoutConfig.iconTopBottomMargin)
        }

        self.addSubview(textView)
        textView.snp.makeConstraints { (maker) in
            maker.leading.equalTo(iconView.snp.trailing).offset(LayoutConfig.iconMargin)
            maker.trailing.equalTo(-LayoutConfig.rightMargin)
            maker.top.equalTo(LayoutConfig.topBottomMargin)
            maker.bottom.equalTo(-LayoutConfig.topBottomMargin)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    public func update(isAlert: Bool, attributedText: NSAttributedString) {
        if isAlert {
            self.iconView.image = UDIcon.errorColorful
            self.backgroundColor = UIColor.ud.functionDanger100
        } else {
            self.iconView.image = UDIcon.infoColorful
            self.backgroundColor = UIColor.ud.primaryFillSolid02
        }
        textView.attributedText = attributedText
    }

}

extension MinutesNoticeView: UITextViewDelegate {

    public func updateReviewStatus() {
        let isAlert = viewModel.minutes.info.reviewStatus == .autoReviewFailed || viewModel.minutes.info.reviewStatus == .complainFailed
        if let text = viewModel.getReviewText() {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4
            paragraphStyle.alignment = .left
            let textArray = text.components(separatedBy: "@@")
            let schemes = viewModel.getSchemes()
            let attributedString = NSMutableAttributedString(string: "")
            for (i, str) in textArray.enumerated() {
                if let scheme = schemes[i] {
                    let aStr = NSAttributedString(string: str, attributes: ([NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.ud.textLinkNormal, NSAttributedString.Key.link: scheme]))
                    attributedString.append(aStr)
                } else {
                    let aStr = NSAttributedString(string: str, attributes: ([NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle]))
                    attributedString.append(aStr)
                }
            }
            update(isAlert: isAlert, attributedText: attributedString)
        }
    }

    public func textView(_ textView: UITextView,
                         shouldInteractWith URL: URL,
                         in characterRange: NSRange,
                         interaction: UITextItemInteraction) -> Bool {
        if URL.scheme == "protocol" {
            gotoUserAgreement()
        } else {
            gotoAppeal(with: URL.scheme)
        }
        return false
    }

    private func gotoUserAgreement() {
        let dependency: MinutesDependency? = try? userResolver.resolve(assert: MinutesDependency.self)
        if let url = dependency?.config?.getUserAgreementURL(), let from = userResolver.navigator.mainSceneWindow?.fromViewController {
            userResolver.navigator.push(url, from: from)
        }
    }

    private func gotoAppeal(with scheme: String?) {
        guard let domain = MinutesSettingsManager.shared.tnsReportDomain(with: self.viewModel.minutes.baseURL)else { return }
        let token = viewModel.minutes.objectToken
        tracker.tracker(name: .clickButton, params: ["action_name": "complaint_submit"])
        if scheme == "appeal" {
            let urlString = "https://\(domain)/cust/lark_report/appeal?entity_id=\(token)&entity_type=minutes_web_id&scene=minutes_ban"
            if let url = URL(string: urlString), let from = userResolver.navigator.mainSceneWindow?.fromViewController {
                userResolver.navigator.push(url, from: from)
            }
            tracker.tracker(name: .detailClick, params: ["click": "appeal", "target": "none"])
        }
        if scheme == "appealDetail", let from = userResolver.navigator.mainSceneWindow?.fromViewController {
            let urlString = "https://\(domain)/cust/lark_report/appeal/detail?entity_id=\(token)&entity_type=minutes_web_id&scene=minutes_ban"
            if let url = URL(string: urlString) {
                userResolver.navigator.push(url, from: from)
            }
        }
    }
}
