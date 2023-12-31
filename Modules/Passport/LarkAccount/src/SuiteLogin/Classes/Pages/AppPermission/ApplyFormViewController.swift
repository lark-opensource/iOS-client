//
//  ApplyFormViewController.swift
//  LarkAccount
//
//  Created by Nix Wang on 2022/12/12.
//

import UIKit
import SnapKit
import LKCommonsLogging
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignToast
import LarkUIKit
import RxSwift
import RxCocoa

class ApplyFormViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {
    static let logger = Logger.plog(ApplyFormViewController.self, category: "SuiteLogin")

    var vm: ApplyFormViewModel

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.lu.register(cellSelf: UserOperationCenterCell.self)
        tableView.backgroundColor = .clear
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
        tableView.estimatedRowHeight = 54.0
        #if swift(>=5.5)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        #endif
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.lu.register(cellSelf: ApplyFormTextCell.self)
        tableView.lu.register(cellSelf: ApplyFormReviewerCell.self)
        tableView.lu.register(cellSelf: ApplyFormTextViewCell.self)

        return tableView
    }()

    private var nextButton: NextButton = {
        let button = NextButton(title: I18N.Lark_Passport_AccountAccessControl_PermissionApplication_SubmitButton)
        return button
    }()

    private var textViewCell: ApplyFormTextViewCell?
    private lazy var errorHandler = V3ErrorHandler(vc: self,
                                                   context: vm.context,
                                                   contextExpiredPostEvent: true)

    init(viewModel vm: ApplyFormViewModel) {
        self.vm = vm

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: false)
        title = I18N.Lark_Passport_AccountAccessControl_PermissionApplication_Title
    }

    private func setupViews() {

        view.backgroundColor = .ud.bgBase
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        view.addGestureRecognizer(tap)

        // Table view
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        // Bottom view
        nextButton.rx.controlEvent(.touchUpInside)
            .compactMap({ [weak self] _ -> String? in
                guard let self = self else { return nil }
                guard let reason = self.textViewCell?.inputText, !reason.isEmpty else {
                    UDToast.showTips(with: I18N.Lark_Passport_AccountAccessControl_PermissionApplication_EnterReasonBeforeSubmitToast, on: self.view)
                    return nil
                }

                return reason
            })
            .flatMap({ [weak self] reason -> Observable<Void> in
                guard let self = self else { return .just(()) }
                self.nextButton.isLoading = true
                return self.vm.submit(reason: reason)
            })
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if let view = self.currentWindow() {
                    UDToast.showTips(with: I18N.Lark_Passport_AccountAccessControl_ApplicationSubmitted_Toast, on: view)
                }
                self.nextButton.isLoading = false
            }) { [weak self] error in
                self?.nextButton.isLoading = false
                self?.errorHandler.handle(error)
            }

        let bottomView = UIView()
        bottomView.backgroundColor = .ud.bgBody
        bottomView.addSubview(nextButton)
        nextButton.snp.makeConstraints { make in
            make.top.equalTo(8)
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(48)
        }
        view.addSubview(bottomView)
        bottomView.snp.makeConstraints { make in
            make.top.equalTo(tableView.snp.bottom)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(8.0 * 2 + 48)
            make.left.right.bottom.equalToSuperview()
        }

        tableView.reloadData()

    }

    @objc
    private func endEditing() {
        view.endEditing(true)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    @objc
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return 1
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 54.0
        case 1:
            return 170.0
        default:
            return 0
        }
    }

    @objc(tableView:cellForRowAtIndexPath:)
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ApplyFormTextCell", for: indexPath) as? ApplyFormTextCell else {
                return UITableViewCell()
            }
            cell.setup(title: I18N.Lark_Passport_AccountAccessControl_PermissionApplication_AppName, subtitle: vm.applyFormInfo.appInfo.appName)
            return cell
        case (0, 1):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ApplyFormReviewerCell", for: indexPath) as? ApplyFormReviewerCell else {
                return UITableViewCell()
            }
            if let reviewer = vm.applyFormInfo.reviewers.first {
                cell.setup(reviewer: reviewer)
            }
            cell.hostViewController = self
            return cell
        case (1, 0):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ApplyFormTextViewCell", for: indexPath) as? ApplyFormTextViewCell else {
                return UITableViewCell()
            }
            textViewCell = cell
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 12.0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
}
