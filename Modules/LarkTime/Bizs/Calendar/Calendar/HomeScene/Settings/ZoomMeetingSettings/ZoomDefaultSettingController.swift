//
//  ZoomDefaultSettingController.swift
//  Calendar
//
//  Created by pluto on 2022-10-21.
//

import UIKit
import Foundation
import LarkContainer
import LKCommonsLogging
import UniverseDesignEmpty
import UniverseDesignToast
import EENavigator
import RxCocoa
import RxSwift
import FigmaKit
import LarkUIKit

final class ZoomDefaultSettingController: BaseUIViewController, UserResolverWrapper {
    enum PlaceholderStatus {
        case loading
        case accountRebind
        case normal
    }

    private let logger = Logger.log(ZoomDefaultSettingController.self, category: "calendar.ZoomDefaultSettingController")
    let viewModel: ZoomDefaultSettingViewModel
    private let disposeBag = DisposeBag()

    @ScopedInjectedLazy var serverPushService: ServerPushService?

    let userResolver: UserResolver

    let doneItem = LKBarButtonItem(title: I18n.Calendar_Common_Save, fontStyle: .medium)
    let cancelItem = LKBarButtonItem(title: I18n.Calendar_Common_Cancel)

    private lazy var settingView = ZoomSettingListView()
    private lazy var loadingView: ZoomCommonPlaceholderView = {
        let view = ZoomCommonPlaceholderView()
        view.layoutNaviOffsetStyle()
        view.isHidden = false
        return view
    }()

    private lazy var loadingFailedView: UDEmptyView = {
        let view = UDEmptyView(config: UDEmptyConfig(title: UDEmptyConfig.Title(titleText: I18n.Calendar_Zoom_AccountInvalid),
                                                     description: UDEmptyConfig.Description(descriptionText: I18n.Calendar_Zoom_BindAgainReenter),
                                                     type: .custom(EmptyBundleResources.image(named: "vcEmptyNegativeZoomFailure")),
                                                     primaryButtonConfig: (I18n.Calendar_Zoom_BindAgain, {[weak self] _ in
            guard let self = self else { return }
            // 账号失效 -》 获取链接并绑定
            self.viewModel.loadZoomOauthUrlAndBind()
        })))
        view.useCenterConstraints = true
        view.isHidden = true
        view.backgroundColor = EventEditUIStyle.Color.viewControllerBackground
        return view
    }()

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(EventEditUIStyle.Color.viewControllerBackground)
    }

    var loadingStatus: PlaceholderStatus = .loading {
        didSet {
            switch loadingStatus {
            case .loading:
                loadingView.isHidden = false
                loadingFailedView.isHidden = true
            case .normal:
                loadingView.isHidden = true
                loadingFailedView.isHidden = true
            case .accountRebind:
                loadingView.isHidden = true
                loadingFailedView.isHidden = false
            }
        }
    }

    init (viewModel: ZoomDefaultSettingViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
        settingView.delegate = self
        viewModel.delegate = self

        viewModel.setPlaceHolderStatus = { [weak self] status in
            self?.loadingStatus = status
        }

        CalendarTracerV2.EventZoomSetting.traceView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = I18n.Calendar_Zoom_MeetSet
        setupNaviItem()
        setupViews()

        bindViewModel()

        registerBindAccountNotification()
    }

    private func bindViewModel() {
        viewModel.rxViewData.bind(to: settingView).disposed(by: disposeBag)
        viewModel.rxToast
            .bind(to: rx.toast)
            .disposed(by: disposeBag)

        viewModel.rxRoute
            .subscribeForUI(onNext: {[weak self] route in
                guard let self = self else { return }
                switch route {
                case let .url(url):
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }).disposed(by: disposeBag)
    }

    private func registerBindAccountNotification() {
        serverPushService?
            .rxZoomBind
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.logger.info("Zoom Account Notification Bind Success Push")
                self.viewModel.loadZoomSetting()
                UDToast.showTips(with: I18n.Calendar_Settings_BindSuccess, on: self.view)
            }).disposed(by: disposeBag)
    }

    private func setupNaviItem() {
        navigationItem.leftBarButtonItem = cancelItem
        cancelItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.dismiss(animated: true)
            }
            .disposed(by: disposeBag)

        doneItem.button.tintColor = UIColor.ud.primaryContentDefault
        navigationItem.rightBarButtonItem = doneItem
        doneItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.viewModel.onSaveSettings()
                CalendarTracerV2.EventZoomSetting.traceClick {
                    $0.click("confirm")
                }
            }
            .disposed(by: disposeBag)
    }

    private func setupViews() {
        view.addSubview(settingView)
        view.addSubview(loadingView)
        view.addSubview(loadingFailedView)

        settingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        loadingFailedView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func updateSaveBtnStatus(enable: Bool) {
        doneItem.isEnabled = enable
    }
}

extension ZoomDefaultSettingController: ZoomDefaultSettingViewModelDelegate {
    func updateSecurityNoticeTips(needShow: Bool) {
        settingView.updateSecurityNoticeTips(needShow: needShow)
        if viewModel.hasSecurityError {
            updateSaveBtnStatus(enable: false)
        } else {
            if viewModel.hasInputError { return }
            updateSaveBtnStatus(enable: true)
        }
    }

    func updateErrorNoticeTips(errorState: Server.UpdateZoomSettingsResponse.State, passTips: [String], hostTip: String) {
        settingView.updateErrorNoticeTips(errorState: errorState, passTips: passTips, hostTip: hostTip)
        updateSaveBtnStatus(enable: false)
    }

    func zoomSettingDismissCallBack() {
        self.dismiss(animated: true)
    }

    func updateErrorTipsStatus(type: Server.UpdateZoomSettingsResponse.State) {
        settingView.hideErrorTips(type: type)

        if !viewModel.hasSecurityError {
            updateSaveBtnStatus(enable: true)
        }
    }
}
