//
//  ForwardMentionViewController.swift
//  LarkForward
//
//  Created by ByteDance on 2023/5/17.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import RxSwift
import RxCocoa
import LarkCore
import LarkAlertController
import EENavigator
import UniverseDesignToast
import LarkKeyboardKit
import LarkKeyCommandKit
import LarkMessengerInterface
import LarkSearchCore
import LKCommonsTracker
import LarkSDKInterface

public final class ForwardMentionViewController: BaseUIViewController, PickerDelegate, UITextViewDelegate {

    private let disposeBag = DisposeBag()
//    let provider: ForwardAlertProvider
    let forwardConfig: ForwardConfig
    private var selectItems: [Option] { picker.selected }
    private var selectRecordInfos: [ForwardSelectRecordInfo] = []

    /// 点击导航左边的x按钮退出At界面
    var cancelCallBack: (() -> Void)?
    /// 分享成功回调
    var successCallBack: ((_ selectItems: [ForwardItem]) -> Void)?

    var inputNavigationItem: UINavigationItem?

    //为true时 切出app会该vc会被隐藏。
    //仅在从其他app分享到飞书时会设为true
    var shouldDismissWhenResignActive = false

    private(set) var isMultiSelectMode: Bool {
        get { picker.isMultiple }
        set { picker.isMultiple = newValue }
    }

    func isMultipleChanged() {
        let currentNavigationItem = inputNavigationItem ?? self.navigationItem
        if isMultiSelectMode {
            currentNavigationItem.leftBarButtonItem = self.cancelItem
            currentNavigationItem.rightBarButtonItem = UIBarButtonItem(customView: sureButton)
        } else {
            currentNavigationItem.leftBarButtonItem = self.leftBarButtonItem
            currentNavigationItem.rightBarButtonItem = self.rightBarButtonItem
        }
        self.updateSureStatus()
    }

    private(set) lazy var leftBarButtonItem: UIBarButtonItem = {
        if hasBackPage, navigationItem.leftBarButtonItem == nil {
            return addBackItem()
        }
        if !hasBackPage, presentingViewController != nil, navigationItem.leftBarButtonItem == nil {
            return addCancelItem()
        }
        return addCancelItem()
    }()

    private(set) lazy var rightBarButtonItem: UIBarButtonItem? = {
        if forwardConfig.chooseConfig.enableSwitchSelectMode {
            return self.multiSelectItem
        }
        return nil
    }()

    private var picker: AtPicker

    private(set) lazy var sureButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 90, height: 30))
        button.addTarget(self, action: #selector(didTapSure), for: .touchUpInside)
        button.setTitleColor(UIColor.ud.textDisable, for: .disabled)
        button.setTitleColor(UIColor.ud.primaryPri500.withAlphaComponent(0.6), for: .highlighted)
        button.setTitleColor(UIColor.ud.primaryPri500, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.setTitle(BundleI18n.LarkForward.Lark_Legacy_Send, for: .normal)
        button.contentHorizontalAlignment = .right
        return button
    }()

    private(set) lazy var cancelItem: UIBarButtonItem = {
        let btnItem = LKBarButtonItem(title: BundleI18n.LarkForward.Lark_Legacy_Cancel)
        btnItem.setProperty(font: UIFont.systemFont(ofSize: 16))
        btnItem.setBtnColor(color: UIColor.ud.textTitle)
        btnItem.button.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        return btnItem
    }()

    private(set) lazy var multiSelectItem: UIBarButtonItem = {
        let btnItem = LKBarButtonItem(title: BundleI18n.LarkForward.Lark_Legacy_MultipleChoice)
        btnItem.setProperty(font: UIFont.systemFont(ofSize: 16), alignment: .right)
        btnItem.setBtnColor(color: UIColor.ud.textTitle)
        btnItem.button.addTarget(self, action: #selector(didTapMultiSelect), for: .touchUpInside)
        return btnItem
    }()

    // MARK: Key bindings
    public override func subProviders() -> [KeyCommandProvider] {
        return [picker]
    }
    public override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + confirmKeyBinding
    }

    private var confirmKeyBinding: [KeyBindingWraper] {
        return isMultiSelectMode && sureButton.isEnabled ? [
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputReturn,
                modifierFlags: .command,
                discoverabilityTitle: BundleI18n.LarkForward.Lark_Legacy_Sure
            )
            .binding(target: self, selector: #selector(didTapSure))
            .wraper
        ] : []
    }

    private var currentAlertController: LarkAlertController?

    public init(forwardConfig: ForwardConfig,
                inputNavigationItem: UINavigationItem? = nil,
                successCallBack: ((_ selectItems: [ForwardItem]) -> Void)? = nil,
                cancelCallBack: (() -> Void)? = nil
    ) {
        self.forwardConfig = forwardConfig
        var pickerParam = AtPicker.InitParam()
        let includeConfigs = forwardConfig.targetConfig.includeConfigs
        pickerParam = ForwardConfigUtils.convertIncludeConfigsToAtPickerInitParams(includeConfigs: includeConfigs, pickerParam: pickerParam)
        // 只显示User和机器人，PM说未来可能拓展为At群聊
        pickerParam.filter = { (item) -> Bool in
            if item.type == .user || item.type == .bot {
                return true
            }
            return false
        }
        pickerParam.scene = "AtUser"
        self.picker = AtPicker(resolver: forwardConfig.alertConfig.userResolver, frame: .zero, params: pickerParam)
        self.inputNavigationItem = inputNavigationItem
        super.init(nibName: nil, bundle: nil)

        picker.delegate = self
        picker.defaultView = AtUserDefaultView(resolver: self.forwardConfig.alertConfig.userResolver,
            frame: .zero, customView: nil, selection: picker, canForwardToTopic: true, scene: picker.scene, fromVC: self, filter: picker.filter
        )
        self.successCallBack = successCallBack
        self.cancelCallBack = cancelCallBack
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.title = BundleI18n.LarkForward.Lark_Legacy_SelectTip

        picker.fromVC = self
        self.view.addSubview(picker)
        picker.frame = view.bounds
        picker.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        self.closeCallback = { [weak self] () in
            guard let `self` = self else { return }
//            self.forwardConfig.commonConfig.dismissAction()
            self.cancelCallBack?()
        }
        self.backCallback = { [weak self] in
            guard let `self` = self else { return }
//            self.forwardConfig.commonConfig.dismissAction()
            self.cancelCallBack?()
        }
        bindViewModel()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil)
    }

    private func bindViewModel() {
        picker.selectedChangeObservable.bind(onNext: { [weak self] _ in self?.updateSelectedInfo() }).disposed(by: disposeBag)
        picker.isMultipleChangeObservable.bind(onNext: { [weak self] _ in self?.isMultipleChanged() }).disposed(by: disposeBag)

        self.isMultipleChanged() // init UI Set
    }
    @objc
    private func willResignActive() {
        guard let vc = currentAlertController, vc.presentingViewController != nil, shouldDismissWhenResignActive else { return }

        vc.dismiss(animated: false, completion: nil)
        self.dismiss(animated: true, completion: { [weak self] in self?.cancelCallBack?() })
    }

    @objc
    func didTapSure(isCreateGroup: Bool = false) {
        self.view.endEditing(false)
        self.atUsers()
    }

    private func atUsers() {
        let selectItems: [ForwardItem] = picker.selected.compactMap { cast(option: $0) }
        self.successCallBack?(selectItems)
        self.dismiss(animated: true, completion: {})

    }

    @objc
    public func didTapCancel() {
        self.isMultiSelectMode = false
    }

    @objc
    public func didTapMultiSelect() {
        self.isMultiSelectMode = true
    }

    private func updateSelectedInfo() {
        assert(Thread.isMainThread, "should occur on main thread!")
        updateSureStatus()
        let idSet = Set(self.selectItems.map { $0.optionIdentifier.id })
        self.selectRecordInfos.removeAll { !idSet.contains($0.id) }
    }

    private func updateSureStatus() {
        self.updateSureButton(count: self.selectItems.count)
        if !self.selectItems.isEmpty {
            self.sureButton.setTitleColor(UIColor.ud.primaryPri500, for: .normal)
            self.sureButton.isEnabled = true
        } else {
            self.sureButton.setTitleColor(UIColor.ud.primaryPri500.withAlphaComponent(0.6), for: .normal)
            self.sureButton.isEnabled = false
        }
    }

    func updateSureButton(count: Int) {
        var title = BundleI18n.LarkForward.Lark_Legacy_Sure
        if count >= 1 {
            title = BundleI18n.LarkForward.Lark_Legacy_Sure + "(\(count))"
        }
        self.sureButton.setTitle(title, for: .normal)
    }

    // MARK: PickerDelegate
    public func picker(_ picker: Picker, disabled option: Option, from: Any?) -> Bool {
        guard let item = cast(option: option) else { return false }
        return item.isCrypto
    }

    public func unfold(_ picker: Picker) {
        let body = PickerSelectedBody(
            picker: self.picker,
            confirmTitle: sureButton.titleLabel?.text ?? BundleI18n.LarkForward.Lark_Legacy_Send,
            allowSelectNone: false,
            shouldDisplayCountTitle: false,
            completion: { [weak self] _ in
                self?.didTapSure()
            })
        self.forwardConfig.alertConfig.userResolver.navigator.push(body: body, from: self)
    }

    public func picker(_ picker: Picker, willSelected option: Option, from: Any?) -> Bool {
        guard let item = cast(option: option) else { return false }
        if picker.isMultiple {
            let maxSelectCount = self.forwardConfig.chooseConfig.maxSelectCount
            if picker.selected.count >= maxSelectCount {
                let alertController = LarkAlertController()
                alertController.setContent(text: String(format: BundleI18n.LarkForward.Lark_Legacy_MaxChooseLimit, maxSelectCount))
                alertController.addButton(text: BundleI18n.LarkForward.Lark_Legacy_Sure)
                self.forwardConfig.alertConfig.userResolver.navigator.present(alertController, from: self)
                return false
            }
        }
        return true
    }
    public func picker(_ picker: Picker, willDeselected option: Option, from: Any?) -> Bool {
        guard let item = cast(option: option) else { return false }
        return traceClick(item: item, selected: false)
    }

    func traceClick(item: ForwardItem, selected: Bool) -> Bool {
        if selected {
            guard let window = view.window else {
                assertionFailure()
                return false
            }
            if !item.hasInvitePermission {
                UDToast.showFailure(
                    with: BundleI18n.LarkForward.Lark_NewContacts_CantForwardDueToBlockOthers,
                    on: window
                )
                return false
            }
            if item.isCrypto {
                UDToast.showFailure(
                    with: BundleI18n.LarkForward.Lark_Forward_CantForwardToSecretChat,
                    on: window
                )
                return false
            }
            return true
        }
        return true
    }

    public func picker(_ picker: Picker, didSelected option: Option, from: Any?) {
        if let info = Self.asForwardSelectRecordInfo(option: option, from: from) {
            if !picker.isMultiple { selectRecordInfos.removeAll() }
            selectRecordInfos.append(info)
        } else {
            assertionFailure("option \(option) can't convert to ForwardSelectRecordInfo")
        }

        if !picker.isMultiple {
            didTapSure()
        }
    }

    static func asForwardSelectRecordInfo(option: Option, from: Any?) -> ForwardSelectRecordInfo? {
        if
            let info = from as? PickerSelectedFromInfo,
            let indexPath = info.indexPath,
            let type = ForwardSelectRecordInfo.ResultType(rawValue: info.tag)
        {
            return ForwardSelectRecordInfo(
                id: option.optionIdentifier.id,
                offset: Int32(indexPath.row),
                resultType: type)
        }
        return nil
    }

    func cast(option: Option) -> ForwardItem? {
        let v = option as? ForwardItem
        assert(v != nil, "all option should be forwarditem")
        return v
    }
}
