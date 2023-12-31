//
//  EventListViewController.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2022/9/26.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkModel
import EENavigator
import LKCommonsLogging
import LarkMessengerInterface
import LarkOpenFeed

final class EventListViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {
    private let disposeBag = DisposeBag()
    private let viewModel: EventListViewModel
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let clearButton = UIButton(type: .custom)

    init(viewModel: EventListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()
        self.bind()
    }

    private func setupViews() {
        self.isNavigationBarHidden = false
        self.title = self.viewModel.title
        self.view.backgroundColor = UIColor.ud.bgBody
        clearButton.setTitle(BundleI18n.LarkFeedEvent.Lark_Event_EventList_Clear_Button, for: .normal)
        clearButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        clearButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        clearButton.setTitleColor(UIColor.ud.N400, for: .disabled)
        clearButton.isEnabled = false
        clearButton.addTarget(self, action: #selector(clearData), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: clearButton)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.backgroundColor = UIColor.ud.bgBody
        self.viewModel.eventManager.providers.values.forEach { provider in
            provider.cellTypes.forEach { reuseId, cellType in
                tableView.register(cellType, forCellReuseIdentifier: reuseId)
            }
        }
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func bind() {
        self.viewModel.renderObservable
            .subscribe(onNext: { [weak self] (_) in
                self?.render()
            }).disposed(by: self.disposeBag)
    }

    private func render() {
        let isEmptyList = self.viewModel.items.isEmpty
        clearButton.isEnabled = !isEmptyList
        self.tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.items.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < viewModel.items.count else {
            return UITableView.automaticDimension
        }
        let item = viewModel.items[indexPath.row]
        switch item.calHeightMode {
        case .automaticDimension: return UITableView.automaticDimension
        case .manualDimension(let height): return height
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < viewModel.items.count else {
            return UITableViewCell()
        }
        let item = viewModel.items[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseId) as? EventItemCell else {
            return UITableViewCell()
        }
        cell.item = item
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedCell = tableView.cellForRow(at: indexPath) as? EventItemCell else {
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    @objc
    func clearData() {
        self.viewModel.clearList()
        super.closeBtnTapped()
    }
}
