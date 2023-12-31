//
//  ZoomMeetingPhoneListCell.swift
//  Calendar
//
//  Created by pluto on 2022-10-20.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import RichLabel

class ZoomMeetingPhoneListCell: UITableViewCell {

    private var textLinks: [LKTextLink] = [LKTextLink]()

    lazy var countryLabel = UILabel()

    lazy var dialInNumberLabel: LKLabel = {
        let label = LKLabel()
        label.backgroundColor = .clear
        label.linkAttributes = [.foregroundColor: UIColor.ud.primaryContentDefault, .font: UIFont.systemFont(ofSize: 14, weight: .regular)]
        label.activeLinkAttributes = [:]
        label.numberOfLines = 0
        return label
    }()

    lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    override func safeAreaInsetsDidChange() {
        countryLabel.snp.updateConstraints {
            $0.left.equalToSuperview().offset(safeAreaInsets.left + 16)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = UIColor.ud.fillHover

        contentView.backgroundColor = .clear
        contentView.clipsToBounds = true

        countryLabel.textColor = UIColor.ud.textTitle
        contentView.addSubview(countryLabel)
        contentView.addSubview(dialInNumberLabel)
        contentView.addSubview(separatorView)

        countryLabel.snp.makeConstraints { make in
            make.height.equalTo(22.0)
            make.top.equalToSuperview().offset(12.0)
            make.left.equalToSuperview().offset(safeAreaInsets.left + 16)
            make.right.equalToSuperview().offset(-16)
        }

        dialInNumberLabel.snp.makeConstraints { make in
            make.top.equalTo(countryLabel.snp.bottom).offset(4.0)
            make.left.equalTo(countryLabel.snp.left)
            make.right.equalTo(countryLabel.snp.right)
            make.bottom.equalToSuperview().offset(-12)
        }

        separatorView.snp.makeConstraints {
            $0.left.equalTo(countryLabel)
            $0.right.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCountryLabel(countryName: String) {
        let style = NSMutableParagraphStyle()
        let lineHeight: CGFloat = 22
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        style.alignment = .left
        style.lineBreakMode = .byWordWrapping
        let font: UIFont = UIFont.systemFont(ofSize: 16)
        let offset = (lineHeight - font.lineHeight) / 4.0
        countryLabel.attributedText = NSAttributedString(string: countryName, attributes: [.paragraphStyle: style,
                                                                                             .baselineOffset: offset,
                                                                                             .font: font])
    }

    func configure(_ model: Server.ZoomPhoneNums) {
        setCountryLabel(countryName: model.countryName)
        let dialInText = model.dialInNumbers.joined(separator: "\n")
        var startIndex = 0
        var endIndex = 0
        let font = UIFont.systemFont(ofSize: 14, weight: .regular)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.minimumLineHeight = 22
        paragraphStyle.maximumLineHeight = 22
        dialInNumberLabel.attributedText = NSAttributedString(string: dialInText, attributes: [.foregroundColor: UIColor.ud.primaryContentDefault, .font: font, .paragraphStyle: paragraphStyle])

        textLinks.forEach { link in
            dialInNumberLabel.removeLKTextLink(link: link)
        }
        textLinks.removeAll()
        var callStr: String = ""
        model.dialInNumbers.forEach { phoneNumber in
            endIndex += phoneNumber.count
            var link = LKTextLink(range: NSRange(location: startIndex, length: endIndex - startIndex), type: .link)
            link.linkTapBlock = { (_, _) in

                if #available(iOS 15.4, *) {
                    callStr = "\(phoneNumber)".replacingOccurrences(of: " ", with: "")
                } else {
                    callStr = "\(phoneNumber)#".replacingOccurrences(of: " ", with: "")
                }

                guard let url = URL(string: "telprompt://\(callStr)") else {
                    return
                }
                UIApplication.shared.open(url)
            }

            endIndex += 1
            startIndex += phoneNumber.count + 1
            dialInNumberLabel.addLKTextLink(link: link)
            textLinks.append(link)
        }
    }
}
