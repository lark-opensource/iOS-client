//
//  MinutesHomeSubViews.swift
//  Minutes
//
//  Created by Todd Cheng on 2021/3/3.
//

import UIKit
import LarkUIKit
import UniverseDesignColor
import MinutesFoundation
import UniverseDesignEmpty
import MinutesNetwork
import UniverseDesignIcon

class MinutesHomeErrorView: UIView {

    var onClickRefreshButton: (() -> Void)?

    private let errorDeleteEmptyType: UDEmptyType = .noContent

    private lazy var imageView: UIImageView = {
        let imageView: UIImageView = UIImageView(image: errorDeleteEmptyType.defaultImage())
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.text = BundleI18n.Minutes.MMWeb_G_SomethingWentWrong
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 15)
        return label
    }()

    private lazy var refreshButton: UIButton = {
        let button: UIButton = UIButton(type: .system)
        button.setTitle(BundleI18n.Minutes.MMWeb_G_Reload, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.backgroundColor = UIColor.ud.bgBody
        button.layer.cornerRadius = 3
        button.layer.borderWidth = 1
        button.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
        button.addTarget(self, action: #selector(onClickRefreshButton(_:)), for: .touchUpInside)
        return button
    }()

    init() {
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.ud.bgBody

        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(refreshButton)
        
        imageView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview().multipliedBy(0.8)
        }

        titleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(imageView.snp.bottom).offset(10)
            maker.centerX.equalToSuperview()
            maker.width.equalTo(self.bounds.width - 40)
        }

        let label: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.width - 40, height: 1000))
        label.text = titleLabel.text
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14)
        label.sizeToFit()
        let refreshButtonWidth = max(88, label.bounds.width + 20)
        refreshButton.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(24)
            maker.centerX.equalToSuperview()
            maker.width.equalTo(refreshButtonWidth)
            maker.height.equalTo(36)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func onClickRefreshButton(_ sender: UIButton) {
        onClickRefreshButton?()
    }
}

class MinutesHomeEmptyView: UIView {

    private let minutesErrorDeleteEmptyType: UDEmptyType = .noContent

    private let minutesHomeTrashEmptyType: UDEmptyType = .noContent

    private lazy var imageView: UIImageView = {
        let imageView: UIImageView = UIImageView(image: minutesErrorDeleteEmptyType.defaultImage())
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.text = ""
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 15)
        return label
    }()

    var type: MinutesSpaceType = .home {
        didSet {
            switch type {
            case .home:
                titleLabel.text = BundleI18n.Minutes.MMWeb_G_List_NoFilesYet_EmptyState
                imageView.image = minutesErrorDeleteEmptyType.defaultImage()
            case .my:
                titleLabel.text = BundleI18n.Minutes.MMWeb_G_List_NoFilesYet_EmptyState
                imageView.image = minutesErrorDeleteEmptyType.defaultImage()
            case .share:
                titleLabel.text = BundleI18n.Minutes.MMWeb_G_List_NoFilesYet_EmptyState
                imageView.image = minutesErrorDeleteEmptyType.defaultImage()
            case .trash:
                titleLabel.text = BundleI18n.Minutes.MMWeb_G_List_NoFilesYet_EmptyState
                imageView.image = minutesHomeTrashEmptyType.defaultImage()
            }
        }
    }

    var isFilter: Bool = false {
        didSet {
            if isFilter {
                titleLabel.text = BundleI18n.Minutes.MMWeb_G_List_FilterNoResults_EmptyState
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody
        addSubview(imageView)
        addSubview(titleLabel)
        layoutSubviewsManually()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutSubviewsManually() {
        imageView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview().multipliedBy(0.8)
        }

        titleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(imageView.snp.bottom).offset(10)
            maker.left.equalToSuperview().offset(20)
            maker.right.equalToSuperview().offset(-20)
        }
    }
}

class MinutesHomeNoNetworkView: UIView {

    private lazy var imageView: UIImageView = {
        let imageView: UIImageView = UIImageView(image: UDIcon.getIconByKey(.moreCloseOutlined, iconColor: UIColor.ud.functionDangerContentDefault, size: CGSize(width: 16, height: 16)))
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.text = BundleI18n.Minutes.MMWeb_G_NoConnection
        label.numberOfLines = 1
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    init() {
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.ud.functionDangerFillSolid02

        addSubview(imageView)
        addSubview(titleLabel)
        createConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createConstraints() {
        imageView.snp.makeConstraints { maker in
            maker.left.equalToSuperview().offset(16)
            maker.centerY.equalToSuperview()
            maker.width.height.equalTo(16)
        }

        titleLabel.snp.makeConstraints { maker in
            maker.left.equalTo(imageView.snp.right).offset(8)
            maker.centerY.equalToSuperview()
            maker.right.equalToSuperview().offset(-15)
        }
    }
}
