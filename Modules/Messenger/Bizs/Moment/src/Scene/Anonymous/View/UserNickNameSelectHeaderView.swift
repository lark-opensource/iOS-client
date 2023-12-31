//
//  UserNickNameSelectHeaderView.swift
//  Moment
//
//  Created by liluobin on 2021/5/23.
//

import Foundation
import UIKit
import SnapKit
import LarkBizAvatar
import LarkInteraction

final class UserNickNameSelectHeaderView: UICollectionReusableView {
    static let reuseId: String = "UserNickNameSelectHeaderView"
    lazy var iconView: BizAvatar = {
        let view = BizAvatar()
        return view
    }()

    private lazy var refreshBtn: NickNameRefreshButton = {
        let btn = NickNameRefreshButton(centerOffSetRatio: 0.9)
        btn.setImage(Resources.refreshNormal, for: .normal)
        btn.setImage(Resources.refreshHighLight, for: .highlighted)
        btn.addTarget(self, action: #selector(btnClick), for: .touchUpInside)
        btn.addPointer(.lift)
        return btn
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textAlignment = .center
        label.textColor = UIColor.ud.textDisable
        label.font = UserNickNameHeaderLayout.titleFont
        label.backgroundColor = .clear
        label.numberOfLines = 0
        return label
    }()

    private lazy var lineView: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.bgBase
        return line
    }()

    private lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.Moment.Lark_Community_NicknameOnceAYearDesc
        label.textColor = UIColor.ud.textCaption
        label.font = UserNickNameHeaderLayout.tipFont
        label.backgroundColor = .clear
        label.numberOfLines = 0
        return label
    }()
    var viewModel: UserNickNameSelectHeaderViewModel? {
        didSet {
            updateUI()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = UIColor.ud.bgBody
        addSubview(iconView)
        iconView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(UserNickNameHeaderLayout.iconTopSpace)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(UserNickNameHeaderLayout.iconHeight)
        }
        addSubview(refreshBtn)
        let size = refreshBtn.image(for: .normal)?.size ?? CGSize(width: 36, height: 36)
        refreshBtn.snp.makeConstraints { (make) in
            make.size.equalTo(size)
            make.bottom.equalTo(iconView.snp.bottom).offset(5)
            make.right.equalTo(iconView.snp.right).offset(10)
        }
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(iconView.snp.bottom).offset(UserNickNameHeaderLayout.titleTopSpace)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(25)
        }
        addSubview(lineView)
        lineView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(UserNickNameHeaderLayout.lineViewTopSpace)
            make.height.equalTo(UserNickNameHeaderLayout.lineViewHeight)
        }
        addSubview(tipLabel)
        tipLabel.snp.makeConstraints { (make) in
            make.top.equalTo(lineView.snp.bottom).offset(UserNickNameHeaderLayout.tipLabelTopSpace)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(23)
        }
    }

    private func updateUI() {
        guard let vm = viewModel, let layout = vm.layout else { return }
        titleLabel.text = vm.nickNameData?.nickname ?? layout.defaultTitle
        titleLabel.textColor = titleLabel.text == layout.defaultTitle ? UIColor.ud.textDisable : UIColor.ud.textTitle
        titleLabel.snp.updateConstraints { (make) in
            make.height.equalTo(layout.titleHeight)
        }
        tipLabel.snp.updateConstraints { (make) in
            make.height.equalTo(layout.tipHeight)
        }

        if let key = self.viewModel?.selectedIcon {
            iconView.setAvatarByIdentifier(MomentsGlobalConfigs.entityEmpty, avatarKey: key, scene: .Moments)
        }
    }

    @objc
    private func btnClick() {
        refreshBtn.showLoading(true)
        viewModel?.refreshIcon { [weak self] _ in
            self?.iconView.setAvatarByIdentifier(MomentsGlobalConfigs.entityEmpty, avatarKey: self?.viewModel?.selectedIcon ?? "", scene: .Moments)
            self?.refreshBtn.showLoading(false)
        }
    }
}
