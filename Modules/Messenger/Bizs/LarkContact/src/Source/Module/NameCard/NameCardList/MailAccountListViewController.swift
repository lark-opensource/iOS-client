//
//  MailAccountListViewController.swift
//  LarkContact
//
//  Created by Quanze Gao on 2022/4/18.
//

import Foundation
import UIKit
import LKCommonsLogging
import UniverseDesignEmpty
import LarkUIKit
import RxSwift
import UniverseDesignToast

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

final class MailAccountListViewController: BaseUIViewController,
                                           UITableViewDelegate,
                                           UITableViewDataSource {
    static let logger = Logger.log(MailAccountListViewController.self, category: "NameCardList")

    private let disposeBag = DisposeBag()
    private let sectionHeaderHeight: CGFloat = 40
    private lazy var tableView = UITableView(frame: .zero, style: .grouped)
    private lazy var emptyView = UDEmptyView(config: UDEmptyConfig(description: UDEmptyConfig.Description(
        descriptionText: BundleI18n.LarkContact.Mail_Contacts_NoContactsAdd
    ), type: .noContact))

    private let viewModel: MailAccountListViewModel
    private var datasource: [MailAccountListSectionModel] = [] {
        didSet {
            DispatchQueue.main.async {
                if self.datasource.isEmpty {
                    self.tableView.isHidden = true
                    self.emptyView.isHidden = false
                } else {
                    self.tableView.isHidden = false
                    self.emptyView.isHidden = true
                }
            }
        }
    }

    init(viewModel: MailAccountListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindViewModel()
        setupNavigationBar()

        NotificationCenter.default.addObserver(self, selector: #selector(refreshAccountListData), name: .LKNameCardEditNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAccountListData), name: .LKNameCardDeleteNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAccountPermissionLost), name: . LKNameCardNoPermissionNotification, object: nil)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        datasource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let name = String(describing: MailAccountDetailCell.self)
        if let cell = tableView.dequeueReusableCell(withIdentifier: name) as? MailAccountDetailCell {
            if let model = cellModel(at: indexPath), let section = datasource[safe: indexPath.section] {
                let needSeparator = section.cellModels.count > 1 && indexPath.item == 0
                cell.config(icon: model.icon, title: model.title, needSeparator: needSeparator)
            }
            return cell
        } else {
            return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        datasource[section].cellModels.count
    }

    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let model = cellModel(at: indexPath) else { return }
        viewModel.didiSelectCell(type: model.type, section: indexPath.section, from: self)
    }
    // swiftlint:enable did_select_row_protection

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        makeHeader(for: section)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    @objc
    private func didClickAddButton() {
        viewModel.didTapAddNameCard(from: self)
    }

    @objc
    private func refreshAccountListData(notification: Notification) {
        viewModel.fetchMailAccountDetail()
        viewModel.updateContactListAccountIfNeeded(notification: notification)
    }

    /// 邮箱账号权限失效
    @objc
    private func onAccountPermissionLost(notification: Notification) {
        viewModel.fetchMailAccountDetail()
    }
}

// MARK: Private

private extension MailAccountListViewController {
    func bindViewModel() {
        loadingPlaceholderView.isHidden = false
        viewModel.datasourceObservable.subscribe(onNext: { [weak self] (sectionModels) in
            guard let self = self else { return }
            self.datasource = sectionModels
            self.retryLoadingView.isHidden = true
            self.loadingPlaceholderView.isHidden = true
            self.tableView.reloadData()
            Self.logger.info("Did receive mail ccount data, count: \(sectionModels.count)")
        }, onError: { [weak self] _ in
            guard let self = self else { return }
            self.retryLoadingView.isHidden = false
            self.loadingPlaceholderView.isHidden = true
            self.datasource = []
            self.tableView.reloadData()
        }).disposed(by: self.disposeBag)

        retryLoadingView.retryAction = { [weak self] in
            self?.viewModel.fetchMailAccountDetail()
            Self.logger.info("Retry loading mail account data")
        }
    }

    func cellModel(at indexPath: IndexPath) -> MailAccountDetailCellModel? {
        self.datasource[safe: indexPath.section]?.cellModels[safe: indexPath.row]
    }
}

// MARK: View Configuration
private extension MailAccountListViewController {
    func setupViews() {
        self.view.addSubview(emptyView)
        emptyView.backgroundColor = UIColor.ud.bgBody
        emptyView.useCenterConstraints = true
        emptyView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.right.bottom.equalToSuperview()
        }

        self.view.addSubview(tableView)
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 48
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = sectionHeaderHeight
        tableView.separatorStyle = .none
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.backgroundColor = UIColor.ud.bgBase
        let name = String(describing: MailAccountDetailCell.self)
        tableView.register(MailAccountDetailCell.self, forCellReuseIdentifier: name)
        tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview()
        }
    }

    func setupNavigationBar() {
        let rightButton = LKBarButtonItem(title: BundleI18n.LarkContact.Lark_Legacy_Add)
        rightButton.button.tintColor = UIColor.ud.primaryContentDefault
        rightButton.setProperty(font: UIFont.systemFont(ofSize: 16), alignment: .center)
        rightButton.addTarget(self, action: #selector(didClickAddButton), for: .touchUpInside)
        parent?.navigationItem.rightBarButtonItem = rightButton
    }

    func makeHeader(for section: Int) -> UIView? {
        guard let address = datasource[safe: section]?.emailAddress else { return nil }
        let sectionPadding: CGFloat = 16
        let container = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: sectionHeaderHeight))
        container.backgroundColor = .clear
        let label = UILabel()
        label.text = address
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(top: sectionPadding + 3, left: sectionPadding, bottom: 4, right: sectionPadding)
            )
        }
        return container
    }
}
