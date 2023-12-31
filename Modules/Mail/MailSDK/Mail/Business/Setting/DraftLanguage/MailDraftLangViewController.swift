//
//  MailDraftLangViewController.swift
//  MailSDK
//
//  Created by Ryan on 2020/12/31.
//

import UIKit
import FigmaKit
import RxSwift
import UniverseDesignFont

class MailDraftLangViewController: MailBaseViewController, UITableViewDataSource, UITableViewDelegate {
    private weak var viewModel: MailSettingViewModel?
    var currentLanguage: MailReplyLanguage? {
        didSet {
            guard oldValue != currentLanguage else { return }
            viewModel?.updateDraftLanguage(currentLanguage)
        }
    }

    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgFloatBase
    }
    
    private let accountContext: MailAccountContext
    private let disposeBag = DisposeBag()

    init(viewModel: MailSettingViewModel?, accountContext: MailAccountContext) {
        self.viewModel = viewModel
        self.accountContext = accountContext
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    lazy var tableView: InsetTableView = {
        let t = InsetTableView(frame: .zero)
        t.dataSource = self
        t.delegate = self
        t.register(DraftLangSettingCell.self, forCellReuseIdentifier: "id")
        t.separatorColor = UIColor.ud.lineDividerDefault
        t.rowHeight = Store.settingData.clientStatus == .coExist ? 46 : 68
        t.backgroundColor = UIColor.ud.bgFloatBase
        let view = UIView(frame: CGRect(x: 0, y: 0, width: Display.width, height: 35))
        let l = UILabel(frame: CGRect(x: 20, y: 11, width: 200, height: 20))
        l.text = BundleI18n.MailSDK.Mail_Setting_SubjectPrefixSubtitle
        l.textColor = UIColor.ud.textCaption
        l.font = UIFont.systemFont(ofSize: 14)
        view.addSubview(l)
        t.tableHeaderView = view
        return t
    }()

    lazy var shouldBlockAuto = accountContext.featureManager.open(.aiBlock)
    lazy var isOversea = accountContext.featureManager.open(.replyLangOpt, openInMailClient: true) ? accountContext.user.isOverSea ?? false : false

    lazy var autoIndex = shouldBlockAuto ? -1 : 0
    lazy var zhIndex: Int = {
        if shouldBlockAuto {
            return isOversea ? -1 : 0
        } else {
            return isOversea ? -1 : 1
        }
    }()
    lazy var usIndex: Int = {
        if shouldBlockAuto {
            return isOversea ? 0 : 1
        } else {
            return isOversea ? 1 : 2
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.MailSDK.Mail_Setting_SubjectPrefixTitle
        view.backgroundColor = UIColor.ud.bgBase
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        reloadData()

        self.viewModel?.refreshDriver.drive(onNext: { [weak self] () in
            guard let `self` = self else { return }
            self.reloadData()
        }).disposed(by: disposeBag)
    }

    private func reloadData() {
        currentLanguage = self.viewModel?.getPrimaryAccountSetting()?.setting.replyLanguage
        if shouldBlockAuto && currentLanguage == .auto {
            if accountContext.user.isOverSea ?? false {
                currentLanguage = .us
            } else {
                currentLanguage = .zh
            }
        }
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRows = 0
        numberOfRows += (autoIndex >= 0 ? 1 : 0)
        numberOfRows += (zhIndex >= 0 ? 1 : 0)
        numberOfRows += (usIndex >= 0 ? 1 : 0)
        return numberOfRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "id") as? DraftLangSettingCell else {
            return UITableViewCell()
        }
        if indexPath.row == autoIndex {
            cell.titleLabel.text = BundleI18n.MailSDK.Mail_Setting_SubjectPrefixAuto
            cell.contentLabel.text = Store.settingData.mailClient ? BundleI18n.MailSDK.Mail_ThirdClient_AdjustBySystemLanguage :
            BundleI18n.MailSDK.Mail_Setting_SubjectPrefixAutoMobile
            cell.isSelected = currentLanguage == .auto
        } else if indexPath.row == zhIndex {
            cell.titleLabel.text = BundleI18n.MailSDK.Mail_Setting_SubjectPrefixCn
            cell.contentLabel.text = BundleI18n.MailSDK.Mail_Setting_SubjectPrefixCnMobile
            cell.isSelected = currentLanguage == .zh
        } else if indexPath.row == usIndex {
            cell.titleLabel.text = BundleI18n.MailSDK.Mail_Setting_SubjectPrefixEn
            cell.contentLabel.text = BundleI18n.MailSDK.Mail_Setting_SubjectPrefixEnMobile
            cell.isSelected = currentLanguage == .us
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        guard let accountSetting = viewModel?.getPrimaryAccountSetting() else { mailAssertionFailure("missing setting"); return }
        if indexPath.row == autoIndex {
            accountSetting.updateSettings(.replyLanguage(.auto))
            currentLanguage = .auto
        } else if indexPath.row == zhIndex {
            currentLanguage = .zh
            accountSetting.updateSettings(.replyLanguage(.zh))
        } else if indexPath.row == usIndex {
            currentLanguage = .us
            accountSetting.updateSettings(.replyLanguage(.us))
        }
        tableView.reloadData()
    }
}
