//
// Created by Yiming Qu on 2019-07-16.
//

import UIKit
import LarkUIKit
import SnapKit
import LKCommonsLogging
import Homeric
import RxSwift
import RxCocoa

protocol OTPVerifyProtocol {
    var title: String { get }
    var subtitle: NSAttributedString { get }
    var expire: BehaviorRelay<uint> { get }

    var updatedSubtitle: BehaviorRelay<Void>? { get }
    var sentBeforePush: Bool { get }

    var showRecoverAccount: Bool { get }
    var recoverAccountTip: NSAttributedString? { get }
    var recoverAccountInfo: [String: Any]? { get }

    var needBackImage: Bool { get }

    func sendCode() -> Observable<Void>
    func verify(code: String) -> Observable<Void>
    func recoverTypeAccountRecover() -> Observable<Void>

    func catchExpireError(error: Error) -> Observable<Void>
}

extension OTPVerifyProtocol {
    var updatedSubtitle: BehaviorRelay<Void>? { nil }
    var sentBeforePush: Bool { false }
    var showRecoverAccount: Bool { false }
    var recoverAccountTip: NSAttributedString? { nil }
    var recoverAccountInfo: [String: Any]? { nil }
    var needBackImage: Bool { true }
}

extension OTPVerifyProtocol {
    func catchExpireError(error: Error) -> Observable<Void> {
        if let err = error as? V3LoginError,
           case .badServerCode(let info) = err,
           info.type == .applyCodeTooOften,
           let exp = info.detail[V3.Const.expire] as? uint {
            self.expire.accept(exp)
            return .just(())
        } else {
            return .error(error)
        }
    }
}

typealias OTPVerifyViewModel = OTPVerifyProtocol & V3ViewModel

class OTPVerifyViewController: BaseViewController {

    lazy var verifyCodeControl: V3VerifyCodeControl = {
        return V3VerifyCodeControl(withResentBlock: { [weak self] in
            self?.sendCode()
        }, textChangeBlock: { [weak self] (currentValue) in
            self?.currentValue = currentValue
            self?.nextButton.isEnabled = currentValue.count >= 6
        }, verifyCodeBlock: { _ in
        }, beginEdit: false, timeoutBlock: {}, source: .login)
    }()

    private lazy var recoverAccountLabel: LinkClickableLabel = {
        return LinkClickableLabel.default(with: self)
    }()

    let vm: OTPVerifyViewModel
    var currentValue: String = ""

    init(vm: OTPVerifyViewModel) {
        self.vm = vm
        super.init(viewModel: vm)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        nextButton.setTitle(BundleI18n.suiteLogin.Lark_Passport_CP_Confirm, for: .normal)

        nextButton.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.verifyCode(code: self.currentValue)
            }).disposed(by: disposeBag)

        configTopInfo(vm.title, detail: vm.subtitle)

        if !vm.sentBeforePush {
            sendCode()
        }

        centerInputView.addSubview(verifyCodeControl.view)
        verifyCodeControl.view.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview().inset(CL.itemSpace)
            if !vm.showRecoverAccount {
                make.bottom.equalToSuperview()
            }
        }
        verifyCodeControl.startTime()

        if vm.showRecoverAccount {
            centerInputView.addSubview(recoverAccountLabel)
            recoverAccountLabel.snp.makeConstraints { (make) in
                make.top.equalTo(verifyCodeControl.view.snp.bottom).offset(4)
                make.left.right.equalToSuperview().inset(12.0)
                make.bottom.equalToSuperview()
            }
            recoverAccountLabel.attributedText = vm.recoverAccountTip
        }

        vm.updatedSubtitle?.subscribe(onNext: { [weak self] (_) in
            guard let self = self else { return }
            self.configTopInfo(self.vm.title, detail: self.vm.subtitle)
            }).disposed(by: disposeBag)

        vm.expire.asObservable()
            .observeOn(MainScheduler.instance)
            .skip(1)
            .subscribe(onNext: { [weak self] (count) in
                self?.verifyCodeControl.updateCountDown(uint(count))
            }).disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        verifyCodeControl.beginEdit()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        verifyCodeControl.endTimer()
    }

    func verifyCode(code: String) {
        self.showLoading()
        vm.verify(code: currentValue)
            .subscribe(onNext: { [weak self](_) in
                self?.stopLoading()
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                self.handle(error)
                self.verifyCodeControl.beginEdit()
                self.verifyCodeControl.resetView()
                self.nextButton.isEnabled = false
            }).disposed(by: disposeBag)
    }

    func sendCode() {
        vm.sendCode()
            .observeOn(MainScheduler.instance)
            .subscribe(onError: { [weak self](error) in
                self?.handle(error)
            }).disposed(by: disposeBag)
    }

    override func handleClickLink(_ URL: URL, textView: UITextView) {
        switch URL {
        case Link.recoverAccountCarrierURL:
            self.showLoading()
            self.vm.recoverTypeAccountRecover()
                .subscribe(onNext: { [weak self](_) in
                    self?.stopLoading()
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    self.handle(error)
                }).disposed(by: disposeBag)
        default:
            break
        }
    }

    override func needBackImage() -> Bool {
        vm.needBackImage
    }
}
