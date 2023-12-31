//
//  PickerSelectedViewController.swift
//  LarkSearchCore
//
//  Created by 赵家琛 on 2021/2/3.
//

import UIKit
import Foundation
import LarkSDKInterface
import LarkUIKit
import RxSwift
import EENavigator
import LarkMessengerInterface
import UniverseDesignToast
import LarkModel
import LarkListItem
import LarkContainer

public final class PickerSelectedViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate, UserResolverWrapper {
    public let userResolver: LarkContainer.UserResolver
    private let completion: (UIViewController) -> Void
    private let confirmTitle: String
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let disposeBag = DisposeBag()
    private weak var delegate: SelectedViewControllerDelegate?
    private let allowSelectNone: Bool
    var isNew: Bool = false

    public var shouldDisplayCountTitle: Bool = true
    public var scene: String?
    public weak var fromVC: UIViewController?
    public var userId: String?
    public var isUseDocIcon: Bool = false
    private var targetPreview: Bool
    private var transformer: PickerSelectedItemTransformer

    public init(resolver: LarkContainer.UserResolver,
                delegate: SelectedViewControllerDelegate,
                confirmTitle: String,
                allowSelectNone: Bool,
                targetPreview: Bool,
                completion: @escaping (UIViewController) -> Void) {
        self.userResolver = resolver
        self.targetPreview = targetPreview
        self.delegate = delegate
        self.completion = completion
        self.confirmTitle = confirmTitle
        self.allowSelectNone = allowSelectNone
        self.transformer = PickerSelectedItemTransformer(accessoryTransformer: .init(isOpen: targetPreview))
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // nolint: duplicated_code 不同业务不同的初始化方法
    public override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.confirmButton)
        if let delegate = self.delegate {
            self.navigationItem.titleView = PickerNavigationTitleView(
                title: BundleI18n.LarkSearchCore.Lark_Groups_MobileYouveSelected,
                observable: delegate.selectedObservable,
                initialValue: delegate.selected,
                shouldDisplayCountTitle: shouldDisplayCountTitle
            )
            self.configureConfirmItem(selected: delegate.selected)
        }

        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = 64
        tableView.register(PickerSelectedTableViewCell.self, forCellReuseIdentifier: "PickerSelectedTableViewCell")
        tableView.register(PickerSelectListCell.self, forCellReuseIdentifier: "PickerSelectListCell")
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.frame = self.view.bounds
        tableView.reloadData()

        self.delegate?.selectedObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] selected in
                guard let self = self else { return }
                self.tableView.reloadData()
                self.configureConfirmItem(selected: selected)
            }).disposed(by: disposeBag)
    }
    // enable-lint: duplicated_code

    private lazy var confirmButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 90, height: 30))
        button.addTarget(self, action: #selector(didConfirm), for: .touchUpInside)
        button.setTitle(self.confirmTitle, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault.withAlphaComponent(0.6), for: .highlighted)
        button.setTitleColor(UIColor.ud.fillDisable, for: .disabled)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.contentHorizontalAlignment = .right
        return button
    }()

    private func configureConfirmItem(selected: [Option]) {
        if selected.isEmpty {
            self.confirmButton.isEnabled = self.allowSelectNone
        } else {
            self.confirmButton.isEnabled = true
        }
        self.confirmButton.setTitle(BundleI18n.LarkSearchCore.Lark_Legacy_Sure + "(\(delegate?.selected.count ?? 0))", for: .normal)
        if self.confirmButton.isEnabled {
            self.confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        } else {
            self.confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        }
    }

    @objc
    func didConfirm(_ button: UIButton) {
        self.completion(self)
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return delegate?.selected.count ?? 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PickerSelectedTableViewCell") as? PickerSelectedTableViewCell,
              let selected = delegate?.selected,
              selected.count > indexPath.row else {
            assertionFailure()
            return UITableViewCell()
        }
        let option = selected[indexPath.row]
        cell.optionIdentifier = option.optionIdentifier
        let targetPreview = self.targetPreview && TargetPreviewUtils.canTargetPreview(optionIdentifier: option.optionIdentifier)
        let ccmTypes: [PickerItem.MetaType] = [.doc, .wiki, .wikiSpace, .mailUser]

        // use list item
        if let item = option as? PickerItem {
            switch item.meta {
            case .chatter(_):
                if let cell = tableView.dequeueReusableCell(withIdentifier: "PickerSelectListCell", for: indexPath) as? PickerSelectListCell {
                    cell.node = transformer.transform(indexPath: indexPath, item: item)
                    cell.delegate = self
                    return cell
                }
            default: break
            }
        }

        if isUseDocIcon, let item = option as? PickerItem,
           ccmTypes.contains(item.meta.type) {
            cell.context.userId = self.userId
            cell.node = PickerItemTransformer.transform(indexPath: indexPath, item: item)
            cell.didDeleteHandler = { [weak self] in
                self?.delegate?.deselect(option: option, from: self)
            }
        } else {
            delegate?.configureInfo(for: option, callback: { [weak self] (info) in
                guard let self = self, option.optionIdentifier == cell.optionIdentifier, let info = info else { return }

                var infoText: String = ""
                var description: String = info.selectedOptionDescription ?? ""
                let imageURLStr: String? = info.avatarImageURLStr
                if option.optionIdentifier.type == OptionIdentifier.Types.chat.rawValue,
                   let chatInfo = info as? SelectedChatOptionInfo {
                    infoText = "\(chatInfo.chatUserCount)"
                    if chatInfo.isUserCountVisible == false {
                        infoText = ""
                    }
                    description = chatInfo.chatDescription
                }

                let props = PickerSelectedCellProps(
                    name: info.name,
                    info: infoText,
                    isMsgThread: info.isMsgThread,
                    description: description,
                    avatarIdentifier: info.avaterIdentifier,
                    avatarKey: info.avatarKey,
                    avatarImageURL: imageURLStr,
                    backupImage: info.backupImage,
                    targetPreview: targetPreview,
                    tapHandler: { [weak self] in
                        guard let self = self else { return }
                        self.delegate?.deselect(option: option, from: self)
                    })
                cell.setProps(props)
            })
        }
        cell.targetInfo.tag = indexPath.row
        cell.targetInfo.addTarget(self, action: #selector(presentPreviewViewController(button:)), for: .touchUpInside)
        if isNew {
            cell.backgroundColor = .clear
        }
        return cell
    }
    @objc
    private func presentPreviewViewController(button: UIButton) {
        guard let selected = delegate?.selected,
              let fromVC = self.fromVC,
              selected.count > button.tag else { return }
        let item = selected[button.tag].optionIdentifier
        let chatID = item.chatId
        //未开启过会话的单聊，chatID为空时，需传入uid
        let userID = chatID.isEmpty ? item.id : ""
        if !TargetPreviewUtils.canTargetPreview(optionIdentifier: item) {
            UDToast.showTips(with: BundleI18n.LarkSearchCore.Lark_IM_UnableToPreviewContent_Toast, on: self.view)
        } else if TargetPreviewUtils.isThreadGroup(optionIdentifier: item) {
            //话题群
            let threadChatPreviewBody = ThreadPreviewByIDBody(chatID: chatID)
            userResolver.navigator.present(body: threadChatPreviewBody, wrap: LkNavigationController.self, from: fromVC)
        } else {
            //会话
            let chatPreviewBody = ForwardChatMessagePreviewBody(chatId: chatID, userId: userID, title: item.name)
            userResolver.navigator.present(body: chatPreviewBody, wrap: LkNavigationController.self, from: fromVC)
        }
        SearchTrackUtil.trackPickerSelectClick(scene: scene, clickType: .chatDetail(target: "none"))
    }
}

extension PickerSelectedViewController: ItemTableViewCellDelegate {
    public func listItemDidClickAccessory(type: ListItemNode.AccessoryType, at indexPath: IndexPath) {
        guard let selected = delegate?.selected,
              selected.count > indexPath.row else { return }
        let option = selected[indexPath.row]
        switch type {
        case .targetPreview:
            if let item = option as? PickerItem,
               let fromVC = self.fromVC,
               case .chatter(let meta) = item.meta {
                let chatPreviewBody = ForwardChatMessagePreviewBody(chatId: meta.p2pChat?.id ?? "", userId: meta.id, title: meta.localizedRealName ?? "")
                userResolver.navigator.present(body: chatPreviewBody, wrap: LkNavigationController.self, from: fromVC)
                SearchTrackUtil.trackPickerSelectClick(scene: scene, clickType: .chatDetail(target: "none"))
            }
        case .delete:
            self.delegate?.deselect(option: option, from: self)
        default:
            break
        }
    }
}
