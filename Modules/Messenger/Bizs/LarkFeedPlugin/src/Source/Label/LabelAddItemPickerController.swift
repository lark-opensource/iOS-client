//
//  LabelAddItemPickerController.swift
//  LarkFeedPlugin
//
//  Created by 夏汝震 on 2022/4/25.
//

import UIKit
import Foundation
import LarkUIKit
import LarkSDKInterface
import LarkSearchCore
import LarkMessengerInterface
import UniverseDesignColor
import LarkContainer
import RxSwift
import RxCocoa
import UniverseDesignToast
import LarkSetting
import EENavigator

final class LabelAddItemPickerController: BaseUIViewController, UserResolverWrapper {
    let userResolver: UserResolver
    private let labelId: Int64
    private let disabledSelectedIds: Set<String>
    let feedAPI: FeedAPI
    private let disposeBag = DisposeBag()

    private lazy var sureButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 90, height: 30))
        button.addTarget(self, action: #selector(didTapSure), for: .touchUpInside)
        button.setTitleColor(UIColor.ud.textDisable, for: .disabled)
        button.setTitleColor(UIColor.ud.primaryContentDefault.withAlphaComponent(0.6), for: .highlighted)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.setTitle(BundleI18n.LarkFeedPlugin.Lark_Core_AddNewChatToLabelName_Add_Button, for: .normal)
        button.contentHorizontalAlignment = .right
        return button
    }()

    private lazy var cancelItem: UIBarButtonItem = {
        let btnItem = LKBarButtonItem(title: BundleI18n.LarkFeedPlugin.Lark_Core_AddNewChatToLabelName_Cancel_Button)
        btnItem.setProperty(font: UIFont.systemFont(ofSize: 16))
        btnItem.setBtnColor(color: UIColor.ud.textTitle)
        btnItem.button.addTarget(self, action: #selector(closeBtnTapped), for: .touchUpInside)
        return btnItem
    }()

    private lazy var picker: ChatPicker = {
        var params = ChatPicker.InitParam()
        params.includeThread = false
        params.isMultiple = true
        params.delegate = self
        params.targetPreview = userResolver.fg.staticFeatureGatingValue(with: "core.forward.target_preview")
        params.shouldShowRecentForward = false
        let picker = ChatPicker(resolver: self.userResolver, frame: .zero, params: params)
        return picker
    }()

    init(resolver: UserResolver,
         labelId: Int64,
         disabledSelectedIds: Set<String>
    ) throws {
        feedAPI = try resolver.resolve(assert: FeedAPI.self)
        self.userResolver = resolver
        self.labelId = labelId
        self.disabledSelectedIds = disabledSelectedIds
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.LarkFeedPlugin.Lark_Core_AddChatToLabel_Button
        self.view.backgroundColor = UIColor.ud.bgBase
        navigationItem.leftBarButtonItem = self.cancelItem
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: sureButton)
        picker.fromVC = self
        self.view.addSubview(picker)
        picker.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        checkSureEnable()
    }

    @objc
    func didTapSure() {
        addItemIntoLabel(targetVC: self)
    }

    func addItemIntoLabel(targetVC: UIViewController) {
        let ids = getSelectedIds()
        FeedCellTrack.trackAddItemInToLabel(id: String(labelId), feedsCount: ids.count)
        self.view.endEditing(true)
        feedAPI.addItemIntoLabel(labelId: labelId, itemIds: ids)
            .asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak targetVC] _ in
                guard let self = self, let window = targetVC?.view.window else { return }
                UDToast.showSuccess(with: BundleI18n.LarkFeedPlugin.Lark_Core_Label_ActionSuccess_Toast, on: window)
                self.closeBtnTapped()
        }, onError: { [weak targetVC] error in
            guard let window = targetVC?.view.window else { return }
            UDToast.showFailure(with: BundleI18n.LarkFeedPlugin.Lark_Core_Label_ActionFailed_Toast, on: window, error: error.transformToAPIError())
        }).disposed(by: disposeBag)
    }

    func getSelectedIds() -> [Int64] {
        var itemIds: [Int64] = []
        picker.selected.forEach({
            guard let item = $0 as? ForwardItem,
                  !self.disabledSelectedIds.contains( item.id) else { return }
            if item.type == .chat {
                if let chatId = item.chatId, let id = Int64(chatId) {
                    itemIds.append(id)
                }
            } else {
                if let chatId = item.chatId, let id = Int64(chatId) {
                    itemIds.append(id)
                }
            }
        })
        return itemIds
    }
}

extension LabelAddItemPickerController {
    private func checkSureEnable() {
        self.sureButton.isEnabled = !getSelectedIds().isEmpty
    }
}

extension LabelAddItemPickerController: PickerDelegate {
    /// 选中后调用
    func picker(_ picker: Picker, didSelected option: Option, from: Any?) {
        checkSureEnable()
    }

    /// 取消选中后调用
    func picker(_ picker: Picker, didDeselected option: Option, from: Any?) {
        checkSureEnable()
    }

    /// 是否禁止选择并展示禁止选择的样式
    func picker(_ picker: Picker, disabled option: Option, from: Any?) -> Bool {
        return disabledSelectedIds.contains(option.optionIdentifier.id)
    }

    func picker(_ picker: Picker, forceSelected option: Option, from: Any?) -> Bool {
        return disabledSelectedIds.contains(option.optionIdentifier.id)
    }

    func unfold(_ picker: Picker) {
        let body = PickerSelectedBody(
            picker: self.picker,
            confirmTitle: "",
            allowSelectNone: false,
            shouldDisplayCountTitle: false,
            targetPreview: self.picker.targetPreview,
            completion: { [weak self] targetVC in
                self?.addItemIntoLabel(targetVC: targetVC)
            })
        userResolver.navigator.push(body: body, from: self)
    }
}
