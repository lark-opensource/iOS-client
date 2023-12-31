//
//  MailClientAdSettingCell.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/11/25.
//

import Foundation
import UIKit
import RxSwift
import UniverseDesignIcon
import UniverseDesignInput
import Lottie

class MailClientAdSettingCell: UITableViewCell {

    lazy var titleLabel = self.makeTitleLabel()
    private func makeTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .left
        return label
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        selectionStyle = .none
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalTo(contentView.snp.top).offset(13)
            make.height.equalTo(20)
        }
    }
}

protocol MailClientAdSettingInputDelegate: AnyObject {
    func didSelectTextField(_ textField: UITextField, cell: MailClientAdSettingInputCell, editEnable: Bool)
    func focusToNextInput()
}

class MailClientAdSettingInputCell: MailClientAdSettingCell, UDTextFieldDelegate {
    let disposeBag = DisposeBag()

    lazy var textField: UDTextField = {
        var config = UDTextFieldUIConfig(isShowBorder: false,
                                         clearButtonMode: .whileEditing,
                                         textColor: UIColor.ud.textTitle,
                                         font: UIFont.systemFont(ofSize: 16.0, weight: .regular))
        let textField = UDTextField(config: config)
        textField.tintColor = UIColor.ud.functionInfoContentDefault
        textField.input.clearButtonMode = .whileEditing
        textField.input.addTarget(self, action: #selector(handleTextChange(sender:)), for: .editingChanged)
        textField.delegate = self
        textField.input.returnKeyType = .done
        textField.input.autocorrectionType = .no
        textField.input.autocapitalizationType = .none
        textField.input.spellCheckingType = .no
        return textField
     }()

    private lazy var tipsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.functionDangerContentDefault
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    var addressInput = false
    var showErrorTips = false
    var hideErrorTips = false
    var shouldDetectAddress = false
    var pwdInput = false {
        didSet {
            textField.input.returnKeyType = pwdInput ? .done : .next
            refreshInputIfNeeded()
        }
    }
    var numberOnly = false {
        didSet {
            if numberOnly {
                textField.input.keyboardType = .numberPad
            } else {
                textField.input.keyboardType = .default
            }
        }
    }
    var inputModel: MailSettingInputModel? {
        item as? MailSettingInputModel
    }
    var editEnable = true
    var updateErrorTip: ((String?) -> Void)?
    private var infoButtonClick: (() -> Void)?
    private var pwdPreview = false
    private lazy var pwdPreviewButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.invisibleOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ud.iconN2
        button.addTarget(self, action: #selector(pwdPreviewClick), for: .touchUpInside)
        return button
    }()

    // freebind场景title可点击
    private lazy var titleInfoButton: UIButton = {
        let button = UIButton(type: .custom)
        let font = UIFont.systemFont(ofSize: 14)
        button.setImage(UDIcon.infoOutlined.ud.withTintColor(UIColor.ud.iconN3).ud.resized(to: CGSize(width: 16, height: 16)), for: .normal)
        button.titleLabel?.font = font
        button.setTitleColor(UIColor.ud.textCaption, for: .normal)
        button.addTarget(self, action: #selector(infoClick), for: .touchUpInside)
        return button
    }()

    weak var delegate: MailClientAdSettingInputDelegate?
    var item: MailSettingItemProtocol? {
        didSet {
            setCellInfo()
        }
    }

    func setCellInfo() {
        if let currItem = inputModel {
            setupTitle(titleType: currItem.title)
            textField.placeholder = currItem.placeholder
            if !currItem.content.isEmpty {
                textField.text = currItem.content
            }
            if let error = currItem.errorTip, !error.isEmpty {
                showDetectTips(error)
            } else {
                detectInputAndUpdateUIIfNeeded()
            }
        }
    }

    private func setupTitle(titleType: MailSettingInputModel.TitleType) {
        switch titleType {
        case let .infoButton(title, clickBlock):
            titleInfoButton.isHidden = false
            titleLabel.isHidden = true
            infoButtonClick = clickBlock
            configInfoButton(title: title)
        case let .normal(title):
            titleInfoButton.isHidden = true
            titleLabel.isHidden = false
            titleLabel.text = title
            infoButtonClick = nil
        }
    }


    private func configInfoButton(title: String) {
        titleInfoButton.setTitle(title, for: .normal)
        let font = UIFont.systemFont(ofSize: 14)
        let textWidth = title.getWidth(font: font)
        let iconWidth = 16.0
        let space = 2.0
        titleInfoButton.imageEdgeInsets = UIEdgeInsets(top: space, left: textWidth + space, bottom: space, right: -(textWidth + space))
        titleInfoButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -(iconWidth + space), bottom: 0, right: iconWidth + space)
        titleInfoButton.hitTestEdgeInsets = UIEdgeInsets(edges: -5)
    }


    @objc
    func pwdPreviewClick() {
        pwdPreview.toggle()
        let icon = pwdPreview ? UDIcon.visibleOutlined : UDIcon.invisibleOutlined
        pwdPreviewButton.setImage(icon.withRenderingMode(.alwaysTemplate), for: .normal)
        textField.input.isSecureTextEntry = !pwdPreview
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        contentView.addSubview(textField)
        textField.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-12)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.height.equalTo(22)
        }
        tipsLabel.isHidden = true
        contentView.addSubview(tipsLabel)
        tipsLabel.snp.makeConstraints { make in
            make.left.equalTo(contentView.snp.left).offset(16)
            make.right.equalTo(contentView.snp.right).offset(-16)
            make.top.equalTo(textField.snp.bottom).offset(0)
            make.bottom.equalTo(contentView.snp.bottom).offset(-12).priority(.high)
        }

        contentView.addSubview(titleInfoButton)
        titleInfoButton.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(contentView.snp.top).offset(13)
            make.height.equalTo(20)
        }
    }

    func refreshInputIfNeeded() {
        if pwdInput {
            let rightView = UIImageView(image: UDIcon.activityColorful.ud.resized(to: CGSize(width: 20, height: 20)))
            rightView.isHidden = true
            textField.setRightView(rightView)
            textField.input.isSecureTextEntry = true
            textField.addSubview(pwdPreviewButton)
            pwdPreviewButton.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.right.equalTo(-4)
                make.width.height.equalTo(20)
            }
            textField.setNeedsLayout()
        }
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textField.text = nil
        detectInputAndUpdateUIIfNeeded()
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if self.textField.isFirstResponder {
            detectInputAndUpdateUIIfNeeded()
        }
        if addressInput {
            delegate?.focusToNextInput()
        }
        return true
    }

    @objc
    func handleTextChange(sender: UITextField) {
        if let inputItem = inputModel, let text = textField.text {
            inputItem.textfieldHandler(text)
            //detectAddressAndUpdateUIIfNeeded()
        }
    }

    @objc
    func infoClick(sender: UIButton) {
        infoButtonClick?()
    }

    func detectInputAndUpdateUIIfNeeded() {
        guard shouldDetectAddress || !addressInput, let validateBlock = inputModel?.validateInputBlock else {
            return
        }
        guard !hideErrorTips else {
            hideDetectTips(clear: false)
            return
        }
        guard let input = textField.text, !input.isEmpty else { return }
        if let errorTip = validateBlock(input) {
            showDetectTips(errorTip)
        } else {
            hideDetectTips(clear: true)
        }
    }
    
    func showDetectTips(_ text: String) {
        showErrorTips = true
        tipsLabel.text = text
        tipsLabel.isHidden = false
        tipsLabel.sizeToFit()
        updateErrorTip?(text)
        tipsLabel.snp.updateConstraints { make in
            make.top.equalTo(textField.snp.bottom).offset(8)
        }
    }

    private func hideDetectTips(clear: Bool) {
        showErrorTips = false
        tipsLabel.text = ""
        tipsLabel.isHidden = true
        tipsLabel.sizeToFit()
        tipsLabel.snp.updateConstraints { make in
            make.top.equalTo(textField.snp.bottom).offset(0)
        }
        if clear {
            updateErrorTip?(nil)
        }
    }

    // 合法性校验
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentCount = textField.text?.count ?? 0
        if currentCount + string.count > 205 {
            if let window = textField.window {
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Signature_Toast, on: window,
                                       event: ToastErrorEvent(event: .signature_edit_max_characters))
            }
            return false
        }
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        tipsLabel.isHidden = true
        delegate?.didSelectTextField(textField, cell: self, editEnable: editEnable)
        return editEnable
    }
}

protocol MailClientAdSettingSelectionDelegate: AnyObject {
    func didSelectProtocol()
    func didSelectEncryption(_ type: MailClientAdSettingSelectionCell.ClientSelectType, cell: MailClientAdSettingCell)
}

class MailClientAdSettingSelectionCell: MailClientAdSettingCell {

    enum ClientSelectType {
        case unknown
        case sender
        case receiver
        case proto
    }

    private lazy var selectionButton: UIButton = {
        var selectionButton = UIButton(type: .custom)
        selectionButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        selectionButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        selectionButton.contentHorizontalAlignment = .left
        selectionButton.addTarget(self, action: #selector(selectBtnClick), for: .touchUpInside)
//        selectionButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -1)
        selectionButton.titleLabel?.lineBreakMode = .byTruncatingTail
        return selectionButton
     }()

    weak var delegate: MailClientAdSettingSelectionDelegate?
    var item: MailSettingItemProtocol? {
        didSet {
            setCellInfo()
        }
    }
    var type: ClientSelectType = .unknown
    let arrowIcon = UIImageView(image: UDIcon.downBoldOutlined.withRenderingMode(.alwaysTemplate))

    @objc
    func selectBtnClick() {
        if let currItem = item as? MailClientSettingProtocolModel {
            delegate?.didSelectProtocol()
        } else if let currItem = item as? MailClientSettingEncryptionModel {
            delegate?.didSelectEncryption(type, cell: self)
        }
    }

    func setCellInfo() {
        if let currItem = item as? MailClientSettingProtocolModel {
            titleLabel.text = currItem.title
            selectionButton.setTitle(currItem.proto.title(), for: .normal)
            arrowIcon.isHidden = true
        } else if let currItem = item as? MailClientSettingEncryptionModel {
            titleLabel.text = currItem.title
            selectionButton.isUserInteractionEnabled = currItem.canSelect
            selectionButton.setTitle(currItem.encryption.rawValue, for: .normal)
            arrowIcon.isHidden = !currItem.canSelect
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        contentView.addSubview(selectionButton)
        titleLabel.sizeToFit()
        selectionButton.snp.makeConstraints { make in
            make.left.right.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.height.equalTo(22)
            make.bottom.equalTo(contentView.snp.bottom).offset(-13)
        }

        arrowIcon.tintColor = UIColor.ud.iconN2
        arrowIcon.isUserInteractionEnabled = false
        arrowIcon.contentMode = .scaleAspectFit
        selectionButton.addSubview(arrowIcon)
        arrowIcon.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(-4)
            make.width.height.equalTo(12)
        }
    }
}
