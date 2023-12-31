//
//  OpenAPIAuthScopeListTableViewCell.swift
//  LarkAccount
//
//  Created by au on 2023/6/7.
//

import RxSwift
import RxCocoa
import UIKit
import UniverseDesignFont
import UniverseDesignIcon

class OpenAPIAuthScopeListTableViewCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configCell(authInfo: OpenAPIAuthGetAuthInfo, showCompleteScope: Bool, descButtonAction: @escaping (() -> Void), showMoreButtonAction: @escaping (() -> Void)) {

        contentView.subviews.forEach { view in
            view.removeFromSuperview()
        }

        descButton.rx.tap.bind { _ in
            descButtonAction()
        }
        .disposed(by: disposeBag)
        contentView.addSubview(descButton)
        descButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.left.right.equalToSuperview().inset(16)
        }

        guard let scopeList = authInfo.currentUser?.scopeList, !scopeList.isEmpty else { return }

        let count = scopeList.count

        let infoBackgroundView = UIView()
        infoBackgroundView.backgroundColor = .clear
        contentView.addSubview(infoBackgroundView)

        infoBackgroundView.snp.makeConstraints { make in
            make.top.equalTo(descButton.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(8) // make dots align left side
            make.bottom.equalToSuperview().offset(showCompleteScope ? -8 : -(12 + 22 + 8))
        }

        let showCount = showCompleteScope ? count : 3

        let labels = (0..<showCount).map { index in
            let desc = scopeList[index].desc
            let label = ScopeItemView(content: desc)
            return label
        }

        let listStack = UIStackView()
        listStack.axis = .vertical
        listStack.alignment = .leading
        listStack.distribution = .fillEqually
        listStack.spacing = 12
        labels.forEach { label in
            listStack.addArrangedSubview(label)
        }

        infoBackgroundView.addSubview(listStack)
        listStack.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }

        if !showCompleteScope {
            showMoreButton.rx.tap.bind { _ in
                showMoreButtonAction()
            }
            .disposed(by: disposeBag)
            contentView.addSubview(showMoreButton)
            showMoreButton.snp.makeConstraints { make in
                make.top.equalTo(infoBackgroundView.snp.bottom).offset(12)
                make.left.equalToSuperview().offset(30)
                make.right.equalToSuperview().offset(-16)
                make.height.equalTo(22)
            }
        }

    }

    let descButton: UIButton = {
        let button = UIButton(type: .system)
        let attriTitle = NSMutableAttributedString(string: I18N.Lark_Passport_ThirdPartyAppAuthorization_AuthRequestPage_PermissionListTitle,
                                                   attributes: [NSAttributedString.Key.font: UDFont.systemFont(ofSize: 14),
                                                                NSAttributedString.Key.foregroundColor: UIColor.ud.textCaption])
        let image = BundleResources.UDIconResources.infoOutlined.withRenderingMode(.alwaysTemplate)
        let imageAttachment = NSTextAttachment()
        if #available(iOS 13.0, *) {
            imageAttachment.image = image.withTintColor(UIColor.ud.textCaption)
        } else {
            imageAttachment.image = image
        }
        imageAttachment.bounds = CGRect(x: 0, y: (UDFont.body0.capHeight - image.size.height).rounded() / 2, width: image.size.width, height: image.size.height)
        let imageString = NSAttributedString(attachment: imageAttachment)
        attriTitle.append(NSAttributedString(string: " "))
        attriTitle.append(imageString)
        button.setAttributedTitle(attriTitle, for: [])
        button.contentHorizontalAlignment = .left
        button.titleLabel?.numberOfLines = 0
        return button
    }()

    lazy var showMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(I18N.Lark_Passport_AuthorizedLoginPage_PermissionsList_ViewMorePermissionsButton, for: [])
        button.tintColor = UIColor.ud.primaryPri500
        button.titleLabel?.font = UDFont.systemFont(ofSize: 14)
        button.contentHorizontalAlignment = .left
        return button
    }()

    let disposeBag = DisposeBag()

}

final class ScopeItemView: UIView {

    var content: String?

    let contentLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()

    init(content: String?) {
        self.content = content
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        let dotBackgroudView = UIView()
        dotBackgroudView.backgroundColor = .clear
        addSubview(dotBackgroudView)
        dotBackgroudView.snp.makeConstraints { make in
            make.top.left.equalToSuperview()
            make.width.height.equalTo(22)
        }

        let dot = UIView()
        dot.backgroundColor = UIColor.ud.iconN2
        dot.layer.cornerRadius = 2
        dotBackgroudView.addSubview(dot)
        dot.snp.makeConstraints { make in
            make.width.height.equalTo(4)
            make.center.equalToSuperview()
        }

        addSubview(contentLabel)
        let pStyle = NSMutableParagraphStyle()
        pStyle.lineSpacing = 3
        let rawAttrDesc = (content ?? "").html2Attributed(font: UDFont.systemFont(ofSize: 14), forgroundColor: UIColor.ud.textTitle)
        let attrDesc = NSMutableAttributedString(attributedString: rawAttrDesc)
        attrDesc.addAttributes([NSAttributedString.Key.paragraphStyle: pStyle], range: NSRange(location: 0, length: attrDesc.length))
        contentLabel.attributedText = attrDesc
        contentLabel.snp.makeConstraints { make in
            make.top.right.equalToSuperview()
            make.left.equalTo(dotBackgroudView.snp.right)
            make.bottom.equalToSuperview()
        }
    }
}
