//
//  MinutesClipNavigationBar.swift
//  Minutes
//
//  Created by panzaofeng on 2022/5/6.
//

import Foundation
import MinutesFoundation
import UniverseDesignColor
import UniverseDesignIcon
import RichLabel
import UIKit

protocol MinutesClipNavigationBarDelegate: AnyObject {
    func navigationBack(_ view: MinutesClipNavigationBar)
    func navigationMore(_ view: MinutesClipNavigationBar)
    func navigationBackToMinutes()

}

public final class MinutesClipNavigationBar: UIView {

    weak var delegate: MinutesClipNavigationBarDelegate?

    private let contentView = UIView()

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()

    private enum Layout {
        static let enlargeRegionInsets = UIEdgeInsets(top: 7,
                                                      left: 7,
                                                      bottom: 7,
                                                      right: 7)
    }

    private lazy var backButton: EnlargeTouchButton = {
        let button: EnlargeTouchButton = EnlargeTouchButton(type: .custom)
        button.enlargeRegionInsets = Layout.enlargeRegionInsets
        button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        button.addTarget(self, action: #selector(onClickBackButton(_:)), for: .touchUpInside)
        return button
    }()

    lazy var moreButton: EnlargeTouchButton = {
        let button: EnlargeTouchButton = EnlargeTouchButton(type: .custom)
        button.enlargeRegionInsets = Layout.enlargeRegionInsets
        button.setImage(UDIcon.getIconByKey(.moreOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        button.addTarget(self, action: #selector(onClickMoreButton(_:)), for: .touchUpInside)
        return button
    }()

    private(set) lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 1
        return titleLabel
    }()

    private lazy var tagLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .medium)
        l.textColor = UIColor.ud.udtokenTagTextSPurple
        l.backgroundColor = UIColor.ud.udtokenTagBgPurple.withAlphaComponent(0.2)
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        l.text = " \(BundleI18n.Minutes.MMWeb_G_Clip) "
        return l
    }()

    lazy var titleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 6
        stackView.distribution = .fillProportionally

        stackView.addArrangedSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.height.equalTo(22)
        }
        
        stackView.addArrangedSubview(tagLabel)
        tagLabel.snp.makeConstraints { (make) in
            make.height.equalTo(16)
        }

        titleLabel.isHidden = true
        tagLabel.isHidden = true
        return stackView
    }()

    lazy var subTitleLabel: LKLabel = {
        let label = LKLabel()
        label.backgroundColor = .clear
        label.numberOfLines = 1
        label.isUserInteractionEnabled = true

        let jumpToFull: String = BundleI18n.Minutes.MMWeb_G_JumpToFull
        let length = NSString(string: jumpToFull).length
        let range = NSRange(location: 0, length: length)
        var link = LKTextLink(range: range,
                              type: .link,
                              attributes: [.foregroundColor: UIColor.ud.textLinkNormal,
                                           .font: UIFont.systemFont(ofSize: 12)],
                              activeAttributes: [.backgroundColor: UIColor.clear])
        link.linkTapBlock = { [weak self] (_, link: LKTextLink) in
            self?.delegate?.navigationBackToMinutes()
        }

        label.addLKTextLink(link: link)

        let attributedString = NSAttributedString(string: jumpToFull,
                                                  attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                               .foregroundColor: UIColor.ud.textPlaceholder])
        label.attributedText = attributedString

        return label
    }()

    private lazy var backView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.addSubview(backButton)
        backButton.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        return v
    }()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.addArrangedSubview(titleStackView)
        titleStackView.snp.makeConstraints { (maker) in
            maker.height.equalTo(22)
        }
        stackView.addArrangedSubview(subTitleLabel)
        subTitleLabel.snp.makeConstraints { (make) in
            make.height.equalTo(20)
        }

        subTitleLabel.isHidden = true
        return stackView
    }()

    var isTitleShow: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody
        addSubview(contentView)
        contentView.snp.makeConstraints { (maker) in
            maker.left.bottom.right.equalToSuperview()
            maker.height.equalTo(44)
        }

        contentView.addSubview(moreButton)
        moreButton.snp.makeConstraints { (maker) in
            maker.trailing.equalToSuperview().offset(-20)
            maker.bottom.equalToSuperview().offset(-12)
            maker.width.equalTo(24)
            maker.height.equalTo(24)
        }

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().offset(20)
            maker.height.equalTo(42)
            maker.bottom.equalToSuperview().offset(-5)
            maker.trailing.equalTo(moreButton.snp.leading).offset(-10)
        }

        stackView.insertArrangedSubview(textStackView, at: 0)
        textStackView.snp.makeConstraints { (maker) in
            maker.height.equalTo(42)
        }

        stackView.insertArrangedSubview(backView, at: 0)
        backView.snp.makeConstraints { (maker) in
            maker.width.equalTo(24)
            maker.height.equalTo(24)
        }
        stackView.setCustomSpacing(8, after: backView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func changeTitle(_ title: String) {
        titleLabel.text = title
    }

    func showTitle() {
        if isTitleShow { return }
        titleLabel.isHidden = false
        tagLabel.isHidden = false
        subTitleLabel.isHidden = false
        isTitleShow = true
    }

    func hideTitle() {
        if !isTitleShow { return }
        titleLabel.isHidden = true
        tagLabel.isHidden = true
        subTitleLabel.isHidden = true
        isTitleShow = false
    }
}

extension MinutesClipNavigationBar {
    @objc
    func onClickBackButton(_ sender: UIButton) {
        self.delegate?.navigationBack(self)
    }

    @objc
    func onClickMoreButton(_ sender: UIButton) {
        self.delegate?.navigationMore(self)
    }

}
