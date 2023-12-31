//
//  InterpreterManageCell.swift
//  ByteView
//
//  Created by Tobb Huang on 2020/10/20.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxCocoa
import UniverseDesignIcon
import UIKit
import ByteViewNetwork

class InterpreterManageCell: UITableViewCell {

    private struct Layout {
        static let commonSpacing: CGFloat = 16
        static let defaultInterpreterTitleColor: UIColor = UIColor.ud.textPlaceholder
        static let defaultLanguageTitleColor: UIColor = UIColor.ud.textPlaceholder
        static let rightIcon: UIImage? = UDIcon.getIconByKey(.downOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 16, height: 16))
    }

    lazy var interpreterNumberLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.text = I18n.View_G_InterpreterNumber(1)
        return label
    }()

    lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKey(.deleteTrashOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 18, height: 18)), for: .normal)
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnTextBgNeutralPressed, for: .highlighted)
        button.vc.setBackgroundColor(.clear, for: .normal)
        return button
    }()

    lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.addSubview(interpreterNumberLabel)
        interpreterNumberLabel.snp.makeConstraints { (maker) in
            maker.bottom.equalToSuperview()
            maker.top.left.equalTo(16)
        }
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { (maker) in
            maker.top.equalTo(18 + 2)
            maker.right.equalTo(-16 - 2)
            maker.size.equalTo(CGSize(width: 18 + 4, height: 18 + 4))
        }
        return view
    }()

    lazy var interpreterView: InterpreterInformationView = {
        return InterpreterInformationView()
    }()

    lazy var firstLanguageView: InterpreterInformationView = {
        return InterpreterInformationView()
    }()

    lazy var secondLanguageView: InterpreterInformationView = {
        return InterpreterInformationView()
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.backgroundColor = .clear
        self.selectionStyle = .none
        self.contentView.backgroundColor = UIColor.ud.bgFloat
        self.contentView.layer.cornerRadius = 10
        self.contentView.layer.masksToBounds = true

        self.contentView.snp.makeConstraints { make in
            make.top.equalTo(16)
            make.right.equalTo(safeAreaLayoutGuide).offset(-16)
            make.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview()
            make.height.greaterThanOrEqualTo(170 + 16)
        }

        self.contentView.addSubview(headerView)
        headerView.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
            maker.height.equalTo(16 + 22)
        }

        self.contentView.addSubview(interpreterView)
        interpreterView.snp.makeConstraints { (maker) in
            maker.top.equalTo(headerView.snp.bottom).offset(16)
            maker.left.right.equalToSuperview().inset(16)
            maker.height.equalTo(44)
        }

        self.contentView.addSubview(firstLanguageView)
        firstLanguageView.snp.makeConstraints { (maker) in
            maker.top.equalTo(interpreterView.snp.bottom).offset(12)
            maker.left.equalTo(interpreterView)
            maker.height.equalTo(44)
            maker.bottom.equalToSuperview().offset(-16)
        }

        self.contentView.addSubview(secondLanguageView)
        secondLanguageView.snp.makeConstraints { (maker) in
            maker.top.width.height.equalTo(firstLanguageView)
            maker.right.equalTo(interpreterView)
            maker.left.equalTo(firstLanguageView.snp.right).offset(12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func config(with channel: InterpretationChannelInfo, httpClient: HttpClient) {

        interpreterNumberLabel.text = I18n.View_G_InterpreterNumber(channel.interpreterIndex + 1)

        var interpreterInfo: InterpreterInformation
        if let avatar = channel.avatarInfo, let name = channel.displayName {
            interpreterInfo = InterpreterInformation(avatarInfo: avatar,
                                                     description: name,
                                                     descriptionColor: UIColor.ud.textTitle,
                                                     joinState: channel.joined ? nil : I18n.View_G_NotJoined_StatusGrey,
                                                     icon: Layout.rightIcon)
        } else {
            interpreterInfo = InterpreterInformation(description: I18n.View_G_AddInterpreter,
                                                     descriptionColor: Layout.defaultInterpreterTitleColor)
        }
        interpreterView.config(with: interpreterInfo, httpClient: httpClient)

        let firstInfo = createInterpreterInformation(with: channel.interpreterSetting.firstLanguage)
        firstLanguageView.config(with: firstInfo, httpClient: httpClient)

        let secondInfo = createInterpreterInformation(with: channel.interpreterSetting.secondLanguage)
        secondLanguageView.config(with: secondInfo, httpClient: httpClient)
    }

    private func createInterpreterInformation(with languageType: LanguageType) -> InterpreterInformation {
        guard !languageType.isEmpty else {
            return InterpreterInformation(description: I18n.View_G_Language,
                                          descriptionColor: Layout.defaultLanguageTitleColor,
                                          icon: Layout.rightIcon)
        }
        return InterpreterInformation(languageType: languageType,
                                      descriptionColor: UIColor.ud.textTitle,
                                      icon: Layout.rightIcon)
    }
}
