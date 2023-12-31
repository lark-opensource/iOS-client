//
//  SchedulerChangeHostViewController.swift
//  Calendar
//
//  Created by tuwenbo on 2023/4/3.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import RxRelay
import UniverseDesignButton
import UniverseDesignIcon
import UniverseDesignToast
import LarkUIKit
import LarkContainer

protocol SchedulerChangeHostParamType {
    var schedulerID: String { get }
    var appointmentID: String { get }
    var creatorID: String { get }
    var hostID: String { get }
    var startTime: Int64 { get }
    var endTime: Int64 { get }
    var message: String { get }
    var email: String { get }
    var timeZone: String { get }
    var chatID: String { get }
}

final class SchedulerChangeHostViewController: UIViewController, UserResolverWrapper {

    static let controllerHeight: CGFloat = 540

    private let disposeBag = DisposeBag()
    private let viewModel: SchedulerChangeHostViewModel

    private let params: SchedulerChangeHostParamType

    var onConfirmed: (() -> Void)?

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.closeSmallOutlined).scaleNaviSize().renderColor(with: .n1), for: .normal)
        button.addTarget(self, action: #selector(onClose), for: .touchUpInside)
        return button
    }()

    private lazy var titleView: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.ud.title3(.fixed)
        label.text = I18n.Calendar_Scheduling_ChangeHost_Bot
        return label
    }()

    private lazy var confirmButton: UDButton = {
        var config = UDButtonUIConifg.textBlue
        var button = UDButton(config)
        button.backgroundColor = .clear
        button.setTitle(I18n.Calendar_Common_Confirm, for: .normal)
        button.addTarget(self, action: #selector(onConfirm), for: .touchUpInside)
        button.titleLabel?.font = UIFont.ud.body0(.fixed)
        return button
    }()

    private lazy var headerView: UIView = {
        let header = UIView()
        header.backgroundColor = UIColor.ud.bgBody
        return header
    }()

    private lazy var divider: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    private lazy var contentView: UIView = {
        let uiView = UIView()
        uiView.backgroundColor = UIColor.ud.bgBody
        uiView.layer.cornerRadius = 10
        uiView.layer.masksToBounds = true
        return uiView
    }()

    private lazy var loadingView: LoadingView = {
        let loadingView = LoadingView(displayedView: self.contentView, centerYMultiplier: 131.0 / 144.0)
        return loadingView
    }()

    private lazy var changeHostView = SchedulerChangeHostView()

    let userResolver: UserResolver

    init(params: SchedulerChangeHostParamType, userResolver: UserResolver) {
        self.params = params
        self.userResolver = userResolver
        self.viewModel = SchedulerChangeHostViewModel(params: params, userResolver: userResolver)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bindRx()
        viewModel.loadAvaiableHost()
    }

    private func bindRx() {
        viewModel.rxViewData.subscribeForUI {[weak self] data in
            guard let self = self else { return }
            switch data {
            case .loading:
                self.changeHostView.isHidden = true
                self.loadingView.showLoading()
            case .error:
                self.changeHostView.isHidden = true
                self.loadingView.showFailed { self.retry() }
            case .data(let hosts):
                self.loadingView.remove()
                self.changeHostView.isHidden = false
                self.changeHostView.viewData = hosts
            case .finish(let err):
                if err == nil {
                    self.onClose()
                } else {
                    if err?.errorCode() == 8400 {
                        UDToast.showFailure(with: I18n.Calendar_Scheduling_EventStartedExpiredUnable, on: self.view)
                    } else {
                        UDToast.showFailure(with: I18n.Calendar_G_SomethingWentWrong, on: self.view)
                    }
                }
            }
        }.disposed(by: disposeBag)
    }

    private func setupView() {
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.top.left.right.equalToSuperview()
        }

        headerView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(28)
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().inset(14)
        }

        headerView.addSubview(titleView)
        titleView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        headerView.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().inset(14)
        }

        view.addSubview(divider)
        divider.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.left.right.equalToSuperview()
            make.top.equalTo(headerView.snp.bottom)
        }

        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.equalTo(divider.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        contentView.addSubview(changeHostView)
        changeHostView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        changeHostView.isHidden = true
        changeHostView.selectedHostID = params.hostID
    }

    @objc
    private func onConfirm() {
        onConfirmed?()
        let newSelect = changeHostView.selectedHostID
        if !newSelect.isEmpty && newSelect != params.hostID {
            viewModel.changeHost(newHosts: [newSelect])
        } else {
            self.dismissSelf()
        }
    }

    @objc
    private func onClose() {
        self.dismissSelf()
    }

    private func dismissSelf() {
        self.parent?.dismiss(animated: true)
    }

    private func retry() {
        viewModel.loadAvaiableHost()
    }
}
