//
//  MomentSettingViewController.swift
//  Moment
//
//  Created by zc09v on 2021/6/11.
//

import Foundation
import LarkUIKit
import RxSwift
import UniverseDesignToast
import FigmaKit
import UIKit
import LarkContainer
import EENavigator
import SwiftUI
import LKCommonsLogging

final class MomentSettingViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate, UserResolverWrapper {
    let userResolver: UserResolver
    private let viewModel: MomentSettingViewModel
    private lazy var tableView = self.createTableView()
    private let disposeBag = DisposeBag()
    private var currenttimeStamp: Int64 {
        return Int64(Date().timeIntervalSince1970)
    }
    static let logger = Logger.log(MomentSettingViewController.self, category: "Module.Moments.Setting")

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.viewModel = MomentSettingViewModel(userResolver: userResolver)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = MomentTab.tabTitle()
        /// 添加表格视图
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        self.viewModel
            .tableRefreshDriver.drive(onNext: { [weak self] in
                self?.tableView.reloadData()
            }).disposed(by: self.disposeBag)

        self.viewModel.errorDriver
            .drive(onNext: { [weak self] errorType in
                switch errorType {
                case .notifySetFail:
                    UDToast.showFailure(with: BundleI18n.Moment.Lark_Settings_MomentsSetFailed, on: self?.view ?? UIView())
                }
            }).disposed(by: self.disposeBag)

        self.viewModel.setup()
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    private func createTableView() -> UITableView {
        let tableView = InsetTableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        tableView.estimatedRowHeight = 68
        tableView.estimatedSectionFooterHeight = 10
        tableView.estimatedSectionHeaderHeight = 10
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.backgroundColor = UIColor.clear
        registerTableViewCells(tableView)
        tableView.contentInsetAdjustmentBehavior = .never
        return tableView
    }

    private func registerTableViewCells(_ tableView: UITableView) {
        tableView.register(NotificationSettingTableViewCell.self, forCellReuseIdentifier: NotificationSettingTableViewCell.lu.reuseIdentifier)
        tableView.register(CardSettingTableViewCell.self, forCellReuseIdentifier: CardSettingTableViewCell.lu.reuseIdentifier)
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.items[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.viewModel.items[indexPath.section][indexPath.row]
        /// 其他的情况默认处理即可
        if let cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier) as? MomentSettingTableViewCell {
            cell.setItem(item)
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 16 : 0.01
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section != self.viewModel.items.count - 1 ? 16 : 0.01
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1, indexPath.row == 0 {
            if let user = viewModel.userCircleConfig?.nicknameUser {
                MomentsNavigator.pushNickNameAvatarWith(userResolver: userResolver,
                                                        userID: user.userID,
                                                        userInfo: (name: user.displayName, avatarKey: user.avatarKey),
                                                        from: self,
                                                        selectPostTab: false)
            }
        } else if indexPath.section == 1, indexPath.row == 1 {
            guard let renewNicknameTimeSec = viewModel.userCircleConfig?.renewNicknameTimeSec else {
                Self.logger.error("getUserCircleConfig renewNicknameTimeSec error")
                return
            }
            let date = Date(timeIntervalSince1970: TimeInterval(renewNicknameTimeSec))
            let tomorrowtimeStamp = MomentSettingViewModel.tomorrowDay(date).timeIntervalSince1970
            if currenttimeStamp > Int64(tomorrowtimeStamp) {
                /// 传入花名设置的style，select表示选择花名的选项（默认为此选项），modify表示修改花名的选项（不可修改花名头像）
                let body = MomentsUserNickNameSelectBody(circleId: viewModel.userCircleConfig?.circleID ?? "",
                                                         completeBlock: { [weak self] (momentUser, renewNicknameTime) in
                    /// 修改花名后，将信息更新到viewModel中
                    self?.viewModel.userCircleConfig?.nicknameUser = momentUser
                    self?.viewModel.userCircleConfig?.renewNicknameTimeSec = renewNicknameTime
                    self?.viewModel.refreshItems()
                    self?.tableView.reloadData()
                },
                                                         nickNameSettingStyle: .modify(
                                                         nickNameID: viewModel.userCircleConfig?.nicknameUser.userID ?? "",
                                                         nickName: viewModel.userCircleConfig?.nicknameUser.name ?? "",
                                                         avatarKey: viewModel.userCircleConfig?.nicknameUser.avatarKey ?? ""))
                userResolver.navigator.present(body: body, from: self, prepare: {
                    $0.modalPresentationStyle = Display.pad ? .pageSheet : .fullScreen
                })
            } else {
                let renewNicknameTime = MomentSettingViewModel.dateToString(MomentSettingViewModel.tomorrowDay(date))
                UDToast.showTips(
                    with: BundleI18n.Moment.Moments_Settings_AddNewNickname_AddAfterDate_Toast(renewNicknameTime),
                    on: self.view)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // swiftlint:enable did_select_row_protection
}
