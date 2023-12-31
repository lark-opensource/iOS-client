//
//  MomentsNickNameViewPersonInfoVC.swift
//  Moment
//
//  Created by ByteDance on 2022/7/21.
//
import Foundation
import UniverseDesignTabs
import LarkUIKit
import SnapKit
import EENavigator
import UIKit
import SwiftUI

final class MomentsNickNameViewPersonInfoVC: UIViewController, UDTabsListContainerViewDelegate, UITableViewDelegate, UITableViewDataSource {
    let viewModel: MomentsNickNamePersonInfoViewModel
    init(viewModel: MomentsNickNamePersonInfoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    weak var delegate: PostListVCDelegate?
    var privacyPolicyTapCallBack: ((_ url: URL) -> Void)?

    let personalInfoDescription: String = BundleI18n.Moment.Moments_NicknameProfilePage_NicknameInfoDesc
    enum Cons {
        static var sideMargin: CGFloat { 16 }
        static var labelbetweenIcon: CGFloat { 2 }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var personInfoTableView: MomentLinkagePostTableView = {
        let personInfoTableView = MomentLinkagePostTableView()
        personInfoTableView.enableTopPreload = false
        personInfoTableView.delegate = self
        personInfoTableView.dataSource = self
        personInfoTableView.showsHorizontalScrollIndicator = false
        personInfoTableView.showsVerticalScrollIndicator = false
        personInfoTableView.backgroundColor = UIColor.clear
        personInfoTableView.rowHeight = UITableView.automaticDimension
        personInfoTableView.separatorStyle = .singleLine
        personInfoTableView.bounces = false
        personInfoTableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        personInfoTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0.01, height: 12))
        registerTableViewCell(personInfoTableView)
        return personInfoTableView
    }()

    private lazy var footerView: UIView = {
        return UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width - 2 * Cons.sideMargin, height: getFooterHeight(self.view.frame.width)))
    }()

    private lazy var privacyPolicyDescriptionView = UIView()

    private lazy var privacyPolicyDescriptionLabel: UILabel = {
        let personalInfoDescriptionLabel = UILabel()
        personalInfoDescriptionLabel.textColor = UIColor.ud.textPlaceholder
        personalInfoDescriptionLabel.font = .systemFont(ofSize: 12)
        personalInfoDescriptionLabel.text = personalInfoDescription
        personalInfoDescriptionLabel.isUserInteractionEnabled = true
        personalInfoDescriptionLabel.numberOfLines = 0
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        personalInfoDescriptionLabel.addGestureRecognizer(tap)
        return personalInfoDescriptionLabel
    }()

    private lazy var rightArrow: UIImageView = {
        let rightArrow = UIImageView()
        rightArrow.image = Resources.personInfoRightOutlined
        return rightArrow
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        viewModel.getNickNamePersonInfo(finishCallBack: { [weak self] in
            self?.personInfoTableView.reloadData()
        })
    }

    private func setupView() {
        self.view.backgroundColor = UIColor.ud.bgBase
        self.view.addSubview(personInfoTableView)
        personInfoTableView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(Cons.sideMargin)
            make.right.equalToSuperview().offset(-Cons.sideMargin)
        }
        personInfoTableView.tableFooterView = footerView
        footerView.addSubview(privacyPolicyDescriptionView)
        privacyPolicyDescriptionView.addSubview(privacyPolicyDescriptionLabel)
        privacyPolicyDescriptionView.addSubview(rightArrow)
        privacyPolicyDescriptionView.snp.makeConstraints { (make) in
            make.top.equalTo(footerView.snp.top).offset(32)
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.centerX.equalToSuperview()
        }
        privacyPolicyDescriptionLabel.snp.makeConstraints { (make) in
            make.top.left.bottom.equalToSuperview()
        }
        rightArrow.snp.makeConstraints { (make) in
            make.centerY.equalTo(privacyPolicyDescriptionLabel)
            make.left.equalTo(privacyPolicyDescriptionLabel.snp.right).offset(2)
            make.right.equalToSuperview()
        }
    }

    func getFooterHeight(_ maxWidth: CGFloat) -> CGFloat {
        /// footer高度为label高度加上32的偏移量
        /// 12为icon的宽度
        let labelWidth = maxWidth - 2 * Cons.sideMargin - Cons.labelbetweenIcon - 12
        let height = MomentsDataConverter.heightForString(personalInfoDescription, onWidth: labelWidth, font: .systemFont(ofSize: 12))
        return height + 32
    }

    private func registerTableViewCell(_ tableView: UITableView) {
        tableView.register(MomentsNickNameViewPersonInfoCell.self, forCellReuseIdentifier: MomentsNickNameViewPersonInfoCell.lu.reuseIdentifier)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        footerView.frame = CGRect(x: footerView.frame.origin.x,
                                  y: footerView.frame.origin.y,
                                  width: footerView.frame.width,
                                  height: self.getFooterHeight(self.view.frame.width))
    }

    @objc
    private func tapped() {
        guard let url = URL(string: viewModel.nickNameProfile.privacyPolicyUrl) else { return }
        privacyPolicyTapCallBack?(url)
        MomentsTracer.trackFeedPageViewClick(.personal_information,
                                             circleId: viewModel.config?.circleID ?? "",
                                             type: .moments_profile,
                                             detail: nil,
                                             profileInfo: MomentsTracer.ProfileInfo(profileUserId: viewModel.userId,
                                                                                    isFollow: false,
                                                                                    isNickName: true,
                                                                                    isNickNameInfoTab: true))
    }

    func listView() -> UIView {
        return self.view
    }

    func listWillAppear() {
        self.delegate?.listWillAppear(personInfoTableView)
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.nickNameProfile.nickNamePersonInfo.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let momentsNickNameViewPersonInfoCell = personInfoTableView.dequeueReusableCell(withIdentifier: MomentsNickNameViewPersonInfoCell.lu.reuseIdentifier,
                                                                                        for: indexPath) as? MomentsNickNameViewPersonInfoCell
        momentsNickNameViewPersonInfoCell?.title.text = viewModel.nickNameProfile.nickNamePersonInfo[indexPath.row].title
        momentsNickNameViewPersonInfoCell?.subTitle.text = viewModel.nickNameProfile.nickNamePersonInfo[indexPath.row].subTitle
        momentsNickNameViewPersonInfoCell?.clipsToBounds = true
        guard viewModel.nickNameProfile.nickNamePersonInfo.count > 1 else {
            momentsNickNameViewPersonInfoCell?.layer.cornerRadius = 10
            momentsNickNameViewPersonInfoCell?.layer.maskedCorners = [.layerMinXMinYCorner,
                                                                      .layerMaxXMinYCorner,
                                                                      .layerMinXMaxYCorner,
                                                                      .layerMaxXMaxYCorner]
            return momentsNickNameViewPersonInfoCell ?? MomentsNickNameViewPersonInfoCell()
        }
        if indexPath.row == 0 {
            momentsNickNameViewPersonInfoCell?.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            momentsNickNameViewPersonInfoCell?.layer.cornerRadius = 10
        } else if indexPath.row == viewModel.nickNameProfile.nickNamePersonInfo.count - 1 {
            momentsNickNameViewPersonInfoCell?.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
            momentsNickNameViewPersonInfoCell?.layer.cornerRadius = 10
        } else {
            momentsNickNameViewPersonInfoCell?.layer.cornerRadius = 0
        }
        return momentsNickNameViewPersonInfoCell ?? MomentsNickNameViewPersonInfoCell()
    }
}
