//
//  PrivacySettingViewController.swift
//  SKCommon
//
//  Created by peilongfei on 2023/12/12.
//  


import SKFoundation
import SKResource
import SwiftyJSON
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignEmpty
import UIKit
import EENavigator
import LarkAppConfig
import RxSwift
import RxCocoa
import RxRelay
import SKUIKit
import SKInfra

public final class PrivacySettingViewController: BaseViewController {

    public enum From: Int {
        case infoView = 3
        case recordListView = 4
    }

    public var supportOrientations: UIInterfaceOrientationMask = .portrait

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = ReadPrivacyHeaderView.height
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.bounces = false
        tableView.backgroundColor = .clear
        tableView.register(ReadPrivacySettingCell.self, forCellReuseIdentifier: ReadPrivacySettingCell.reuseIdentifier)
        tableView.register(ReadPrivacyHeaderView.self, forHeaderFooterViewReuseIdentifier: ReadPrivacyHeaderView.reuseIdentifier)
        return tableView
    }()

    fileprivate lazy var adminConfig: UDEmptyConfig = {
        return UDEmptyConfig(title: .init(titleText: BundleI18n.SKResource.LarkCCM_Docs_DocDetail_PrivacyNoAvailable_Descrip
),
                             description: nil,
                             type: .noAccess,
                             labelHandler: nil,
                             primaryButtonConfig: nil,
                             secondaryButtonConfig: nil)
    }()

    fileprivate lazy var emptyView = UDEmptyView(config: adminConfig).construct { it in
        it.backgroundColor = UDColor.bgBase
        it.useCenterConstraints = true
        it.isHidden = true
    }

    private let from: From

    private let viewModel: PrivacySettingViewModel

    private let disposeBag = DisposeBag()

    public init(from: From, docsInfo: DocsInfo) {
        self.from = from
        self.viewModel = PrivacySettingViewModel(docsInfo: docsInfo)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBinding()
        viewModel.fetchData()
    }

    public override func backBarButtonItemAction() {
        super.backBarButtonItemAction()
        DocsDetailInfoReport.settingClick(action: from == .infoView ? .basic : .record).report(docsInfo: viewModel.docsInfo)
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DocsDetailInfoReport.settingView.report(docsInfo: viewModel.docsInfo)
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }

    private func setupUI() {

        title = BundleI18n.SKResource.CreationMobile_Common_PrivacySettings_tab
        view.backgroundColor = UDColor.bgBase

        navigationBar.customizeBarAppearance(backgroundColor: view.backgroundColor)
        statusBar.backgroundColor = view.backgroundColor

        view.addSubview(tableView)
        view.addSubview(emptyView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(self.navigationBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension PrivacySettingViewController: UITableViewDataSource, UITableViewDelegate {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.models.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = viewModel.models[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ReadPrivacySettingCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? ReadPrivacySettingCell {
            cell.eventHandler = { [weak self] even in
                self?.handlerEvent(with: even, model: model)
            }
            cell.updateState(title: model.title, detail: model.detail, isOn: model.isOn)
            return cell
        }
        return UITableViewCell(frame: .zero)
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReadPrivacyHeaderView.reuseIdentifier) as? ReadPrivacyHeaderView {
            header.setTitle(BundleI18n.SKResource.CreationMobile_Common_PrivacySettings_title)
            return header
        }
        return nil
    }
}

extension PrivacySettingViewController {

    func handlerEvent(with event: ReadPrivacySettingCell.Event, model: SwitchSettingModel) {
        switch event {
        case .switch(let isOn):
            viewModel.handlerSwitch(isOn, model: model)
        case .more:
            openMore()
        }
    }

    func openMore() {
        DocsDetailInfoReport.settingClick(action: .more).report(docsInfo: viewModel.docsInfo)
        guard let nav = self.navigationController else {
            return
        }
        do {
            let url = try HelpCenterURLGenerator.generateURL(article: .privacySettingHelpCenter)
            Navigator.shared.push(url, from: nav)
        } catch {
            DocsLogger.error("failed to generate helper center URL when openMorefrom privacy setting", error: error)
        }
    }
}

extension PrivacySettingViewController {

    func setupBinding() {
        self.viewModel.uiAction
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] action in
                guard let self = self else { return }
                switch action {
                case .reloadTableView:
                    self.tableView.reloadData()

                case let .showLoading(isLoading, coverPage):
                    if isLoading {
                        if coverPage {
                            self.showLoading(backgroundAlpha: 1)
                        } else {
                            self.showLoading(isBehindNavBar: true, backgroundAlpha: 0.1)
                        }
                    } else {
                        self.hideLoading()
                    }

                case let .showEmpty(isEmpty):
                    if isEmpty {
                        self.emptyView.isHidden = false
                    } else {
                        self.emptyView.isHidden = true
                    }

                case let .showToast(type):
                    switch type {
                    case let .success(msg):
                        UDToast.showSuccess(with: msg, on: self.view.window ?? self.view)
                    case let .error(msg):
                        UDToast.showFailure(with: msg, on: self.view.window ?? self.view)
                    }
                }
            }).disposed(by: disposeBag)
    }
}
