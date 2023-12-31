//
//  AdditionalTimeZoneManageViewController.swift
//  Calendar
//
//  Created by chaishenghua on 2023/10/18.
//

import Foundation
import LarkUIKit
import FigmaKit
import UniverseDesignColor
import RxSwift
import LarkContainer
import CTFoundation
import UniverseDesignToast

class AdditionalTimeZoneManagerViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    typealias Config = AdditionalTimeZone
    var userResolver: LarkContainer.UserResolver

    @ScopedInjectedLazy private var timeZoneService: TimeZoneService?
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UDColor.bgBase)
    }

    private let viewModel: AdditionalTimeZoneManagerViewModel
    private let disposebag = DisposeBag()
    private let tableView = {
        let tableView = InsetTableView()
        tableView.contentInset = UIEdgeInsets(top: -18, left: 0, bottom: 0, right: 0)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        return tableView
    }()

    init(viewModel: AdditionalTimeZoneManagerViewModel,
         userResolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
        self.viewModel.vc = self
        self.title = BundleI18n.Calendar.Calendar_G_SecondaryTimeZone_Tab
        tableView.register(AdditionalTimeZoneCell.self, forCellReuseIdentifier: AdditionalTimeZoneCell.identifier)
        tableView.register(AddAdditionanalTimeZoneCell.self, forCellReuseIdentifier: AddAdditionanalTimeZoneCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self

        listenDataPush()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UDColor.bgBase
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SettingService.shared().stateManager.activate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SettingService.shared().stateManager.inActivate()
    }

    private func listenDataPush() {
        viewModel.additionalTimeZoneObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.tableView.reloadData()
            }).disposed(by: disposebag)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.getCellHeight(at: indexPath.row)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let viewData = viewModel.cellData(at: indexPath.row) else { return UITableViewCell() }
        switch viewData.type {
        case .timeZoneCell(let identifier):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? AdditionalTimeZoneCell,
                  let cellData = viewData as? AdditionalTimeZoneViewData
            else { return UITableViewCell() }
            cell.setViewData(viewData: cellData)
            return cell
        case .addTimeZoneCell(let identifier):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? AddAdditionanalTimeZoneCell,
                  let cellData = viewData as? AddAdditionalTimeZoneViewData
            else { return UITableViewCell() }
            cell.setViewData(viewData: cellData)
            return cell
        }
    }

    func getCellIndexPath(cell: UITableViewCell) -> IndexPath? {
        return self.tableView.indexPath(for: cell)
    }
}
