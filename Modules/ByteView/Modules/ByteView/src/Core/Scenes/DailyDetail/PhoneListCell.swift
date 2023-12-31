//
//  PhoneListCell.swift
//  ByteView
//
//  Created by 费振环 on 2020/8/11.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RichLabel

final class PhoneListCell: UITableViewCell {

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
            make.height.equalTo(24.0)
            make.top.equalToSuperview().offset(10.0)
            make.left.equalToSuperview().offset(safeAreaInsets.left + 16)
            make.right.equalToSuperview().offset(-16)
        }

        dialInNumberLabel.snp.makeConstraints { make in
            make.top.equalTo(countryLabel.snp.bottom).offset(4.0)
            make.left.equalTo(countryLabel.snp.left)
            make.right.equalTo(countryLabel.snp.right)
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

    func configure(_ model: DialInInfoModel, meetingNumber: String) {
        countryLabel.attributedText = NSAttributedString(string: model.country, config: .body)
        let dialInText = model.dialInNumbers.joined(separator: "\n")
        var startIndex = 0
        var endIndex = 0
        let font = UIFont.systemFont(ofSize: 14, weight: .regular)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.minimumLineHeight = 20
        paragraphStyle.maximumLineHeight = 20
        dialInNumberLabel.attributedText = NSAttributedString(string: dialInText, attributes: [.foregroundColor: UIColor.ud.primaryContentDefault, .font: font, .paragraphStyle: paragraphStyle])

        textLinks.forEach { link in
            dialInNumberLabel.removeLKTextLink(link: link)
        }
        textLinks.removeAll()
        if Display.phone {
            var callStr: String = ""
            model.dialInNumbers.forEach { phoneNumber in
                endIndex += phoneNumber.count
                var link = LKTextLink(range: NSRange(location: startIndex, length: endIndex - startIndex), type: .link)
                link.linkTapBlock = { (_, _) in
                    if #available(iOS 15.4, *) {
                        callStr = "\(phoneNumber),,\(meetingNumber)".replacingOccurrences(of: " ", with: "")
                    } else {
                        callStr = "\(phoneNumber),,\(meetingNumber)#".replacingOccurrences(of: " ", with: "")
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
}
