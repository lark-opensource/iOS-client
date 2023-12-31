//
//  MailUndoSettingViewController.swift
//  MailSDK
//
//  Created by majx on 2020/8/28.
//

import Foundation
import RxSwift
import FigmaKit

class MailUndoSettingViewController: MailBaseViewController, UITableViewDataSource, UITableViewDelegate {
    private weak var viewModel: MailSettingViewModel?
    private let disposeBag = DisposeBag()
    private let timeOptions: [Int64] = [5, 10, 20, 30, 60]
    private let accountContext: MailAccountContext

    private var undoEnable: Bool {
        didSet {
            guard oldValue != undoEnable else { return }
            viewModel?.updateUndoSetting(enable: undoEnable, time: undoTime)
        }
    }

    private var undoTime: Int64 {
        didSet {
            guard oldValue != undoTime else { return }
            viewModel?.updateUndoSetting(enable: undoEnable, time: undoTime)
        }
    }

    init(viewModel: MailSettingViewModel?, accountContext: MailAccountContext) {
        self.viewModel = viewModel
        self.accountContext = accountContext
        if let setting = viewModel?.getPrimaryAccountSetting()?.setting {
            self.undoEnable = setting.undoSendEnable
            self.undoTime = setting.undoTime
        } else {
            self.undoEnable = true
            self.undoTime = Int64(5)
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        viewModel?.updateUndoSwitch(undoEnable)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()

        self.viewModel?.refreshDriver.drive(onNext: { [weak self] () in
            guard let `self` = self else { return }
            self.reloadData()
        }).disposed(by: disposeBag)
    }

    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgFloatBase
    }

    lazy var timesTitleLabel: UILabel = {
        let timesTitleLabel = UILabel()
        timesTitleLabel.text = BundleI18n.MailSDK.Mail_Setting_UndoCancellation
        timesTitleLabel.textColor = UIColor.ud.textCaption
        timesTitleLabel.font = UIFont.systemFont(ofSize: 14)
        return timesTitleLabel
    }()

    lazy var tableView: InsetTableView = {
        let t = InsetTableView(frame: .zero)
        t.dataSource = self
        t.delegate = self
        t.lu.register(cellSelf: MailSettingSwitchCell.self)
        t.lu.register(cellSelf: MailBaseSettingOptionCell.self)
        t.separatorColor = UIColor.ud.lineDividerDefault
        t.rowHeight = 48
        t.backgroundColor = UIColor.ud.bgFloatBase
        return t
    }()

    func setupViews() {
        self.title = BundleI18n.MailSDK.Mail_Setting_UndoSend
        view.backgroundColor = UIColor.ud.bgFloatBase
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        reloadData()
    }

    func reloadData() {
        if let setting = viewModel?.getPrimaryAccountSetting()?.setting {
            self.undoEnable = setting.undoSendEnable
            self.undoTime = setting.undoTime
        }
        self.tableView.reloadData()
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return undoEnable ? 2 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : timeOptions.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 1 else { return nil }
        let view = UITableViewHeaderFooterView()
        view.addSubview(timesTitleLabel)
        timesTitleLabel.snp.makeConstraints { make in
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
                                               accountId: accountContext.accountID,
                                               title: BundleI18n.MailSDK.Mail_Setting_UndoSend,
                                               status: undoEnable,
                                               switchHandler: { [weak self] status in
                guard let `self` = self else { return }
                self.undoEnable = status
                self.tableView.reloadData()
            })
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MailBaseSettingOptionCell.lu.reuseIdentifier) as? MailBaseSettingOptionCell else {
                return UITableViewCell()
            }
            if indexPath.row < timeOptions.count {
                let time = timeOptions[indexPath.row]
                cell.titleLabel.text = BundleI18n.MailSDK.Mail_Setting_UndoCancellationSeconds(number: time)
                cell.isSelected = (time == undoTime)
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        guard indexPath.section == 1 else { return }
        guard indexPath.row < timeOptions.count else { return }
        undoTime = timeOptions[indexPath.row]
        tableView.reloadData()
    }
}
