//
//  MyAIToolselectedFooterView.swift
//  LarkIMMention
//
//  Created by ByteDance on 2023/5/30.
//

import UIKit
import Foundation

final class MyAIToolselectedFooterView: UIView, UITextViewDelegate {

    var startNewTopicHandler: (() -> Void)?

    private lazy var startNewTopicView: UIView = {
        let textview = UITextView()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = 22
        paragraphStyle.minimumLineHeight = 22
        paragraphStyle.lineSpacing = 2
        paragraphStyle.alignment = .center
        let attributes = [NSAttributedString.Key.font: UIFont.ud.body2,
                          NSAttributedString.Key.paragraphStyle: paragraphStyle,
                          NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder]
        let attrStr = NSMutableAttributedString(string: BundleI18n.LarkAI.MyAI_IM_CantChangePluginsInTopicsTemplate_Text(BundleI18n.LarkAI.MyAI_IM_CantChangePluginsInTopicsStartNew_Button),
                                                attributes: attributes)
        let range = attrStr.mutableString.range(of: BundleI18n.LarkAI.MyAI_IM_CantChangePluginsInTopicsStartNew_Button,
                                                options: .caseInsensitive)
        attrStr.addAttribute(NSAttributedString.Key.link, value: "", range: range)
        textview.linkTextAttributes = [.font: UIFont.ud.body2,
                                       .paragraphStyle: paragraphStyle,
                                       .foregroundColor: UIColor.ud.textLinkNormal]
        textview.attributedText = attrStr
        textview.backgroundColor = .clear
        textview.isEditable = false
        textview.isSelectable = true
        textview.textDragInteraction?.isEnabled = false
        textview.isScrollEnabled = false
        textview.showsVerticalScrollIndicator = false
        textview.showsHorizontalScrollIndicator = false
        textview.delegate = self
        textview.textContainerInset = .zero
        textview.textContainer.lineFragmentPadding = 0
        let containerView = UIView()
        let textViewWidth = UIScreen.main.bounds.size.width - Cons.leftMargin * 2
        let contentHeight = attrStr.string.boundingRect(with: CGSize(width: textViewWidth, height: CGFloat.greatestFiniteMagnitude),
                                    options: .usesLineFragmentOrigin,
                                    attributes: attributes, context: nil).height
        containerView.addSubview(textview)
        textview.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(contentHeight)
        }
        return containerView
    }()

    init() {
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.ud.bgBase
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {
        addSubview(startNewTopicView)
        startNewTopicView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Cons.topMargin)
            make.bottom.equalToSuperview().offset(-Cons.topMargin)
            make.left.equalToSuperview().offset(Cons.leftMargin)
            make.right.equalToSuperview().offset(-Cons.leftMargin)
        }
    }

    // MARK: - UITextViewDelegate
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if interaction == .invokeDefaultAction {
            // start new topic
            startNewTopicHandler?()
        }
        return false
    }
}

extension MyAIToolselectedFooterView {
    enum Cons {
        static var leftMargin: CGFloat { 16 }
        static var topMargin: CGFloat { 24 }
    }
}
