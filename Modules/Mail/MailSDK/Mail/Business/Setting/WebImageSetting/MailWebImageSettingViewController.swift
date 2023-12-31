//
//  MailWebImageSettingViewController.swift
//  MailSDK
//
//  Created by Quanze Gao on 2022/12/19.
//

import Foundation
import UIKit
import FigmaKit
import RxSwift
import UniverseDesignFont

final class MailWebImageSettingViewController: MailBaseViewController, UITableViewDataSource, UITableViewDelegate {
    private weak var viewModel: MailSettingViewModel?
    private var shouldIntercept: Bool {
        didSet {
            guard oldValue != shouldIntercept else { return }
            viewModel?.updateWebImageSetting(shouldIntercept: shouldIntercept)
        }
    }
    
    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgFloatBase
    }

    private var accountContext: MailAccountContext?
    private let disposeBag = DisposeBag()

    init(viewModel: MailSettingViewModel?, accountContext: MailAccountContext?) {
        self.viewModel = viewModel
        self.accountContext = accountContext
        if let setting = viewModel?.primaryAccountSetting?.setting {
            self.shouldIntercept = !setting.webImageDisplay
        } else {
            self.shouldIntercept = true
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        viewModel?.updateWebImageSwitch(enable: !shouldIntercept)
    }

    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    lazy var tableView: InsetTableView = {
        let t = InsetTableView(frame: .zero)
        t.dataSource = self
        t.delegate = self
        t.register(MailBaseSettingOptionCell.self, forCellReuseIdentifier: "id")
        t.separatorColor = UIColor.ud.lineDividerDefault
        t.rowHeight = 48
        t.backgroundColor = UIColor.ud.bgFloatBase
        return t
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.MailSDK.Mail_Settings_ExterImages_Title
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
        if let setting = viewModel?.primaryAccountSetting?.setting {
            self.shouldIntercept = !setting.webImageDisplay
        } else {
            self.shouldIntercept = true
        }
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "id") as? MailBaseSettingOptionCell else {
            return UITableViewCell()
        }
        if indexPath.row == 0 {
            cell.titleLabel.text = BundleI18n.MailSDK.Mail_Settings_ExterImagesAskBeforeShowing_Option
        } else if indexPath.row == 1 {
            cell.titleLabel.text = BundleI18n.MailSDK.Mail_Settings_ExterImagesAlwaysShow_Option
        }
        let selectedRow = shouldIntercept ? 0 : 1
        cell.isSelected = indexPath.row == selectedRow
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 12
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UITableViewHeaderFooterView()
        let detailLabel: UILabel = UILabel()
        detailLabel.text = BundleI18n.MailSDK.Mail_Settings_ExterImages_Hover
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.textColor = UIColor.ud.textPlaceholder
        detailLabel.numberOfLines = 0
        view.contentView.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalTo(4)
            make.bottom.equalTo(-16)
        }
        return view
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        shouldIntercept = indexPath.row == 0
        tableView.reloadData()
    }
}
