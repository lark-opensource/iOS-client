//
//  RedPacketCoverController.swift
//
//  Created by JackZhao on 2021/10/28.
//  Copyright © 2021 JACK. All rights reserved.
//

import RxSwift
import LarkCore
import LarkUIKit
import Foundation
import EENavigator
import LarkSDKInterface
import LKCommonsLogging
import UniverseDesignToast
import LarkMessengerInterface
import UIKit
import LarkContainer

// 红包封面控制器
final class RedPacketCoverController: BaseUIViewController,
                                UITableViewDelegate,
                                UITableViewDataSource,
                                        UserResolverWrapper {
    private static let logger = Logger.log(RedPacketCoverController.self, category: "LarkFinace")
    var userResolver: LarkContainer.UserResolver

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.register(RedPacketCoverCell.self, forCellReuseIdentifier: NSStringFromClass(RedPacketCoverCell.self))
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    private let naviBar = TitleNaviBar(titleString: BundleI18n.LarkFinance.Lark_RedPacket_PacketTheme)

    private let viewModel: RedPacketCoverViewModel
    private var datas: [RedPacketCoverCellViewModel] = []
    private let disposeBag = DisposeBag()

    init(viewModel: RedPacketCoverViewModel,
         userResolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBody

        configNavigation()
        initView()
        showLoading()
        bindEvent()
    }

    private func bindEvent() {
        viewModel.coverItemCellTapHandler = { [weak self] identifier in
            guard let self = self else { return }
            // check the data is Empty
            if self.datas.isEmpty {
                Self.logger.info("data empty")
                assertionFailure("data empty")
                return
            }
            let covers = self.datas.reduce([]) { res, data in
                return res + data.datas.map { $0.cover }
            }
            var body = RedPacketCoverDetailBody(tapCoverId: identifier,
                                                covers: covers)
            // pop current page when user touches the confirm button
            body.confirmHandler = { [weak self] in
                self?.popSelf()
            }
            body.coverIdToThemeTypeMap = self.viewModel.coverIdToThemeTypeMap
            // open cover detail page
            self.userResolver.navigator.present(body: body,
                                     from: self,
                                     prepare: {
                $0.modalPresentationStyle = .overCurrentContext
            })
        }
        // observe data changes then reload table
        viewModel.dataObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (res) in
                guard let self = self else { return }
                switch res {
                case .success(let datas):
                    self.datas = datas
                    // hidden loading when data get
                    if !datas.isEmpty, !self.loadingPlaceholderView.isHidden {
                        self.loadingPlaceholderView.isHidden = true
                    }
                    self.tableView.reloadData()
                case .failure(let error):
                    self.loadingPlaceholderView.isHidden = true
                    UDToast.showFailure(with: BundleI18n.LarkFinance.Lark_Legacy_NetworkError, on: self.view, error: error)
                }
            }).disposed(by: self.disposeBag)

    }

    private func showLoading() {
        loadingPlaceholderView.isHidden = false
        loadingPlaceholderView.snp.remakeConstraints { make in
            make.top.equalTo(naviBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }

    private func configNavigation() {
        isNavigationBarHidden = true
        let titleColor = UIColor.ud.primaryOnPrimaryFill
        view.addSubview(naviBar)
        (naviBar.titleView as? UILabel)?.textColor = titleColor
        naviBar.backgroundColor = UIColor.ud.functionDangerContentDefault
        naviBar.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }

        let backButton = UIButton()
        let backIcon = Resources.red_packet_back.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
        backButton.setImage(backIcon, for: .normal)
        backButton.setImage(backIcon, for: .selected)
        backButton.addTarget(self, action: #selector(closeOrBackButtonDidClick), for: .touchUpInside)
        naviBar.addSubview(backButton)
        backButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 48, height: 48))
            make.centerY.equalTo(naviBar.titleView.snp.centerY)
            make.left.equalToSuperview()
        }
    }

    private func initView() {
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.equalTo(4)
            make.right.bottom.equalToSuperview()
            make.top.equalTo(naviBar.snp.bottom)
        }
    }

    @objc
    private func closeOrBackButtonDidClick() {
        self.popSelf()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < datas.count else {
            Self.logger.info(" cellForRowAt datasource out of range, indexPath.row: \(indexPath.row) datas.count: \(datas.count)")
            assertionFailure("datasource out of range")
            return UITableViewCell()
        }
        let cellVM = datas[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellVM.reuseIdentify, for: indexPath) as? RedPacketCoverCell else { return UITableViewCell() }
        cell.viewModel = cellVM
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }
}
