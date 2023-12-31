//
//  FeedMsgDisplayMoreSettingViewController.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/29.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import FigmaKit
import EENavigator
import LarkOpenFeed
import LarkContainer

final class FeedMsgDisplayMoreSettingViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    var userResolver: UserResolver { viewModel.userResolver }
    let viewModel: FeedMsgDisplayMoreSettingViewModel
    let defaultCellIdentifier = "FeedMsgDisplayMoreDefaultCellIdentifier"
    let disposeBag = DisposeBag()

    let tableView: InsetTableView = {
        let tableView = InsetTableView(frame: .zero)
        tableView.lu.register(cellSelf: FeedSubFilterCell.self)
        tableView.register(HeaderViewWithTitle.self, forHeaderFooterViewReuseIdentifier: HeaderViewWithTitle.identifier)
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 58
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }()

    // 右上保存按钮
    lazy var saveButtonItem: LKBarButtonItem = {
        let item = LKBarButtonItem(image: nil, title: BundleI18n.LarkFeed.Lark_FeedFilter_Done_Button, fontStyle: .medium)
        item.addTarget(self, action: #selector(saveFilterEditor), for: .touchUpInside)
        item.setBtnColor(color: UIColor.ud.primaryContentDefault)
        return item
    }()

    let hintLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.textColor = UIColor.ud.textCaption
        label.isHidden = true
        return label
    }()

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    init(viewModel: FeedMsgDisplayMoreSettingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bind()
    }

    private func setupViews() {
        self.title = viewModel.getNavTitle()
        self.navigationItem.rightBarButtonItem = self.saveButtonItem
        addCancelItem()

        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        view.addSubview(hintLabel)
        hintLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(22)
        }
    }

    override func closeBtnTapped() {
        super.closeBtnTapped()
    }

    @objc
    func saveFilterEditor() {
        viewModel.saveOptions()
        closeBtnTapped()
    }

    private func bind() {
        viewModel.reloadDataDriver.drive(onNext: { [weak self] in
            self?.tableView.reloadData()
        })

        viewModel.pushVCDriver.drive(onNext: { [weak self] body in
            guard let self = self, let body = body else { return }
            self.navigator.present(body: body,
                                     wrap: LkNavigationController.self,
                                     from: self,
                                     prepare: { $0.modalPresentationStyle = .formSheet },
                                     animated: true)
        }).disposed(by: disposeBag)

        viewModel.showToastDriver.drive(onNext: { [weak self] toast in
            self?.hintLabel.text = toast
            self?.hintLabel.isHidden = toast.isEmpty
        })
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < viewModel.rows.count else {
            return UITableViewCell(style: .default, reuseIdentifier: defaultCellIdentifier)
        }

        var item = viewModel.rows[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier) as? FeedSubFilterCell {
            item.isLastRow = indexPath.row == viewModel.rows.count
            item.indexPath = indexPath
            cell.item = item
            return cell
        }

        return UITableViewCell(style: .default, reuseIdentifier: defaultCellIdentifier)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !viewModel.rows.isEmpty,
              let sectionHeader = tableView.dequeueReusableHeaderFooterView(withIdentifier: HeaderViewWithTitle.identifier) as? FeedFilterSectionHeaderProtocol,
              let labelTitle = FeedFilterTabSourceFactory.source(for: .tag)?.titleProvider(),
              !labelTitle.isEmpty else {
            return nil
        }
        sectionHeader.setText(BundleI18n.LarkFeed.Lark_IM_MessageDisplaySettings_Desc(labelTitle), "")
        sectionHeader.setTitleLabelLeadingOffset(0.0)
        return sectionHeader
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
}
