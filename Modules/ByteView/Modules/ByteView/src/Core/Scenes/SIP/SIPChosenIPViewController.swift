//
//  SIPChooseIPViewController.swift
//  ByteView
//
//  Created by admin on 2022/5/27.
//

import UIKit
import ByteViewUI
import UniverseDesignColor
import UniverseDesignIcon
import ByteViewCommon
import RxSwift

final class SIPChosenIPViewController: VMViewController<SIPDialViewModel>, UITableViewDataSource, UITableViewDelegate {
    private let disposeBag = DisposeBag()

    var chosenIPAddrChanged: (() -> Void)?

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.separatorColor = .clear
        tableView.alwaysBounceVertical = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = I18n.View_MV_SelectIPAddress
        setNavigationBarBgColor(.ud.bgFloatBase)
        view.backgroundColor = .ud.bgFloatBase

        view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        self.viewModel.sipInviteObservable
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self]_ in
                self?.tableView.reloadData()
            }
            .disposed(by: disposeBag)
    }

    override func bindViewModel() {
        self.viewModel.fetchIPAddrs()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.viewModel.ipAddrs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let ipAddrs = self.viewModel.ipAddrs
        let cell = SIPChosenIPCell(style: .default, reuseIdentifier: "SIPChooseReuseIdentifier")
        var ipAddr: H323Info?
        if indexPath.row < ipAddrs.count {
            ipAddr = ipAddrs[indexPath.row]
        }
        cell.textLabel?.text = ipAddr?.h323Description ?? ""
        cell.showChecked = self.viewModel.isIPAddrChosen(ipAddr)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        48
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        var ipAddr: H323Info?
        if indexPath.row < viewModel.ipAddrs.count {
            ipAddr = viewModel.ipAddrs[indexPath.row]
        }
        viewModel.currentIPAddr = ipAddr
        tableView.reloadData()
        self.chosenIPAddrChanged?()
    }
}
