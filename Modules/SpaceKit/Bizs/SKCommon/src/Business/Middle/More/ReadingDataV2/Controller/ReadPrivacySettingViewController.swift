//
//  ReadPrivacySettingViewController.swift
//  SKCommon
//
//  Created by CJ on 2021/9/25.
//

import Foundation
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
import SKUIKit
import SKInfra

public final class ReadPrivacySettingViewController: BaseViewController, UITableViewDataSource {
    
    public enum From: Int {
        case infoView = 3
        case recordListView = 4
    }
    
    public var supportOrientations: UIInterfaceOrientationMask = .portrait
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.dataSource = self
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
        return UDEmptyConfig(title: .init(titleText: BundleI18n.SKResource.CreationMobile_Stats_Visits_NoPermissionToUse_title),
                             description: .init(descriptionText: BundleI18n.SKResource.CreationMobile_Stats_Visits_NoPermissionToUse_desc),
                             type: .noAccess,
                             labelHandler: nil,
                             primaryButtonConfig: nil,
                             secondaryButtonConfig: nil)
    }()
    
    private var settingOn = true
    
    fileprivate lazy var emptyView = UDEmptyView(config: adminConfig).construct { it in
        it.backgroundColor = UDColor.bgBody
        it.useCenterConstraints = true
        it.isHidden = true
    }
    
    var docsInfo: DocsInfo
    
    var from: From
    
    private var disposeBag = DisposeBag()
    
    public init(from: From, docsInfo: DocsInfo) {
        self.from = from
        self.docsInfo = docsInfo
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        showLoading(backgroundAlpha: 1)
        request()
    }
    
    public override func backBarButtonItemAction() {
        super.backBarButtonItemAction()
        DocsDetailInfoReport.settingClick(action: from == .infoView ? .basic : .record).report(docsInfo: docsInfo)
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DocsDetailInfoReport.settingView.report(docsInfo: docsInfo)
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }

    private func setupView() {
        
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

    func showAdminError() {
        emptyView.isHidden = false
        emptyView.backgroundColor = view.backgroundColor
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReadPrivacySettingCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? ReadPrivacySettingCell {
            cell.eventHandler = { [weak self] even in
                self?.handlerEvent(even)
            }
            cell.updateState(title: BundleI18n.SKResource.CreationMobile_Common_PrivacySettings_title, detail: BundleI18n.SKResource.CreationMobile_Stats_Visits_DisableDesc, isOn: self.settingOn)
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReadPrivacyHeaderView.reuseIdentifier) as? ReadPrivacyHeaderView {
            header.setTitle(BundleI18n.SKResource.CreationMobile_Common_PrivacySettings_title)
            return header
        }
        return nil
    }
}

// MARK: - handle action

extension ReadPrivacySettingViewController {
    
    func handlerEvent(_ event: ReadPrivacySettingCell.Event) {
        switch event {
        case .switch(let isOn):
            handlerSwitch(isOn)
        case .more:
            openMore()
        }
    }
    
    func handlerSwitch(_ isOn: Bool) {
        DocsDetailInfoReport.settingClick(action: isOn ? .readRecordOpen : .readRecordClose).report(docsInfo: docsInfo)
        if !DocsNetStateMonitor.shared.isReachable {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_OperateFailedNoNet, on: self.view.window ?? self.view)
            return
        }
        self.showLoading(isBehindNavBar: true, backgroundAlpha: 0.1)
        self.requestSetting(isOn: isOn) { [weak self] res in
            guard let self = self else { return }
            self.hideLoading()
            if res {
                self.settingOn = isOn
                if isOn {
                    UDToast.showSuccess(with: BundleI18n.SKResource.CreationMobile_Stats_Visits_OnToast, on: self.view.window ?? self.view)
                } else {
                    UDToast.showSuccess(with: BundleI18n.SKResource.CreationMobile_Stats_Visits_OffToast, on: self.view.window ?? self.view)
                }
            } else {
                self.settingOn = !isOn
                self.tableView.reloadData()
                UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_OperateFailedNoNet, on: self.view.window ?? self.view)
            }
        }
    }
    
    func openMore() {
        DocsDetailInfoReport.settingClick(action: .more).report(docsInfo: docsInfo)
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

// MARK: - request

// 页面简单，使用MVC即可。后续根据业务场景调整再规划

extension ReadPrivacySettingViewController {
    
    func request() {
        Observable.zip(checkAdminStatus(), getSetting()).subscribe(onNext: { [weak self] (adminIsOn, settingIsOn) in
            guard let self = self else { return }
            self.hideLoading()
            if adminIsOn {
                self.settingOn = settingIsOn
                self.tableView.reloadData()
            } else {
                self.showAdminError()
            }
        }).disposed(by: disposeBag)
    }
    
    /// 获取用户隐私设置开关
    public func getSetting() -> Observable<Bool> {
        return Observable.create { [weak self] ob in
            let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getUserProperties, params: nil)
                .set(method: .GET)
                .set(timeout: 20)
                .set(encodeType: .urlEncodeDefault)
            request.start(callbackQueue: DispatchQueue.main, result: { [weak self] json, error in
                guard let self = self else { return }
                guard error == nil else {
                    ob.onNext(false)
                    if let err = error as NSError?, err.code == 8 {
                        DocsLogger.error("ReadPrivacySetting getSetting errorCode:\(err.code)")
                        return
                    }
                    DocsLogger.error("ReadPrivacySetting getSetting error", error: error)
                    return
                }
                if let code = json?["code"].int, code == 8 {
                    ob.onNext(false)
                    return
                }
                let isOn = json?["data"]["settings"]["allow_read_list_setting"].boolValue ?? false
                ob.onNext(isOn)
            })
            request.makeSelfReferenced()
            return Disposables.create {
                request.cancel()
            }
        }
    }
    
    public func requestSetting(isOn: Bool, result: @escaping ((Bool) -> Void)) {
        let params = ["properties": ["allow_read_list_setting": isOn]]
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.setUserProperties, params: params)
            .set(method: .POST)
            .set(timeout: 20)
            .set(encodeType: .jsonEncodeDefault)
        request.start(callbackQueue: DispatchQueue.main, result: {json, error in
            guard error == nil else {
                DocsLogger.error("ReadPrivacySetting requestSetting error", error: error)
                result(false)
                return
            }
            guard let code = json?["code"].int, code == 0 else {
                DocsLogger.info("ReadPrivacySetting requestSetting code is not equal 0")
                result(false)
                return
            }
            result(true)
        })
        request.makeSelfReferenced()
    }
    
    /// 现在只有这个接口能检查是Admin开关状态
    func checkAdminStatus() -> Observable<Bool> {
        let token = docsInfo.objToken
        let type = docsInfo.type.rawValue
        var path = OpenAPI.APIPath.getReadRecordInfo + "?obj_type=\(type)&token=\(token)&get_view_count=\(true)&page_size=\(20)"
        return Observable.create { ob in
            let request = DocsRequest<JSON>(path: path, params: nil)
                .set(method: .GET)
                .set(timeout: 20)
                .set(encodeType: .urlEncodeDefault)
            request.start(callbackQueue: DispatchQueue.main, result: { json, error in
                guard error == nil else {
                    if let err = error as? NSError, err.code == 8 {
                        ob.onNext(false)
                        DocsLogger.error("ReadPrivacySetting checkAdminStatus close")
                        return
                    }
                    // 其他错误 暂不处理
                    DocsLogger.error("ReadPrivacySetting checkAdminStatus error", error: error)
                    ob.onNext(true)
                    return
                }
                if let code = json?["code"].int, code == 8 {
                    DocsLogger.error("ReadPrivacySetting checkAdminStatus close")
                    ob.onNext(false)
                    return
                }
                ob.onNext(true)
            })
            request.makeSelfReferenced()
            return Disposables.create {
                request.cancel()
            }
        }
    }
}
