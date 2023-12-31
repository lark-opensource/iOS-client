//
//  ChatAddPinURLPreviewTitleView.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/6/5.
//

import Foundation
import LarkSDKInterface
import UniverseDesignColor
import LKCommonsLogging
import RxSwift
import RxCocoa
import UniverseDesignIcon
import LarkCore
import UniverseDesignToast
import LarkModel
import TangramService
import RustPB
import ByteWebImage
import LarkDocsIcon
import LarkContainer

enum ChatAddPinURLPreviewTitleType {
    case doc(DocModel)
    case url(URLModel)

    struct DocModel {
        let url: String
        let docType: RustPB.Basic_V1_Doc.TypeEnum
        let wikiSubType: RustPB.Basic_V1_Doc.TypeEnum
        let title: String
        let ownerName: String
        let iconInfo: String
    }

    struct URLModel {
        let url: String
        let inlineEntity: InlinePreviewEntity?
    }
}

final class ChatAddPinURLPreviewTitleView: UIView {
    private static let logger = Logger.log(ChatAddPinURLPreviewTitleView.self, category: "Module.IM.ChatPin")

    private lazy var tipLabel: UILabel = {
        let tipLabel = UILabel()
        tipLabel.font = UIFont.systemFont(ofSize: 12)
        tipLabel.textColor = UIColor.ud.textCaption
        tipLabel.text = BundleI18n.LarkChat.Lark_IM_NewPin_AddPin_Selected_Text
        return tipLabel
    }()

    private lazy var containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.ud.bgBody
        containerView.layer.cornerRadius = 8
        return containerView
    }()

    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        return iconImageView
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        return titleLabel
    }()

    private lazy var subTitleLabel: UILabel = {
        let subTitleLabel = UILabel()
        subTitleLabel.font = UIFont.systemFont(ofSize: 14)
        subTitleLabel.textColor = UIColor.ud.textPlaceholder
        subTitleLabel.text = ""
        return subTitleLabel
    }()

    private let disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.top.right.equalToSuperview()
        }
        self.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(tipLabel.snp.bottom).offset(4)
            make.height.equalTo(64)
            make.bottom.equalToSuperview().inset(8)
        }

        containerView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(16)
            make.size.equalTo(40)
            make.centerY.equalToSuperview()
        }
    }

    private func setURLPlaceholderIcon() {
        iconImageView.layer.cornerRadius = 20
        iconImageView.backgroundColor = UIColor.ud.textLinkHover
        iconImageView.contentMode = .center
        iconImageView.image = UDIcon.getIconByKey(.globalLinkOutlined, iconColor: UIColor.ud.textLinkNormal, size: CGSize(width: 26, height: 26)).ud.withTintColor(UIColor.ud.bgBody)
    }

    private func resetURLIcon() {
        iconImageView.layer.cornerRadius = 0
        iconImageView.backgroundColor = UIColor.clear
        iconImageView.contentMode = .scaleToFill
    }

    func set(_ type: ChatAddPinURLPreviewTitleType, userResolver: UserResolver) {
        switch type {
        case .url(let urlModel):
            containerView.addSubview(titleLabel)
            titleLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(iconImageView.snp.right).offset(12)
                make.right.equalToSuperview().inset(16)
                make.centerY.equalToSuperview()
            }
            titleLabel.text = urlModel.inlineEntity?.title ?? urlModel.url
            let iconSize = CGSize(width: 40, height: 40)
            if let inlineEntity = urlModel.inlineEntity,
               let iconPB = URLPreviewPinIconTransformer.convertToChatPinIcon(inlineEntity) {
                let iconResource = URLPreviewPinIconTransformer.transform(iconPB,
                                                                          iconSize: iconSize,
                                                                          defaultIcon: UDIcon.getIconByKey(.globalLinkOutlined, size: iconSize).ud.withTintColor(UIColor.ud.B500),
                                                                          placeholder: nil)
                URLPreviewPinIconTransformer.renderIcon(
                    iconImageView,
                    iconResource: iconResource,
                    iconCornerRadius: 0,
                    disposeBag: nil,
                    successHandler: { [weak self] in
                        self?.resetURLIcon()
                    },
                    errorHandler: { [weak self] _ in
                        self?.setURLPlaceholderIcon()
                    }
                )
            } else {
                setURLPlaceholderIcon()
            }
        case .doc(let docModel):
            containerView.addSubview(titleLabel)
            containerView.addSubview(subTitleLabel)
            titleLabel.snp.remakeConstraints { (make) in
                make.top.equalToSuperview().offset(12)
                make.left.equalTo(iconImageView.snp.right).offset(12)
                make.right.equalToSuperview().inset(16)
                make.height.equalTo(22)
            }
            subTitleLabel.snp.remakeConstraints { (make) in
                make.top.equalTo(titleLabel.snp.bottom).offset(4)
                make.left.equalTo(iconImageView.snp.right).offset(12)
                make.right.equalToSuperview().inset(16)
            }
            titleLabel.text = docModel.title
            subTitleLabel.text = "\(BundleI18n.CCM.Lark_Legacy_SendDocDocOwner)\(BundleI18n.CCM.Lark_Legacy_Colon)\(docModel.ownerName)"
            let docType: RustPB.Basic_V1_Doc.TypeEnum
            if docModel.docType == .wiki {
                docType = docModel.wikiSubType
            } else {
                docType = docModel.docType
            }
            let defaultIcon = LarkCoreUtils.docIconColorful(docType: docType, fileName: docModel.title)
            iconImageView.di.clearDocsImage()
            if !docModel.iconInfo.isEmpty {
                let containerInfo = ContainerInfo(isShortCut: docModel.docType == .shortcut, defaultCustomIcon: defaultIcon)
                iconImageView.di.setDocsImage(iconInfo: docModel.iconInfo, url: docModel.url, shape: .SQUARE, container: containerInfo, userResolver: userResolver)
            } else {
                iconImageView.image = defaultIcon
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
