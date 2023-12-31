//
//  MinutesChapterCell.swift
//  Minutes
//
//  Created by ByteDance on 2023/9/4.
//

import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import MinutesFoundation
import SnapKit
import FigmaKit
import YYText

class MinutesAIFooterView: UIView {
    lazy var line: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.numberOfLines = 0
        textLabel.textAlignment = .center
        textLabel.textColor = UIColor.ud.textPlaceholder
        textLabel.font = .systemFont(ofSize: 10, weight: .regular)
        textLabel.text = BundleI18n.Minutes.MMWeb_G_AINotesDisclaimer_Desc
        return textLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(line)
        addSubview(textLabel)

        line.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(20)
            make.height.equalTo(0.5)
        }
        textLabel.snp.makeConstraints { make in
            make.top.equalTo(line.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MinutesAIHeaderView: UIView {
    
    private let enlargeSize = 6.0
    
    lazy var iconView: UIImageView = {
        let iconView = UIImageView()
        iconView.image = UDIcon.getIconByKey(.myaiColorful, size: CGSize(width: 16, height: 16))
        return iconView
    }()

    var text: String? {
        didSet {
            textLabel.text = text
            if let text = text {
                textLabel.textColor = UDColor.AISendicon.toColor(withSize: CGSize(
                    width: width(text: text, font: textLabel.font, height: textLabel.font.lineHeight),
                    height: textLabel.font.lineHeight))
            }
        }
    }

    func width(text: String, font: UIFont, height: CGFloat) -> CGFloat {
        let rect = NSString(string: text).boundingRect(
            with: CGSize(width: CGFloat(MAXFLOAT), height: height),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(rect.width)
    }

    lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.numberOfLines = 1
        textLabel.font = .systemFont(ofSize: 16, weight: .medium)
        textLabel.text = ""
        return textLabel
    }()

    lazy var foldButton: EnlargeTouchButton = {
        let button = EnlargeTouchButton(type: .custom)
        button.enlargeRegionInsets = UIEdgeInsets(top: enlargeSize, left: enlargeSize, bottom: enlargeSize, right: enlargeSize)
        button.setImage(UDIcon.getIconByKey(.upOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: 16, height: 16)), for: .normal)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(iconView)
        addSubview(textLabel)
        addSubview(foldButton)

        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(45)
            make.width.height.equalTo(16)
            make.left.equalToSuperview().offset(16)
        }
        textLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(6)
            make.centerY.equalTo(iconView)
            make.right.equalToSuperview().offset(-16)
        }
        foldButton.snp.makeConstraints { make in
            make.centerY.equalTo(iconView)
            make.height.equalTo(16)
            make.width.equalTo(16)
            make.right.equalToSuperview().offset(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class MinutesAIChapterHeaderView: MinutesAIHeaderView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(feedbackView)
        
        feedbackView.snp.makeConstraints { (make) in
            make.right.equalTo(foldButton.snp.left).offset(-12)
            make.centerY.equalTo(foldButton)
            make.height.equalTo(20)
            make.width.equalTo(52)
        }
        
        textLabel.snp.remakeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(6)
            make.centerY.equalTo(iconView)
            make.right.equalTo(feedbackView.snp.left).offset(-16)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var feedbackView : MinutesFeedbackView = {
        let view = MinutesFeedbackView(frame: .zero, type: .chapter, likeStatus: .none)
        return view
    }()
    
}

final class MinutesChapterDashedView: UIView {
    var shapeLayer: CAShapeLayer?
    override init(frame: CGRect) {
        super.init(frame: frame)

        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = UIColor.ud.functionInfoFillSolid03.cgColor
        shapeLayer.lineWidth = 1
        shapeLayer.lineDashPattern = [5, 5]
        layer.addSublayer(shapeLayer)
        self.shapeLayer = shapeLayer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let cgPath = CGMutablePath()
        let cgPoint = [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: self.bounds.height)]
        cgPath.addLines(between: cgPoint)
        shapeLayer?.path = cgPath
    }
}

class MinutesChapterDotView: UIView {
    let centerDot = UIView()
    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(centerDot)
        centerDot.backgroundColor = UIColor.ud.functionInfoContentDefault
        centerDot.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.width.height.equalTo(self).multipliedBy(0.5)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var isSelected: Bool = false {
        didSet {
            backgroundColor = isSelected ? UIColor.ud.primaryFillTransparent02.withAlphaComponent(0.15) : .clear
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = bounds.size.width / 2.0
        centerDot.layer.cornerRadius = bounds.size.width / 4.0
    }
}

class MinutesChapterCell: UITableViewCell {
    var info: MinutesChapterInfo?
    var didTextTappedBlock: ((Phrase?) -> Void)?

    private lazy var titleLabel: YYTextView = {
        let textView = YYTextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.textContainerInset = .zero
        textView.allowSelectionDot = false
        textView.allowShowMagnifierCaret = false
        textView.allowsCopyAttributedString = false
        textView.textTapEndAction = { [weak self] (containerView, text, range, rect) in
            let filter = self?.info?.dPhrases[.title]?.first(where: {$0.range.intersection(range) != nil })
            self?.didTextTappedBlock?(filter)
        }
        return textView
    }()

    lazy var detailLabel: YYTextView = {
        let textView = YYTextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.textContainerInset = .zero
        textView.allowSelectionDot = false
        textView.allowShowMagnifierCaret = false
        textView.allowsCopyAttributedString = false
        textView.textTapEndAction = { [weak self] (containerView, text, range, rect) in
            let filter = self?.info?.dPhrases[.content]?.first(where: {$0.range.intersection(range) != nil })
            self?.didTextTappedBlock?(filter)
        }

        return textView
    }()

    private lazy var dictBorder: YYTextBorder = {
        let border = YYTextBorder()
        border.cornerRadius = 6
        border.fillColor = .clear
        border.bottomLineStrokeColor = UIColor.ud.N400
        border.bottomLineStrokeWidth = 1.0
        border.bottomLineType = .dottedLine
        return border
    }()

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    let selectedView = UIView()
    let dotView = MinutesChapterDotView()
    let dashedView = MinutesChapterDashedView()

    func setInfo(_ info: MinutesChapterInfo?, width: CGFloat, isInTranslationMode: Bool) {
        guard let info = info else { return }

        self.info = info
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 5.0

        titleLabel.attributedText = NSMutableAttributedString(string: info.title, attributes: [.foregroundColor: UIColor.ud.textTitle, .font: UIFont.systemFont(ofSize: 16, weight: .medium), .paragraphStyle: style])

        let attributedText = NSMutableAttributedString(string: info.content, attributes: [.foregroundColor: UIColor.ud.textCaption, .font: UIFont.systemFont(ofSize: 14, weight: .regular), .paragraphStyle: style])
        detailLabel.attributedText = attributedText

        if let text = titleLabel.attributedText {
            let size = CGSize(width: width - 56, height: CGFloat.greatestFiniteMagnitude)
            let container = YYTextContainer(size: size, insets: .zero)
            let layout = YYTextLayout(container: container, text: text)

            titleLabel.snp.remakeConstraints { make in
                make.left.equalTo(dotView.snp.right).offset(10)
                make.top.equalTo(dotView).offset(-3)
                make.right.equalToSuperview().offset(-16)
                make.height.equalTo(layout?.textBoundingSize.height ?? 0.0)
            }
        }

        if let text = detailLabel.attributedText {
            let size = CGSize(width: width - 56, height: CGFloat.greatestFiniteMagnitude)
            let container = YYTextContainer(size: size, insets: .zero)
            let layout = YYTextLayout(container: container, text: text)

            detailLabel.snp.remakeConstraints { make in
                make.left.right.equalTo(titleLabel)
                make.top.equalTo(titleLabel.snp.bottom).offset(8)
                make.height.equalTo(layout?.textBoundingSize.height ?? 0.0)
            }
        }
        titleLabel.removeMySelectionRects()
        if !isInTranslationMode {
            info.dPhrases[.title]?.forEach { (phrase) in
                self.titleLabel.setMySelectionRects(self.dictBorder, range: phrase.range)
            }
        }

        detailLabel.removeMySelectionRects()
        if !isInTranslationMode {
            info.dPhrases[.content]?.forEach { (phrase) in
                self.detailLabel.setMySelectionRects(self.dictBorder, range: phrase.range)
            }
        }

        if info.content.isEmpty == true {
            timeLabel.snp.remakeConstraints { make in
                make.left.equalTo(titleLabel)
                make.top.equalTo(titleLabel.snp.bottom).offset(8)
                make.bottom.equalToSuperview().offset(-10)
            }
        } else {
            timeLabel.snp.remakeConstraints { make in
                make.left.equalTo(titleLabel)
                make.top.equalTo(detailLabel.snp.bottom).offset(8)
                make.bottom.equalToSuperview().offset(-10)
            }
        }

        timeLabel.text = info.formatTime

        titleLabel.textColor = info.isSelected == true ? UIColor.ud.functionInfoContentDefault : UIColor.ud.textTitle
        dotView.isSelected = info.isSelected == true
        selectedView.isHidden = info.isSelected == false
    }

    var index: Int = 0 {
        didSet {
            dashedView.snp.remakeConstraints { make in
                make.left.equalTo(dotView.snp.centerX)
                index == 0 ? make.top.equalTo(dotView.snp.bottom).offset(3) : make.top.equalToSuperview()
                make.right.bottom.equalToSuperview()
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        selectedView.backgroundColor = UIColor.ud.functionInfoFillDefault.withAlphaComponent(0.06)
        selectedView.layer.cornerRadius = 8
        contentView.addSubview(selectedView)
        contentView.addSubview(dashedView)
        contentView.addSubview(dotView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(timeLabel)

        selectedView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
        }
        dashedView.snp.makeConstraints { make in
            make.left.equalTo(dotView.snp.centerX)
            make.top.equalToSuperview()
            make.right.bottom.equalToSuperview()
        }
        dotView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 12, height: 12))
            make.left.equalToSuperview().offset(18)
            make.top.equalToSuperview().offset(13)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(dotView.snp.right).offset(10)
            make.top.equalTo(dotView).offset(-3)
            make.right.equalToSuperview().offset(-16)
        }
        detailLabel.snp.makeConstraints { make in
            make.left.right.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
        }
        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.top.equalTo(detailLabel.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-10)
        }
    }

    func updateUI(isFirst: Bool, isLast: Bool) {
        if isFirst {
            dashedView.snp.remakeConstraints { make in
                make.left.equalTo(dotView.snp.centerX)
                make.top.equalTo(dotView.snp.bottom)
                make.right.bottom.equalToSuperview()
            }
        } else if isLast {
            dashedView.snp.remakeConstraints { make in
                make.left.equalTo(dotView.snp.centerX)
                make.top.equalToSuperview()
                make.right.equalToSuperview()
                make.bottom.equalTo(dotView.snp.top)
            }
        } else {
            dashedView.snp.remakeConstraints { make in
                make.left.equalTo(dotView.snp.centerX)
                make.top.equalToSuperview()
                make.right.bottom.equalToSuperview()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
