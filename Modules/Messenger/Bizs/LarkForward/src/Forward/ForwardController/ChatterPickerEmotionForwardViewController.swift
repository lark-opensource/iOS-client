//
//  ChatterPickerEmotionForwardViewController.swift
//  LarkForward
//
//  Created by JackZhao on 2021/5/13.
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
import Swinject
import LarkNavigation
import LarkMessengerInterface
import LarkSearchCore
import LarkKeyCommandKit
import UniverseDesignToast
import LarkSDKInterface

final class ChatterPickerEmotionForwardViewController: BaseUIViewController, PickerDelegate {
    private let disposeBag = DisposeBag()
    private let provider: EmotionShareToPanelProvider
    private var animated: Bool = false
    private var picker: ChatPicker

    // MARK: Key bindings
    public override func subProviders() -> [KeyCommandProvider] {
        return [picker]
    }
    public override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings()
    }

    init(provider: EmotionShareToPanelProvider,
         picker: ChatPicker) {
        self.picker = picker
        self.provider = provider
        super.init(nibName: nil, bundle: nil)

        picker.delegate = self
    }

    convenience init(provider: EmotionShareToPanelProvider,
                     canForwardToTopic: Bool = false) {
        let pickerParam = ChatPicker.InitParam()
        pickerParam.includeOuterTenant = provider.needSearchOuterTenant
        pickerParam.includeThread = canForwardToTopic
        self.init(provider: provider, picker: ChatPicker(resolver: provider.userResolver, frame: .zero, params: pickerParam))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = BundleI18n.LarkForward.Lark_Legacy_SelectTip
        self.view.addSubview(picker)
        picker.frame = view.bounds
        picker.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.navigationItem.leftBarButtonItem = self.addCloseItem()
    }

    public func picker(_ picker: Picker, disabled option: Option, from: Any?) -> Bool {
        guard let item = cast(option: option) else { return false }
        return item.isCrypto
    }

    func picker(_ picker: Picker, didSelected option: Option, from: Any?) {
        let selectItems: [ForwardItem] = picker.selected.compactMap { cast(option: $0) }
        guard let model = selectItems.first else {
            return
        }
        guard let window = self.view.window else {
            assertionFailure()
            return
        }
        if !model.hasInvitePermission {
            UDToast.showTips(
                with: BundleI18n.LarkForward.Lark_NewContacts_CantForwardDueToBlockOthers,
                on: window
            )
            return
        }
        if model.isCrypto {
            UDToast.showTips(
                with: BundleI18n.LarkForward.Lark_Forward_CantForwardToSecretChat,
                on: window
            )
            return
        }
        self.provider
            .sureAction(items: [model], input: nil, from: self)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (_) in
            }, onError: { [weak self] (error) in
                guard let self = self else {
                    return
                }
                shareErrorHandler(userResolver: self.provider.userResolver, hud: UDToast(), on: self, error: error)
            }).disposed(by: self.disposeBag)
    }

    func cast(option: Option) -> ForwardItem? {
        let v = option as? ForwardItem
        assert(v != nil, "all option should be forwarditem")
        return v
    }
}
