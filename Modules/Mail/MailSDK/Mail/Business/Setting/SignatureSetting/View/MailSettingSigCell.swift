//
//  MailSettingSigCell.swift
//  MailSDK
//
//  Created by tanghaojin on 2021/10/8.
//

import Foundation
import RxSwift
import UniverseDesignIcon

enum MailSettingSigCellType: String {
    case SigCellLeftArrowType
    case SigCellRightArrowType
    case SigCellRightArrowMoreMarginType
    case SigCellMarkType
}

struct MailSettingSigUIModel {
    var title: String?
    var subTitle: String?
    var sigId: String?
    var sigType: Int = 0 // 0: newMail 1: replyMail
    var marked: Bool = false
    var styleType: MailSettingSigCellType = .SigCellLeftArrowType
    var open: Bool = false
    var address: String? // cell从属的address
    var needRightArrow: Bool = false
    var disableStyle: Bool = false
    init() {}
    static func genAddressTypeModel(sigModel: MailSettingSigModel) -> MailSettingSigUIModel {
        var model = MailSettingSigUIModel()
        model.title = sigModel.address
        model.open = sigModel.open
        model.address = sigModel.address
        model.styleType = .SigCellLeftArrowType
        return model
    }
    static func genNewMailTypeModel(sigModel: MailSettingSigModel,
                                    type: MailSettingSigCellType) -> MailSettingSigUIModel {
        var model = MailSettingSigUIModel()
        model.styleType = type
        model.title = BundleI18n.MailSDK.Mail_Signature_UseForNewEmails_Header
        if let newSig = sigModel.newMailSig, !newSig.isEmpty {
            model.subTitle = newSig
        }
        model.sigId = sigModel.newMailSigId
        model.sigType = 0
        model.address = sigModel.address
        return model
    }
    static func genReplyMailTypeModel(sigModel: MailSettingSigModel,
                                      type: MailSettingSigCellType) -> MailSettingSigUIModel {
        var model = MailSettingSigUIModel()
        model.styleType = type
        model.title = BundleI18n.MailSDK.Mail_Signature_UseForForwardReply_Header
        if let replySig = sigModel.replySig, !replySig.isEmpty {
            model.subTitle = replySig
        }
        model.sigId = sigModel.replySigId
        model.sigType = 1
        model.address = sigModel.address
        return model
    }
    static func genSelectionModel(sig: MailSignature? = nil,
                                  marked: Bool) -> MailSettingSigUIModel {
        var model = MailSettingSigUIModel()
        model.styleType = .SigCellMarkType
        if sig == nil {
            model.title = BundleI18n.MailSDK.Mail_BusinessSignature_NoUse
        } else {
            model.sigId = sig?.id
            model.title = sig?.name
        }
        model.marked = marked
        return model
    }
}

class MailSettingSigCell: UITableViewCell {
    let disposeBag = DisposeBag()
    var model: MailSettingSigUIModel

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(model: MailSettingSigUIModel) {
        self.model = model
        super.init(style: .default, reuseIdentifier: model.styleType.rawValue)
        self.selectionStyle = .none
        setupViews(styleType: model.styleType)
        configModel(model: model)
    }

    func setupViews(styleType: MailSettingSigCellType) {
        self.backgroundColor = UIColor.ud.bgBody
        let leftMargin = styleType == .SigCellRightArrowMoreMarginType ? 44 : 18
        contentView.addSubview(self.bottomLine)
        bottomLine.snp.makeConstraints { (make) in
            make.height.equalTo(1 / UIScreen.main.scale)
            make.bottom.trailing.equalToSuperview()
            make.left.equalToSuperview().offset(leftMargin)
        }
        if styleType == .SigCellLeftArrowType || styleType == .SigCellMarkType {
            titleLabel.numberOfLines = 2
        } else {
            titleLabel.numberOfLines = 1
        }
        if styleType == .SigCellLeftArrowType {
            setupViewForLeftArrowType()
        } else if styleType == .SigCellRightArrowType ||
                    styleType == .SigCellRightArrowMoreMarginType {
            setupViewForRightArrowType(styleType: styleType)

        } else if styleType == .SigCellMarkType {
            setupViewForMarkType()
        }
    }

    func setupViewForLeftArrowType() {
        contentView.addSubview(leftArrow)
        contentView.addSubview(titleLabel)
        leftArrow.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 6.5, height: 10))
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(20)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(44)
            make.right.equalToSuperview().offset(-18)
            make.centerY.equalToSuperview()
        }
    }

    func setupViewForRightArrowType(styleType: MailSettingSigCellType) {
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(rightArrow)
        let leftMargin = styleType == .SigCellRightArrowType ? 16 : 44
        rightArrow.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 12, height: 12))
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(leftMargin)
            make.right.equalTo(subtitleLabel.snp.left).offset(-20)
            make.centerY.equalToSuperview()
        }
        rightArrow.isHidden = !model.needRightArrow
        subtitleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            if model.needRightArrow {
                make.right.equalTo(rightArrow.snp.left).offset(-4)
            } else {
                make.right.equalToSuperview().offset(-16)
            }

            make.left.equalTo(titleLabel.snp.right).offset(20)
        }
    }

    func setupViewForMarkType() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(markImageView)
        markImageView.isHidden = true
        if model.disableStyle {
            titleLabel.textColor = UIColor.ud.textDisabled
        } else {
            titleLabel.textColor = UIColor.ud.textTitle
        }
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.equalTo(markImageView.snp.left).offset(-16)
            make.centerY.equalToSuperview()
        }
        markImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 18, height: 18))
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-18)
        }
    }

    func configModel(model: MailSettingSigUIModel, lastCell: Bool = false) {
        self.model = model
        if model.styleType == .SigCellLeftArrowType {
            titleLabel.text = model.title
        } else if model.styleType == .SigCellRightArrowType ||
                    model.styleType == .SigCellRightArrowMoreMarginType {

            titleLabel.text = model.title
            subtitleLabel.text = model.subTitle
        } else if model.styleType == .SigCellMarkType {
            titleLabel.text = model.title
            titleLabel.sizeToFit()
            markImageView.isHidden = !model.marked
            // disable态不展示mark标识
            if model.disableStyle {
                markImageView.isHidden = true
            }
        }
        bottomLine.isHidden = lastCell
        if model.styleType == .SigCellLeftArrowType {
            // config arrow rotation
            if model.open {
                // arrow down
                leftArrow.image = Resources.mail_setting_icon_down_arrow.withRenderingMode(.alwaysTemplate)
                leftArrow.snp.remakeConstraints { (make) in
                    make.size.equalTo(CGSize(width: 10, height: 6.5))
                    make.centerY.equalToSuperview()
                    make.left.equalToSuperview().offset(18)
                }
            } else {
                // arrow right
                //self.leftArrow.transform = CGAffineTransform(rotationAngle: 0)
                leftArrow.image = Resources.mail_setting_icon_left_arrow.withRenderingMode(.alwaysTemplate)
                leftArrow.snp.remakeConstraints { (make) in
                    make.size.equalTo(CGSize(width: 6.5, height: 10))
                    make.centerY.equalToSuperview()
                    make.left.equalToSuperview().offset(20)
                }
            }
        }
    }

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 1
        label.sizeToFit()
        label.isUserInteractionEnabled = false
        return label
    }()

    lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 1
        label.sizeToFit()
        label.textAlignment = .right
        label.isUserInteractionEnabled = false
        return label
    }()

    lazy var rightArrow: UIImageView = {
        let arrowImageView = UIImageView()
        arrowImageView.image = UDIcon.hideToolbarOutlined.withRenderingMode(.alwaysTemplate)
        arrowImageView.tintColor = UIColor.ud.iconN3
        return arrowImageView
    }()

    lazy var leftArrow: UIImageView = {
        let arrowImageView = UIImageView()
        arrowImageView.image = Resources.mail_setting_icon_left_arrow.withRenderingMode(.alwaysTemplate)
        arrowImageView.tintColor = UIColor.ud.iconN3
        return arrowImageView
    }()

    lazy var markImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Resources.mail_setting_icon_checkMark.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor.ud.colorfulBlue
        imageView.contentMode = .scaleAspectFill
        return imageView

    }()

    lazy var bottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

}
