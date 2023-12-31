//
//  RiskRemindView.swift
//  LarkAccount
//
//  Created by au on 2023/05/17.
//

import UIKit
import UniverseDesignEmpty
import UniverseDesignFont
import LarkIllustrationResource

/// 风险提示 view
final class RiskRemindView: UIView {

    let title: String?
    let subtitle: String?
    let descList: [String]?

    init(title: String?, subtitle: String?, descList: [String]?) {
        self.title = title
        self.subtitle = subtitle
        self.descList = descList
        super.init(frame: .zero)

        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = UIColor.clear

        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)

        titleLabel.text = title

        let centerStyle = NSMutableParagraphStyle()
        centerStyle.alignment = NSTextAlignment.center
        centerStyle.lineSpacing = 4
        let rawAttrSubtitle = (subtitle ?? "").html2Attributed(font: UDFont.body0, forgroundColor: UIColor.ud.textCaption)
        let attrSubtitle = NSMutableAttributedString(attributedString: rawAttrSubtitle)
        attrSubtitle.addAttributes([NSAttributedString.Key.paragraphStyle: centerStyle], range: NSRange(location: 0, length: attrSubtitle.length))
        subtitleLabel.attributedText = attrSubtitle

        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(100)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
            if (descList?.isEmpty ?? true) {
                make.bottom.equalToSuperview().inset(24)
            }
        }

        setupInfoView()
    }

    func setupInfoView() {
        // 没有 desc 时，不添加内容
        guard let infos = descList, !infos.isEmpty else {
            return
        }

        let count = infos.count

        let infoBackgroundView = UIView()
        infoBackgroundView.layer.cornerRadius = 8
        infoBackgroundView.backgroundColor = UIColor.ud.bgBodyOverlay
        addSubview(infoBackgroundView)

        infoBackgroundView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }

        let labels = (0..<count).map { index in
            let desc = infos[index]
            let label = UnorderedListView(desc: desc)
            return label
        }

        let listStack = UIStackView()
        listStack.axis = .vertical
        listStack.alignment = .leading
        listStack.spacing = 12
        labels.forEach { label in
            listStack.addArrangedSubview(label)
        }

        infoBackgroundView.addSubview(listStack)
        listStack.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview().inset(20)
        }
    }

    let imageView: UIImageView = UIImageView(image: EmptyBundleResources.image(named: "adminEmptyNegativeLoginAlert"))

    let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.title3
        return label
    }()

    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
}

final class UnorderedListView: UIView {

    var desc: String?

    let descLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.numberOfLines = 0
        label.font = UDFont.systemFont(ofSize: 16)
        return label
    }()

    init(desc: String?) {
        self.desc = desc
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
            make.width.height.equalTo(20)
        }

        let dot = UIView()
        dot.backgroundColor = UIColor.ud.iconDisabled
        dot.layer.cornerRadius = 3
        dotBackgroudView.addSubview(dot)
        dot.snp.makeConstraints { make in
            make.width.height.equalTo(6)
            make.center.equalToSuperview()
        }

        addSubview(descLabel)
        let pStyle = NSMutableParagraphStyle()
        pStyle.lineSpacing = 4
        let rawAttrDesc = (desc ?? "").html2Attributed(font: UDFont.body0, forgroundColor: UIColor.ud.textCaption)
        let attrDesc = NSMutableAttributedString(attributedString: rawAttrDesc)
        attrDesc.addAttributes([NSAttributedString.Key.paragraphStyle: pStyle], range: NSRange(location: 0, length: attrDesc.length))
        descLabel.attributedText = attrDesc
        descLabel.snp.makeConstraints { make in
            make.top.right.equalToSuperview()
            make.left.equalTo(dotBackgroudView.snp.right)
            make.bottom.equalToSuperview()
        }
    }

    func updateDescLabel(_ attrText: NSAttributedString) {
        descLabel.attributedText = attrText
    }
}
