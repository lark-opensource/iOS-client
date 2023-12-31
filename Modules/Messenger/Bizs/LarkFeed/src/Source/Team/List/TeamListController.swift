//
//  TeamListListController.swift
//  LarkFeed
//
//  Created by chaishenghua on 2022/12/29.
//

import UIKit
import Foundation
import LarkSDKInterface
import Swinject
import LarkModel
import LarkContainer
import RxSwift
import RustPB
import LKCommonsLogging
import LarkUIKit
import FigmaKit

final class TeamListController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    let viewModel: TeamListViewModel
    private let tableView: InsetTableView = InsetTableView(frame: .zero)
    private let disposeBag = DisposeBag()

    init(viewModel: TeamListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addCancelItem()
        self.title = self.viewModel.title
        view.backgroundColor = UIColor.ud.bgFloatBase

        self.initializeTableView()
        self.bindViewModel()
    }

    private func initializeTableView() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.rowHeight = 48
        self.tableView.estimatedRowHeight = 48
        self.tableView.estimatedSectionHeaderHeight = 0
        self.tableView.estimatedSectionFooterHeight = 0
        self.tableView.separatorStyle = .none
        self.tableView.contentInsetAdjustmentBehavior = .never
        self.tableView.backgroundColor = UIColor.ud.bgFloatBase
        let name = String(describing: TeamListCell.self)
        self.tableView.register(TeamListCell.self, forCellReuseIdentifier: name)
        self.tableView.register(TeamListAddCell.self, forCellReuseIdentifier: String(describing: TeamListAddCell.self))
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func bindViewModel() {
        self.viewModel.dataSourceObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.tableView.reloadData()
            }).disposed(by: self.disposeBag)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.dataSource.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < self.viewModel.dataSource.count {
            let team = self.viewModel.dataSource[indexPath.row]
            if let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TeamListCell.self)) as? TeamListCell {
                cell.set(team: team)
                return cell
            }
        } else if indexPath.row == self.viewModel.dataSource.count {
            let name = String(describing: TeamListAddCell.self)
            if let cell = tableView.dequeueReusableCell(withIdentifier: name) as? TeamListAddCell {
                return cell
            }
        }
        return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        if indexPath.row < self.viewModel.dataSource.count {
            FeedTracker.Team.Click.AddChatToTeamMenuClick(isCreateTeam: false)
            self.viewModel.joinToTeamDialog(team: self.viewModel.dataSource[indexPath.row], currentVC: self, isNewTeam: false)
        } else if indexPath.row == self.viewModel.dataSource.count {
            FeedTracker.Team.Click.AddChatToTeamMenuClick(isCreateTeam: true)
            self.viewModel.createTeam(currentVC: self)
        }
    }
}
