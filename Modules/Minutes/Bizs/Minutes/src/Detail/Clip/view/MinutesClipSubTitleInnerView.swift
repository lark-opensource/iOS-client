//
//  MinutesClipSubTitleInnerView.swift
//  Minutes
//
//  Created by admin on 2022/5/14.
//
import UIKit
import UniverseDesignColor
import MinutesFoundation
import UniverseDesignColor
import RichLabel

protocol MinutesClipSubTitleInnerViewDelegate: AnyObject {
    func tapLinkClosure()
}

class MinutesClipSubTitleInnerView: UIView {

    var viewHeight: CGFloat = 0

    var preferredMaxLayoutWidth: CGFloat = 0

    weak var delegate: MinutesClipSubTitleInnerViewDelegate?

    private lazy var subTitleLabel: LKLabel = {
        let label = LKLabel()
        label.backgroundColor = .clear
        label.numberOfLines = 1
        label.isUserInteractionEnabled = true
        return label
    }()

    private lazy var subTitleLabel2: LKLabel = {
        let label = LKLabel()
        label.backgroundColor = .clear
        label.numberOfLines = 1
        label.isUserInteractionEnabled = true
        return label
    }()

    private var duration: String = ""
    private var isContinue: Bool = false

    private func constructTextForLabel() {
        var result: String = ""
        if !duration.isEmpty {
            result += duration
        }

        if !isContinue {
            result += "  |  "
            result += BundleI18n.Minutes.MMWeb_G_NotFullMinutes
        }

        let temp = result + "  |  " + BundleI18n.Minutes.MMWeb_G_JumpToFull
        let attributedStr = NSAttributedString(string: temp, attributes: [.font: UIFont.systemFont(ofSize: 14)])
        let layout = LKTextLayoutEngineImpl()
        layout.attributedText = attributedStr
        layout.preferMaxWidth = preferredMaxLayoutWidth
        layout.layout(size: CGSize(width: preferredMaxLayoutWidth, height: CGFloat.greatestFiniteMagnitude))
        if layout.lines.count > 1 {
            let attributedString = NSAttributedString(string: result,
                                                      attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                                   .foregroundColor: UIColor.ud.textPlaceholder])
            subTitleLabel.attributedText = attributedString

            let jumpToFull: String = BundleI18n.Minutes.MMWeb_G_JumpToFull
            let length = NSString(string: jumpToFull).length
            let range = NSRange(location: 0, length: length)
            var link = LKTextLink(range: range,
                                  type: .link,
                                  attributes: [.foregroundColor: UIColor.ud.textLinkNormal,
                                               .font: UIFont.systemFont(ofSize: 14)],
                                  activeAttributes: [.backgroundColor: UIColor.clear])
            link.linkTapBlock = { [weak self] (_, link: LKTextLink) in
                self?.delegate?.tapLinkClosure()
            }

            subTitleLabel2.addLKTextLink(link: link)

            let attributedString2 = NSAttributedString(string: jumpToFull,
                                                      attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                                   .foregroundColor: UIColor.ud.textPlaceholder])
            subTitleLabel2.attributedText = attributedString2

            viewHeight = 20 * 2 + 2
        } else {
            result += "  |  "
            let location = NSString(string: result).length
            let jumpToFull: String = BundleI18n.Minutes.MMWeb_G_JumpToFull
            let length = NSString(string: jumpToFull).length
            let range = NSRange(location: location, length: length)
            result += jumpToFull

            var link = LKTextLink(range: range,
                                  type: .link,
                                  attributes: [.foregroundColor: UIColor.ud.textLinkNormal,
                                               .font: UIFont.systemFont(ofSize: 14)],
                                  activeAttributes: [.backgroundColor: UIColor.clear])
            link.linkTapBlock = { [weak self] (_, link: LKTextLink) in
                self?.delegate?.tapLinkClosure()
            }

            subTitleLabel.addLKTextLink(link: link)

            let attributedString = NSAttributedString(string: result,
                                                      attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                                   .foregroundColor: UIColor.ud.textPlaceholder])
            subTitleLabel.attributedText = attributedString
            viewHeight = 20
            subTitleLabel.snp.remakeConstraints { make in
                make.top.left.right.bottom.equalToSuperview()
            }
        }
    }

    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        addSubview(subTitleLabel)
        subTitleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        addSubview(subTitleLabel2)
        subTitleLabel2.snp.makeConstraints { make in
            make.top.equalTo(subTitleLabel.snp.bottom).offset(2)
            make.bottom.left.right.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(duration: String, isContinue: Bool) {
        self.duration = duration
        self.isContinue = isContinue
        self.constructTextForLabel()
    }
}
