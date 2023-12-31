//
//  MeetingAccountManageViewController.swift
//  Calendar
//
//  Created by pluto on 2022-10-18.
//

import UIKit
import Foundation
import LarkContainer
import LKCommonsLogging
import CalendarFoundation
import UniverseDesignTheme
import UniverseDesignToast
import UniverseDesignDialog
import RoundedHUD
import RxSwift
import LarkUIKit
import FigmaKit

final class MeetingAccountManageViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate, UserResolverWrapper {

    private let logger = Logger.log(MeetingAccountManageViewController.self, category: "calendar.MeetingAccountManageViewController")

    @ScopedInjectedLazy var serverPushService: ServerPushService?

    let userResolver: UserResolver

    private let viewModel: MeetingAccountManageViewModel
    private let disposeBag = DisposeBag()

    private let tableView: UITableView = {
        let tableView = InsetTableView()
        tableView.separatorStyle = .none
        tableView.register(CalendarAccountAddCell.self, forCellReuseIdentifier: "CalendarAccountAddCell")
        tableView.register(CalendarMeetingAccountCell.self, forCellReuseIdentifier: String(describing: "CalendarMeetingAccountCell".self))
        tableView.register(MeetingAccountManageHeaderView.self, forHeaderFooterViewReuseIdentifier: String(describing: "MeetingAccountManageHeaderView".self))
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        return tableView
    }()

    private lazy var loadingView: ZoomCommonPlaceholderView = {
        let view = ZoomCommonPlaceholderView()
        view.isHidden = false
        view.layoutNaviOffsetStyle()
        return view
    }()

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    private var zoomAccountStatus: ZoomAccountStatus = .inital

    init(viewModel: MeetingAccountManageViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
        tableView.delegate = self
        tableView.dataSource = self
        viewModel.delegate = self

        viewModel.refreshAccountCallBack = { [weak self] in
            guard let self = self else { return }
            self.refreshUI()
            self.loadingView.isHidden = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = I18n.Calendar_Settings_ThirdPartyManage
        addBackItem()
        layoutTableView()
        layoutLoadingView()

        bindViewModel()

        registerBindAccountNotification()
    }

    private func bindViewModel() {
        viewModel.rxToast
            .bind(to: rx.toast)
            .disposed(by: disposeBag)

        viewModel.rxRoute
            .subscribeForUI(onNext: {[weak self] route in
                guard let self = self else { return }
                switch route {
                case let .url(url):
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }).disposed(by: disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutTableView() {
        view.addSubview(tableView)
        tableView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func layoutLoadingView() {
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func refreshUI() {
        self.tableView.reloadData()
    }

    // 调用时机： 首次VC加载时 + 收到通知时
    private func reloadData() {
        viewModel.loadZoomAccount()
    }

    private func registerBindAccountNotification() {
        serverPushService?
            .rxZoomBind
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.logger.info("Zoom Account Notification Bind Success Push")
                self.reloadData()
                UDToast.showTips(with: I18n.Calendar_Settings_BindSuccess, on: self.view)
            }).disposed(by: disposeBag)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch viewModel.zoomMeetingAccount.type {
        case .add:
            viewModel.importZoomAccount()
        default: break
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel.zoomMeetingAccount.type {
        case .add:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CalendarAccountAddCell", for: indexPath) as? CalendarAccountAddCell else {
                assertionFailureLog()
                return UITableViewCell()
            }
            cell.configCellInfo(labelText: viewModel.zoomMeetingAccount.name)
            cell.updateBottomBorder(isHidden: true)
            return cell
        case .zoom:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CalendarMeetingAccountCell", for: indexPath) as? CalendarMeetingAccountCell else {
                assertionFailureLog()
                return UITableViewCell()
            }
            cell.update(model: viewModel.zoomMeetingAccount, tapSelector: #selector(tapRemove))
            cell.status = zoomAccountStatus
            cell.tapErrorTipsCallBack = { [weak self] in
                guard let self = self else { return }
                self.viewModel.importZoomAccount()
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: MeetingAccountManageHeaderView.self)) as? MeetingAccountManageHeaderView else {
            return nil
        }
        header.setup(titleText: I18n.Calendar_Settings_ZoomMeet)
        return header
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.cellHeight ?? 48
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    @objc
    private func tapRemove() {
        let dialog = UDDialog()
        dialog.setContent(text: I18n.Calendar_Settings_ConfirmRemoveAcct)
        dialog.addCancelButton()
        dialog.addDestructiveButton(text: I18n.Calendar_Settings_RemoveButton, dismissCompletion: { [weak self] in
            self?.logger.info("User click: remove zoom account")
            self?.viewModel.removeZoomAccount()
        })
        self.present(dialog, animated: true, completion: nil)
    }
}

extension MeetingAccountManageViewController: MeetingAccountManageViewModelDelegate {
    func updateExpiredTips(needShow: Bool) {
        zoomAccountStatus = needShow ? .expired : .normal
    }
}

final class MeetingAccountManageHeaderView: UITableViewHeaderFooterView {
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.cd.regularFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder

        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.height.equalTo(20)
            make.bottom.equalToSuperview().offset(-2)
        }
    }

    func setup(titleText: String) {
        titleLabel.text = titleText
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
