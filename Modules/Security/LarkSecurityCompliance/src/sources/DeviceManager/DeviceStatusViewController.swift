//
//  DeviceStatusViewController.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/4/12.
//

import UIKit
import LarkUIKit
import SnapKit
import RxSwift
import RxCocoa
import UniverseDesignActionPanel
import UniverseDesignToast
import LarkSecurityComplianceInfra
import ByteDanceKit

final class DeviceStatusViewController: BaseViewController<DeviceStatusViewModel>, DeviceStatusViewDelegate {

    private let container = Container(frame: LayoutConfig.bounds)

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgBase)
    }

    override func loadView() {
        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        container.statusView.delegate = self
        if Display.phone {
            title = I18N.Lark_Conditions_Device
        }

        Logger.info("show device status view")

        viewModel.deviceInfoResp
            .observeOn(MainScheduler.instance)
            .bind { [weak self] resp in
                self?.container.statusView.model = resp
            }
            .disposed(by: viewModel.bag)
        
        // 等申报理由页消失后再弹alert
        Observable.combineLatest(viewModel.showAlert,
                                 viewModel.deviceDeclarationDismissed)
            .observeOn(MainScheduler.instance)
            .bind { [weak self] (alert, dismissed) in
                Logger.info("declaration justification combineLatest:\(alert), dismissed:\(dismissed)")
                guard let self, dismissed else { return }
                self.showAlert(with: alert)
            }.disposed(by: viewModel.bag)
        
        viewModel.toast
            .observeOn(MainScheduler.instance)
            .bind { [weak self] type in
                guard let self else { return }
                let config = self.toastConfigWithType(type)
                if let topVC = BTDResponder.topViewController() {
                    UDToast.showToast(with: config, on: topVC.view)
                } else {
                    UDToast.showToast(with: config, on: self.view)
                }
            }
            .disposed(by: viewModel.bag)
        
        viewModel.applyEntryButton
            .map { [weak self] in self }
            .bind(to: viewModel.showJustificationSheet)
            .disposed(by: viewModel.bag)
    }

    private func toastConfigWithType(_ type: DeviceStatusViewModel.Toast) -> UDToastConfig {
        switch type {
        case .info(let str):
            return UDToastConfig(toastType: .info, text: str, operation: nil)
        case .failed(let str):
            return UDToastConfig(toastType: .error, text: str, operation: nil)
        case .success(let str):
            return UDToastConfig(toastType: .success, text: str, operation: nil)
        case .warning(let str):
            return UDToastConfig(toastType: .warning, text: str, operation: nil)
        }
    }

    // MARK: - DeviceStatusTableCellDelegate
    /// 点击申报按钮
    func didTapApplyEntryButton(_ from: UIButton) {
        showOwnershipSelectionSheet()
    }

    /// 点击刷新按钮
    func didTapRefreshButton(_ from: UIButton) {
        viewModel.refreshButton.onNext(())
    }

    private func showAlert(with alert: DeviceStatusViewModel.Alert) {
        switch alert {
        case .waiting:
            Alerts.showAlert(from: self, title: I18N.Lark_Conditions_TipsNotice, content: I18N.Lark_Conditions_Submitted, actions: [
                Alerts.AlertAction(title: I18N.Lark_Conditions_GotIt, style: .default, handler: nil)
            ])
        case .successImmediately:
            var actions = [Alerts.AlertAction(title: I18N.Lark_Conditions_GotIt, style: .secondary, handler: nil)]
            if viewModel.isAccessLimited {
                actions.append(Alerts.AlertAction(title: I18N.Lark_Conditions_VisitAgain, style: .default, handler: { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }))
            }
            Alerts.showAlert(from: self, title: I18N.Lark_Conditions_TipsNotice, content: I18N.Lark_Conditions_SuccessfulYay, actions: actions)
        case .success:
            Alerts.showAlert(from: self, title: I18N.Lark_Conditions_TipsNotice, content: I18N.Lark_Conditions_SuccessfulYay, actions: [
                Alerts.AlertAction(title: I18N.Lark_Conditions_GotIt, style: .secondary, handler: { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                })
            ])
        case .rejected:
            Alerts.showAlert(from: self, title: I18N.Lark_Conditions_TipsNotice, content: I18N.Lark_Conditions_TakenBack, actions: [
                Alerts.AlertAction(title: I18N.Lark_Conditions_GotIt, style: .secondary, handler: nil),
                Alerts.AlertAction(title: I18N.Lark_Conditions_OkDoAgain, style: .default, handler: { [weak self] in
                    self?.showOwnershipSelectionSheet()
                })
            ])
        }
    }

    private func showOwnershipSelectionSheet() {
        let items = [
            UDActionSheetItem(title: I18N.Lark_SelfDeclareDevice_Option_OrganizationDevice, style: .default, action: { [weak self] in
                self?.viewModel.applyOwnership = .company
                self?.viewModel.applyEntryButton.onNext(())
            }),
            UDActionSheetItem(title: I18N.Lark_SelfDeclareDevice_Option_PersonalDevice, style: .default, action: { [weak self] in
                self?.viewModel.applyOwnership = .personal
                self?.viewModel.applyEntryButton.onNext(())
            })
        ]
        Alerts.showSheet(source: container.statusView.applyButton, from: self, title: I18N.Lark_Conditions_SelectBelonging, items: items)
    }
}

private final class Container: UIView {

    let bgView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    let statusView = DeviceStatusView(frame: CGRect(x: 0, y: 0, width: 100, height: 200))

    let padTitleLabel: UILabel = {
        let label = UILabel()
        label.text = I18N.Lark_Conditions_Device
        label.font = UIFont.systemFont(ofSize: 26)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = I18N.Lark_Conditions_DeviceSecurity
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        label.numberOfLines = 0
        return label
    }()

    var statusHeight: Constraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        
        statusView.deviceStatusViewDidUpdate = { [weak self] (height) in
            guard let self else { return }
            let offset = self.titleLabel.frame.maxY
            let superHeight = self.superview?.frame.height ?? 0
            let originY = self.frame.minY
            self.statusHeight?.update(offset: min(height, superHeight - 12 - offset - originY - LayoutConfig.safeAreaInsets.bottom))
        }
    }

    required init?(coder: NSCoder) {
        return nil
    }

    private func setupViews() {
        addSubview(bgView)
        bgView.addSubview(statusView)
        bgView.addSubview(titleLabel)

        if !Display.phone {
            bgView.addSubview(padTitleLabel)
            padTitleLabel.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.left.equalTo(16)
                make.right.equalTo(-16)
            }
        }

        bgView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            if Display.phone {
                make.top.width.equalToSuperview()
            } else {
                make.width.equalTo(400)
                make.centerY.equalToSuperview()
                make.height.lessThanOrEqualToSuperview()
            }
        }
        titleLabel.snp.makeConstraints { make in
            if Display.phone {
                make.top.equalTo(20)
                make.left.equalTo(16)
                make.right.equalTo(-16)
            } else {
                make.top.equalTo(padTitleLabel.snp.bottom).offset(24)
                make.left.equalTo(16)
                make.right.equalTo(-16)
            }
        }
        statusView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.bottom.equalToSuperview()
            statusHeight = make.height.equalTo(0).constraint
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !Display.phone {
            let width = min(400, bounds.width)
            bgView.snp.updateConstraints { make in
                make.width.equalTo(width)
            }
        }
    }
}
