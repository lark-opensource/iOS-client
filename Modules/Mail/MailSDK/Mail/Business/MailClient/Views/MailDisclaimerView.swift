//
//  MailDisclaimerView.swift
//  MailSDK
//
//  Created by Fawaz on 4/24/20.
//

import Foundation

protocol MailDisclaimerViewDelegate: NSObjectProtocol {
    func mailDisclaimerView(_ view: MailDisclaimerView, didTap policy: MailPolicyType)
}

class MailDisclaimerView: UIView {

    private weak var delegate: MailDisclaimerViewDelegate?
    private let textView = UITextView(frame: .zero)
    private let stackView = UIStackView(frame: .zero)

    init(delegate: MailDisclaimerViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
        setup()
        setupTextViewContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        stackView.axis = .vertical
        stackView.layoutMargins = UIEdgeInsets(top: 10, left: 30, bottom: 10, right: 30)
        stackView.isLayoutMarginsRelativeArrangement = true
        addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        stackView.addArrangedSubview(textView)
        textView.isEditable = false
        textView.delaysContentTouches = false
        textView.delegate = self
        textView.isScrollEnabled = false
        textView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.primaryContentDefault]
    }

    private func setupTextViewContent() {
        let disclaimerString = BundleI18n.MailSDK.Mail_Onboard_Term(MailPolicyType.privacy.string, MailPolicyType.termsOfUse.string)
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.textCaption,
                          NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11)]
        let attributedString = NSMutableAttributedString(string: disclaimerString,
                                                         attributes: attributes)
        for type in MailPolicyType.allCases {
            let range = (attributedString.string as NSString).range(of: type.string)
            if attributedString.string.hasRange(range), let url = type.url {
                attributedString.addAttribute(.link, value: url, range: range)
            }
        }
        textView.attributedText = attributedString
        textView.textAlignment = .center
    }
}

extension MailDisclaimerView: UITextViewDelegate {
    func textView(_ textView: UITextView,
                  shouldInteractWith URL: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        for type in MailPolicyType.allCases {
            if let url = type.url, url == URL {
                delegate?.mailDisclaimerView(self, didTap: type)
                return false
            }
        }
        return false
    }
}

extension String {
    func hasRange(_ range: NSRange) -> Bool {
        return Range(range, in: self) != nil
    }
}
