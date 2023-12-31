//
//  LDRGuideViewController.swift
//  LarkContact
//
//  Created by mochangxing on 2021/4/2.
//

import UIKit
import Foundation
import ServerPB
import LarkUIKit
import RxSwift
import EENavigator
import LKCommonsTracker
import Homeric
import LarkTab
import UniverseDesignToast
import UniverseDesignTheme
import UniverseDesignFont
import UniverseDesignColor
import LarkContainer

final class LDRGuideViewController: BaseUIViewController, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    private var disposeBag = DisposeBag()
    private lazy var successTipsView: LDRGuideTipView = {
        let successTipsView = LDRGuideTipView()
        successTipsView.backgroundColor = UIColor.ud.bgBody
        return successTipsView
    }()

    private lazy var enterTeamButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.setTitle(BundleI18n.LDR.Lark_Guide_EnterNewTeam, for: .normal)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.primaryContentDefault), for: .normal)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.fillDisabled), for: .disabled)
        button.layer.cornerRadius = IGLayer.commonButtonRadius
        button.clipsToBounds = true
        return button
    }()

    private lazy var flowOptionView: UIView = {
        let view = UIView()
        return view
    }()

    var ldrResponse: GetLDRServiceAppLinkResponse?

    private let viewModel: LDRGuideViewModel
    private let showBackItem: Bool

    init(vm: LDRGuideViewModel, showBackItem: Bool = false, resolver: UserResolver) {
        self.showBackItem = showBackItem
        self.viewModel = vm
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgBody)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            self.isModalInPresentation = true
        }
        bindViewModel()
        self.view.backgroundColor = UIColor.ud.bgBody
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reportEndGuide()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    @discardableResult
    override func addBackItem() -> UIBarButtonItem {
        if !self.showBackItem {
            self.navigationItem.leftBarButtonItem = nil
            let barItem = LKBarButtonItem()
            /// Base 控制器会在切换时候自动添加关闭按钮
            /// 但是本页面不需要返回按钮
            return barItem
        }
        return super.addBackItem()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        (self.navigationController as? LkNavigationController)?.update(style: self.navigationBarStyle)
    }

    private func setNavigationBarRightItem() {
        guard !viewModel.isOversea else {
            // Lark不加跳过按钮
            navigationItem.rightBarButtonItem = nil
            return
        }
        let rightItem = LKBarButtonItem()
        rightItem.setBtnColor(color: UIColor.ud.primaryContentDefault)
        rightItem.button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        rightItem.button.titleLabel?.font = UDFont.headline
        rightItem.reset(title: BundleI18n.LDR.Lark_Guide_Benefits1ButtonSkip, font: UDFont.headline)
        rightItem.addTarget(self, action: #selector(navigationBarRightItemTapped), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = rightItem
    }

    func bindViewModel() {
        self.loadingPlaceholderView.isHidden = false
        viewModel.getLDRService().drive(onNext: { [weak self] resp in
            guard let self = self else { return }
            self.loadingPlaceholderView.isHidden = true
            self.ldrResponse = resp
            var keys: [String] = []
            if let optionCount = self.ldrResponse?.options.count, optionCount > 0 {
                self.showLDRGuideView(resp: resp)
                resp.options.forEach { option in
                    keys.append(option.eventKey)
                }
                self.setNavigationBarRightItem()
            } else {
                self.showEnterTeamView()
            }

            Tracker.post(TeaEvent(Homeric.ONBOARDING_GUIDE_ADDMEMBER_CONGRATES_SHOW,
                                  params: ["banners_show": (resp.isOpenEntry ? "ldr" : "none")]))
            Tracer.trackLDRGuideView(keys: keys)
        }).disposed(by: disposeBag)
    }

    func showLDRGuideView(resp: GetLDRServiceAppLinkResponse) {
        self.view.addSubview(successTipsView)
        self.view.addSubview(enterTeamButton)
        self.view.addSubview(flowOptionView)

        var lastLDRGuideView: LDRGuideView?

        for (index, option) in resp.options.enumerated() {
            let ldrGuideView = LDRGuideView()
            ldrGuideView.titleLabel.text = option.title
            ldrGuideView.subTitleLabel.text = option.subTitle
            ldrGuideView.iconView.bt.setLarkImage(with: .default(key: option.imgURL))
            ldrGuideView.flowOption = option
            ldrGuideView.tag = 1000 + index
            ldrGuideView.tapHandler = {
                self.invalidButton()
            }
            flowOptionView.addSubview(ldrGuideView)

            if let lastView = lastLDRGuideView {
                ldrGuideView.snp.makeConstraints { (make) in
                    make.left.right.equalToSuperview()
                    make.height.equalTo(82)
                    make.top.equalTo(lastView.snp.bottom).offset(12)
                }
            } else {
                ldrGuideView.snp.makeConstraints { (make) in
                    make.left.right.equalToSuperview()
                    make.height.equalTo(82)
                    make.top.equalToSuperview()
                }
            }
            lastLDRGuideView = ldrGuideView
        }

        enterTeamButton.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-24 - self.additionalSafeAreaInsets.bottom)
            make.height.equalTo(48)
        }

        flowOptionView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(resp.options.count * 82 + (resp.options.count - 1) * 12)
            make.bottom.equalTo(enterTeamButton.snp.top).offset(-24)
        }

        var top = 0
        switch resp.options.count {
        case 1:
            top = 158
        case 2:
            top = 105
        case 3:
            top = 64
        default:
            top = 0
        }

        successTipsView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(flowOptionView.snp.top).offset(-top)
        }

        enterTeamButton.addTarget(self, action: #selector(fetchRightNowTapped), for: .touchUpInside)
        enterTeamButton.setTitle(BundleI18n.LDR.Lark_Guide_Benefits1ButtonGet, for: .normal)
        successTipsView.titleLabel.text = BundleI18n.LDR.Lark_Guide_Benefits1Title(viewModel.tenantName)
        successTipsView.subTitleLabel.text = BundleI18n.LDR.Lark_Guide_Benefits1SubTitle()
    }

    func invalidButton() {
        let selectedKeys = self.selectEventKeyList()
        self.enterTeamButton.isEnabled = !selectedKeys.isEmpty
    }

    func showEnterTeamView() {
        self.view.addSubview(successTipsView)
        self.view.addSubview(enterTeamButton)

        enterTeamButton.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-32 - self.additionalSafeAreaInsets.bottom)
            make.height.equalTo(48)
        }

        successTipsView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(enterTeamButton.snp.top).offset(-20)
        }

        enterTeamButton.addTarget(self, action: #selector(enterNewTeamTapped), for: .touchUpInside)
        enterTeamButton.setTitle(BundleI18n.LDR.Lark_UgRetention_QADescUgRetentionRegisterFormPCEnterButton(), for: .normal)
        successTipsView.titleLabel.text = BundleI18n.LDR.Lark_Guide_TeamCreate3SuccessTitle
        successTipsView.subTitleLabel.text = BundleI18n.LDR.Lark_Guide_TeamCreate3SuccessSubTitle
    }

    @objc
    func enterNewTeamTapped() {
        enterNewTeam()
        Tracer.trackLDRGuideViewClick(clickEvent: "next", keys: [])
    }

    @objc
    func fetchRightNowTapped() {
        enterNewTeam()
        guard let resp = self.ldrResponse else {
            return
        }

        if let applink = self.ldrResponse?.appLink,
           let window = self.view.window,
           let url = URL(string: applink) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                /// 0.3延迟再执行
                if Display.pad {
                    self.navigator.present(url, wrap: LkNavigationController.self, from: window, prepare: { (vc) in
                        vc.modalPresentationStyle = .formSheet
                    })
                } else {
                    self.navigator.push(url, from: window)
                }
            })
        }

        guard !resp.options.isEmpty else {
            return
        }

        let eventKeyList: [String] = self.selectEventKeyList()
        if !eventKeyList.isEmpty {
            viewModel.reportEvent(eventKeyList: eventKeyList)

            if let window = self.view.window {
                UDToast.showSuccess(with: BundleI18n.LDR.Lark_Guide_Benefits1Toast, on: window)
            }
        }
        Tracer.trackLDRGuideViewClick(clickEvent: "fetch", keys: eventKeyList)
    }

    func enterNewTeam() {
        Tracker.post(TeaEvent(Homeric.ONBOARDING_GUIDE_ADDMEMBER_CONGRATES_CLICK))
        navigator.switchTab(Tab.feed.url, from: self, animated: false, completion: nil)
    }

    private func selectEventKeyList() -> [String] {
        var eventKeyList: [String] = []
        if let resp = self.ldrResponse {
            for index in 0...resp.options.count {
                if let ldrGuideView = self.flowOptionView.viewWithTag(1000 + index) as? LDRGuideView {
                    if let option = ldrGuideView.flowOption, ldrGuideView.isSelected {
                        eventKeyList.append(option.eventKey)
                    }
                }
            }
        }
        return eventKeyList
    }

    @objc
    private func navigationBarRightItemTapped() {
        Tracer.trackLDRGuideViewClick(clickEvent: "skip", keys: self.selectEventKeyList())
        navigator.switchTab(Tab.feed.url, from: self, animated: false, completion: nil)
    }
}
