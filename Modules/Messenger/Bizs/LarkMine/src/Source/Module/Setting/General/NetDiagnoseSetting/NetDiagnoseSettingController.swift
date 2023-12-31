//
//  NetDiagnoseSettingController.swift
//  LarkMine
//
//  Created by huanglx on 2021/12/15.
//

import Foundation
import LarkUIKit
import RxSwift
import LarkModel
import UniverseDesignToast
import LarkFocus
import EENavigator
import UIKit
import LarkFoundation
import UniverseDesignTheme
import SwiftUI
import LKCommonsTracker
import LarkSDKInterface

private typealias Path = LarkSDKInterface.PathWrapper

//网络诊断vc
final class NetDiagnoseSettingController: BaseUIViewController,
                                    UITableViewDataSource,
                                    UITableViewDelegate,
                                    NetDiagnoseNavBarDelegate,
                                    NetDiagnoseBottomViewDelegate,
                                    NetDiagnoseSettingViewModelDelegate,
                                    UIDocumentInteractionControllerDelegate {
    ///网络诊断vm
    private let viewModel: NetDiagnoseSettingViewModel
    /// 表格视图
    private lazy var tableView = self.createTableView()
    private lazy var navBar = self.createNavNar()
    private lazy var headerView = self.createHeaderView()
    private lazy var footerView = self.createFoooterView()
    private lazy var gradientView = self.createGradientView()
    private let disposeBag = DisposeBag()
    private let navHeight = 80.0
    private let tableHeaderHeight = 132.0

    init(viewModel: NetDiagnoseSettingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.isNavigationBarHidden = true
        self.view.backgroundColor = UIColor.ud.bgBody
        ///初始化数据
        self.viewModel.setupNetDiagnoseItems()
        self.viewModel.startObserver()
        self.viewModel.delegate = self

        self.view.addSubview(self.gradientView)
        self.gradientView.snp.makeConstraints { (make) in
            make.top.left.trailing.equalToSuperview()
            make.height.equalTo(navHeight + tableHeaderHeight)
        }

        ///添加nav
        self.view.addSubview(self.navBar)
        self.navBar.snp.makeConstraints { (make) in
            make.top.left.trailing.equalToSuperview()
            make.height.equalTo(navHeight)
        }
        ///添加footer
        self.view.addSubview(self.footerView)
        var footerOffset = -8
        if Display.iPhoneXSeries {
            footerOffset = -34
        }
        self.footerView.snp.makeConstraints { (make) in
            make.height.equalTo(56)
            make.left.right.trailing.equalToSuperview()
            make.bottom.trailing.equalToSuperview().offset(footerOffset)
        }
        /// 添加表格视图
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.top.equalTo(navBar.snp.bottom)
            make.left.right.trailing.equalToSuperview()
            make.bottom.equalTo(footerView.snp.top)
        }
        /// 刷新表格和头尾
        self.viewModel.reloadDataDriver.drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.tableView.reloadData()
            self.gradientView.set(status: self.viewModel.diagnoseStatus)
            self.headerView.set(status: self.viewModel.diagnoseStatus)
            self.footerView.set(status: self.viewModel.diagnoseStatus)
        }).disposed(by: self.disposeBag)
        //开始检测
        self.viewModel.startDiagnose()
        self.footerView.set(status: self.viewModel.diagnoseStatus)
        var trackerParams: [String: String] = [:]
        trackerParams.updateValue(self.viewModel.from.rawValue, forKey: "occasion")
        MineTracker.trackNetworkCheckPageShowView(trackerParams: trackerParams)
    }

    /// 创建表格视图
    private func createTableView() -> UITableView {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = self.headerView
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = .clear
        tableView.lu.register(cellSelf: NetDiagnoseCell.self)
        tableView.lu.register(cellSelf: NetDiagnoseBaseInfoCell.self)
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.separatorStyle = .none
        tableView.bounces = false
        return tableView
    }

    //创建渐变view
    private func createGradientView() -> NetDiagnoseHeaderGradientView {
        let gradientView = NetDiagnoseHeaderGradientView()
        gradientView.set(status: self.viewModel.diagnoseStatus)
        return gradientView
    }

    //创建navBar
    private func createNavNar() -> NetDiagnoseNavBar {
        let navBar = NetDiagnoseNavBar()
        navBar.delegate = self
        return navBar
    }

    //创建header
    private func createHeaderView() -> NetDiagnoseHeaderView {
        let view = NetDiagnoseHeaderView()
        view.set(status: self.viewModel.diagnoseStatus)
        let screenWidth: CGFloat = self.view.bounds.width
        view.frame = CGRect(x: 0, y: 0, width: screenWidth, height: tableHeaderHeight)
        return view
    }

    //创建footer
    private func createFoooterView() -> NetDiagnoseBottomView {
        let view = NetDiagnoseBottomView()
        view.delegate = self
        return view
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.netDiagnoseItems.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 { //基本信息
            guard let cell = tableView.dequeueReusableCell(withIdentifier: NetDiagnoseBaseInfoCell.lu.reuseIdentifier) as? NetDiagnoseBaseInfoCell else {
                return UITableViewCell()
            }
            cell.set(title: BundleI18n.LarkMine.Lark_NetworkDiagnosis_Info,
                     appVersion: "\(BundleI18n.LarkMine.Lark_NewSettings_AboutFeishuCurrentVersionMobile)V\(LarkFoundation.Utils.appVersion)",
                     osVersion:
                        "\(BundleI18n.LarkMine.Lark_NetworkDiagnosis_SystemVersion):   iOS \(UIDevice.current.systemVersion)", status: self.viewModel.diagnoseStatus)
            return cell
        } else {    //诊断信息
            guard let cell = tableView.dequeueReusableCell(withIdentifier: NetDiagnoseCell.lu.reuseIdentifier) as? NetDiagnoseCell else {
                return UITableViewCell()
            }
            let netDiagnoseItems = self.viewModel.netDiagnoseItems
            guard netDiagnoseItems.count > indexPath.row - 1 else {
                return UITableViewCell()
            }
            if let netDiagnoseItem = netDiagnoseItems[indexPath.row - 1] as? NetDiagnoseItem {
                cell.set(title: netDiagnoseItem.itemName, desc: netDiagnoseItem.itemDesc, status: netDiagnoseItem.status)
                return cell
            }
        }
        return UITableViewCell()
    }

    // MARK: NetDiagnoseBottomViewDelegate
    //开始诊断
    func startDiagnose() {
        self.viewModel.startDiagnose()
    }
    //停止诊断
    func stopDiagnose() {
        self.viewModel.canceDiagnose()
    }
    //重新诊断
    func againDiagnose() {
        self.viewModel.againDiagnose()
    }
    //查看日志
    func viewLog() {
        self.viewModel.viewLogs()
    }

    // MARK: NetDiagnoseHeaderViewDelegate
    //点击返回
    func backButtonClicked() {
        self.viewModel.userNavigator.pop(from: self)
    }

    // MARK: NetDiagnoseSettingViewModelDelegate
    //展示actionSheet
    private var documentIteractionController: UIDocumentInteractionController?
    public func showNetDiagnoseActionSheet(filePath: String) {
        if Path(filePath).exists {
            let fileURL = NSURL.fileURL(withPath: filePath)
            let vc = UIDocumentInteractionController()
            self.documentIteractionController = vc
            vc.delegate = self
            vc.url = fileURL
            vc.presentOptionsMenu(from: self.view.bounds, in: self.view, animated: true)
        }
    }

    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }

    func documentInteractionControllerViewForPreview(_ controller: UIDocumentInteractionController) -> UIView? {
        return self.view
    }

    func documentInteractionControllerRectForPreview(_ controller: UIDocumentInteractionController) -> CGRect {
        self.view.frame
    }
}
