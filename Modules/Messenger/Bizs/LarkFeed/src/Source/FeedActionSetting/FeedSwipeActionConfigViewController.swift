//
//  FeedSwipeActonConfigViewController.swift
//  LarkFeed
//
//  Created by ByteDance on 2023/11/12.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import UniverseDesignToast
import LarkModel
import EENavigator
import FigmaKit

final class FeedSwipeActionConfigViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    var viewModel: FeedSwipeActionConfigViewModel
    var reachLimit: Bool = false
    private let bag = DisposeBag()
    private var allSwitch: Bool = false

    lazy var tableView: InsetTableView = {
        let tableView = InsetTableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.separatorStyle = .none
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 48
        tableView.lu.register(cellSelf: FeedSettingSwitchCell.self)
        tableView.lu.register(cellSelf: FeetSettingCheckCell.self)
        return tableView
    }()

    init(viewModel: FeedSwipeActionConfigViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupViews()
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    private func setupViewModel() {
        viewModel.reloadData.drive(onNext: {[weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: bag)
        viewModel.toast.drive(onNext: {[weak self] tips in
            guard let self = self else { return }
            guard let window = self.view.window else {
                assertionFailure("no window")
                return
            }
            switch tips {
            case let .info(text):
                UDToast.showTips(with: text, on: window)
            case let .fail(text):
                UDToast.showFailure(with: text, on: window)
            }
        }).disposed(by: bag)
    }

    private func setupViews() {
        view.backgroundColor = UIColor.ud.bgFloatBase
        title = viewModel.title
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(0)
        }
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section >= 0 && section < viewModel.dataSource.count else {
            return 0
        }
        return viewModel.dataSource[section].count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section >= 0 && indexPath.section < viewModel.dataSource.count else {
            return UITableViewCell()
        }
        let cellType = viewModel.dataSource[indexPath.section][indexPath.row]
        switch cellType {
        case .switchCell(let data):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: FeedSettingSwitchCell.lu.reuseIdentifier) as? FeedSettingSwitchCell else {
                return UITableViewCell()
            }
            cell.config(viewModel: data)
            cell.didChangeSwitch = {[weak self] status in
                guard let self = self else { return }
                self.viewModel.changeSwitch(status: status)
            }
            return cell
        case .checkCell(let data):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: FeetSettingCheckCell.lu.reuseIdentifier) as? FeetSettingCheckCell else {
                return UITableViewCell()
            }
            cell.config(viewModel: data)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        viewModel.selectCell(section: indexPath.section, row: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 1 else { return UIView() }
        let view = UITableViewHeaderFooterView()
        let detailLabel = UILabel()
        detailLabel.text = viewModel.detailLabel
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.textColor = UIColor.ud.textCaption
        detailLabel.numberOfLines = 0
        view.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(12)
            make.left.equalTo(18)
            make.right.equalTo(-16)
            make.height.equalTo(20)
        }
        return view
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            return 12
        }
        return 0.01
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}
