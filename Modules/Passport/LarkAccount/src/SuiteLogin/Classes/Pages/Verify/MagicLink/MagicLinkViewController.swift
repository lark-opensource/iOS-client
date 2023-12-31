//
//  MagicLinkViewController.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/8/3.
//

import UIKit
import LarkActionSheet
import Homeric

class MagicLinkViewController: BaseViewController {

    let topImageView: UIImageView = UIImageView(image: BundleResources.LarkIllustrationResources.initializationFunctionEmail)
    lazy var mainTitleLabel: UILabel = {
        let lb = UILabel()
        lb.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        lb.numberOfLines = 0
        lb.textAlignment = .center
        lb.text = vm.titleString
        return lb
    }()

    lazy var subTitleLabel: UILabel = {
        let lb = UILabel()
        lb.font = UIFont.systemFont(ofSize: 14)
        lb.numberOfLines = 0
        lb.textAlignment = .center
        lb.textColor = UIColor.ud.textCaption
        lb.attributedText = vm.subTitleString
        return lb
    }()

    let openBtn: NextButton = NextButton(
        title: I18N.Lark_Login_MagicLinkOpenInboxButton,
        style: .roundedRectBlue
    )

    lazy var resendBtn: CountDownButton = {
        let btn = CountDownButton(
            normalTitle: I18N.Lark_Login_MagicLinkResendButton,
            templateTitle: { (count) -> String in
                I18N.Lark_Login_MagicLinkResendVeriEmailbutton(count)
            }, countDownOver: { [weak self] in
                self?.stopWaiting()
            })
        return btn
    }()

    lazy var remindTipLabel: UILabel = {
        let lb = UILabel()
        lb.font = UIFont.systemFont(ofSize: 12)
        lb.numberOfLines = 0
        lb.textColor = UIColor.ud.textPlaceholder
        lb.textAlignment = .center
        lb.isHidden = true
        lb.text = vm.remindTip
        return lb
    }()

    let vm: MagicLinkViewModel

    private var retryCheckWhenBecomeActive = false
    private var isResignActive = false

    init(vm: MagicLinkViewModel) {
        self.vm = vm
        super.init(viewModel: vm)
        self.useCustomNavAnimation = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(topImageView)
        view.addSubview(mainTitleLabel)
        view.addSubview(subTitleLabel)
        view.addSubview(openBtn)
        view.addSubview(resendBtn)
        view.addSubview(remindTipLabel)

        let img = BundleResources.LarkIllustrationResources.initializationFunctionEmail
        let imageRadio = img.size.width / img.size.height
        topImageView.snp.makeConstraints { (make) in
            make.top.greaterThanOrEqualTo(viewTopConstraint).offset(CL.underBackBtnTopSpace)
            make.left.greaterThanOrEqualToSuperview().offset(Layout.imageHorizonSpace)
            make.right.lessThanOrEqualToSuperview().inset(Layout.imageHorizonSpace)
            make.centerX.equalToSuperview()
            make.width.equalTo(topImageView.snp.height).multipliedBy(imageRadio)
        }

        mainTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(view.snp.centerY)
            make.top.equalTo(topImageView.snp.bottom).offset(Layout.sectionSpace)
            make.left.right.equalToSuperview().inset(CL.itemSpace)
        }

        subTitleLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(CL.itemSpace)
            make.top.equalTo(mainTitleLabel.snp.bottom).offset(Layout.labelSpace)
        }

        if vm.mailWebURL == nil && vm.avaliableMailApps.isEmpty {
            openBtn.isHidden = true

            resendBtn.snp.makeConstraints { (make) in
                make.top.equalTo(subTitleLabel.snp.bottom).offset(Layout.singleBtnTop)
                make.left.right.equalToSuperview().inset(CL.itemSpace)
                make.height.equalTo(NextButton.Layout.nextButtonHeight48)
            }

            remindTipLabel.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview().inset(CL.itemSpace)
                make.top.greaterThanOrEqualTo(resendBtn.snp.bottom).offset(Layout.tipTop)
                make.bottom.equalToSuperview().inset(Layout.sectionSpace)
            }
        } else {
            openBtn.isHidden = false

            openBtn.snp.makeConstraints { (make) in
                make.top.equalTo(subTitleLabel.snp.bottom).offset(CL.itemSpace)
                make.left.right.equalToSuperview().inset(CL.itemSpace)
                make.height.equalTo(NextButton.Layout.nextButtonHeight48)
            }

            resendBtn.snp.makeConstraints { (make) in
                make.top.equalTo(openBtn.snp.bottom).offset(CL.itemSpace)
                make.left.right.height.equalTo(openBtn)
            }

            remindTipLabel.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview().inset(CL.itemSpace)
                make.top.equalTo(resendBtn.snp.bottom).offset(Layout.tipTop)
                make.bottom.lessThanOrEqualToSuperview().inset(Layout.sectionSpace)
            }
        }

        openBtn.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] (_) in
                self?.showOpenSheet()
            }).disposed(by: disposeBag)

        resendBtn.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self](_) in
                self?.sendMagicLink(needLoading: true)
            }).disposed(by: disposeBag)

        vm.expire.subscribe(onNext: { [weak self] (expire) in
            self?.startWaiting(count: expire)
            }).disposed(by: disposeBag)

        sendMagicLink(needLoading: false)

        NotificationCenter.default.rx.notification(UIApplication.willResignActiveNotification)
            .subscribe(onNext: { [weak self](_) in
                self?.isResignActive = true
            }).disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .subscribe(onNext: { [weak self](_) in
                guard let self = self else { return }
                self.checkIfNeedRetryPolling()
                self.isResignActive = false
            }).disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let pn = pageName() {
            SuiteLoginTracker.track(pn)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        endProcedure()
    }

    override func onlyNavUI() -> Bool {
        return true
    }

    override var needSkipWhilePop: Bool {
        return true
    }

    func showOpenSheet() {
        let sheet = ActionSheet()
        vm.avaliableMailApps.forEach { (app) in
            sheet.addItem(title: app.name) {
                UIApplication.shared.open(app.url)
            }
        }
        if let url = vm.mailWebURL {
            sheet.addItem(title: I18N.Lark_Login_MagicLinkOpenMailListOpeninBrowser) {
                UIApplication.shared.open(url)
            }
        }
        sheet.addCancelItem(title: I18N.Lark_Login_Cancel)
        self.present(sheet, animated: true, completion: nil)
    }

    func endProcedure() {
        stopLoading()
        vm.stopPolling()
    }

    func checkIfNeedRetryPolling() {
        if self.retryCheckWhenBecomeActive {
            self.retryCheckWhenBecomeActive = false
            self.logger.info("retry verify polling")
            self.startPolling()
        }
    }

    override func pageName() -> String? {
        Homeric.PASSPORT_ENTER_MAGIC_LINK
    }

    deinit {
        endProcedure()
    }
}

extension MagicLinkViewController {
    func startWaiting(count: uint? = nil) {
        remindTipLabel.isHidden = true
        resendBtn.startCountDown(withCount: count)
    }

    func stopWaiting() {
        remindTipLabel.isHidden = false
    }

    func startPolling() {
        vm.verifyPolling(apiSuccess: { [weak self] in
            self?.showLoading()
        })
        .subscribe(onError: { [weak self](error) in
            guard let self = self else { return }
            if self.isResignActive {
                self.retryCheckWhenBecomeActive = true
                self.logger.info("verify polling failed at background need retry")
            } else {
                self.handle(error)
            }
        }).disposed(by: disposeBag)
    }

    func sendMagicLink(needLoading: Bool) {
        if needLoading { self.showLoading() }
        vm.sendMagicLink()
            .subscribe(onNext: { [weak self](_) in
                guard let self = self else { return }
                if needLoading { self.stopLoading() }
                self.startWaiting()
                self.startPolling()
            }, onError: { [weak self](error) in
                if needLoading { self?.stopLoading() }
                self?.handle(error)
            }).disposed(by: disposeBag)
    }
}

extension MagicLinkViewController {
    enum Layout {
        static let sectionSpace: CGFloat = 40
        static let tipTop: CGFloat = 32
        static let labelSpace: CGFloat = 12
        static let imageHorizonSpace: CGFloat = 50
        static let singleBtnTop: CGFloat = 24
    }
}
