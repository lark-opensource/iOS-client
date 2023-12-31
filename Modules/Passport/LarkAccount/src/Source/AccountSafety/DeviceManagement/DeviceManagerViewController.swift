//
//  MineAccountViewController.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2017/4/11.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import LarkActionSheet
import LarkUIKit
import RxSwift
import RxCocoa
import LKCommonsLogging
import RoundedHUD
import LarkContainer
import LarkAccountInterface

/// 设备登陆
class DeviceManagerViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {
    fileprivate let disposeBag = DisposeBag()

    fileprivate var validSessions: [LoginDevice] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }

    lazy var tableView: UITableView = {
        var tableView: UITableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 50
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.lu.register(cellSelf: ValidSessionsInfoCell.self)
        return tableView
    }()

    @Provider var deviceService: DeviceManageServiceProtocol // user:checked (global-resolve)
    @Provider var loginService: V3LoginService

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBase
        self.navigationController?.navigationBar.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.bgBase), for: .default)
        setupView()
        deviceService.fetchLoginDevices()
    }

    fileprivate func setupView() {
        view.addSubview(tableView)

        tableView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(CL.itemSpace)
            make.right.bottom.equalToSuperview().offset(-CL.itemSpace)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        tableView.contentInsetAdjustmentBehavior = .never
        title = I18N.Lark_Legacy_MineDataAccountanddevice
        self.deviceService.loginDevices.asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] (sessions) in
            guard let `self` = self else { return }
            self.validSessions = sessions.sorted { (model1, _) -> Bool in
                return model1.isCurrent
            }
        }).disposed(by: disposeBag)
    }
    
    fileprivate func tenantName() -> String {
        return loginService.getCurrentUser()?.user.tenant.name ?? ""
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tableView.reloadData()
        self.tableView.layoutIfNeeded()
        self.view.layoutIfNeeded()
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView(frame: .zero)
        header.backgroundColor = UIColor.ud.bgBase
        let label = UILabel(frame: .zero)
        header.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-9)
        }
        label.text = I18N.Lark_Passport_AccountSecurityCenter_ManageService_ManagePageDesc(tenantName())
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return I18N.Lark_Passport_AccountSecurityCenter_ManageService_ManagePageDesc(tenantName()).getHeight(withConstrainedWidth: view.bounds.width - 30, font: .systemFont(ofSize: 14)) + 21
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let isFirstCell = indexPath.row == 0
        let isLastCell = indexPath.row == validSessions.count - 1
        let size = cell.bounds
        let radius = 0
        let maskPath = UIBezierPath(roundedRect: size,
                                    byRoundingCorners: [UIRectCorner.topLeft, UIRectCorner.topRight, UIRectCorner.bottomLeft, UIRectCorner.bottomRight],
                                    cornerRadii: CGSize(width: radius, height: radius))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = size
        maskLayer.path = maskPath.cgPath
        cell.layer.mask = maskLayer
        cell.clipsToBounds = true
        guard isFirstCell || isLastCell else {
            return
        }
        let sizeR = cell.bounds
        let radiusR = Common.Layer.commonCardContainerViewRadius
        let maskPathR = UIBezierPath(roundedRect: sizeR,
                                    byRoundingCorners: isFirstCell && isLastCell ? [UIRectCorner.topLeft, UIRectCorner.topRight, UIRectCorner.bottomLeft, UIRectCorner.bottomRight] : isFirstCell ? [UIRectCorner.topLeft, UIRectCorner.topRight] : [UIRectCorner.bottomLeft, UIRectCorner.bottomRight],
                                    cornerRadii: CGSize(width: radiusR, height: radiusR))
        let maskLayerR = CAShapeLayer()
        maskLayerR.frame = sizeR
        maskLayerR.path = maskPathR.cgPath
        cell.layer.mask = maskLayerR
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return validSessions.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sessionInfo = validSessions[indexPath.row]
        guard let cell: ValidSessionsInfoCell = tableView.dequeueReusableCell(withIdentifier: ValidSessionsInfoCell.lu.reuseIdentifier) as? ValidSessionsInfoCell else {
            return UITableViewCell()
        }
        
        cell.set(sessionInfo: sessionInfo)
        cell.isLastCell = indexPath.row == validSessions.count - 1
        cell.kickSession = { [weak self] id, deviceName, view in
            guard let `self` = self else { return }
            let actionSheetAdapter = ActionSheetAdapter()
            let source = ActionSheetAdapterSource(sourceView: view,
                                                      sourceRect: view.bounds,
                                                      arrowDirection: [.right])
            let actionSheet = actionSheetAdapter.create(level: .normal(source: source), title: I18N.Lark_Passport_AccountSecurityCenter_ManageService_LogOutPopup(self.tenantName()))
            actionSheetAdapter.addItem(title: I18N.Lark_Legacy_Logout, textColor: UIColor.ud.functionDangerContentDefault) {
                let hud = RoundedHUD.showLoading(with: I18N.Lark_Legacy_Processing, on: self.view, disableUserInteraction: true)
                self.deviceService.disableLoginDevice(deviceID: id)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { (success) in
                        if !success {
                            hud.remove()
                            RoundedHUD.showFailure(with: I18N.Lark_Legacy_MineDataKickdeviceFail, on: self.view)
                        } else {
                            hud.remove()
                        }
                    }, onError: { [weak self] (error) in
                        guard let window = self?.view.window else {
                            assertionFailure("缺少 window")
                            return
                        }
                        Self.baseLogger.error("forceSessionInvalid error", error: error)
                        hud.remove()
                        RoundedHUD.showFailure(with: I18N.Lark_Legacy_MineDataKickdeviceFail, on: window)
                    })
                    .disposed(by: self.disposeBag)
            }

            actionSheetAdapter.addCancelItem(title: I18N.Lark_Login_Cancel)

            self.present(actionSheet, animated: true, completion: nil)
        }
        return cell
    }
}
