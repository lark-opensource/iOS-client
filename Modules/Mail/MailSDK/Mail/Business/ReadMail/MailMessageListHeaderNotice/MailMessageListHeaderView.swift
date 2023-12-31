//
//  MailMessageListHeaderView.swift
//  MailSDK
//
//  Created by ByteDance on 2023/11/14.
//

import Foundation
import SnapKit
import LarkAlertController
import UniverseDesignNotice
import UniverseDesignIcon

class MailMessageListHeaderView: UIView, UDNoticeDelegate {
    func handleLeadingButtonEvent(_ button: UIButton) {
        if outboxTipsView?.leadingButton == button {
            delegate?.didClickOutboxTips()
        }
    }
    
    func handleTrailingButtonEvent(_ button: UIButton) {
        if outboxTipsView?.trailingButton == button {
            delegate?.didClickDismissOutboxTips()
        }
    }
    
    func handleTextButtonEvent(URL: URL, characterRange: NSRange) {
        if URL.absoluteString == kHeaderOutboxTextBtnUrl {
            delegate?.didClickOutboxTips()
        }
    }
    
    weak var delegate: MailOutboxTipsViewDelegate?
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        relayout()
    }
    
    var superViewWidth: CGFloat = Display.width {
        didSet {
            if oldValue != superViewWidth {
                self.relayout()
            }
        }
    }
    
    func relayout() {
        var width: CGFloat = 0.0
        if intrinsicContentSize.width == 0 {
            if superview?.bounds.width == 0 {
                width = superViewWidth
            } else {
                width = superview?.bounds.width ?? superViewWidth
            }
        }
        if let outboxTipsView = outboxTipsView {
            if outboxTipsView.isHidden {
                outboxTipsView.removeFromSuperview()
            } else {
                self.addSubview(outboxTipsView)
                outboxTipsView.snp.remakeConstraints { (make) in
                    make.top.bottom.height.equalToSuperview()
                    make.width.equalTo(superViewWidth)
                }
            }
        }
        if let blackTipsView = blackTipsView {
            if blackTipsView.isHidden {
                blackTipsView.removeFromSuperview()
            } else {
                self.addSubview(blackTipsView)
                blackTipsView.snp.remakeConstraints { make in
                    make.top.bottom.height.equalToSuperview()
                    make.width.equalTo(superViewWidth)
                }
            }
        }
        self.frame = CGRect(x: 0, y: 0, width: width, height: intrinsicContentSize.height)
        layoutIfNeeded()
    }
    
    private func setupOutboxTipsViewIfNeeded() {
        guard outboxTipsView == nil else { return }
        outboxTipsView = makeOutboxTipsView()
    }
    
    private func setupBlackTipsViewIfNeeded() {
        guard blackTipsView == nil else { return }
        blackTipsView = makeBlackTipsView()
    }
    
    func showBlackTips() -> MailMessageListHeaderView {
        setupBlackTipsViewIfNeeded()
        if let blackTipsView = blackTipsView, blackTipsView.isHidden {
            self.blackTipsView?.isHidden = false
            relayout()
        }
        return self
    }
    
    func dismissBlackTips() -> MailMessageListHeaderView {
        guard let blackTipsView = blackTipsView else { return self }
        if !blackTipsView.isHidden {
            blackTipsView.isHidden = true
            relayout()
        }
        return self
    }
    
    func showOutboxtips() -> MailMessageListHeaderView {
        setupOutboxTipsViewIfNeeded()
        if let outboxTipsView = outboxTipsView, outboxTipsView.isHidden {
            self.outboxTipsView?.isHidden = false
            
            relayout()
        }
        return self
    }
    func dismissOutboxTips() -> MailMessageListHeaderView {
        guard let outboxTipsView = outboxTipsView else { return self }
        if !outboxTipsView.isHidden {
            outboxTipsView.isHidden = true
            relayout()
        }
        return self
    }
    
    private(set) var outboxTipsView: UDNotice?
    private func makeOutboxTipsView() -> UDNotice {
        let text: String
        let range: NSRange
        text = BundleI18n.MailSDK.Mail_Outbox_UnableToSendCheckMobile
        range = (text as NSString).range(of: BundleI18n.MailSDK.Mail_Outbox_OutboxMobile)
        let attrStr = NSMutableAttributedString(string: text,
                                                attributes: [.foregroundColor: UIColor.ud.textTitle])
        attrStr.addAttribute(.foregroundColor, value: UIColor.ud.primaryContentDefault, range: range)
        attrStr.addAttributes([NSAttributedString.Key.link: kHeaderOutboxTextBtnUrl],
                              range: range)
        var config = UDNoticeUIConfig(type: .warning, attributedText: attrStr)
        config.trailingButtonIcon = UDIcon.closeOutlined
        let view = UDNotice(config: config)
        view.delegate = self
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }
    
    private(set) var blackTipsView: UDNotice?
    private func makeBlackTipsView() -> UDNotice {
        let text: String
        text = BundleI18n.MailSDK.Mail_FollowEmailContact_SenderBlocked_Banner
        let config = UDNoticeUIConfig(type: .info, attributedText: NSAttributedString(string: text))
        let view = UDNotice(config: config)
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }
    override var intrinsicContentSize: CGSize {
        var height: CGFloat = previewCardCurrentTopMargin()
        return CGSize(width: bounds.width, height: height)
    }
}

extension MailMessageListHeaderView {
    func previewCardCurrentTopMargin() -> CGFloat {
        var height: CGFloat = 0
        setNeedsLayout()
        layoutIfNeeded()
        if !(outboxTipsView?.isHidden ?? true) {
            height = (outboxTipsView?.isHidden ?? true) ? 0 : outboxTipsView?.heightThatFitsOrActualHeight(containerWidth: superViewWidth) ?? 0
        } else if !(blackTipsView?.isHidden ?? true) {
            height = (blackTipsView?.isHidden ?? true) ? 0 : blackTipsView?.heightThatFitsOrActualHeight(containerWidth: superViewWidth) ?? 0
        }
        return height
    }
}
