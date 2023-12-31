//
//  EnterpriseCallOutViewController.swift
//  ByteView
//
//  Created by bytedance on 2021/8/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import RxSwift
import Action
import RxCocoa
import ByteViewTracker
import UniverseDesignIcon

class EnterpriseCallOutViewController: VMViewController<EnterpriseCallOutViewModel> {

    var disposeBag: DisposeBag = DisposeBag()

    lazy var callOutView = EnterpriseCallOutView(frame: .zero, isVoiceCall: true)

    lazy var backButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: .ud.iconN1, size: CGSize(width: 24, height: 24)), for: .normal)
        button.addTarget(self, action: #selector(dismissAction), for: .touchUpInside)
        return button
    }()

    let minimumDisplayRelay = PublishRelay<Void>()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        self.isNavigationBarHidden = true
        setupViews()
        bindViewModel()

        VCTracker.post(name: .vc_phone_calling_prompt_status, params: ["status": "start", "emterprise_phone_id": viewModel.enterprisePhoneId])
    }

    deinit {
        VCTracker.post(name: .vc_phone_calling_prompt_status, params: ["status": "end", "emterprise_phone_id": viewModel.enterprisePhoneId])
    }

    // MARK: - Lifecycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        启动头像边波纹特效
        callOutView.playRipple()
        callOutView.updateOverlayAlpha(alpha: 1)
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(3)) {
            self.minimumDisplayRelay.accept(Void())
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        callOutView.stopRipple()
    }


    // MARK: - Layout views
    override func setupViews() {
        view.addSubview(callOutView)
        view.addSubview(backButton)

        callOutView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        backButton.snp.makeConstraints { (maker) in
            maker.size.equalTo(24)
            maker.left.equalToSuperview().inset(16)
            maker.top.equalTo(view.safeAreaLayoutGuide).offset(10)
        }
    }

    // MARK: - UI bindings
//    绑定UI控件以及更新参数
    override func bindViewModel() {
        bindAvatar()
        bindName()
        bindDescription()
        bindUIAction()
        bindDailingTimeout()

        Observable.combineLatest(viewModel.leaveRelay.distinctUntilChanged(), minimumDisplayRelay) { isLeave, _ in isLeave }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLeave in
                if isLeave {
                    self?.dismiss(animated: true, completion: nil)
                }
            })
            .disposed(by: disposeBag)
    }

    func bindUIAction() {
        callOutView.cancelButton.addTarget(self, action: #selector(cancelDialing), for: .touchUpInside)
    }

    func bindDailingTimeout() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }

    @objc func cancelDialing() {
        self.viewModel.cancelCallAction()
        self.dismiss(animated: true, completion: nil)
        VCTracker.post(name: .vc_phone_calling_prompt_click, params: [.click: "cancel"])
    }

    @objc func dismissAction() {
        self.dismiss(animated: true, completion: nil)
        VCTracker.post(name: .vc_phone_calling_prompt_click, params: [.click: "return"])
    }

//  设置显示的头像
    func bindAvatar() {
        callOutView.updateAvatar(avatarInfo: viewModel.avatarInfo)
    }

    private func bindName() {
        callOutView.updateName(name: viewModel.userName)
    }

    private func bindDescription() {
        self.callOutView.updateDescription(description: I18n.View_MV_AnswerSystemPhone)
    }

}
