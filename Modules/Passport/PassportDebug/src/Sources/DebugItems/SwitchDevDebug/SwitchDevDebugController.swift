//
//  SwitchDevDebugController.swift
//  PassportDebug
//
//  Created by qihongye on 2023/11/13.
//

#if DEBUG || BETA || ALPHA

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkEnv
import UniverseDesignButton
import UniverseDesignInput
import UniverseDesignFont
import RoundedHUD
import LarkContainer
import EENavigator
import LKCommonsLogging
import LarkStorage
import WebBrowser
import LarkAlertController

final class SwitchDevDebugVM {
    let accountService: AccountService
    @Provider var passportDebugService: PassportDebugService

    let readmeURL = "https://bytedance.larkoffice.com/docx/S4rBdJ6vKoiJHGxLvQ9cxxIqnaf"

    let xttEnvObservable: BehaviorRelay<String>
    let idcFlowControlObservable: BehaviorRelay<String>
    let preReleaseFDObservable: BehaviorRelay<String>
    let preReleaseMockTagObservable: BehaviorRelay<String>
    let preReleaseStressTagObservable: BehaviorRelay<String>
    let envObservable: BehaviorRelay<Env>
    let brandObservable: BehaviorRelay<String>

    var isLogin: Bool {
        return accountService.isLogin
    }

    init(accountService: AccountService) {
        self.accountService = accountService
        xttEnvObservable = .init(value: PassportDebugEnv.xttEnv)
        idcFlowControlObservable = .init(value: PassportDebugEnv.idcFlowControlValue)
        preReleaseFDObservable = .init(value: PassportDebugEnv.preReleaseFd)
        preReleaseMockTagObservable = .init(value: PassportDebugEnv.mockTag)
        preReleaseStressTagObservable = .init(value: PassportDebugEnv.stressTag)
        envObservable = .init(value: EnvManager.env)
        brandObservable = .init(value: accountService.foregroundTenantBrand.rawValue)
    }

    func syncToPassportDebugEnv() {
        PassportDebugEnv.xttEnv = xttEnvObservable.value
        PassportDebugEnv.idcFlowControlValue = idcFlowControlObservable.value
        PassportDebugEnv.preReleaseFd = preReleaseFDObservable.value
        PassportDebugEnv.mockTag = preReleaseMockTagObservable.value
        PassportDebugEnv.stressTag = preReleaseStressTagObservable.value
    }

    func syncToEnvManager() {
        EnvManager.switchEnv(envObservable.value, brand: brandObservable.value)
    }
}

/// https://github.com/apple/swift-evolution/blob/main/proposals/0258-property-wrappers.md#referencing-the-enclosing-self-in-a-wrapper-type
@propertyWrapper
struct AnySubview<VC: UIViewController, View: UIView, ContainerView: UIView> {
    typealias ValueKeyPath = ReferenceWritableKeyPath<VC, View>
    typealias SelfKeyPath = ReferenceWritableKeyPath<VC, Self>

    static subscript(
        _enclosingInstance instance: VC,
        wrapped wrappedKeyPath: ValueKeyPath,
        storage storageKeyPath: SelfKeyPath
    ) -> View {
        get {
            let _instance = instance[keyPath: storageKeyPath]
            let containerKeyPath = _instance.containerKeyPath
            let view = _instance.view
            if view.superview == nil {
                instance[keyPath: containerKeyPath].addSubview(view)
            }
            return view
        }
        set {
            let _instance = instance[keyPath: storageKeyPath]
            _instance.view.removeFromSuperview()
            instance[keyPath: _instance.containerKeyPath].addSubview(newValue)
            instance[keyPath: storageKeyPath].view = newValue
        }
    }

    var wrappedValue: View {
        get { fatalError() }
        set { fatalError() }
    }

    private var view: View
    private var containerKeyPath: KeyPath<VC, ContainerView>

    init(wrappedValue view: @autoclosure () -> View, _ containerKeyPath: KeyPath<VC, ContainerView>) {
        self.view = view()
        self.containerKeyPath = containerKeyPath
    }
}

protocol AddSubview: UIViewController {
    typealias Subview<View: UIView, ContainerView: UIView> = AnySubview<Self, View, ContainerView>
}

final class SwitchDevDebugController: UIViewController, AddSubview {
    private static var logger = Logger.log(SwitchDevDebugController.self, category: "SwitchDevDebugItem")

    @Subview(\SwitchDevDebugController.scrollView)
    private var editContentView = UIView()
    @Subview(\SwitchDevDebugController.editContentView)
    private var preReleaseMockInput = UDTextField(config: UDTextFieldUIConfig(isShowBorder: true, isShowTitle: true))
    @Subview(\SwitchDevDebugController.editContentView)
    private var preReleaseFDInput = UDTextField(config: UDTextFieldUIConfig(isShowBorder: true, isShowTitle: true))
    @Subview(\SwitchDevDebugController.editContentView)
    private var preReleaseStressTagInput = UDTextField(config: UDTextFieldUIConfig(isShowBorder: true, isShowTitle: true))
    @Subview(\SwitchDevDebugController.editContentView)
    private var xttEnvInput = UDTextField(config: UDTextFieldUIConfig(isShowBorder: true, isShowTitle: true))
    @Subview(\SwitchDevDebugController.editContentView)
    private var idcFlowControlInput = UDTextField(config: UDTextFieldUIConfig(isShowBorder: true, isShowTitle: true))

    @Subview(\SwitchDevDebugController.view)
    private var readmeButton = UDButton()
    @Subview(\SwitchDevDebugController.view)
    private var switchEnvText = UDButton()
    /// 确认变更后的提交按钮
    @Subview(\SwitchDevDebugController.view)
    private var submitButton = UDButton()
    @Subview(\SwitchDevDebugController.view)
    private var cancelButton = UDButton()

    @Subview(\SwitchDevDebugController.view)
    private var scrollView = UIScrollView()

    private let vm: SwitchDevDebugVM
    private let disposeBag = DisposeBag()

    init(accountService: AccountService) {
        self.vm = SwitchDevDebugVM(accountService: accountService)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindData()

        if #available(iOS 17.0, *) {
            self.registerForTraitChanges([UITraitVerticalSizeClass.self, UITraitHorizontalSizeClass.self]) { (_: SwitchDevDebugController, _) in
                self.syncToScrollViewContentSize()
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 17.0, *) {

        } else {
            syncToScrollViewContentSize()
        }
    }

    private func syncToScrollViewContentSize() {
        self.view.layoutIfNeeded()
        self.scrollView.contentSize = self.editContentView.frame.size
    }

    private func setupUI() {
        view.backgroundColor = UIColor.ud.bgBase

        xttEnvInput.title = "tt_feature_env(BOE环境染色)"
        idcFlowControlInput.title = "Idc Flow Control Value(切换机房用的变量)"
        preReleaseFDInput.title = "pre_fd(pre环境染色)"
        preReleaseMockInput.title = "pre_mock_value(pre环境mock)"
        preReleaseStressTagInput.title = "stress tag(压测时使用)"
        readmeButton.setTitle("BOE环境使用指南", for: .normal)
        submitButton.setTitle("Submit", for: .normal)
        cancelButton.setTitle("Cancel", for: .normal)

        let buttonHeight = 40
        readmeButton.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(20)
            make.left.equalTo(self.view.safeAreaLayoutGuide).offset(10)
            make.right.equalTo(self.view.safeAreaLayoutGuide).offset(-10)
            make.height.equalTo(buttonHeight)
        }
        switchEnvText.snp.makeConstraints { make in
            make.top.equalTo(readmeButton.snp.bottom).offset(10)
            make.left.equalTo(self.view.safeAreaLayoutGuide).offset(10)
            make.right.equalTo(self.view.safeAreaLayoutGuide).offset(-10)
            make.height.equalTo(buttonHeight)
        }
        scrollView.snp.makeConstraints { make in
            make.left.equalTo(self.view.safeAreaLayoutGuide).offset(10)
            make.right.equalTo(self.view.safeAreaLayoutGuide).offset(-10)
            make.top.equalTo(switchEnvText.snp.bottom).offset(10)
            make.bottom.equalTo(submitButton.snp.top).offset(-10)
        }
        editContentView.snp.makeConstraints { make in
            make.left.equalTo(self.view.safeAreaLayoutGuide).offset(10)
            make.right.equalTo(self.view.safeAreaLayoutGuide).offset(-10)
        }
        submitButton.snp.makeConstraints { make in
            make.bottom.equalTo(cancelButton.snp.top).offset(-10)
            make.left.equalTo(self.view.safeAreaLayoutGuide).offset(10)
            make.right.equalTo(self.view.safeAreaLayoutGuide).offset(-10)
            make.height.equalTo(buttonHeight)
        }
        cancelButton.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.safeAreaLayoutGuide).offset(-20)
            make.left.equalTo(self.view.safeAreaLayoutGuide).offset(10)
            make.right.equalTo(self.view.safeAreaLayoutGuide).offset(-10)
            make.height.equalTo(buttonHeight)
        }

        xttEnvInput.snp.makeConstraints { make in
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left).offset(10)
            make.top.equalToSuperview()
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right).offset(-10)
            
        }
        idcFlowControlInput.snp.makeConstraints { make in
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left).offset(10)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right).offset(-10)
            make.top.equalTo(xttEnvInput.snp.bottom)
        }
        preReleaseFDInput.snp.makeConstraints { make in
            make.top.equalTo(idcFlowControlInput.snp.bottom)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left).offset(10)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right).offset(-10)
            
        }
        preReleaseMockInput.snp.makeConstraints { make in
            make.top.equalTo(preReleaseFDInput.snp.bottom)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left).offset(10)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right).offset(-10)
            
        }
        preReleaseStressTagInput.snp.makeConstraints { make in
            make.top.equalTo(preReleaseMockInput.snp.bottom)
            make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left).offset(10)
            make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right).offset(-10)
            make.bottom.equalToSuperview()
        }

        DispatchQueue.main.async {
            self.syncToScrollViewContentSize()
        }
    }

    private func bindData() {
        vm.xttEnvObservable.bind(to: xttEnvInput.input.rx.text).disposed(by: disposeBag)
        xttEnvInput.input.rx.text.orEmpty.bind(to: vm.xttEnvObservable).disposed(by: disposeBag)

        vm.idcFlowControlObservable.bind(to: idcFlowControlInput.input.rx.text).disposed(by: disposeBag)
        idcFlowControlInput.input.rx.text.orEmpty.bind(to: vm.idcFlowControlObservable).disposed(by: disposeBag)

        vm.preReleaseFDObservable.bind(to: preReleaseFDInput.input.rx.text).disposed(by: disposeBag)
        preReleaseFDInput.input.rx.text.orEmpty.bind(to: vm.preReleaseFDObservable).disposed(by: disposeBag)

        vm.preReleaseMockTagObservable.bind(to: preReleaseMockInput.input.rx.text).disposed(by: disposeBag)
        preReleaseMockInput.input.rx.text.orEmpty.bind(to: vm.preReleaseMockTagObservable).disposed(by: disposeBag)

        vm.preReleaseStressTagObservable.bind(to: preReleaseStressTagInput.input.rx.text).disposed(by: disposeBag)
        preReleaseStressTagInput.input.rx.text.orEmpty.bind(to: vm.preReleaseStressTagObservable).disposed(by: disposeBag)

        /// Switch env button data-binding.
        vm.envObservable.bind(to: Binder(switchEnvText, binding: { view, value in
            view.setTitle("Env: \(value.description)", for: .normal)
        })).disposed(by: disposeBag)

        readmeButton.rx.tap.bind { [unowned self] in
            if let url = URL(string: self.vm.readmeURL),
               let from = Navigator.shared.mainSceneWindow?.fromViewController {
                Navigator.shared.present(body: WebBody(url: url), from: from)
            }
        }.disposed(by: disposeBag)

        switchEnvText.rx.tap.bind { [unowned self] in
            self.switchEnv()
        }.disposed(by: disposeBag)

        submitButton.rx.tap.bind { [unowned self] in
            self.submitEnv()
        }.disposed(by: disposeBag)

        cancelButton.rx.tap.bind { [unowned self] in
            self.vm.syncToPassportDebugEnv()
            self.dismiss(animated: true)
        }.disposed(by: disposeBag)
    }

    static func switchDevEnv(_ env: Env, brand: String) {
        self.logger.info("switchDevEnv begin")
        assert(Thread.isMainThread, "should occur on main thread!")
        EnvManager.debugMenuUpdateEnv(env, brand: brand)

        // 创建qa专属文件夹
        let qaDir: IsoPath = .global.in(domain: Domain.biz.passport).build(.document).appendingRelativePath("qa")
        try? qaDir.createDirectoryIfNeeded()
        // BOE标识文件
        let boeTxt: IsoPath = qaDir.appendingRelativePath("BOE.txt")
        // 如果是切换到BOE环境，则写上对应文件
        if env.type == .staging {
            self.logger.info("env.type == .staging")
            if !boeTxt.exists {
                self.logger.info("boeTxt createFile")
                try? boeTxt.createFile()
            }
        } else {
            self.logger.info("env.type != .staging")
            if boeTxt.exists {
                self.logger.info("boeTxt removeItem")
                try? boeTxt.removeItem()
            }
        }

        self.logger.info("switchDevEnv end")
        // NOTE: 使用私有API, graceful exit. this ensure cleanup work like UserDefaults sync
        // delay and exit(0) not gurantee UserDefaults save
        UIApplication.shared.perform(Selector(["terminate", "With", "Success"].joined()), on: Thread.main, with: nil, waitUntilDone: false)
    }

    private func switchEnv() {
        let devPickerVC = DebugEnvPickerViewController(brand: vm.brandObservable.value, completion: { [weak self] (env, brand) in
            guard let self = self else {
                return
            }
            self.vm.envObservable.accept(env)
            self.vm.brandObservable.accept(brand)
        })
        devPickerVC.modalPresentationStyle = .fullScreen
        Navigator.shared.present(devPickerVC, from: self)
    }

    private func submitEnv() {
        self.vm.syncToPassportDebugEnv()
        let alertController = LarkAlertController()
        alertController.setContent(text: "Switch Brand：\(self.vm.brandObservable.value), Switch Env：\(self.vm.envObservable.value.description)\nSwitch Env will lead app to restart.")
        alertController.addSecondaryButton(text: "Cancel")
        alertController.addPrimaryButton(text: "Ok", dismissCompletion: { [weak self] in
            guard let self = self else { return }
            // if user is login switch env without logout:
            // 1. backend will record a session not in use.
            // 2. may casue force logout (error) next launch app.
            if self.vm.isLogin {
                let hud = RoundedHUD.showLoading(on: self.view, disableUserInteraction: true)
                self.vm.accountService.relogin(
                    conf: .debugSwitchEnv,
                    onError: { [view = self.view] error in
                        hud.remove()
                        if let view = view {
                            RoundedHUD.showFailure(with: error, on: view)
                        }
                    }, onSuccess: { [weak self] in
                        hud.remove()

                        guard let self = self else { return }
                        let env = self.vm.envObservable.value
                        //如果env type 出现变更，清空passport global的所有数据
                        if EnvManager.env.type != env.type {
                            self.vm.passportDebugService.removeGlobalStoreData()
                        }
                        self.dismiss(animated: true)
                        Self.switchDevEnv(env, brand: self.vm.brandObservable.value)
                    }, onInterrupt: {
                        hud.remove()
                    })
            } else {
                if EnvManager.env.type != self.vm.envObservable.value.type {
                    self.vm.passportDebugService.removeGlobalStoreData()
                }
                self.dismiss(animated: true)
                Self.switchDevEnv(self.vm.envObservable.value, brand: self.vm.brandObservable.value)
            }
        })
        DispatchQueue.main.async {
            self.present(alertController, animated: true)
        }
    }
}

#endif
