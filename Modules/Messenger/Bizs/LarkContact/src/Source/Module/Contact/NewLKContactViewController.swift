//
//  NewLKContactViewController.swift
//  LarkContact
//
//  Created by zc09v on 2020/12/14.
//

import UIKit
import Foundation
import LarkUIKit
import LarkContainer
import RxSwift
import EENavigator
import SnapKit
import LarkSDKInterface
import LarkModel
import LarkSearchCore
import LarkMessengerInterface
import LarkKeyCommandKit
import LarkAccountInterface
import LarkFeatureGating
import LarkTraitCollection
import UniverseDesignFont
import RustPB

enum MultiSelectLeftBarItemStatus {
    case close, skip
}

class NewLKContactViewController: BaseUIViewController {

    // Navibar
    let multiSelectItem = LKBarButtonItem(title: BundleI18n.LarkContact.Lark_Legacy_Select)
    let cancelItem = LKBarButtonItem(title: BundleI18n.LarkContact.Lark_Legacy_Cancel, fontStyle: .regular)
    var sureButton: UIButton { return (sureItem.customView as? UIButton) ?? UIButton(frame: .zero) }
    let sureItem = UIBarButtonItem(customView: UIButton())

    var inputNavigationItem: UINavigationItem?
    let picker: ChatterPicker
    private(set) var singleMultiChangeableStatus: SingleMultiChangeableStatus = .single
    var multiSelectLeftBarItemStatus: MultiSelectLeftBarItemStatus = .close
    let style: NewDepartmentViewControllerStyle
    lazy var customNavigationItem: UINavigationItem = {
        return inputNavigationItem ?? self.navigationItem
    }()
    private let disposeBag = DisposeBag()
    private let allowSelectNone: Bool
    private let allowDisplaySureNumber: Bool
    init(chatterPicker: ChatterPicker,
         style: NewDepartmentViewControllerStyle,
         allowSelectNone: Bool,
         allowDisplaySureNumber: Bool) {

        self.picker = chatterPicker
        self.style = style
        self.allowSelectNone = allowSelectNone
        self.allowDisplaySureNumber = allowDisplaySureNumber
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !isToolBarHidden {
            if let toolbar = self.navigationController?.toolbar as? PickerToolBar {
                self.toolbarItems = toolbar.toolbarItems()
            }
        }
        configNaviBar()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        isNavigationBarHidden = false
        if (navigationController?.toolbar as? PickerToolBar) != nil {
            isToolBarHidden = false
        } else {
            isToolBarHidden = true
        }

        multiSelectItem.button.addTarget(self, action: #selector(multiSelectDidClick), for: .touchUpInside)
        multiSelectItem.button.setTitleColor(UIColor.ud.N900, for: .normal)

        cancelItem.button.addTarget(self, action: #selector(cancelDidClick), for: .touchUpInside)
        cancelItem.button.setTitleColor(UIColor.ud.N900, for: .normal)

        sureButton.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        sureButton.setTitleColor(UIColor.ud.N400, for: .disabled)
        sureButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        sureButton.contentHorizontalAlignment = .right
        sureButton.addTarget(self, action: #selector(sureDidClick), for: .touchUpInside)

        self.updateSureButtonTitle(items: self.picker.selected)
        if self.style == .singleMultiChangeable, !self.picker.selected.isEmpty {
            singleMultiChangeableStatus = .multi
        }
        configNaviBar()

        picker.selectedObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (items) in
                self?.updateSureButtonTitle(items: items)
            }).disposed(by: self.disposeBag)

        RootTraitCollection.observer
            .observeRootTraitCollectionDidChange(for: view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.configNaviBar()
            }).disposed(by: disposeBag)
    }

    // MARK: Key bindings
    override func subProviders() -> [KeyCommandProvider] {
        return [picker]
    }

    override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + confirmKeyBinding
    }

    private var confirmKeyBinding: [KeyBindingWraper] {
        return style == .multi && sureButton.isEnabled ? [
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputReturn,
                modifierFlags: .command,
                discoverabilityTitle: BundleI18n.LarkContact.Lark_Legacy_ConfirmInfo
            )
            .binding(handler: { [weak self] in
                self?.sureDidClick()
            })
            .wraper
        ] : []
    }

    // MARK: NaviBar
    func configNaviBar() {
        let addBackOrCloseItem = { [weak self ] in
            guard let strongSelf = self else { return }
            if strongSelf.hasBackPage {
                strongSelf.addBackItem()
            } else if strongSelf.presentingViewController != nil {
                strongSelf.addCancelItem()
            } else {
                strongSelf.customNavigationItem.leftBarButtonItem = nil
            }
        }

        switch style {
        case .multi:
            switch multiSelectLeftBarItemStatus {
            case .close:
                addBackOrCloseItem()
            case .skip: // 跳过样式
                setNavigationBarSkipItem()
            }
            // 多选
            customNavigationItem.rightBarButtonItem = sureItem
        case .single:
            // 单选： 只有返回
            addBackOrCloseItem()
        case .singleMultiChangeable:
            switch singleMultiChangeableStatus {
            case .single:
                // 默认单选： 返回 + 多选
                addBackOrCloseItem()
                customNavigationItem.rightBarButtonItem = multiSelectItem
            case .multi:
                // 默认多选： 取消 + 确定
                customNavigationItem.leftBarButtonItem = cancelItem
                customNavigationItem.rightBarButtonItem = sureItem
            }
        }

        if case .singleMultiChangeable = style, singleMultiChangeableStatus == .multi {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        } else {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }

    private func setNavigationBarSkipItem() {
        let leftItem = LKBarButtonItem()
        leftItem.button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        leftItem.button.titleLabel?.font = UDFont.headline
        leftItem.reset(title: BundleI18n.LDR.Lark_Guide_Benefits1ButtonSkip, font: UDFont.headline)
        leftItem.addTarget(self, action: #selector(navigationBarSkipItemTapped), for: .touchUpInside)
        customNavigationItem.leftBarButtonItem = leftItem
    }

    @objc
    private func navigationBarSkipItemTapped() {
        // 点击跳过，收起键盘
        UIApplication.shared.sendAction(#selector(self.resignFirstResponder), to: nil, from: nil, for: nil)
        self.closeCallback?()
    }

    @objc
    func multiSelectDidClick() {
        guard case .singleMultiChangeable = style, singleMultiChangeableStatus == .single else {
            return
        }
        singleMultiChangeableStatus = .multi
        configNaviBar()
        picker.isMultiple = true
    }

    @objc
    func cancelDidClick() {
        guard case .singleMultiChangeable = style, singleMultiChangeableStatus == .multi else {
            return
        }
        singleMultiChangeableStatus = .single
        picker.isMultiple = false
        configNaviBar()
    }

    @objc
    func sureDidClick() {
        assertionFailure("子类需要重写该方法")
    }

    func updateSureButtonTitle(items: [Option]) {
        var sureTitle = BundleI18n.LarkContact.Lark_Legacy_ConfirmInfo
        if self.allowDisplaySureNumber {
            let totalCount = items.count
            sureTitle += "(\(totalCount))"
        }
        self.sureButton.setTitle(sureTitle, for: .normal)
        self.sureButton.sizeToFit()

        if items.isEmpty {
            self.sureButton.isEnabled = self.allowSelectNone
        } else {
            self.sureButton.isEnabled = true
        }
    }
}

extension ContactPickerResult {
    /// convert picker options to old ContactPickerResult struct
    final class FromOptionBuilder: ConvertOptionToSelectChatterInfo {
        var includeMeetingGroup = false

        var userResolver: UserResolver
        init(resolver: UserResolver) {
            self.userResolver = resolver
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func build(options: [Option], extra: Any?, isRecommendSelected: Bool = false) -> ContactPickerResult {
            var meetingGroupChatIds = [String]()
            var mails = [String]()
            var departments = [SelectDepartmentInfo]()
            var chatInfos = [SelectChatInfo]()
            var mailContacts = [SelectMailInfo]()
            for i in options {
                let identifier = i.optionIdentifier
                switch identifier.type {
                case OptionIdentifier.Types.chat.rawValue:
                    if includeMeetingGroup && i.isMeeting {
                        meetingGroupChatIds.append(identifier.id)
                    } else {
                        if let info = asChatInfo(option: i) {
                            chatInfos.append(info)
                        } else {
                            assertionFailure("unknown chat types \(i)")
                        }
                    }
                case OptionIdentifier.Types.mailContact.rawValue:
                    if let m = asMailInfo(option: i, email: identifier.id) {
                        mailContacts.append(m)
                    } else {
                        mails.append(identifier.id)
                    }
                case OptionIdentifier.Types.department.rawValue:
                    guard let v = asDepartmentInfo(option: i) else {
                        assertionFailure("unknown department types \(i). id only department is not supported")
                        break
                    }
                    departments.append(v)
                default: break
                }
            }
            let chatterInfos = self.chatterInfos(from: options)
            let botInfos = self.botInfos(from: options)
            assert(botInfos.count + chatterInfos.count + chatInfos.count + meetingGroupChatIds.count + mails.count + departments.count + mailContacts.count == options.count,
                   "has unsupported selected option be choosed")
            return ContactPickerResult(chatterInfos: chatterInfos,
                                       botInfos: botInfos,
                                       chatInfos: chatInfos,
                                       departments: departments,
                                       mails: mails,
                                       meetingGroupChatIds: meetingGroupChatIds,
                                       mailContacts: mailContacts,
                                       isRecommendSelected: isRecommendSelected,
                                       extra: extra)
        }
        func asDepartmentInfo(option: Option) -> SelectDepartmentInfo? {
            let identifier = option.optionIdentifier
            guard identifier.type == OptionIdentifier.Types.department.rawValue else { return nil }
            switch option {
            case let v as SelectedOptionInfoConvertable:
                return SelectDepartmentInfo(id: identifier.id, name: v.asSelectedOptionInfo().name)
            default: return nil
            }
        }

        func asChatInfo(option: Option) -> SelectChatInfo? {
            let identifier = option.optionIdentifier
            guard identifier.type == OptionIdentifier.Types.chat.rawValue else { return nil }
            switch option {
            case let v as SelectedOptionInfoConvertable:
                guard let selectedChatOptionInfo = v.asSelectedOptionInfo() as? SelectedChatOptionInfo else { return nil }
                var chatInfo = SelectChatInfo(id: identifier.id,
                                      name: selectedChatOptionInfo.name,
                                      avatarKey: selectedChatOptionInfo.avatarKey,
                                      chatUserCount: selectedChatOptionInfo.chatUserCount,
                                      chatDescription: selectedChatOptionInfo.chatDescription,
                                      crossTenant: selectedChatOptionInfo.crossTenant)
                if let result = option as? LarkSDKInterface.Search.Result,
                   let res = result.base as? Search_V2_SearchResult,
                   case .groupChatMeta(let chatMeta) = res.resultMeta.typedMeta {
                    chatInfo.isInTeam = chatMeta.isInTeam
                }
                return chatInfo
            default: return nil
            }
        }

        func asMailInfo(option: Option, email: String) -> SelectMailInfo? {
            let identifier = option.optionIdentifier
            guard identifier.type == OptionIdentifier.Types.mailContact.rawValue else { return nil }
            switch option {
            case let v as SelectedOptionInfoConvertable:
                guard let selectedOptionInfo = v.asSelectedOptionInfo() as? SelectedOptionInfo else { return nil }
                return SelectMailInfo(displayName: selectedOptionInfo.name,
                                      avatarKey: selectedOptionInfo.avatarKey, email: email,
                                      entityId: selectedOptionInfo.avaterIdentifier,
                                      type: option.contactType)
            default: return nil
            }
        }
    }
}

extension Option {
    public var isMeeting: Bool {
        if let v = self as? SearchResultType, case .chat(let meta) = v.meta { return meta.isMeeting }
        return false
    }

    public var contactType: SelectMailInfo.ContactType {
        if let v = self as? SearchResultType, case .mailContact(let meta) = v.meta {
            switch meta.type {
            case .chatter: return .chatter
            case .externalContact: return .external
            case .group: return .group
            case .mailGroup: return .mailGroup
            case .nameCard: return .nameCard
            case .sharedMailbox: return .sharedMailbox
            case .unknown: return .unknown
            case .noneType: return .noneType
            @unknown default: return .unknown
            }
        }
        if let v = self as? NameCardInfo {
            return .nameCard
        }
        if let v = self as? MailSharedEmailAccount {
            return .sharedMailbox
        }
        return .unknown
    }
}
