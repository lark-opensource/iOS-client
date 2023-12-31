//
//  TopStructureTeamConversionBanner.swift
//  LarkContact
//
//  Created by Meng on 2020/2/29.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

extension TopStructureTeamConversionBanner {
    enum Layout {
        static let minHeight: CGFloat = 140.0
        static let horizontalPadding: CGFloat = 16.0
        static let verticalPadding: CGFloat = 20.0

        static let leftTrailing: CGFloat = 16.0
        static let titleWidth: CGFloat = 216.0
        static let entryTop: CGFloat = 12.0
        static let detailTop: CGFloat = 4.0
        static let entryContentInset = UIEdgeInsets(top: 4.0, left: 16.0, bottom: 4.0, right: 16.0)
        static let iconSize = CGSize(width: 108.0, height: 100.0)
        static let closeSize = CGSize(width: 16.0, height: 16.0)
        static let closePadding: CGFloat = 8.0
    }
    enum Style {
        static let cornerRadius: CGFloat = 8.0
        static let backgroundColor = UIColor.ud.N00
        static let shadowOffset = CGSize(width: 0.0, height: 2.0)
        static let shadowRadius: CGFloat = 10.0
        static let shadowColor = UIColor.ud.N900.withAlphaComponent(0.1)

        static let titleFont: UIFont = .systemFont(ofSize: 16.0, weight: .semibold)
        static let titleColor = UIColor.ud.N900

        static let detailFont: UIFont = .systemFont(ofSize: 12.0)
        static let detailColor = UIColor.ud.N500

        static let entryBackgroundColor = UIColor.ud.colorfulBlue
        static let entryCornerRadius: CGFloat = 14.0
        static let entryTitleColor = UIColor.ud.N00
        static let entryFont: UIFont = .systemFont(ofSize: 14.0, weight: .medium)
    }
    enum Text {
        static var title: String {
            BundleI18n.LarkContact.Lark_Chat_ContactsPageUpgradeToTeamEditionBannerTitle
        }
        static var detail: String {
            BundleI18n.LarkContact.Lark_Chat_ContactsPageUpgradeToTeamEditionBannerContent()
        }
        static var entryTitle: String {
            BundleI18n.LarkContact.Lark_Chat_ContactsPageUpgradeToTeamEditionBannerButton
        }
    }
}

final class TopStructureTeamConversionBanner: UIControl {
    private let leftContent = UIStackView(frame: .zero)

    private let titleLabel = UILabel(frame: .zero)
    private let detailLabel = UILabel(frame: .zero)
    private let entryButton = UIButton(frame: .zero)

    private let iconView = UIImageView(frame: .zero)
    private let closeButton = UIButton(frame: .zero)

    var entryHandler: (() -> Void)?
    var closeHandler: (() -> Void)?

    private let disposeBag = DisposeBag()

    init() {
        super.init(frame: .zero)
        setupViews()
        setupLayouts()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TopStructureTeamConversionBanner {
    private func setupViews() {
        addSubview(leftContent)
        leftContent.addArrangedSubview(titleLabel)
        leftContent.addArrangedSubview(detailLabel)
        leftContent.addArrangedSubview(entryButton)
        addSubview(iconView)
        addSubview(closeButton)

        backgroundColor = Style.backgroundColor
        layer.cornerRadius = Style.cornerRadius
        layer.shadowColor = Style.shadowColor.cgColor
        layer.shadowOffset = Style.shadowOffset
        layer.shadowRadius = Style.shadowRadius
        layer.shadowOpacity = 1.0

        leftContent.axis = .vertical
        leftContent.alignment = .leading
        leftContent.isUserInteractionEnabled = false
        titleLabel.text = Text.title
        titleLabel.font = Style.titleFont
        titleLabel.textColor = Style.titleColor
        detailLabel.text = Text.detail
        detailLabel.font = Style.detailFont
        detailLabel.textColor = Style.detailColor
        detailLabel.numberOfLines = 0
        entryButton.setTitle(Text.entryTitle, for: .normal)
        entryButton.backgroundColor = Style.entryBackgroundColor
        entryButton.layer.cornerRadius = Style.entryCornerRadius
        entryButton.setTitleColor(Style.entryTitleColor, for: .normal)
        entryButton.titleLabel?.font = Style.titleFont
        iconView.image = Resources.team_conversion
        iconView.isUserInteractionEnabled = false
        closeButton.setImage(Resources.team_conversion_close, for: .normal)

        entryButton.rx
            .controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] in
                self?.entryHandler?()
            })
            .disposed(by: disposeBag)
        self.rx
            .controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] in
                self?.entryHandler?()
            })
            .disposed(by: disposeBag)
        closeButton.rx
            .controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] in
                self?.closeHandler?()
            })
            .disposed(by: disposeBag)
    }

    private func setupLayouts() {
        leftContent.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(Layout.horizontalPadding)
            make.trailing.equalTo(iconView.snp.leading).offset(-Layout.leftTrailing)
            make.centerY.equalToSuperview()
        }

        leftContent.setCustomSpacing(Layout.detailTop, after: titleLabel)
        leftContent.setCustomSpacing(Layout.entryTop, after: detailLabel)
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
        }
        detailLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        detailLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        detailLabel.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
        }
        entryButton.setContentHuggingPriority(.required, for: .vertical)
        entryButton.setContentHuggingPriority(.required, for: .horizontal)
        entryButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        entryButton.setContentCompressionResistancePriority(.required, for: .vertical)
        entryButton.contentEdgeInsets = Layout.entryContentInset

        iconView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.size.equalTo(Layout.iconSize)
            make.trailing.equalToSuperview().offset(-Layout.horizontalPadding)
        }

        closeButton.snp.makeConstraints { (make) in
            make.size.equalTo(Layout.closeSize)
            make.top.trailing.equalToSuperview().inset(Layout.closePadding)
        }

        self.snp.makeConstraints { (make) in
            make.bottom.greaterThanOrEqualTo(leftContent.snp.bottom).offset(Layout.horizontalPadding)
            make.height.greaterThanOrEqualTo(Layout.minHeight)
        }
    }
}
