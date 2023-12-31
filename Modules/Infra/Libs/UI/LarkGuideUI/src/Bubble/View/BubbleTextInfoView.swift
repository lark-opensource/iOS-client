//
//  BubbleTextInfoView.swift
//  LarkGuide
//
//  Created by zhenning on 2020/5/18.
//
import UIKit
import Foundation
import LarkUIKit
import RichLabel

public final class BubbleTextInfoView: UIView {

    private var titleText: String? {
        didSet {
            self.titleLabel.text = titleText
        }
    }
    private var detailText: String {
       didSet {
           self.detailLabel.text = detailText
       }
   }
    private lazy var titleLabel: LKLabel = {
        let _titleLabel = LKLabel()
        _titleLabel.font = Style.titleFont
        _titleLabel.backgroundColor = .clear
        _titleLabel.textColor = Style.textColor
        _titleLabel.numberOfLines = 0
        _titleLabel.lineSpacing = Style.titleLineSpacing
        _titleLabel.preferredMaxLayoutWidth = Layout.defaultMaxWidth - Layout.marginWidth
        return _titleLabel
    }()
    private lazy var detailLabel: LKLabel = {
        let _detailLabel = LKLabel()
        _detailLabel.backgroundColor = .clear
        _detailLabel.font = Style.detailTextFont
        _detailLabel.textColor = Style.textColor
        _detailLabel.numberOfLines = 0
        _detailLabel.lineSpacing = Style.detailLineSpacing
        _detailLabel.preferredMaxLayoutWidth = Layout.defaultMaxWidth - Layout.marginWidth
        return _detailLabel
    }()
    private var isTitleHidden: Bool {
        return titleLabel.text?.isEmpty ?? true
    }

    public override var intrinsicContentSize: CGSize {
        var height: CGFloat = 0.0
        var width: CGFloat = 0.0
        let titleSize = getTextLabelFitSize(label: titleLabel, lineHeight: Style.titleLineHeight)
        let detailSize = getTextLabelFitSize(label: detailLabel, lineHeight: Style.detailLineHeight)
        let contentWidth = max(titleSize.width, detailSize.width)
        width = (contentWidth < Layout.defaultMaxWidth) ? contentWidth : Layout.defaultMaxWidth
        height += Layout.contentInset.top
        if !isTitleHidden {
            height += titleSize.height
            height += Layout.detailTopPadding
        }
        height += detailSize.height
        height += Layout.contentInset.bottom
        return CGSize(width: width, height: height)
    }

    init(textPartConfig: TextInfoConfig) {
        self.titleText = textPartConfig.title
        self.detailText = textPartConfig.detail
        super.init(frame: .zero)
        setupUI()
    }

    private func setupUI() {
        if let titleText = self.titleText {
            self.titleLabel.text = titleText
        }
        self.addSubview(self.titleLabel)

        self.detailLabel.text = detailText
        self.addSubview(self.detailLabel)

        let titleHeight = getTextLabelFitSize(label: titleLabel, lineHeight: Style.titleLineHeight).height
        self.titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        self.titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(Layout.contentInset.top)
            make.leading.equalToSuperview().offset(Layout.contentInset.left)
            make.trailing.equalToSuperview().offset(-Layout.contentInset.right)
            make.height.equalTo(titleHeight)
        }

        self.detailLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        self.detailLabel.snp.makeConstraints { (make) in
            if isTitleHidden {
                make.top.equalTo(Layout.contentInset.top)
            } else {
                make.top.equalTo(titleLabel.snp.bottom).offset(Layout.detailTopPadding)
            }
            make.leading.equalToSuperview().offset(Layout.contentInset.left)
            make.trailing.equalToSuperview().offset(-Layout.contentInset.right)
            make.bottom.equalToSuperview().offset(-Layout.contentInset.bottom)
        }
    }

    func updateContent(title: String?, detail: String) {
        self.titleText = title
        self.detailText = detail

        let titleHeight = getTextLabelFitSize(label: titleLabel, lineHeight: Style.titleLineHeight).height
        self.titleLabel.snp.updateConstraints { (make) in
            make.height.equalTo(titleHeight)
        }
    }

    private func getTextLabelFitSize(label: LKLabel, lineHeight: CGFloat) -> CGSize {
        let textPrepareSize = CGSize(width: Layout.defaultMaxWidth - Layout.marginWidth,
                                     height: CGFloat.greatestFiniteMagnitude)
        let fitWidth = label.intrinsicContentSize.width + Layout.marginWidth
        let width = (fitWidth < Layout.defaultMaxWidth) ? fitWidth : Layout.defaultMaxWidth
        let fitHeight = label.sizeThatFits(textPrepareSize).height
        let height = CGFloat(Int(ceil(fitHeight / lineHeight))) * lineHeight
        return CGSize(width: width, height: height)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BubbleTextInfoView {
    enum Layout {
        static let detailTopPadding: CGFloat = 8
        static let contentInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        static let defaultMaxWidth: CGFloat = BaseBubbleView.Layout.defaultMaxWidth
        static let marginWidth: CGFloat = Layout.contentInset.left + Layout.contentInset.right
    }
    enum Style {
        static let titleFont: UIFont = .systemFont(ofSize: 20.0, weight: .semibold)
        static let detailTextFont: UIFont = .systemFont(ofSize: 16.0, weight: .medium)
        static let titleLineSpacing: CGFloat = 7.5
        static let detailLineSpacing: CGFloat = 6
        static let titleLineHeight: CGFloat = 30
        static let detailLineHeight: CGFloat = 24
        static let textColor: UIColor = UIColor.ud.primaryOnPrimaryFill
    }
}
