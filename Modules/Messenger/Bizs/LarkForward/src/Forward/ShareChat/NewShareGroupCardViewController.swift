//
//  NewShareGroupCardViewController.swift
//  LarkForward
//
//  Created by Jiang Chun on 2022/4/25.
//

import UIKit
import Foundation
import LarkSegmentedView
import SnapKit
import LarkUIKit
import LarkMessengerInterface
import LarkSearchCore
import LarkSetting

final class NewShareGroupCardViewController: NewForwardViewController, JXSegmentedListContainerViewListDelegate {
    var listWillAppearHandler: () -> Void
    public init(provider: ForwardAlertProvider,
                router: NewForwardViewControllerRouter,
                canForwardToTopic: Bool = false,
                inputNavigationItem: UINavigationItem? = nil,
                listWillAppearHandler: @escaping () -> Void) {
        self.listWillAppearHandler = listWillAppearHandler
        var pickerParam = ChatPicker.InitParam()
        pickerParam.includeOuterTenant = provider.needSearchOuterTenant
        pickerParam.includeThread = canForwardToTopic
        pickerParam.filter = provider.getFilter()
        pickerParam.scene = provider.pickerTrackScene
        pickerParam.targetPreview = provider.userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.target_preview"))
        let isRemoteSyncFG = provider.userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "messenger.message.duoduan_sync"))
        if isRemoteSyncFG, let includeConfigs = provider.getForwardItemsIncludeConfigs() {
            //picerkParam传给转发搜索的部分参数，需要由includConfigs映射后再传给searchFactory使用
            pickerParam = ForwardConfigUtils.convertIncludeConfigsToPickerInitParams(includeConfigs: includeConfigs, pickerParam: pickerParam)
            //pickerParam.includeConfigs可直接传给最近访问接口使用
            pickerParam.includeConfigs = includeConfigs
        }
        pickerParam.permissions = provider.permissions ?? [.shareMessageSelectUser]
        let picker: ChatPicker = ChatPicker(resolver: provider.userResolver, frame: .zero, params: pickerParam)
        picker.filterParameters = provider.filterParameters
        super.init(provider: provider, router: router,
                   picker: picker,
                  inputNavigationItem: inputNavigationItem)
        self.logger.info("\(Self.loggerKeyword) <IOS_RECENT_VISIT> picker params:\(pickerParam.description)")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.ud.bgBody
    }

    func updateNavigationItem() {
        let currentNavigationItem = inputNavigationItem ?? self.navigationItem
        if isMultiSelectMode {
            currentNavigationItem.leftBarButtonItem = self.cancelItem
            currentNavigationItem.rightBarButtonItem = UIBarButtonItem(customView: sureButton)
        } else {
            self.addCancelItem()
            currentNavigationItem.rightBarButtonItem = self.multiSelectItem
        }
    }

    // MARK: JXSegmentedListContainerViewListDelegate
    func listView() -> UIView {
        return view
    }

    func listWillAppear() {
        updateNavigationItem()
        self.listWillAppearHandler()
    }

    func listWillDisappear() {
        let currentNavigationItem = inputNavigationItem ?? self.navigationItem
        currentNavigationItem.rightBarButtonItem = nil
        currentNavigationItem.leftBarButtonItem = self.addCancelItem()
        /// 取消选中时失去第一响应，transitionCoordinator 有值是代表是 container 生命周期触发 disappear，不作响应
        if self.transitionCoordinator == nil {
            self.view.endEditing(true)
        }
    }
}
