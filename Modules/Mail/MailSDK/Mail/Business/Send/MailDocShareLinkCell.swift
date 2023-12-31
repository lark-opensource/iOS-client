//
//  MailDocShareLinkCell.swift
//  Action
//
//  Created by TangHaojin on 2023/5/4.
//

import UIKit
import LarkUIKit
import UniverseDesignSwitch
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignActionPanel
import EENavigator
import RustPB

protocol MailDocShareLinkCellDelegate: AnyObject {
    var navigator: Navigatable? { get }
    func linkCellStatusChange(model: DocShareModel)
    func showNoChangeToast(text: String)
}

class MailDocShareLinkCell: UITableViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    static let closeHeight = 68.0
    static let openHeight = 116.0
    let imageWidth = 36.0
    let normalMargin = 16.0
    let textMargin = 10.0
    let subTextMargin = 2.5
    let titleRightMargin = -72.0
    let switchWidth = 48.0
    let switchHeight = 28.0
    let switchTopMargin = 20.0
    let lineHeight = 0.5
    let permissionDescRightMargin = -32.0
    let arrowRightMargin = -18.0
    let arrowWidth = 12
    let arrowHeight = 12
    var model: DocShareModel?
    weak var delegate: MailDocShareLinkCellDelegate?

    weak var settingSwitchDelegate: MailSettingSwitchDelegate?
    /// icon （在moreActionView里可能会需要）
    private var iconImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 18.0
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    /// 标题
    private let titleLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UDColor.textTitle
        return label
    }()
    /// 副标题
    private let subTitleLabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UDColor.textPlaceholder
        return label
    }()
    /// 开关
    private lazy var switchButton: UDSwitch = UDSwitch()
    
    /// 分隔线
    private lazy var line: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()
    
    private lazy var permissionDesc = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UDColor.textCaption
        return label
    }()
    //private var permissionTapGesture: UITapGestureRecognizer?

    /// 箭头
    private lazy var arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.hideToolbarOutlined.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor.ud.iconN3
        return imageView
    }()
    
    

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        switchButton.tapCallBack = { [weak self] _ in
            self?.switchButtonClicked()
        }
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.permissionTaped))
        self.permissionDesc.isUserInteractionEnabled = true
        self.permissionDesc.addGestureRecognizer(gesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        self.backgroundColor = UIColor.ud.bgFloat
        self.contentView.addSubview(iconImageView)
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(subTitleLabel)
        self.contentView.addSubview(switchButton)
        self.contentView.addSubview(line)
        self.contentView.addSubview(permissionDesc)
        self.contentView.addSubview(arrowImageView)
        self.iconImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: imageWidth, height: imageWidth))
            make.left.top.equalToSuperview().offset(normalMargin)
        }
        self.titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(textMargin)
            make.top.equalToSuperview().offset(normalMargin)
            make.right.equalToSuperview().offset(titleRightMargin)
        }
        self.subTitleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(textMargin)
            make.top.equalTo(titleLabel.snp.bottom).offset(subTextMargin)
            make.right.equalToSuperview().offset(titleRightMargin)
        }
        self.switchButton.snp.makeConstraints { make in
            make.width.equalTo(switchWidth)
            make.height.equalTo(switchHeight)
            make.right.equalTo(normalMargin * -1)
            make.top.equalToSuperview().offset(switchTopMargin)
        }
        self.line.snp.makeConstraints { make in
            make.height.equalTo(lineHeight)
            make.right.equalToSuperview()
            make.top.equalToSuperview().offset(MailDocShareLinkCell.closeHeight)
            make.left.equalToSuperview().offset(normalMargin)
        }
        
        self.permissionDesc.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(normalMargin)
            make.top.equalTo(line.snp.bottom).offset(15.5)
            make.right.equalToSuperview().offset(permissionDescRightMargin)
        }
        self.arrowImageView.snp.makeConstraints { make in
            make.width.equalTo(arrowWidth)
            make.height.equalTo(arrowHeight)
            make.centerY.equalTo(self.permissionDesc.snp.centerY)
            make.right.equalToSuperview().offset(arrowRightMargin)
        }
    }
    
    private func switchButtonClicked() {
        if var model = self.model {
            if !model.forbidReason.isEmpty {
                //展示原因
                self.delegate?.showNoChangeToast(text: model.forbidReason)
            } else if model.changePermission {
                if model.permission == .notShare {
                    model.permission = .shareRead
                } else {
                    model.permission = .notShare
                }
                self.delegate?.linkCellStatusChange(model: model)
            }
        }
    }
    @objc private func permissionTaped() {
        let source = UDActionSheetSource(sourceView: self,
                                                 sourceRect: self.bounds,
                                                 arrowDirection: .up)
        let pop = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: false, popSource: source))
        let selectedColor = UIColor.ud.primaryContentDefault
        let permission = self.model?.permission ?? .shareRead
        let readItem = UDActionSheetItem(title: BundleI18n.MailSDK.Mail_LinkSharing_AnyoneWithAccessCanView_Text, titleColor: permission == .shareRead ? selectedColor : UIColor.ud.textTitle) { [weak self]  in
            self?.model?.permission = .shareRead
            if let model = self?.model {
                self?.delegate?.linkCellStatusChange(model: model)
            }
        }
        pop.addItem(readItem)
        let editItem = UDActionSheetItem(title: BundleI18n.MailSDK.Mail_LinkSharing_AnyoneWithAccessCanEdit_Text, titleColor: permission == .shareEdit ? selectedColor : UIColor.ud.textTitle) { [weak self]  in
            self?.model?.permission = .shareEdit
            if let model = self?.model {
                self?.delegate?.linkCellStatusChange(model: model)
            }
        }
        pop.addItem(editItem)
        pop.setCancelItem(text: BundleI18n.MailSDK.Mail_Alert_Cancel)
        if let window = self.window {
            delegate?.navigator?.present(pop, from: window)
        }
    }
    
    func updateModel(model: DocShareModel) {
        self.model = model
        let isOn = (model.permission == .shareEdit || model.permission == .shareRead)
        self.line.isHidden = !isOn
        self.permissionDesc.isHidden = !isOn
        self.arrowImageView.isHidden = !isOn
        self.switchButton.setOn(isOn,
                                animated: false,
                                ignoreValueChanged: true)
        self.titleLabel.setText(model.title)
        self.subTitleLabel.setText(BundleI18n.MailSDK.Mail_LinkSharing_DocumentOwner_Text(model.author))
        self.iconImageView.image = getIconImage(type: model.docType)
        if model.permission == .shareRead {
            self.permissionDesc.setText(BundleI18n.MailSDK.Mail_LinkSharing_AnyoneWithAccessCanView_Text)
        } else if model.permission == .shareEdit {
            self.permissionDesc.setText(BundleI18n.MailSDK.Mail_LinkSharing_AnyoneWithAccessCanEdit_Text)
        }
        switchButton.isEnabled =  model.changePermission
    }
    func getIconImage(type: Email_Client_V1_DocStruct.ObjectType) -> UIImage {
        switch type {
        case .doc:
            return UDIcon.getIconByKey(.fileRoundDocColorful, size: CGSize(width: imageWidth, height: imageWidth))
        case .docx:
            return UDIcon.getIconByKey(.fileRoundDocxColorful, size: CGSize(width: imageWidth, height: imageWidth))
        case .bitable, .bitableShareForm:
            return UDIcon.getIconByKey(.fileRoundBitableColorful, size: CGSize(width: imageWidth, height: imageWidth))
        case .sheet:
            return UDIcon.getIconByKey(.fileRoundSheetColorful, size: CGSize(width: imageWidth, height: imageWidth))
        case .mindnote:
            return UDIcon.getIconByKey(.fileRoundMindnoteColorful, size: CGSize(width: imageWidth, height: imageWidth))
        case .link:
            return UDIcon.getIconByKey(.fileRoundLinkColorful, size: CGSize(width: imageWidth, height: imageWidth))
        case .folder:
            return UDIcon.getIconByKey(.fileRoundFolderColorful, size: CGSize(width: imageWidth, height: imageWidth))
        @unknown default:
            return UDIcon.getIconByKey(.fileRoundUnknowColorful, size: CGSize(width: imageWidth, height: imageWidth))
        }
    }
   
}


