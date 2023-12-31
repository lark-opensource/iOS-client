//
//  NewChatChooseViewController.swift
//  LarkForward
//
//  Created by Jiang Chun on 2022/5/7.
//

import UIKit
import Foundation
import LarkSegmentedView
import SnapKit
import LarkUIKit
import LarkMessengerInterface
import LarkSDKInterface
import LarkSnsShare
import LarkSearchCore
import LarkSetting

final class NewChatChooseViewController: NewForwardViewController, ChooseChatViewControllerAbility, JXSegmentedListContainerViewListDelegate {

    public init(provider: ForwardAlertProvider,
                router: NewForwardViewControllerRouter,
                canForwardToTopic: Bool = false,
                inputNavigationItem: UINavigationItem? = nil) {
        var pickerParam = ChatPicker.InitParam()
        pickerParam.includeOuterTenant = provider.needSearchOuterTenant
        pickerParam.includeOuterChat = provider.includeOuterChat
        pickerParam.includeThread = canForwardToTopic
        pickerParam.filter = provider.getFilter()
        pickerParam.scene = provider.pickerTrackScene
        pickerParam.shouldShowRecentForward = provider.shouldShowRecentForward
        pickerParam.targetPreview = provider.targetPreview
        if let infos = (provider.content as? ChatChooseAlertContent)?.preSelectInfos {
            pickerParam.preSelects = infos.map({
                var type = OptionIdentifier.Types.chatter.rawValue
                var id = ""
                switch $0 {
                case .chatID(let chatID):
                    type = OptionIdentifier.Types.chat.rawValue
                    id = chatID
                case .chatterID(let chatterID):
                    type = OptionIdentifier.Types.chatter.rawValue
                    id = chatterID
                default:
                    break
                }
                return OptionIdentifier(type: type, id: id)
            })
        }
        let isRemoteSyncFG = provider.userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "messenger.message.duoduan_sync"))
        if isRemoteSyncFG, let includeConfigs = provider.getForwardItemsIncludeConfigs() {
            //picerkParam传给转发搜索的部分参数，需要由includConfigs映射后再传给searchFactory使用
            pickerParam = ForwardConfigUtils.convertIncludeConfigsToPickerInitParams(includeConfigs: includeConfigs, pickerParam: pickerParam)
            //pickerParam.includeConfigs可直接传给最近访问接口使用
            pickerParam.includeConfigs = includeConfigs
        }
        pickerParam.permissions = provider.permissions ?? [.shareMessageSelectUser]
        super.init(provider: provider, router: router,
                   picker: ChatPicker(resolver: provider.userResolver, frame: .zero, params: pickerParam),
                  inputNavigationItem: inputNavigationItem)
        self.logger.info("\(Self.loggerKeyword) <IOS_RECENT_VISIT> picker params:\(pickerParam.description)")
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var closeHandler: (() -> Void)?
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.ud.bgBase
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
    }

    func listWillDisappear() {
        let currentNavigationItem = inputNavigationItem ?? navigationItem
        currentNavigationItem.rightBarButtonItem = nil
        currentNavigationItem.leftBarButtonItem = leftBarButtonItem
        // 取消选中时失去第一响应，transitionCoordinator 有值是代表是 container 生命周期触发 disappear，不作响应
        if transitionCoordinator == nil {
            view.endEditing(true)
        }
    }

    @objc
    public override func closeBtnTapped() {
        closeHandler?()
        super.closeBtnTapped()
    }

    @objc
    public override func backItemTapped() {
        closeHandler?()
        super.backItemTapped()
    }
}
