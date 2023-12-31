//
//  AliasInputView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2019/12/15.
//

import Foundation
import UniverseDesignFont
import UniverseDesignIcon
import RxSwift

class AliasInputView: UIView {

    var actionHandler: (() -> Void)?

    var aliasAddress = MailAddress(name: "", address: "", larkID: "", tenantId: "", displayName: "", type: nil)

    private var fieldLabel = UILabel()
    private var aliasButton = UIButton()
    private var arrowIcon = UIImageView()
    private let attachImage = NSTextAttachment()
    private var isExpanding = false

    private lazy var tapGesture = UITapGestureRecognizer()
    private let disposeBag = DisposeBag()

    var showArrow: Bool = true {
        didSet {
            arrowIcon.isHidden = !showArrow
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()

        tapGesture.rx.event.asObservable().subscribe(onNext: { [weak self] recognizer in
            self?.aliasButtonClicked()
        }).disposed(by: disposeBag)
        self.addGestureRecognizer(tapGesture)
        self.isUserInteractionEnabled = true
    }

    private func setupViews() {
        backgroundColor = UIColor.ud.bgBody

        fieldLabel.translatesAutoresizingMaskIntoConstraints = false
        fieldLabel.font = UIFont.systemFont(ofSize: 14)
        fieldLabel.textColor = UIColor.ud.textCaption
        fieldLabel.text = BundleI18n.MailSDK.Mail_Normal_FromColon
        fieldLabel.sizeToFit()

        aliasButton.contentHorizontalAlignment = .left
        aliasButton.isUserInteractionEnabled = false

        arrowIcon.image = UDIcon.avSetDownOutlined.withRenderingMode(.alwaysTemplate)
        arrowIcon.tintColor = UIColor.ud.iconN3
        arrowIcon.isUserInteractionEnabled = false

        addSubview(fieldLabel)
        addSubview(aliasButton)
        addSubview(arrowIcon)
    }

    @objc
    func aliasButtonClicked() {
        actionHandler?()
        isExpanding = true
    }

    private func setupLayout() {
        let width = self.getFieldLabelWidth()
        fieldLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(width)
        }
        aliasButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(fieldLabel.snp.right).offset(8)
            make.right.equalToSuperview().offset(-39)
        }
        arrowIcon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(14)
            make.right.equalTo(-21)
        }
    }

    func resetAddress(nickName: String, addressName: String) {
        isExpanding = false
        let attributeString = NSMutableAttributedString()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail // .byWordWrapping
        paragraphStyle.lineSpacing = 3.0
        let addressNameString = NSAttributedString(string: nickName + " " + "<\(addressName)>",
                                                   attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .regular),
                                                                .foregroundColor: UIColor.ud.textPlaceholder,
                                                                .paragraphStyle: paragraphStyle])

        attributeString.append(addressNameString)
        attributeString.addAttribute(.foregroundColor, value: UIColor.ud.textTitle, range: NSRange(location: 0, length: nickName.utf16.count))

        aliasButton.setAttributedTitle(attributeString, for: .normal)
        aliasButton.titleLabel?.lineBreakMode = .byTruncatingTail
        aliasButton.titleLabel?.numberOfLines = 1
        aliasAddress.name = nickName
        aliasAddress.address = addressName
//        aliasButton.titleLabel?.sizeToFit()

        // 设置button内容居中
        let titleSize = aliasButton.titleLabel?.bounds.size
        let buttonSize = aliasButton.bounds.size

        let textWidth = addressNameString.string.getTextWidth() // + nickNameString.string.getTextWidth()

        // 右侧箭头自适应邮件地址
        let maxWidth = UIScreen.main.bounds.width - 32 - self.getFieldLabelWidth() - 36
        let attrSize = attributeString.boundingRect(with: CGSize(width: maxWidth, height: CGFloat(MAXFLOAT)),
                                                    options: [.usesFontLeading, .usesLineFragmentOrigin],
                                                    context: nil)
        var nickNameWidth: CGFloat = (nickName.contains(" ") ? 16 : 0)
        if textWidth < attrSize.width {
            nickNameWidth += nickName.getTextWidth() + 4
        } else {
            nickNameWidth += 6
        }
    }

    func getFieldLabelWidth() -> CGFloat {
        var width = fieldLabel.bounds.size.width
        if width <= 0 {
            width = fieldLabel.text?.getTextWidth() ?? 0
        }
        return ceil(width)
    }

    func cancel() {
        resetAddress(nickName: aliasAddress.name, addressName: aliasAddress.address)
        isExpanding = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension String {
    func getTextWidth(fontSize: CGFloat = 14, height: CGFloat = 15) -> CGFloat {
        let font = UIFont.systemFont(ofSize: fontSize, weight: .regular)
        return getTextWidth(font: font, height: height)
    }

    func getTextWidth(font: UIFont, height: CGFloat) -> CGFloat {
        let rect = NSString(string: self).boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: height),
                                                       options: [.usesFontLeading, .usesLineFragmentOrigin],
                                                       attributes: [NSAttributedString.Key.font: font],
                                                       context: nil)
        return ceil(rect.width)
    }

    func getTextHeight(font: UIFont = UIFont.systemFont(ofSize: 14.0), width: CGFloat = 300) -> CGFloat {
        let rect = NSString(string: self).boundingRect(with: CGSize(width: width, height: CGFloat(MAXFLOAT)),
                                                       options: [.usesFontLeading, .usesLineFragmentOrigin],
                                                       attributes: [NSAttributedString.Key.font: font],
                                                       context: nil)
        return ceil(rect.height)
    }
}
