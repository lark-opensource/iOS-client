//
//  InterpreterInformationView.swift
//  ByteView
//
//  Created by Tobb Huang on 2020/10/21.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit
import ByteViewNetwork
import ByteViewUI

class InterpreterInformationView: UIButton {

    enum Layout {
        static let infoLeft = 12.0
        static let infoRight = 12.0
        static let infoGap = 8.0
        static let languageIconSize = 20.0
        static let descriptionHeight = 22.0
        static let descriptionFont = 16.0
    }

    private let disposeBag = DisposeBag()

    lazy var languageIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.clear
        return imageView
    }()

    lazy var avatarView = AvatarView()

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: Layout.descriptionFont)
        label.textColor = UIColor.ud.textTitle
        label.snp.makeConstraints { make in
            make.height.equalTo(Layout.descriptionHeight)
        }
        label.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        return label
    }()

    lazy var joinStateLabel: UILabel = {
       let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = UIColor.ud.textPlaceholder
        label.snp.makeConstraints { make in
            make.height.equalTo(22)
        }
        return label
    }()

    lazy var infoView: UIStackView = {
        let stackView: UIStackView = UIStackView()
        stackView.isUserInteractionEnabled = false
        stackView.alignment = .center
        stackView.spacing = Layout.infoGap
        return stackView
    }()

    lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        vc.setBackgroundColor(UIColor.ud.bgFloatOverlay, for: .normal)
        vc.setBackgroundColor(UIColor.ud.fillPressed, for: .highlighted)

        layer.cornerRadius = 8.0
        layer.masksToBounds = true

        infoView.addArrangedSubview(descriptionLabel)
        infoView.addArrangedSubview(joinStateLabel)
        infoView.setCustomSpacing(4, after: descriptionLabel)
        addSubview(infoView)
        infoView.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(Layout.infoLeft)
            maker.right.lessThanOrEqualToSuperview().offset(-Layout.infoRight)
            maker.centerY.equalToSuperview()
        }
        addSubview(iconView)
        iconView.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().inset(12)
            maker.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func config(with info: InterpreterInformation, showIcon: Bool = true, httpClient: HttpClient) {
        if showIcon {
            if let languageType = info.languageType, !languageType.iconStr.isEmpty {
                infoView.insertArrangedSubview(languageIconView, at: 0)
                languageIconView.image = LanguageIconManager.get(by: languageType)
                languageIconView.snp.remakeConstraints { (maker) in
                    maker.size.equalTo(Layout.languageIconSize)
                }
            } else {
                languageIconView.removeFromSuperview()
            }
        }

        if let avatarInfo = info.avatarInfo {
            infoView.insertArrangedSubview(avatarView, at: 0)
            avatarView.setAvatarInfo(avatarInfo)
            avatarView.snp.remakeConstraints { (maker) in
                maker.size.equalTo(20)
            }
        } else {
            avatarView.removeFromSuperview()
        }

        if let desc = info.description {
            descriptionLabel.text = desc
        } else if let languageType = info.languageType, !languageType.despI18NKey.isEmpty {
            httpClient.i18n.get(languageType.despI18NKey) { [weak self] result in
                Util.runInMainThread {
                    guard let self = self else { return }
                    switch result {
                    case .success(let text):
                        self.descriptionLabel.text = text
                    case .failure:
                        self.descriptionLabel.text = I18n.View_G_SelectLanguage
                    }
                }
            }
        }

        joinStateLabel.text = info.joinState
        joinStateLabel.isHidden = info.joinState == nil

        if let color = info.descriptionColor {
            descriptionLabel.textColor = color
        }

        if let icon = info.icon {
            iconView.isHidden = false
            iconView.image = icon
            infoView.snp.remakeConstraints { (maker) in
                maker.left.equalToSuperview().offset(12)
                maker.right.lessThanOrEqualTo(iconView.snp.left).offset(-12)
                maker.centerY.equalToSuperview()
            }
        } else {
            iconView.isHidden = true
            infoView.snp.remakeConstraints { (maker) in
                maker.left.equalToSuperview().offset(12)
                maker.right.lessThanOrEqualToSuperview().offset(-12)
                maker.centerY.equalToSuperview()
            }
        }
    }

    static func maxWidthWithLanguageIcon(_ descrption: String) -> CGFloat {
        let textW = descrption.vc.boundingWidth(height: Layout.descriptionHeight, font: UIFont.systemFont(ofSize: Layout.descriptionFont))
        return Layout.infoLeft + Layout.languageIconSize + Layout.infoGap + textW + Layout.infoRight
    }
}
