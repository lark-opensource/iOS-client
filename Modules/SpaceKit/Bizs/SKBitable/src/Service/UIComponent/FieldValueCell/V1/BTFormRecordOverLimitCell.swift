//
//  BTFormRecordOverLimitCell.swift
//  SKBitable
//
//  Created by X-MAN on 2023/3/21.
//

import Foundation
import UniverseDesignNotice
import SKResource

final class BTFormRecordOverLimitCell: UICollectionViewCell {
    
    weak var delegate: BTFieldDelegate?
        
    private static var topTipView: UDNotice?
    
    private static var _topTipView: UDNotice {
        if let tipView = Self.topTipView {
            return tipView
        }
        let text = BundleI18n.SKResource.Bitable_Billing_RecordReachLimitInCurrentTable_Description
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        var att = NSMutableAttributedString(string: text)
        att.setAttributes([NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle,
                           NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
                           NSAttributedString.Key.paragraphStyle: paragraphStyle],
                          range: NSRangeFromString(text))
        var config = UDNoticeUIConfig(type: .warning, attributedText: att)
        config.leadingButtonText = BundleI18n.SKResource.Bitable_Billing_HelpDoc_Common
        let notice = UDNotice(config: config)
        Self.topTipView = notice
        return notice
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(Self._topTipView)
        Self._topTipView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        Self._topTipView.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func contentHeight(with width: CGFloat) -> CGFloat {
        return Self._topTipView.sizeThatFits(CGSize(width: width, height: .infinity)).height
    }
}

extension BTFormRecordOverLimitCell: UniverseDesignNotice.UDNoticeDelegate {
    
    func handleLeadingButtonEvent(_ button: UIButton) {
        delegate?.didClickRecordLimitMoreInForm()
    }
    
    func handleTrailingButtonEvent(_ button: UIButton) {
        
    }
    
    func handleTextButtonEvent(URL: URL, characterRange: NSRange) {
        
    }
}
