//
//  MinutesAddCommentsView.swift
//  Minutes
//
//  Created by yangyao on 2021/1/29.
//

import UIKit
import YYText
import UniverseDesignColor

extension Int {
    func formatUsingAbbreviation() -> String {
        let numFormatter = NumberFormatter()

        typealias Abbrevation = (threshold: Double, divisor: Double, suffix: String)
        let abbreviations: [Abbrevation] = [
            (0, 1, ""),
            (1000.0, 1000.0, "k")
        ]

        let startValue = Double(abs(self))
        let abbreviation: Abbrevation = {
            var prevAbbreviation = abbreviations[0]
            for tmpAbbreviation in abbreviations {
                if startValue < tmpAbbreviation.threshold {
                    break
                }
                prevAbbreviation = tmpAbbreviation
            }
            return prevAbbreviation
        }()

        let value = Double(self) / abbreviation.divisor
        numFormatter.positiveSuffix = abbreviation.suffix
        numFormatter.negativeSuffix = abbreviation.suffix
        numFormatter.allowsFloats = true
        numFormatter.minimumIntegerDigits = 1
        numFormatter.minimumFractionDigits = 0
        numFormatter.maximumFractionDigits = 1

        return numFormatter.string(from: NSNumber(value: value))!
    }
}

class MinutesAddCommentsView: UIView {
    static let minutesCommentMaxCount = 1000

    lazy var contentView: MinutesAddCommentsQuoteView = {
        let view = MinutesAddCommentsQuoteView()
        return view
    }()

    lazy var placeholderLabel: UILabel = {
        let placeholderLabel = UILabel()
        placeholderLabel.text = BundleI18n.Minutes.MMWeb_G_AddComment
        placeholderLabel.textColor = UIColor.ud.textDisable
        placeholderLabel.font = .systemFont(ofSize: 16)
        return placeholderLabel
    }()
    
    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.isUserInteractionEnabled = true
        textView.textColor = UIColor.ud.textTitle
        
        placeholderLabel.sizeToFit()
        textView.addSubview(placeholderLabel)
        placeholderLabel.frame.origin = CGPoint(x: 5, y: (textView.font?.pointSize)! / 2)
        placeholderLabel.isHidden = !textView.text.isEmpty
        textView.delegate = self
        return textView
    }()

    lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(BundleI18n.Minutes.MMWeb_G_CommentSend, for: .normal)
        button.addTarget(self, action: #selector(onBtnSend), for: .touchUpInside)
        button.titleLabel?.textColor = UIColor.ud.colorfulPurple
        button.isUserInteractionEnabled = false
        button.alpha = 0.3
        return button
    }()

    lazy var countOverflowLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.colorfulRed
        label.font = .systemFont(ofSize: 16)
        label.isHidden = true
        return label
    }()

    lazy var indicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView()
        indicatorView.transform = CGAffineTransform(scaleX: 0.86, y: 0.86)
        return indicatorView
    }()

    var textContent: String {
        return textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var quoteString: String = "" {
        didSet {
            contentView.contentLabel.text = quoteString
        }
    }

    var sendCommentsBlock: ((String) -> Void)?

    func showLoading(_ show: Bool) {
        sendButton.isHidden = show
        indicatorView.isHidden = !show
        if #available(iOS 12.0, *) {
            if self.traitCollection.userInterfaceStyle == .dark {
                indicatorView.style = .white
            } else {
                indicatorView.style = .gray
            }
        } else {
            indicatorView.style = .gray
        }
        if show {
            indicatorView.startAnimating()
        } else {
            indicatorView.stopAnimating()
        }
    }

    @objc func onBtnSend() {
        sendCommentsBlock?(textContent)
    }

    private lazy var shape: CAShapeLayer = {
        let shape = CAShapeLayer()
        return shape
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.mask = shape

        backgroundColor = UIColor.ud.bgFloat
        addSubview(contentView)
        addSubview(textView)
        addSubview(sendButton)
        addSubview(countOverflowLabel)
        addSubview(indicatorView)

        contentView.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(15)
            maker.right.equalToSuperview().offset(-15)
            maker.top.equalToSuperview().offset(15)
            maker.height.equalTo(40)
        }

        textView.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(15)
            maker.top.equalTo(contentView.snp.bottom).offset(15)
            maker.height.equalTo(50)
        }

        sendButton.snp.makeConstraints { (maker) in
            maker.left.equalTo(textView.snp.right).offset(15)
            maker.right.equalToSuperview().offset(-15)
            maker.top.equalTo(textView)
        }

        indicatorView.snp.makeConstraints { (maker) in
            maker.centerX.centerY.equalTo(sendButton)
        }

        countOverflowLabel.snp.makeConstraints { (maker) in
            maker.centerX.centerY.equalTo(sendButton)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        shape.bounds = bounds
        shape.position = bounds.center
        shape.path = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 12, height: 12)).cgPath
    }
}

extension MinutesAddCommentsView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        let text = textContent
        sendButton.isUserInteractionEnabled = !text.isEmpty
        sendButton.alpha = !text.isEmpty ? 1.0 : 0.3

        if text.count > MinutesAddCommentsView.minutesCommentMaxCount {
            sendButton.isHidden = true
            countOverflowLabel.isHidden = false

            let newCount = text.count - MinutesAddCommentsView.minutesCommentMaxCount
            countOverflowLabel.text = "-\(newCount.formatUsingAbbreviation())"
        } else {
            sendButton.isHidden = false
            countOverflowLabel.isHidden = true

            countOverflowLabel.text = nil
        }
    }
}
