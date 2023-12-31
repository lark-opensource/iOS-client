//
//  MailAutoCCSettingViewController.swift
//  MailSDK
//
//  Created by Ender on 2023/6/27.
//

import Foundation
import RxSwift
import FigmaKit
import UniverseDesignSwitch

class MailAutoCCSettingViewController: MailBaseViewController, UITableViewDataSource, UITableViewDelegate {
    private weak var viewModel: MailSettingViewModel?
    private var accountId: String
    private let disposeBag = DisposeBag()

    private var autoCCEnable: Bool {
        didSet {
            guard oldValue != autoCCEnable else { return }
            viewModel?.updateAutoCCSetting(enable: autoCCEnable, type: autoCCType)
        }
    }
    private var autoCCType: MailAutoCCType {
        didSet {
            guard oldValue != autoCCType else { return }
            viewModel?.updateAutoCCSetting(enable: autoCCEnable, type: autoCCType)
        }
    }

    init(viewModel: MailSettingViewModel?, accountId: String) {
        self.viewModel = viewModel
        self.accountId = accountId
        if let setting = viewModel?.getPrimaryAccountSetting()?.setting {
            self.autoCCEnable = setting.autoCcAction.autoCcEnable
            self.autoCCType = setting.autoCcAction.autoCcType
        } else {
            self.autoCCEnable = false
            self.autoCCType = .cc
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        viewModel?.updateAutoCCSwitch(enable: autoCCEnable)
    }

    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgFloatBase
    }

    private lazy var tableView: InsetTableView = {
        let table = InsetTableView(frame: .zero)
        table.delegate = self
        table.dataSource = self
        table.backgroundColor = UIColor.ud.bgFloatBase
        table.rowHeight = 48
        table.contentInsetAdjustmentBehavior = .never
        table.separatorColor = UIColor.ud.lineDividerDefault
        table.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        table.showsVerticalScrollIndicator = false
        table.showsHorizontalScrollIndicator = false
        table.lu.register(cellSelf: MailSettingSwitchCell.self)
        table.lu.register(cellSelf: MailBaseSettingOptionCell.self)
        return table
    }()

    private lazy var headerView: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        label.text = BundleI18n.MailSDK.Mail_Settings_AutoCcOrBccPrompt_Title
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()

        self.viewModel?.refreshDriver.drive(onNext: { [weak self] () in
            guard let `self` = self else { return }
            self.reloadData()
        }).disposed(by: disposeBag)
    }

    func setupViews() {
        self.title = BundleI18n.MailSDK.Mail_Settings_AutoCcOrBcc_Name
        view.backgroundColor = UIColor.ud.bgFloatBase
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.reloadData()
    }

    func reloadData() {
        if let setting = viewModel?.getPrimaryAccountSetting()?.setting {
            self.autoCCEnable = setting.autoCcAction.autoCcEnable
            self.autoCCType = setting.autoCcAction.autoCcType
        }
        tableView.reloadData()
    }

    // MARK: tableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return autoCCEnable ? 2 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : 2
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 1 else { return nil }
        let view = UITableViewHeaderFooterView()
        view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview().inset(24)
            make.height.equalTo(20)
        }
        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 16 : 24
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 ? 16 : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MailSettingSwitchCell.lu.reuseIdentifier) as? MailSettingSwitchCell else {
                return UITableViewCell()
            }
            cell.item = MailSettingSwitchModel(cellIdentifier: MailSettingSwitchCell.lu.reuseIdentifier,
                                               accountId: accountId,
                                               title: BundleI18n.MailSDK.Mail_Settings_AutoCcOrBcc_Name,
                                               status: autoCCEnable,
                                               switchHandler: { [weak self] status in
                guard let `self` = self else { return }
                self.autoCCEnable = status
                self.tableView.reloadData()
            })
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MailBaseSettingOptionCell.lu.reuseIdentifier) as? MailBaseSettingOptionCell else {
                return UITableViewCell()
            }
            if indexPath.row == 0 {
                cell.titleLabel.text = BundleI18n.MailSDK.Mail_Settings_AutoCcOrBcc_Cc_Checkbox
                cell.isSelected = (autoCCType == .cc)
            } else {
                cell.titleLabel.text = BundleI18n.MailSDK.Mail_Settings_AutoCcOrBcc_BccMyself_Checkbox
                cell.isSelected = (autoCCType == .bcc)
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        autoCCType = (indexPath.row == 0 ? MailAutoCCType.cc : MailAutoCCType.bcc)
        tableView.reloadData()
    }
}
