//
//  RoundedView.swift
//  UniverseDesignToast
//
//  Created by 白镜吾 on 2022/12/22.
//

import Foundation
import UIKit
import UniverseDesignFont

private let screenMargin: CGFloat = 40.0

private struct UDRoundViewLayoutConfig {
    let margin: CGFloat = 20.0 //左右边距
    let marginTopBottom: CGFloat = 10.0 //上下边距
    let marginTopBottomWithOperation: CGFloat = 16.0 //显示底部操作按钮时的上下边距
    let spacingAfterIcon: CGFloat = 8.0
    let spacingAfterText: CGFloat = 16.0
    let spacingAfterSeparator: CGFloat = 18.0
    let verticalSpacingAfterStackViewH: CGFloat = 16.0
    let verticalSpacingAfterSeparator: CGFloat = 12
    let iconWidth: CGFloat = 20.0
    let speratorLineWidth: CGFloat = 1.0
    let titleLabelMinHeight: CGFloat = 20.0
    let defaultCornerRadius: CGFloat = 20.0
    let multilineCornerRadius: CGFloat = 8.0
    let numberOfLines: Int = 12
}

public final class RoundedView: UIView {
    let iconWrapper = UIView()
    var host: UDToast?
    var isRemoving: Bool = false
    var tapCallBack: ((String?) -> Void)?
    static var textFont: UIFont { UDFont.body1(.fixed) }

    var operationConfig: UDToastOperationConfig?

    lazy var isRoundedViewInCenter: Bool = false

    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = layoutConfig.numberOfLines
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.textAlignment = .left
        label.font = RoundedView.textFont
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    lazy var separatorLineH: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.3)
        return view
    }()

    lazy var operationLabelH: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.textAlignment = .left
        label.font = RoundedView.textFont
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                          action: #selector(handleTapOperationText(recognizer:))))
        return label
    }()

    lazy var separatorLineV: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.3)
        return view
    }()

    lazy var operationLabelV: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.textAlignment = .center
        label.font = RoundedView.textFont
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                          action: #selector(handleTapOperationText(recognizer:))))
        return label
    }()

    lazy var iconView: UIImageView = {
        return UIImageView()
    }()

    lazy var indicator: ActivityIndicatorView = {
        return ActivityIndicatorView(color: UIColor.ud.primaryOnPrimaryFill)
    }()

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if self.superview == nil {
            self.host = nil
        }
    }

    //竖向 stackView
    let stackViewV = UIStackView()
    //横向 stackView
    let stackViewH = UIStackView()

    private let layoutConfig = UDRoundViewLayoutConfig()


    public init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        backgroundColor = UIColor.ud.bgTips //.withAlphaComponent(0.9)
        layer.ud.setShadow(type: .s4Down)
        layer.cornerRadius = layoutConfig.defaultCornerRadius

        stackViewV.axis = .vertical
        stackViewV.alignment = .center
        addSubview(stackViewV)
        stackViewV.snp.makeConstraints({ (make) in
            make.height.greaterThanOrEqualTo(20)
            make.top.equalToSuperview().offset(layoutConfig.marginTopBottom)
            make.bottom.equalToSuperview().offset(-layoutConfig.marginTopBottom).priority(.high)
            make.left.equalToSuperview().offset(layoutConfig.margin)
            make.right.equalToSuperview().offset(-layoutConfig.margin)
        })

        stackViewV.insertArrangedSubview(operationLabelV, at: 0)

        stackViewV.insertArrangedSubview(separatorLineV, at: 0)
        stackViewV.setCustomSpacing(layoutConfig.verticalSpacingAfterSeparator, after: separatorLineV)

        stackViewH.axis = .horizontal
        stackViewH.alignment = .top

        stackViewV.insertArrangedSubview(stackViewH, at: 0)
        stackViewV.setCustomSpacing(layoutConfig.verticalSpacingAfterStackViewH, after: stackViewH)

        stackViewH.insertArrangedSubview(operationLabelH, at: 0)

        stackViewH.insertArrangedSubview(separatorLineH, at: 0)
        stackViewH.setCustomSpacing(layoutConfig.spacingAfterSeparator, after: separatorLineH)

        stackViewH.insertArrangedSubview(textLabel, at: 0)
        stackViewH.setCustomSpacing(layoutConfig.spacingAfterText, after: textLabel)

        stackViewH.insertArrangedSubview(iconWrapper, at: 0)
        stackViewH.setCustomSpacing(layoutConfig.spacingAfterIcon, after: iconWrapper)

        iconWrapper.addSubview(self.iconView)
        self.iconView.snp.makeConstraints({ (make) in
            make.width.equalTo(layoutConfig.iconWidth)
            make.height.equalTo(layoutConfig.iconWidth)
            make.center.equalToSuperview()
        })

        iconWrapper.addSubview(self.indicator)
        self.indicator.snp.makeConstraints({ (make) in
            make.center.equalToSuperview()
            make.height.width.equalTo(layoutConfig.iconWidth - 3)
        })
    }

    func styleChanged() -> Bool {
        return layer.cornerRadius != layoutConfig.defaultCornerRadius
    }

    func adjustRoundView(with tips: String, superView: UIView, operation: UDToastOperationConfig? = nil) {
        self.operationConfig = operation

        textLabel.numberOfLines = layoutConfig.numberOfLines
        textLabel.textAlignment = operation?.textAlignment ?? .left

        var iconSpacing: CGFloat = 0.0
        if !iconWrapper.isHidden {
            iconSpacing = layoutConfig.iconWidth + layoutConfig.spacingAfterIcon

            iconWrapper.snp.remakeConstraints({ (make) in
                make.width.equalTo(layoutConfig.iconWidth)
                make.height.equalTo(layoutConfig.iconWidth)
            })
        } else {
            iconWrapper.snp.removeConstraints()
        }

        var trailingSpacing: CGFloat = 0.0
        if !operationLabelH.isHidden, let operationText = operation?.text {

            separatorLineH.snp.remakeConstraints({ (make) in
                make.centerY.equalToSuperview()
                make.width.equalTo(layoutConfig.speratorLineWidth)
                make.height.equalToSuperview()
            })

            var operationTextWidth = textWidth(of: operationText)
            if operationTextWidth > 72, operation?.displayType == .horizontal {
                operationTextWidth = 72
            }

            operationLabelH.snp.remakeConstraints({ (make) in
                make.centerY.equalToSuperview()
                make.width.equalTo(operationTextWidth)
            })

            trailingSpacing = layoutConfig.spacingAfterText + layoutConfig.spacingAfterSeparator
            + layoutConfig.speratorLineWidth + operationTextWidth
        } else {
            separatorLineH.snp.removeConstraints()
            operationLabelH.snp.removeConstraints()
        }

        let maxWidth: CGFloat = superView.bounds.width - screenMargin * 2 - layoutConfig.margin * 2 - iconSpacing - trailingSpacing

        let wholeTextWidth = textWidth(of: tips)
        var textLabelWidth: CGFloat = 0.0

        if wholeTextWidth > maxWidth {
            textLabelWidth = maxWidth
            layer.cornerRadius = layoutConfig.multilineCornerRadius

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.05
            paragraphStyle.alignment = .left
            paragraphStyle.lineBreakMode = .byTruncatingTail
            let attrString = NSMutableAttributedString(string: tips)

            attrString.addAttribute(.paragraphStyle,
                                    value: paragraphStyle,
                                    range: NSRange(location: 0, length: attrString.length))
            textLabel.attributedText = attrString

            textLabel.snp.remakeConstraints({ (make) in
                make.width.equalTo(textLabelWidth).priority(.high)
            })
        } else {
            textLabelWidth = wholeTextWidth
            layer.cornerRadius = layoutConfig.defaultCornerRadius
            textLabel.text = tips

            textLabel.snp.remakeConstraints({ (make) in
                make.centerY.equalToSuperview()
                make.width.equalTo(textLabelWidth).priority(.high)
                make.height.greaterThanOrEqualTo(layoutConfig.titleLabelMinHeight)
            })
        }

        stackViewH.snp.remakeConstraints({ (make) in
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.centerX.equalToSuperview()
        })

        if !operationLabelV.isHidden, let operationText = operation?.text {
            layer.cornerRadius = layoutConfig.multilineCornerRadius
            separatorLineV.snp.remakeConstraints({ (make) in
                make.centerX.equalToSuperview()
                make.height.equalTo(layoutConfig.speratorLineWidth)
                make.left.right.equalToSuperview()
            })

            let width = textLabelWidth + iconSpacing + trailingSpacing
            let operationLabelwidth = textWidth(of: operationText) + trailingSpacing

            operationLabelV.snp.remakeConstraints({ (make) in
                make.centerX.equalToSuperview()
                make.width.equalToSuperview()
            })

            stackViewV.snp.remakeConstraints({ (make) in
                make.top.equalToSuperview().offset(layoutConfig.marginTopBottomWithOperation)
                make.bottom.equalToSuperview().offset(-layoutConfig.marginTopBottomWithOperation).priority(.high)
                make.left.equalToSuperview().offset(layoutConfig.margin)
                make.right.equalToSuperview().offset(-layoutConfig.margin).priority(.high)
                make.width.equalTo(min(max(width, operationLabelwidth), UIScreen.main.bounds.width - 2 * screenMargin - 2 * layoutConfig.margin))
            })
        } else {
            separatorLineV.snp.removeConstraints()
            operationLabelV.snp.removeConstraints()

            stackViewV.snp.remakeConstraints({ (make) in
                make.top.equalToSuperview().offset(layoutConfig.marginTopBottom)
                make.bottom.equalToSuperview().offset(-layoutConfig.marginTopBottom).priority(.high)
                make.left.equalToSuperview().offset(layoutConfig.margin)
                make.right.equalToSuperview().offset(-layoutConfig.margin).priority(.high)
                make.width.equalTo(min(textLabelWidth + iconSpacing + trailingSpacing, UIScreen.main.bounds.width - 2 * screenMargin - 2 * layoutConfig.margin))
            })
        }
    }

    private var prevBounds: CGRect = .zero

    public override func layoutSubviews() {
        super.layoutSubviews()
        if bounds != prevBounds {
            observeToastBoundsDidChange()
        }
        prevBounds = bounds
    }

    @objc
    private func observeToastBoundsDidChange() {
        guard let superview = self.superview else { return }
        guard let text = self.textLabel.text else { return }
        self.update(tips: text, superView: superview, with: self.operationConfig)
        self.adjustRoundView(with: text, superView: superview, operation: self.operationConfig)
    }

    private func textWidth(of text: String,
                           height: CGFloat = RoundedView.textFont.pointSize + 10) -> CGFloat {
        let font = RoundedView.textFont
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: CGFloat(MAXFLOAT), height: height),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(rect.width)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func handleTapOperationText(recognizer: UITapGestureRecognizer) {
        self.tapCallBack?(self.operationLabelH.text)
        self.host?.dismissRoundView()
    }

    func update(tips: String, superView: UIView, with operationConfig: UDToastOperationConfig?) {
        self.operationConfig = operationConfig
        if let operationConfig = operationConfig {
            var type: UDOperationDisplayType = operationConfig.displayType ?? .horizontal
            if type == .auto {
                let operationTextWidth = textWidth(of: operationConfig.text)

                let trailingSpacing = layoutConfig.spacingAfterText + layoutConfig.spacingAfterSeparator
                + layoutConfig.speratorLineWidth + operationTextWidth

                var maxWidth: CGFloat = 0
                let iconSpacing: CGFloat = iconWrapper.isHidden ? 0 : layoutConfig.iconWidth + layoutConfig.spacingAfterIcon

                maxWidth = superView.bounds.width - screenMargin * 2 - layoutConfig.margin * 2 - iconSpacing - trailingSpacing

                let wholeTextWidth = textWidth(of: tips, height: 40)

                if wholeTextWidth > maxWidth {
                    type = .vertical
                } else {
                    type = .horizontal
                }
            }
            switch type {
            case .vertical:
                separatorLineH.isHidden = true
                operationLabelH.isHidden = true
                separatorLineV.isHidden = false
                operationLabelV.isHidden = false
                operationLabelV.text = operationConfig.text
            case .horizontal:
                separatorLineH.isHidden = false
                operationLabelH.isHidden = false
                separatorLineV.isHidden = true
                operationLabelV.isHidden = true
                operationLabelH.text = operationConfig.text
            case .auto:
                break
            }
        } else {
            self.separatorLineH.isHidden = true
            self.operationLabelH.isHidden = true
            self.separatorLineV.isHidden = true
            self.operationLabelV.isHidden = true
        }
    }
}
