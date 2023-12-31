//
//  PermissionTopTipView.swift
//  SKCommon
//
//  Created by guoqp on 2020/8/6.
//

import Foundation
import SKResource
import SKFoundation

enum PermissionTopTipLevel: Int {
    case info = 0
    case warn
}

public final class PermissionTopTipView: UIView {

    var linkRanges: [NSRange] = []
    public var linkCheckEnable: Bool {
        get { titleLabel.isUserInteractionEnabled }
        set { titleLabel.isUserInteractionEnabled = newValue }
    }
    public weak var delegate: PermissionTopTipViewDelegate?

    public var attributeTitle: NSAttributedString? {
        didSet {
            titleLabel.attributedText = attributeTitle
        }
    }

    public var paragraphStyle: NSMutableParagraphStyle?

    public var titleColor: UIColor? {
        didSet {
            titleLabel.textColor = titleColor
        }
    }
    
    public var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    public var iconView: UIImageView = {
        let v = UIImageView(frame: CGRect.zero)
        v.image = BundleResources.SKResource.Common.Tips.common_net_alert_warn.withRenderingMode(.alwaysTemplate)
        return v
    }()

    public var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.backgroundColor = .clear
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        return label
    }()

    public var titleLabelFont = UIFont.docs.pfsc(14) {
        didSet {
            titleLabel.font = titleLabelFont
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true

        self.backgroundColor = .clear
        self.addSubview(self.iconView)
        self.addSubview(self.titleLabel)

        titleLabel.font = titleLabelFont
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.left.equalTo(iconView.snp.right).offset(13)
            make.right.equalToSuperview().offset(-16)
        }

        iconView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
            make.height.width.equalTo(16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func height(superViewW: CGFloat) -> CGFloat {
        guard let text = titleLabel.text else {
            return 0
        }
        let paraph = NSMutableParagraphStyle()
        paraph.lineSpacing = 4
        let attributes = [NSAttributedString.Key.font: titleLabelFont, NSAttributedString.Key.paragraphStyle: paraph]
        let option = NSStringDrawingOptions.usesLineFragmentOrigin
        let gapW = 16 + 16 + 13 + 16 // 计算titleLabel的左右间隙之和
        let r = text.boundingRect(with: CGSize(width: Int(superViewW) - gapW, height: 200), options: option, attributes: attributes, context: nil)
        return ceil(r.height) + 28
    }

    public func setIconHidden(_ hidden: Bool) {
        iconView.isHidden = hidden
        if hidden {
            titleLabel.snp.remakeConstraints { (make) in
                make.top.equalToSuperview().offset(14)
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
            }
        }
    }
    
    public func setHidden(_ hidden: Bool) {
        iconView.isHidden = hidden
        titleLabel.isHidden = hidden
    }

    func setLevel(_ level: PermissionTopTipLevel) {
        switch level {
        case .info:
            iconView.tintColor = UIColor.ud.colorfulBlue
            backgroundColor = UIColor.ud.B100
        case .warn:
            iconView.tintColor = UIColor.ud.colorfulOrange
            backgroundColor = UIColor.ud.O100
            titleLabel.textColor = UIColor.ud.N900
        }
    }
}

public protocol PermissionTopTipViewDelegate: AnyObject {
    func handleTitleLabelClicked(_ tipView: PermissionTopTipView, index: Int, range: NSRange)
}

extension PermissionTopTipView {
    public func addTapRange(_ range: NSRange) {
        self.linkRanges.append(range)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapTitleLable(_:)))
        self.titleLabel.addGestureRecognizer(tap)
    }

    @objc
    func tapTitleLable(_ ges: UITapGestureRecognizer) {
        let characterIndex = characterIndexAtPoint(ges.location(in: ges.view))
        guard let attributedText = self.titleLabel.attributedText,
              characterIndex >= 0,
              characterIndex < attributedText.length,
              linkRanges.count > 0 else {
            return
        }
        let ranges = linkRanges
        for index in 0..<ranges.count {
            let range = ranges[index]
            if characterIndex >= range.location && (characterIndex <= range.location + range.length) {
                //命中
                delegate?.handleTitleLabelClicked(self, index: index, range: range)
            }
        }
    }

    func characterIndexAtPoint(_ location: CGPoint) -> Int {
        guard let titleLabelAttributedText = self.titleLabel.attributedText else { return 0 }
        let attributedText = NSMutableAttributedString(attributedString: titleLabelAttributedText)
        attributedText.addAttribute(.font,
                                    value: titleLabelFont,
                                    range: NSRange(location: 0, length: attributedText.string.count - 1))
        if let paragraphStyle = self.paragraphStyle {
            attributedText.addAttribute(NSAttributedString.Key.paragraphStyle,
                                        value: paragraphStyle,
                                        range: NSRange(location: 0, length: attributedText.string.count - 1))
        }
        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: CGSize(width: self.titleLabel.bounds.width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.maximumNumberOfLines = 100
        textContainer.lineBreakMode = self.titleLabel.lineBreakMode
        textContainer.lineFragmentPadding = 0.0 
        layoutManager.addTextContainer(textContainer)
        return layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
    }
}
