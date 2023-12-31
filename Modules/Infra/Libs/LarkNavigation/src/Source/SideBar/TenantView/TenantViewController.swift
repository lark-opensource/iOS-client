//
//  TenantViewController.swift
//  LarkNavigation
//
//  Created by Supeng on 2021/6/2.
//

import UIKit
import Foundation
import UniverseDesignColor
import RxSwift

protocol TenantViewControllerDependency {
    var currentTenants: [TenantModel] { get }
    var currentTenantsObservable: Observable<[TenantModel]> { get }
    func changeTenant(from: Tenant, to: Tenant, vc: UIViewController)
    func addAccount(vc: UIViewController, from: UIView)
    var leanmodeIsOpen: Bool { get }
    func switchToLeanMode(vc: UIViewController)
}

final class TenantViewController: UIViewController {
    private let tableView = UITableView()
    private let dependency: TenantViewControllerDependency
    private let disposeBag = DisposeBag()
    lazy var tapGesture: UITapGestureRecognizer = {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(switchToLeanMode))
        tapGesture.delaysTouchesBegan = true
        tapGesture.cancelsTouchesInView = false
        tapGesture.numberOfTapsRequired = 5
        return tapGesture
    }()

    private var dataSource: [TenantModel] {
        didSet { tableView.reloadData() }
    }

    init(dependency: TenantViewControllerDependency) {
        self.dependency = dependency
        self.dataSource = dependency.currentTenants

        super.init(nibName: nil, bundle: nil)

        dependency.currentTenantsObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] models in
                self?.dataSource = models
            })
            .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UDColor.bgBase

        tableView.separatorStyle = .none
        tableView.rowHeight = 88
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.register(TenantView.self, forCellReuseIdentifier: TenantView.resuseIdentifier)
        tableView.register(AddView.self, forCellReuseIdentifier: AddView.resuseIdentifier)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
        }
        tableView.reloadData()
    }

    func addView() -> UIView? {
        let row = tableView.numberOfRows(inSection: 0)
        guard row > 1 else { return nil }
        guard row < 5 else { return nil }
        return (tableView.visibleCells.last as? AddView)?.backgrounView
    }

    @objc
    private func switchToLeanMode() {
        dependency.switchToLeanMode(vc: self)
    }
}

extension TenantViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < dataSource.count else { return UITableViewCell() }
        let tenantItem = dataSource[indexPath.row]
        switch tenantItem {
        case .tenant(let tenant):
            if let cell = tableView.dequeueReusableCell(withIdentifier: TenantView.resuseIdentifier) as? TenantView {
                cell.set(tenantItem: tenant)
                if dependency.leanmodeIsOpen {
                    if indexPath.row == 0 {
                        cell.addGestureRecognizer(tapGesture)
                    } else {
                        cell.removeGestureRecognizer(tapGesture)
                    }
                }
                return cell
            }
        case .add:
            if let cell = tableView.dequeueReusableCell(withIdentifier: AddView.resuseIdentifier) as? AddView {
                return cell
            }
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: false)

        guard indexPath.row < dataSource.count else { return }

        let tenantItem = dataSource[indexPath.row]

        switch tenantItem {
        case .tenant(let tenant):
            if indexPath.row != 0, case let .tenant(currentTenant) = dataSource.first {
                dependency.changeTenant(from: currentTenant, to: tenant, vc: self)
            }
        case .add:
            dependency.addAccount(vc: self, from: tableView)
        }
    }
}
