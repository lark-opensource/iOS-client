//
//  SearchInstanceView.swift
//  CalendarInChat
//
//  Created by zoujiayi on 2019/8/9.
//

import UIKit
import Foundation
import CalendarFoundation
import LarkFoundation

final class SearchInstanceView: UIView {
    private var content: SearchInstanceViewContent?
    private let titleLabel = UILabel.cd.titleLabel(fontSize: 14)
    private let timeDesLabel = UILabel.cd.titleLabel(fontSize: 14)
    private let subTitleLabel = UILabel.cd.subTitleLabel(fontSize: 12)
    private let locationLabel = UILabel.cd.subTitleLabel(fontSize: 12)
    private let thirdTitleLabel = UILabel.cd.subTitleLabel(fontSize: 12)
    private let descLabel = UILabel.cd.subTitleLabel(fontSize: 12)
    private let coverLayer: InstanceCoverLayer = InstanceCoverLayer()
    private let backgroundLayer = CAReplicatorLayer()
    private let scripLayer = CALayer()
    // 虚线-内边框
    private let dashedBorder = DashedBorder()
    // 竖条
    private let indicator = Indicator()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 4

        dashedBorder.lineDashPattern = [3, 1.5]
        indicator.lineDashPattern = [2.5, 2.5]
        self.layoutStrip(replicatorLayer: backgroundLayer, instanceLayer: scripLayer)
        layer.addSublayer(indicator)
        layer.addSublayer(dashedBorder)
        self.layoutTitleLabel(titleLabel, timeDescLabel: timeDesLabel)

        self.layoutSubTitleText(subTitleLabel, locationLabel: locationLabel)
        self.layoutThirdTitleText(thirdTitleLabel, descLabel: descLabel)

        self.layer.addSublayer(coverLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        coverLayer.frame = self.bounds
        backgroundLayer.frame = self.bounds
        backgroundLayer.instanceCount = Int(self.bounds.width + self.bounds.height) / 15 + 1
        dashedBorder.updateWith(rect: bounds.insetBy(dx: 0.5, dy: 0.5), cornerWidth: 4)
        indicator.updateWith(iWidth: 3.0, iHeight: bounds.height)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let content = self.content else {
            return
        }
        self.updateContent(content: content)
    }

    func updateContent(content: SearchInstanceViewContent) {
        self.content = content

        setupLabels(content: content)

        // dashedBorder
        if let dashedColor = content.dashedBorderColor {
            dashedBorder.ud.setStrokeColor(dashedColor, bindTo: self)
            dashedBorder.isHidden = false
        } else {
            dashedBorder.isHidden = true
        }

        if let (indicatorColor, isStripe) = content.indicatorInfo {
            if isStripe {
                indicator.ud.setStrokeColor(indicatorColor)
                indicator.ud.setBackgroundColor(.ud.bgFloat)
            } else {
                indicator.ud.setStrokeColor(.clear)
                indicator.ud.setBackgroundColor(indicatorColor)
            }
            indicator.isHidden = false
        } else {
            indicator.isHidden = true
        }

        coverLayer.update(with: content.endDate, isCoverPassEvent: content.isCoverPassEvent, maskOpacity: content.maskOpacity)

        if let stripLineColor = content.stripLineColor {
            self.backgroundColor = UIColor.ud.bgBody
            self.backgroundLayer.isHidden = false
            self.drawStrip(backgroundColor: .ud.bgBody,
                           scripColor: stripLineColor)
        } else {
            self.backgroundLayer.isHidden = true
            backgroundColor = content.backgroundColor
        }
    }

    private func setupLabels(content: SearchInstanceViewContent) {
        let titleAttrString = content
            .titleText
            .attributedText(with: titleLabel.font,
                            color: content.textColor,
                            hasStrikethrough: content.hasStrikethrough,
                            strikethroughColor: UIColor.ud.textPlaceholder,
                            lineBreakMode: .byWordWrapping)
        if let highlights = content.highlightStrings[.title] {
            setAttributeString(for: titleLabel,
                               attributedString: titleAttrString,
                               terms: highlights,
                               highlightColor: content.highlightedBGColor,
                               usedWidth: content.timeDes.width(with: timeDesLabel.font))
        } else {
            titleLabel.attributedText = titleAttrString
        }

        if !content.timeDes.isEmpty {
            timeDesLabel.isHidden = false
            timeDesLabel.attributedText = content.timeDes
                .attributedText(
                    with: timeDesLabel.font,
                    color: content.textColor,
                    hasStrikethrough: content.hasStrikethrough,
                    strikethroughColor: UIColor.ud.textPlaceholder,
                    lineBreakMode: .byTruncatingTail
            )
        } else {
            timeDesLabel.isHidden = true
        }

        subTitleLabel.attributedText = content.timeText
                   .attributedText(
                       with: subTitleLabel.font,
                       color: content.textColor,
                       hasStrikethrough: content.hasStrikethrough,
                       strikethroughColor: UIColor.ud.textPlaceholder,
                       lineBreakMode: .byTruncatingTail)

        if !content.locationText.isEmpty {
            locationLabel.isHidden = false
            let locationAttrString = content.locationText
                .attributedText(
                    with: locationLabel.font,
                    color: content.textColor,
                    hasStrikethrough: content.hasStrikethrough,
                    strikethroughColor: UIColor.ud.textPlaceholder,
                    lineBreakMode: .byWordWrapping
            )
            var highlights = content.highlightStrings[.meetingRoom] ?? []
            highlights += content.highlightStrings[.location] ?? []
            if !highlights.isEmpty {
                setAttributeString(for: locationLabel,
                                   attributedString: locationAttrString,
                                   terms: highlights,
                                   highlightColor: content.highlightedBGColor,
                                   usedWidth: content.timeText.width(with: subTitleLabel.font))
            } else {
                locationLabel.attributedText = locationAttrString
            }
        } else {
            locationLabel.isHidden = true
        }

        if content.highlightStrings[.attendee] != nil {
            showAttendee(content: content)
        } else if content.highlightStrings[.desc] != nil {
            showDesc(content: content)
        } else if !content.attendeeText.isEmpty {
            showAttendee(content: content)
        } else if !content.descText.isEmpty {
            showDesc(content: content)
        } else {
            thirdTitleLabel.isHidden = true
            descLabel.isHidden = true
        }
    }

    func showAttendee(content: SearchInstanceViewContent) {
        thirdTitleLabel.isHidden = true
        descLabel.isHidden = false
        let attr = content.attendeeText
            .attributedText(
                with: descLabel.font,
                color: content.textColor,
                hasStrikethrough: content.hasStrikethrough,
                strikethroughColor: UIColor.ud.textPlaceholder,
                lineBreakMode: .byWordWrapping
        )
        let highlights = content.highlightStrings[.attendee] ?? []
        if !highlights.isEmpty {
            setAttributeString(for: descLabel,
                               attributedString: attr,
                               terms: highlights,
                               highlightColor: content.highlightedBGColor,
                               usedWidth: 0)
        } else {
            descLabel.attributedText = attr
        }
    }

    func showDesc(content: SearchInstanceViewContent) {
        thirdTitleLabel.isHidden = false
        descLabel.isHidden = false
        thirdTitleLabel.attributedText = "\(BundleI18n.Calendar.Calendar_Edit_Description):".attributedText(
            with: thirdTitleLabel.font,
            color: content.textColor,
            hasStrikethrough: content.hasStrikethrough,
            strikethroughColor: UIColor.ud.textPlaceholder,
            lineBreakMode: .byWordWrapping)

        let attr = content.descText
            .attributedText(
                with: descLabel.font,
                color: content.textColor,
                hasStrikethrough: content.hasStrikethrough,
                strikethroughColor: UIColor.ud.textPlaceholder,
                lineBreakMode: .byWordWrapping)

        let highlights = content.highlightStrings[.desc] ?? []
        if !highlights.isEmpty {
            setAttributeString(for: descLabel,
                               attributedString: attr,
                               terms: highlights,
                               highlightColor: content.highlightedBGColor,
                               usedWidth: (thirdTitleLabel.text ?? "").width(with: thirdTitleLabel.font))
        } else {
            descLabel.attributedText = attr
        }

    }

    private func layoutIndicator(_ layer: CALayer, frame: CGRect) {
        layer.frame = frame
        self.layer.addSublayer(layer)
    }

    private func layoutTitleLabel(_ label: UILabel, timeDescLabel: UILabel) {
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let stackView = UIStackView(arrangedSubviews: [label, timeDescLabel])
        stackView.axis = .horizontal
        stackView.spacing = 8
        self.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(8)
            make.right.lessThanOrEqualToSuperview()
            make.top.equalToSuperview().offset(4)
        }
    }

    private func layoutSubTitleText(_ label: UILabel, locationLabel: UILabel) {
        label.numberOfLines = 1
        locationLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        let stackView = UIStackView(arrangedSubviews: [label, locationLabel])
        stackView.axis = .horizontal
        stackView.spacing = 8
        self.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(0)
            make.top.equalToSuperview().offset(26)
        }
    }

    private func layoutThirdTitleText(_ label: UILabel, descLabel: UILabel) {
        label.numberOfLines = 1
        descLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        let stackView = UIStackView(arrangedSubviews: [label, descLabel])
        stackView.axis = .horizontal
        stackView.spacing = 8
        self.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(0)
            make.top.equalToSuperview().offset(45)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutStrip(replicatorLayer: CAReplicatorLayer, instanceLayer: CALayer) {
        replicatorLayer.instanceTransform = CATransform3DMakeTranslation(15, 0, 0)
        self.layer.addSublayer(replicatorLayer)

        instanceLayer.anchorPoint = CGPoint(x: 1, y: 0)
        instanceLayer.frame = CGRect(x: 1, y: 0, width: 5, height: self.frame.height * 3)
        let transform = CGAffineTransform(rotationAngle: .pi / 4)
        instanceLayer.setAffineTransform(transform)
        backgroundLayer.addSublayer(instanceLayer)
    }

    private func drawStrip(backgroundColor: UIColor, scripColor: UIColor) {
        backgroundLayer.ud.setBackgroundColor(backgroundColor, bindTo: self)
        scripLayer.ud.setBackgroundColor(scripColor, bindTo: self)
    }

    func setAttributeString(for label: UILabel,
                            attributedString: NSAttributedString,
                            terms: [String],
                            highlightColor: UIColor,
                            usedWidth: CGFloat) {
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        var text: NSString = mutableAttributedString.string as NSString
        while text.contains("\n") {
            let wrapRange = text.range(of: "\n")
            mutableAttributedString.replaceCharacters(in: wrapRange, with: NSAttributedString(string: ""))
            text = mutableAttributedString.string as NSString
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.maximumLineHeight = label.font.lineHeight
        mutableAttributedString.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle], range: NSRange(location: 0, length: mutableAttributedString.length))
        var attributedText = NSAttributedString(attributedString: mutableAttributedString)
        if let info = firstHitAttrTextInfo(attributedText: attributedText, terms: terms) {
            let textWithFirstHitTerm = info.0
            let remainText = info.1
            // 为了判断第一个hitTerm是否能在label上显示完全
            // 先让第一个hitTerm显示出来，看看这个时候label有多宽
            // 为了确保width是hitTerm完全展示出来的宽度，多计算两个空格的长度
            // 一些极端情况，不加空格计算出来的width仍然展示不全hitTerm， 应该是是后面又加了attribute导致的
            // 这里没有把textWithFirstHitTerm加上attribute执行sizeToFit是为了保证效率。
            let width = (textWithFirstHitTerm.string + "  ").width(with: label.font)
            if width + usedWidth > self.bounds.width - 8 {
                attributedText = remainText
            }
        }
        highlightText(attributedString: attributedText, withHitTerms: terms, highlightColor: highlightColor) { (attrString) in
            label.attributedText = attrString
        }
    }

    /// 将一个attributed String 分解成完整显示的和非完整显示的两种
    /// 完整显示的:   AAAAAAAA[BBBB]
    /// 非完整显示的: ...AAAAA[BBB]CCCC...
    /// - Parameter attributedText: 带分解的string
    /// - Parameter terms: 高亮关键字
    func firstHitAttrTextInfo(attributedText: NSAttributedString, terms: [String]) -> (textWithFirstHitTerm: NSAttributedString, remainText: NSAttributedString)? {

        let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)
        let text: NSString = mutableAttributedText.string as NSString
        guard let firstTerm = terms.first else { return nil }
        let range = (text as NSString).range(of: firstTerm, options: [.caseInsensitive])
        if range.location == NSNotFound {
            return nil
        }
        let remainTextAtt: NSAttributedString
        let textWithFirstHitTermAtt = mutableAttributedText.attributedSubstring(from: NSRange(location: 0, length: range.location + range.length))
        if range.location > 5 {
            let remainTextMuAtt: NSMutableAttributedString = NSMutableAttributedString(string: "...")
            remainTextMuAtt.append(mutableAttributedText.attributedSubstring(from: NSRange(location: range.location - 5, length: mutableAttributedText.length - (range.location - 5))))
            remainTextAtt = NSAttributedString(attributedString: remainTextMuAtt)
        } else {
            remainTextAtt = textWithFirstHitTermAtt
        }

        return (textWithFirstHitTermAtt, remainTextAtt)

    }

    func highlightText(attributedString: NSAttributedString,
                       withHitTerms terms: [String],
                       highlightColor: UIColor,
                       calcHighlightFininsh: @escaping (NSAttributedString) -> Void) {
        DispatchQueue.global().async {
            let text = attributedString.string
            let muAttributedString = NSMutableAttributedString(attributedString: attributedString)
            // 去重，terms 作为高亮数据源，重复计算没有意义
            terms.enumerated().filter { (index, value) -> Bool in
                return terms.firstIndex(of: value) == index
            }.map { $0.element }.forEach { (term) in
                do {
                    let findTermExpression = try NSRegularExpression(pattern: term, options: .caseInsensitive)
                    let matchs = findTermExpression.matches(in: text, options: .reportProgress, range: NSRange(location: 0, length: text.count))
                    matchs.forEach { (checkingResult) in
                        let heightLightRange = checkingResult.range
                        muAttributedString.addAttribute(.backgroundColor,
                                                        value: highlightColor,
                                                        range: heightLightRange)
                    }
                } catch {
                    print("matching error")
                }
            }
            let attString = NSAttributedString(attributedString: muAttributedString)

            DispatchQueue.main.async {
                calcHighlightFininsh(attString)
            }
        }
    }
}
