//
//  FolderManagementViewController.swift
//  LarkFile
//
//  Created by 赵家琛 on 2021/4/7.
//

import UIKit
import Foundation
import LarkUIKit
import LarkMessengerInterface
import EENavigator
import LarkActionSheet
import LarkCore
import RxSwift
import LarkStorage
import UniverseDesignToast
import LarkModel
import LarkContainer

extension KVStores {
    static var file: KVStore {
        Self.udkv(space: .global, domain: Domain.biz.messenger.child("File"))
    }
}

extension KVKeys {
    struct FileManagement {
        static let defaultStyle = KVKey("default.style", default: false)
    }
}

final class FolderManagementViewController: BaseUIViewController {
    private var configuration: FolderManagementConfiguration
    private let contentView: UIView
    private let extra: [AnyHashable: Any]
    private let gridSubject: BehaviorSubject<Bool>
    private let userResolver: UserResolver
    var sourceScene: FileSourceScene
    weak var router: FolderBrowserRouter?
    let viewWillTransitionSubject: PublishSubject<CGSize>
    private lazy var styleButton: UIButton = {
        let btn = UIButton()
        btn.setImage(Resources.icon_item_grid, for: .normal)
        btn.setImage(Resources.icon_item_list, for: .selected)
        btn.addTarget(self, action: #selector(updateFileDisplayStyle(btn:)), for: .touchUpInside)
        return btn
    }()

    @KVConfig(key: KVKeys.FileManagement.defaultStyle, store: KVStores.file)
    static var localIsGridStyle: Bool

    private var trackerCommonParams: [AnyHashable: Any] {
        var params: [AnyHashable: Any] = self.extra
        switch self.sourceScene {
        // 消息-文件夹
        case .chat, .messageDetail:
            params["source"] = "from_msg_folder"
        // 文件tab
        case .fileTab:
            params["source"] = "from_file_tab"
        // 搜索侧文件夹
        case .search:
            params["source"] = "from_search_folder"
        // 其他
        default:
            params["source"] = "other"
        }
        params["page_type"] = "folder_view"
        return params
    }

    init(configuration: FolderManagementConfiguration,
         gridSubject: BehaviorSubject<Bool>,
         viewWillTransitionSubject: PublishSubject<CGSize>,
         contentView: UIView,
         sourceScene: FileSourceScene,
         extra: [AnyHashable: Any],
         userResolver: UserResolver) {
        self.configuration = configuration
        self.contentView = contentView
        self.extra = extra
        self.gridSubject = gridSubject
        self.viewWillTransitionSubject = viewWillTransitionSubject
        self.sourceScene = sourceScene
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var searchContainerView: UIView = {
        let searchTextField = SearchUITextField()
        searchTextField.canEdit = false
        searchTextField.tapBlock = { [weak self] _ in
            self?.router?.goSearch()
        }

        let containerView = UIView()
        containerView.backgroundColor = UIColor.ud.bgBody
        containerView.addSubview(searchTextField)
        searchTextField.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(8)
            make.height.equalTo(38)
        }
        return containerView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.supportSecondaryOnly = true
        self.view.backgroundColor = UIColor.ud.bgBody
        self.title = BundleI18n.LarkFile.Lark_Legacy_FileFragmentTitle
        self.view.addSubview(contentView)
        addRightBarButtonItemIfNeeded()
        addSearchIfNeeded()
        if self.configuration.supportSearch {
            contentView.snp.makeConstraints { (make) in
                make.top.equalTo(searchContainerView.snp.bottom)
                make.left.bottom.right.equalToSuperview()
            }
        } else {
            contentView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }

        self.backCallback = { [weak self] in
            IMTracker.FileManage.Click.close(extra: self?.trackerCommonParams ?? [:])
        }
        self.styleButton.isSelected = Self.localIsGridStyle
    }

    private func addSearchIfNeeded() {
        guard self.configuration.supportSearch else { return }

        self.view.addSubview(searchContainerView)
        searchContainerView.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
        }
    }

    private func addRightBarButtonItemIfNeeded() {
        var items: [UIBarButtonItem] = []
        let styleItem = UIBarButtonItem(customView: styleButton)
        items.append(styleItem)
        guard !self.configuration.menuOptions.isEmpty else {
            self.navigationItem.rightBarButtonItems = items
            return
        }
        let rightBarButtonItem = LKBarButtonItem(image: Resources.more)
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spaceItem.width = 16
        items.insert(spaceItem, at: 0)
        items.insert(rightBarButtonItem, at: 0)
        self.navigationItem.rightBarButtonItems = items
        rightBarButtonItem.button.addTarget(self, action: #selector(rightBarButtonItemClicked(_:)), for: .touchUpInside)
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] (_) in
            self?.viewWillTransitionSubject.onNext(size)
        }, completion: nil)
    }

    @objc
    private func rightBarButtonItemClicked(_ sender: UIButton) {
        if let router = router {
            IMTracker.FileManage.Click.more(extra: self.trackerCommonParams,
                                            fileType: router.getTopVCFileType())
            IMTracker.FileManage.More.View(extra: self.extra, fileType: router.getTopVCFileType())
        }
        let actionSheetAdapter = ActionSheetAdapter()
        let actionSheet = actionSheetAdapter.create(level: .normal(source: sender.defaultSource))

        if configuration.menuOptions.contains(.viewInChat) {
            actionSheetAdapter.addItem(title: BundleI18n.LarkFile.Lark_Legacy_JumpToChat) { [weak self] in
                self?.router?.goChat()
            }
        }
        if configuration.menuOptions.contains(.forward) {
            actionSheetAdapter.addItem(title: BundleI18n.LarkFile.Lark_Legacy_ToastForwardCopy) { [weak self] in
                if let disableBehavior = self?.configuration.disableAction.actions[Int32(MessageDisabledAction.Action.transmit.rawValue)] {
                    let errorMessage: String
                    switch disableBehavior.code {
                    case 311_150:
                        errorMessage = BundleI18n.LarkFile.Lark_IM_MessageRestrictedCantForward_Hover
                    default:
                        errorMessage = BundleI18n.LarkFile.Lark_IM_UnableOperationDueToPermissionRestrictions_Toast
                    }
                    if let view = self?.view {
                        UDToast.showFailure(with: errorMessage, on: view)
                    }
                    return
                }
                self?.router?.forwardCopy()
            }
        }
        if configuration.menuOptions.contains(.openWithOtherApp) {
            actionSheetAdapter.addItem(title: BundleI18n.LarkFile.Lark_Legacy_OpenInAnotherApp) { [weak self] in
                if let disableBehavior = self?.configuration.disableAction.actions[Int32(MessageDisabledAction.Action.saveToLocal.rawValue)] {
                    let errorMessage: String
                    switch disableBehavior.code {
                    case 311_150:
                        errorMessage = BundleI18n.LarkFile.Lark_IM_MessageRestrictedCantDownload_Hover
                    default:
                        errorMessage = BundleI18n.LarkFile.Lark_IM_UnableOperationDueToPermissionRestrictions_Toast
                    }
                    if let view = self?.view {
                        UDToast.showFailure(with: errorMessage, on: view)
                    }
                    return
                }
                self?.router?.openWithOtherApp()
            }
        }
        actionSheetAdapter.addCancelItem(title: BundleI18n.LarkFile.Lark_Legacy_Cancel)
        userResolver.navigator.present(actionSheet, from: self)
    }

    @objc
    func updateFileDisplayStyle(btn: UIButton) {
        btn.isSelected = !btn.isSelected
        Self.localIsGridStyle = btn.isSelected
        self.gridSubject.onNext(btn.isSelected)
        IMTracker.FileManage.Click.changeViewType(extra: self.trackerCommonParams)
    }
    //更改navigation的展示状态；传nil表示保持原状态不更改
    func updateNavigationButton(styleButtonisHidden: Bool, canOpenWithOtherApp: Bool) {
        styleButton.isHidden = styleButtonisHidden
        /// 转发预览页面不做额外处理
        switch self.sourceScene {
        case .forwardPreview:
            return
        default:
            break
        }
        if canOpenWithOtherApp {
            configuration.menuOptions.insert(.openWithOtherApp)
        } else {
            configuration.menuOptions.remove(.openWithOtherApp)
        }
    }
}
