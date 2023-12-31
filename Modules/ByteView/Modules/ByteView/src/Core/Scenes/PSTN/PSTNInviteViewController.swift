//
//  PSTNInviteViewController.swift
//  ByteView
//
//  Created by yangyao on 2020/4/10.
//

import UIKit
import RxSwift
import RxCocoa
import Action
import SnapKit
import LarkLocalizations
import UniverseDesignIcon
import ByteViewUI

let PSTNInputMaxCharacterLength = 32

extension PSTNInviteViewController {
    func bindViewModel() {
        doSubscribes()
    }

    func configureView(_ status: PSTNStatus) {

        statusBar.isHidden = status.barIsHidden
        if !status.barIsHidden {
            disabledTipView.isHidden = true
        }
        statusBar.backgroundColor = status.barBackgroundColor
        statusLabel.text = status.barText
        statusLabel.textColor = status.barTextColor

        actionButton.setTitle(status.buttonText, for: .normal)

        phoneLabel.textColor = status.textColor

        let enabled = !status.isRinging
        arrowImageView.image = UDIcon.getIconByKey(.downOutlined, iconColor: enabled ? .ud.iconN3 : .ud.iconN3.withAlphaComponent(0.3), size: CGSize(width: 16, height: 16))

        seperatorView.backgroundColor = status.seperatorColor
        areaSelectionButton.isEnabled = enabled
        nameField.isEnabled = enabled
        phoneField.isEnabled = enabled

        nameField.textColor = status.textColor
        phoneField.textColor = status.textColor

        nameField.attributedPlaceholder =
            NSAttributedString(string: I18n.View_G_EnterInviteeName,
                                                                   attributes:
            [NSAttributedString.Key.foregroundColor:
                status.placeHolderColor])
        phoneField.attributedPlaceholder =
            NSAttributedString(string: I18n.View_G_EnterPhoneNumber,
        attributes:
            [NSAttributedString.Key.foregroundColor:
                status.placeHolderColor])

        phoneField.returnKeyType = .send
        phoneField.keyboardType = .phonePad
        phoneField.enablesReturnKeyAutomatically = true
    }

    private func doSubscribes() {
        let setting = self.viewModel.setting
        let hasPstnQuota = setting.hasPstnQuota
        let hasPstnRefinedQuota = setting.hasPstnRefinedQuota
        let isRefinementManagement = setting.isRefinementManagement

        nameField.attributedPlaceholder =
            NSAttributedString(string: I18n.View_G_EnterInviteeName,
                                                                   attributes:
            [NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder])

        ///////////////// action and content
        Observable.merge(
            actionButton.rx.tap.asObservable(),
            phoneField.rx.controlEvent(UIControl.Event.editingDidEndOnExit)
                .filter { [weak self] _ in Display.pad && self?.actionButton.isEnabled == true }
                .map { _ in Void() }
            )
            .throttle(.milliseconds(500), latest: false, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                MeetingTracks.trackTabPhoneCallClick()
                let name = self.nameField.text ?? ""
                let code = self.phoneLabel.text ?? ""
                let phone = self.phoneField.text ?? ""
                BillingTracksV2.trackPSTNInviteClick(hasName: !name.isEmpty,
                                                     isMeetingLocked: self.viewModel.setting.isMeetingLocked)
                self.viewModel.inviteUsers(mainAddress: "\(code)-\(phone)",
                    displayName: name,
                    participantType: .pstnUser)
                self.doBack()
            }).disposed(by: disposeBag)

        viewModel.selectedObservable
            .map { $0?.code ?? "" }
            .bind(to: phoneLabel.rx.text)
            .disposed(by: disposeBag)
        areaSelectionButton.addTarget(self, action: #selector(didClickAreaCode(_:)), for: .touchUpInside)

        viewModel.nameRelay.asObservable()
            .bind(to: nameField.rx.text)
            .disposed(by: disposeBag)
        nameField.rx.text.orEmpty
            .bind(to: viewModel.nameRelay)
            .disposed(by: disposeBag)

        viewModel.phoneRelay.asObservable()
            .bind(to: phoneField.rx.text)
            .disposed(by: disposeBag)
        phoneField.rx.text.orEmpty
            .bind(to: viewModel.phoneRelay)
            .disposed(by: disposeBag)

        Observable.combineLatest(phoneField.rx.text.orEmpty, viewModel.selectedObservable)
            .map { (text, selected) in
                guard selected != nil, text.count >= 3 else { return false }
                // 如果开启精细化服务FG，则需要租户和个人都有余额，否则只要判断租户是否有余额
                return hasPstnQuota && (!isRefinementManagement || hasPstnRefinedQuota)
            }
            .share(replay: 1)
            .bind(to: actionButton.rx.isEnabled)
            .disposed(by: disposeBag)

        nameField.rx.controlEvent(.editingDidEndOnExit)
            .subscribe(onNext: { [weak self] (_) in
                self?.phoneField.becomeFirstResponder()
            })
            .disposed(by: disposeBag)

        nameField.rx.text
            .map { $0?.isEmpty ?? false }
            .subscribe(onNext: { [weak self] (isEmpty) in
                if !isEmpty && self?.nameField.isFirstResponder == true {
                    self?.createRightView(self?.nameField)
                } else {
                    self?.nameField.rightView = nil
                }
            })
            .disposed(by: disposeBag)
        phoneField.rx.text
            .map { $0?.isEmpty ?? false }
            .subscribe(onNext: { [weak self] (isEmpty) in
                if !isEmpty && self?.phoneField.isFirstResponder == true {
                    self?.createRightView(self?.phoneField)
                } else {
                    self?.phoneField.rightView = nil
                }
            })
            .disposed(by: disposeBag)

        viewModel.pstnUserStatus
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] (status) in
                guard let self = self else { return }
                self.nameTipLabel.snp.remakeConstraints { (maker) in
                    maker.left.equalTo(self.nameField)
                    maker.right.equalToSuperview().inset(Layout.marginRight)
                    if status.barIsHidden {
                        maker.top.equalToSuperview().offset(16)
                    } else {
                        maker.top.equalTo(self.statusBar.snp.bottom).offset(16)
                    }
                    maker.height.equalTo(22)
                }
            })
            .subscribe(onNext: { [weak self] (status) in
                self?.configureView(status)
            }).disposed(by: disposeBag)

        showTipsIfNeeded(isRefinementManagement: isRefinementManagement, hasPstnQuota: hasPstnQuota, hasPstnRefinedQuota: hasPstnRefinedQuota)
    }

    private func showTipsIfNeeded(isRefinementManagement: Bool, hasPstnQuota: Bool, hasPstnRefinedQuota: Bool) {
        var message: String = ""
        if isRefinementManagement {
            if !hasPstnRefinedQuota {
                message = I18n.View_MV_NotEnoughBalanceContact_PopExplain
            } else if !hasPstnQuota {
                message = I18n.View_G_UpgradePlanToExtendPhoneCallLimit
            } else {
                return
            }
        } else {
            if !hasPstnQuota {
                message = I18n.View_G_UpgradePlanToExtendPhoneCallLimit
            } else {
                return
            }
        }
        self.disabledTipView.changeTipsInfo(message: message)
        self.disabledTipView.isHidden = false
        self.statusBar.isHidden = true
        self.nameTipLabel.snp.remakeConstraints { (maker) in
            maker.left.equalTo(self.nameField)
            maker.right.equalToSuperview().inset(Layout.marginRight)
            maker.top.equalTo(self.disabledTipView.snp.bottom).offset(12)
            maker.height.equalTo(22)
        }
        BillingTracks.trackDisplayPSTNTips()
    }
}

final class PSTNInviteViewController: BaseViewController, UITextFieldDelegate {
    private let disposeBag = DisposeBag()
    let viewModel: PSTNInviteViewModel
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delaysContentTouches = false
        scrollView.keyboardDismissMode = .onDrag
        return scrollView
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.addSubview(statusBar)

        statusBar.snp.makeConstraints { (maker) in
            maker.left.right.top.equalToSuperview()
            maker.height.equalTo(36)
        }

        view.addSubview(disabledTipView)
        view.addSubview(nameTipLabel)
        view.addSubview(nameContainer)
        disabledTipView.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
        }
        nameTipLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(self.nameField)
            maker.right.equalToSuperview().inset(Layout.marginRight)
            maker.top.equalToSuperview().offset(16)
            maker.height.equalTo(20)
        }
        nameContainer.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview().inset(16)
            maker.top.equalTo(nameTipLabel.snp.bottom).offset(4)
            maker.height.equalTo(48)
        }

        view.addSubview(phoneTipLabel)
        view.addSubview(phoneContainer)

        phoneTipLabel.snp.makeConstraints { (maker) in
            maker.left.right.equalTo(nameTipLabel)
            maker.top.equalTo(nameContainer.snp.bottom).offset(24)
            maker.height.equalTo(20)
        }
        phoneContainer.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview().inset(16)
            maker.top.equalTo(phoneTipLabel.snp.bottom).offset(4)
            maker.height.equalTo(48)
        }
        return view
    }()

    private lazy var nameContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.layer.cornerRadius = 10.0
        view.layer.masksToBounds = true
        view.addSubview(nameField)
        nameField.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(16)
            maker.right.equalToSuperview().inset(16)
            maker.height.equalTo(22)
            maker.centerY.equalToSuperview()
        }
        return view
    }()

    private lazy var nameTipLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.text = I18n.View_G_InviteeName
        return label
    }()

    private lazy var phoneTipLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.text = I18n.View_G_PhoneNumber
        return label
    }()

    private lazy var nameField: UITextField = {
        let textField = UITextField()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byClipping
        textField.attributedPlaceholder = NSAttributedString(
            string: I18n.View_G_EnterInviteeName,
            attributes: [NSAttributedString.Key.foregroundColor: PSTNStatus.initial.placeHolderColor,
                         NSAttributedString.Key.paragraphStyle: paragraphStyle])
        textField.textColor = PSTNStatus.initial.textColor
        textField.returnKeyType = .next
        textField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textField.delegate = self
        createRightView(textField)
        return textField
    }()

    private lazy var phoneContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.layer.cornerRadius = 10.0
        view.layer.masksToBounds = true

        view.addSubview(phoneLeftView)
        view.addSubview(phoneField)
        phoneLeftView.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalToSuperview().offset(16)
        }
        phoneField.snp.makeConstraints { (maker) in
            maker.left.equalTo(phoneLeftView.snp.right).offset(12)
            maker.right.equalToSuperview().inset(16)
            maker.height.equalTo(22)
            maker.centerY.equalToSuperview()
        }
        return view
    }()

    private lazy var phoneField: UITextField = {
        let textField = UITextField()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byClipping
        textField.attributedPlaceholder = NSAttributedString(
            string: I18n.View_G_EnterPhoneNumber,
            attributes: [NSAttributedString.Key.foregroundColor: PSTNStatus.initial.placeHolderColor,
                         NSAttributedString.Key.paragraphStyle: paragraphStyle])
        textField.textColor = PSTNStatus.initial.textColor
        textField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textField.keyboardType = .decimalPad
        textField.delegate = self
        createRightView(textField)
        return textField
    }()

    private lazy var areaSelectionButton: UIButton = {
        let button = UIButton()
        return button
    }()

    private lazy var phoneLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    private lazy var arrowImageView: UIImageView = {
        let arrowImageView = UIImageView()
        arrowImageView.image = UDIcon.getIconByKey(.downOutlined, iconColor: .ud.iconN3, size: CGSize(width: 16, height: 16))
        return arrowImageView
    }()

    private lazy var seperatorView: UIView = {
        let seperatorView = UIView()
        seperatorView.backgroundColor = UIColor.ud.lineBorderComponent
        return seperatorView
    }()

    private lazy var phoneLeftView: UIView = {
        let view = UIView()
        view.addSubview(areaSelectionButton)

        view.addSubview(phoneLabel)
        view.addSubview(arrowImageView)
        view.addSubview(seperatorView)

        phoneLabel.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview()
            maker.centerY.equalToSuperview()
            maker.height.equalTo(22)
        }
        arrowImageView.snp.makeConstraints { (maker) in
            maker.left.equalTo(phoneLabel.snp.right).offset(8)
            maker.centerY.equalToSuperview()
            maker.size.equalTo(16)
        }
        seperatorView.snp.makeConstraints { (maker) in
            maker.left.equalTo(arrowImageView.snp.right).offset(12)
            maker.right.equalToSuperview()
            maker.width.equalTo(1)
            maker.height.equalTo(22)
            maker.centerY.equalToSuperview()
        }
        areaSelectionButton.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        return view
    }()

    private lazy var actionButton: UIButton = {
        let button = UIButton()
        button.setTitle(I18n.View_VM_CallButton, for: .normal)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.setTitleColor(UIColor.ud.udtokenBtnPriTextDisabled, for: .disabled)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.vc.setBackgroundColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.primaryContentPressed, for: .highlighted)
        button.vc.setBackgroundColor(UIColor.ud.fillDisabled, for: .disabled)
        button.layer.cornerRadius = 10.0
        button.layer.masksToBounds = true
        button.addInteraction(type: .lift)

        return button
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.ud.bgBody
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        return label
    }()

    private lazy var statusBar: UIView = {
        let view = UIView()
        view.addSubview(statusLabel)

        statusLabel.snp.makeConstraints { (maker) in
            maker.centerX.centerY.equalToSuperview()
            maker.height.equalTo(20)
            maker.left.equalToSuperview().offset(20)
            maker.right.equalToSuperview().inset(20)
        }
        view.isHidden = true
        return view
    }()

    private lazy var disabledTipView: PSTNDisabledTipView = {
        let tipView = PSTNDisabledTipView()
        tipView.isHidden = true
        view.addSubview(tipView)
        tipView.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
        }
        return tipView
    }()

    private lazy var tapGesture: UITapGestureRecognizer = {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.rx.event
            .subscribe(onNext: { [weak nameField, weak phoneField] _ in
                nameField?.endEditing(true)
                phoneField?.endEditing(true)
            }).disposed(by: rx.disposeBag)
        return tapGesture
    }()

    init(viewModel: PSTNInviteViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.viewModel.nameRelay.accept(nil)
        self.viewModel.phoneRelay.accept("")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarBgColor(UIColor.ud.bgFloatBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = I18n.View_M_InviteByPhone
        view.backgroundColor = UIColor.ud.bgFloatBase
        view.addSubview(scrollView)
        view.addGestureRecognizer(tapGesture)
        scrollView.addSubview(containerView)
        scrollView.addSubview(actionButton)
        doConstraints()
        bindViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        BillingTracksV2.trackEnterPSTNInvite()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        MeetingTracksV2.trackInviteAggClickClose(location: "tab_phone", fromCard: false)
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if newContext.layoutChangeReason.isOrientationChanged {
            self.nameTipLabel.snp.updateConstraints { (make) in
                make.right.equalToSuperview().inset(Layout.marginRight)
            }
        }
    }

    private func doConstraints() {
        scrollView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        containerView.snp.makeConstraints { (maker) in
            maker.centerX.top.equalToSuperview()
            maker.width.equalToSuperview()
            maker.bottom.equalTo(actionButton.snp.top)
        }
        actionButton.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.width.equalToSuperview().offset(-32)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).offset(Display.iPhoneXSeries ? -8 : -12)
            maker.height.equalTo(48)
        }
    }

    enum Layout {
        static var marginRight: CGFloat {
            let insets = VCScene.safeAreaInsets
            return max(insets.right, 32)
        }

        static var marginLeft: CGFloat {
            let insets = VCScene.safeAreaInsets
            return max(insets.left, 32)
        }
    }

    private func createRightView(_ textField: UITextField?) {
        let clearButton = UIButton()
        clearButton.setImage(UDIcon.getIconByKey(.closeFilled, iconColor: .ud.iconN3, size: CGSize(width: 20, height: 20)), for: .normal)
        clearButton.frame = CGRect(x: 0, y: 0, width: 50, height: 20)
        let container = UIView()
        container.addSubview(clearButton)
        clearButton.snp.makeConstraints { (maker) in
            maker.top.bottom.right.centerY.equalToSuperview()
            maker.left.equalToSuperview().offset(6)
        }
        textField?.rightViewMode = .always
        textField?.rightView = container

        clearButton.rx.tap.subscribe(onNext: { (_) in
            textField?.text = ""
            textField?.sendActions(for: .valueChanged)
        }).disposed(by: disposeBag)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    override var shouldAutorotate: Bool {
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.rightView = nil
    }

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        var text = textField.text ?? ""
        guard let strRange = Range<String.Index>(range, in: text) else {
            return false
        }

        let maxLength = PSTNInputMaxCharacterLength
        text.replaceSubrange(strRange, with: string)
        return text.count <= maxLength
    }

    @objc private func didClickAreaCode(_ sender: Any?) {
        let setting = self.viewModel.setting
        let vm = PSTNAreaCodeViewModel(pstnOutgoingCallCountryDefault: setting.pstnOutgoingCallCountryDefault,
                                       pstnOutgoingCallCountryList: setting.pstnOutgoingCallCountryList,
                                       selectedRelay: self.viewModel.selectedRelay)
        viewModel.router.push(PSTNAreaCodeViewController(viewModel: vm), from: self)
    }
}

extension Reactive where Base: UIView {
    var borderColor: Binder<(UIColor?, CGFloat)> {
        return Binder(self.base) { view, wrapper in
            view.layer.vc.borderColor = wrapper.0
            view.layer.borderWidth = wrapper.1
        }
    }
}

extension Reactive where Base: UILabel {
    var textColor: Binder<UIColor?> {
        return Binder(self.base) { label, color in
            label.textColor = color
        }
    }
}

extension Reactive where Base: UITextField {
    var textColor: Binder<UIColor?> {
        return Binder(self.base) { textField, color in
            textField.textColor = color
        }
    }
}
