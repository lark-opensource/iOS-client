//
//  BTExtendNoticeView.swift
//  SKBitable
//
//  Created by zhysan on 2023/5/11.
//

import UIKit
import SKFoundation
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignColor

protocol BTExtendNoticeViewDelegate: AnyObject {
    func onNoticeViewActionButtonClick(_ sender: BTExtendNoticeView)
}

private struct Const {
    static let actionBtnH: CGFloat = 22.0
    static let textMarginV: CGFloat = 12.0;
}

class BTExtendNoticeView: UIView {
    // MARK: - public
    
    weak var delegate: BTExtendNoticeViewDelegate?
    
    var actionText: String? {
        didSet {
            actionButton.setTitle(actionText, for: .normal)
            setNeedsUpdateConstraints()
            setNeedsLayout()
        }
    }
    
    var noticeText: String? {
        didSet {
            attrNoticeText = NSAttributedString(string: noticeText ?? "", attributes: noticeAttrs)
            textLabel.attributedText = attrNoticeText
            setNeedsUpdateConstraints()
            setNeedsLayout()
        }
    }
    
    // MARK: - life cycle
    init(frame: CGRect = .zero, delegate: BTExtendNoticeViewDelegate? = nil) {
        super.init(frame: frame)
        
        self.delegate = delegate
        
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        let hasNotice = attrNoticeText?.string.isEmpty == false
        let hasAction = actionText?.isEmpty == false
        
        textLabel.snp.updateConstraints { make in
            make.top.equalToSuperview().inset(hasNotice ? Const.textMarginV : 0)
        }
        
        actionButton.snp.updateConstraints { make in
            make.height.equalTo(hasAction ? Const.actionBtnH : 0)
            make.bottom.equalToSuperview().inset((hasAction || hasNotice) ? Const.textMarginV : 0)
        }
        
        super.updateConstraints()
    }
    
    // MARK: - private
    
    private let noticeAttrs: [NSAttributedString.Key : Any] = [
        .font: UDFont.body2,
        .foregroundColor: UDColor.textTitle,
        .paragraphStyle: {
            let style = NSMutableParagraphStyle()
            style.lineBreakMode = .byWordWrapping
            style.lineHeightMultiple = 1.12
            return style
        }()
    ]
    
    private var attrNoticeText: NSAttributedString?
    
    private let iconView: UIImageView = {
        let vi = UIImageView()
        vi.image = UDIcon.warningColorful
        return vi
    }()
    
    private let textLabel: UILabel = {
        let vi = UILabel()
        vi.numberOfLines = 0
        vi.lineBreakMode = .byWordWrapping
        return vi
    }()
    
    private let actionButton: UIButton = {
        let vi = UIButton(type: .custom)
        vi.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        vi.titleLabel?.font = UDFont.body2
        return vi
    }()
    
    @objc
    private func onActionButtonTap(_ sender: UIButton) {
        delegate?.onNoticeViewActionButtonClick(self)
    }
    
    private func subviewsInit() {
        backgroundColor = UDColor.functionWarningFillSolid02
        addSubview(iconView)
        addSubview(textLabel)
        addSubview(actionButton)
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(14)
        }
        textLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Const.textMarginV)
            make.right.equalToSuperview().inset(16)
            make.left.equalTo(iconView.snp.right).offset(8)
        }
        actionButton.snp.makeConstraints { make in
            make.top.equalTo(textLabel.snp.bottom)
            make.left.equalTo(textLabel)
            make.right.lessThanOrEqualToSuperview().inset(16)
            make.height.equalTo(Const.actionBtnH)
            make.bottom.equalToSuperview().inset(Const.textMarginV)
        }
        
        actionButton.setContentHuggingPriority(.required, for: .horizontal)
        actionButton.addTarget(self, action: #selector(onActionButtonTap(_:)), for: .touchUpInside)
    }
}
