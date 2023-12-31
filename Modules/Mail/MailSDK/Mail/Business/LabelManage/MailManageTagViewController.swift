//
//  MailManageTagViewController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/11/9.
//

import Foundation
import UIKit
import EENavigator
import LarkUIKit
import UniverseDesignTabs

protocol MailManageTagDelegate: AnyObject {
    func createTagHandler(_ index: Int)
}

protocol MailManageTagNavigateDelegate: AnyObject {
    func pushVC(_ vc: MailBaseViewController)
}

class MailManageTagViewController: MailBaseViewController {
    enum Scene {
        case editLabel
        case editFolder
        case setting
    }

    var scene: Scene = .editFolder
    weak var delegate: MailManageTagDelegate?
    private lazy var titleTabsView: UDTabsTitleView = {
        let tabsView = UDTabsTitleView()
        tabsView.titles = Store.settingData.mailClient ? [BundleI18n.MailSDK.Mail_Folder_FolderTab]
            : [BundleI18n.MailSDK.Mail_Folder_FolderTab, BundleI18n.MailSDK.Mail_Folder_ManageLabelMobile]
        let config = tabsView.getConfig()
        config.layoutStyle = .average
        config.itemSpacing = 0
        tabsView.setConfig(config: config)
        /// 配置指示器
        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2
        indicator.indicatorCornerRadius = 0
        tabsView.indicators = [indicator]
        tabsView.delegate = self
        tabsView.backgroundColor = ModelViewHelper.listColor()
        return tabsView
    }()
    private lazy var tabsContainer: UDTabsListContainerView = {
        return UDTabsListContainerView(dataSource: self)
    }()

    var items = [MailBaseViewController & UDTabsListContainerViewDelegate]()
    var firstLoad = true
    
    let accountContext: MailAccountContext

    override var navigationBarTintColor: UIColor {
        return ModelViewHelper.navColor()
    }
    
    init(accountContext: MailAccountContext) {
        self.accountContext = accountContext
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.shouldRecordMailState = false
        setupViews()
    }

    func setupViews() {
        title = BundleI18n.MailSDK.Mail_Manage_FolderManageMobile
        view.backgroundColor = ModelViewHelper.listColor()
        // 适配iOS 15 bartintcolor颜色不生效问题
        updateNavAppearanceIfNeeded()
        // tabs
        titleTabsView.listContainer = tabsContainer

        let folderVC = MailManageFolderController(accountContext: accountContext)
        folderVC.delegate = self
        items.append(folderVC)

        if !Store.settingData.mailClient {
            let labelVC = MailManageLabelsController(accountContext: accountContext)
            labelVC.delegate = self
            items.append(labelVC)
        }

        //setupCreateBtnOnNav()
        if !Display.pad {
            layoutFilp()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if firstLoad, Display.pad {
            layoutFilp()
            firstLoad = false
        }
    }

    func layoutFilp() {
        let naviHeight = navigationController?.navigationBar.frame.height ?? 0 + UIApplication.shared.statusBarFrame.height
        let safeAreaMargin = Display.bottomSafeAreaHeight + Display.topSafeAreaHeight
        let offset = Display.pad ? 0 : safeAreaMargin + naviHeight
        view.addSubview(titleTabsView)
        view.addSubview(tabsContainer)

        let sep = UIView()
        sep.backgroundColor = UIColor.ud.lineDividerDefault
        view.addSubview(sep)

        titleTabsView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.width.equalToSuperview()
            $0.height.equalTo(40)
            $0.top.equalToSuperview().offset(0)
        }
        sep.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalTo(titleTabsView.snp.bottom)
            $0.height.equalTo(0.5)
        }

        tabsContainer.snp.makeConstraints {
            $0.top.equalTo(titleTabsView.snp.bottom)
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }
}

extension MailManageTagViewController: MailManageTagNavigateDelegate {
    func pushVC(_ vc: MailBaseViewController) {
        navigator?.push(vc, from: self)
    }
}

extension MailManageTagViewController: MailCreateLabelTagDelegate {
    /// if create a new label, refresh the list, and selected new label
    func didCreateNewLabel(labelId: String) {
        // do nothing

    }
    func didCreateLabelAndDismiss(_ toast: String, create: Bool) {
        MailRoundedHUD.showSuccess(with: toast, on: self.view)
    }
}

extension MailManageTagViewController: MailCreateFolderTagDelegate {
    func didEditFolderAndDismiss() {
        
    }

    func didCreateNewFolder(labelId: String) {

    }

    func didEditFolder(labelId: String) {}

    func didCreateFolderAndDismiss(_ toast: String, create: Bool, moveTo: Bool, folder: MailFilterLabelCellModel) {
        MailRoundedHUD.showSuccess(with: toast, on: self.view)
    }
}
