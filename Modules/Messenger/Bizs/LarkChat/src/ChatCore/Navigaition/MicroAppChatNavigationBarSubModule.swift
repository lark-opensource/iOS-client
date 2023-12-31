//
//  MicroAppChatNavigationBarSubModule.swift
//  LarkChat
//
//  Created by zc09v on 2021/10/27.
//

import UIKit
import Foundation
import LarkOpenChat
import LarkOpenIM
import LarkUIKit
import UniverseDesignColor
import LarkMessengerInterface
import LarkInteraction
import EENavigator
import RxSwift
import RxCocoa
import LarkCore
import LarkAccountInterface
import LarkContainer
import LarkBadge
import LarkSDKInterface
import UniverseDesignToast
import LarkFeatureSwitch
import LarkModel
import UniverseDesignIcon
import LarkLocalizations
import LarkFeatureGating
import LKCommonsLogging

final public class MicroAppChatNavigationBarSubModule: BaseNavigationBarItemSubModule {
    private static let logger = Logger.log(MicroAppChatNavigationBarSubModule.self, category: "MicroAppChatNavigationBarSubModule")
    //右侧区域
    public override var items: [ChatNavigationExtendItem] {
        return _rightItems
    }

    private var _rightItems: [ChatNavigationExtendItem] = []
    private var metaModel: ChatNavigationBarMetaModel?
    private var oncallRole: Chatter.ChatExtra.OncallRole = .unknown
    @ScopedInjectedLazy private var chatterAPI: ChatterAPI?
    @ScopedInjectedLazy private var userSettings: UserGeneralSettings?

    private let disposeBag: DisposeBag = DisposeBag()

    public override class func canInitialize(context: ChatNavgationBarContext) -> Bool {
        return true
    }

    public override func canHandle(model: ChatNavigationBarMetaModel) -> Bool {
        return model.chat.chatMode != .threadV2
    }

    public override func handler(model: ChatNavigationBarMetaModel) -> [Module<ChatNavgationBarContext, ChatNavigationBarMetaModel>] {
        return [self]
    }

    public override func createItems(metaModel: ChatNavigationBarMetaModel) {
        if self.context.currentSelectMode() == .multiSelecting {
            self._rightItems = []
            return
        }
        let chat = metaModel.chat
        var items: [ChatNavigationExtendItem] = []
        self.metaModel = metaModel
        self._rightItems = self.buildRigthItems(metaModel: metaModel)
        self.loadCurrentAccountChatChatter(metaModel: metaModel)
    }

    private func buildRigthItems(metaModel: ChatNavigationBarMetaModel) -> [ChatNavigationExtendItem] {
        var items: [ChatNavigationExtendItem] = []
        let disableIPadEntry = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "openplatform.helpdesk.ipad.miniapp.entry"))
        if self.oncallRole == .oncall || self.oncallRole == .oncallHelper {
            Feature.on(.oncallMiniProgram).apply(on: { [weak self] in
                guard let self = self else { return }
                items.append(self.oncallMiniProgramItem)
                Self.logger.info("buildRigthItems oncallMiniProgram on")
            }, off: {}, downgraded: {
                Self.logger.info("buildRigthItems oncallMiniProgram off disableIPadEntry \(disableIPadEntry)")
                if !disableIPadEntry {
                    items.append(self.oncallMiniProgramItem)
                }
            })
        }
        return items
    }

    private lazy var oncallMiniProgramButton: UIButton = {
        let button = UIButton()
        Self.addPointerStyle(button)
        let image = ChatNavigationBarItemTintColor.tintColorFor(image: UDIcon.getIconByKey(.workorderOutlined),
                                                                style: self.context.navigationBarDisplayStyle())
        button.setImage(image, for: .normal)
        button.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.oncallMiniProgramItemClicked()
        }).disposed(by: disposeBag)
        return button
    }()
    lazy private var oncallMiniProgramItem: ChatNavigationExtendItem = {
        return ChatNavigationExtendItem(type: .oncallMiniProgram, view: oncallMiniProgramButton)
    }()

    private func oncallMiniProgramItemClicked() {
        guard let metaModel = self.metaModel, let userSettings else { return }
        let targetVC = self.context.chatVC()
        targetVC.view.endEditing(true)
        // 跳转到指定的小程序
        let appId = userSettings.helpdeskCommon.helpdeskMiniProgramAppId
        // 对startPage进行小程序规定的编码，appendPercentEncodedQuery默认用的urlHostAllowed不满足小程序要求
        var startPage = "pages/mobile/index?chat_id=\(metaModel.chat.id)&locale=\(LanguageManager.currentLanguage.languageCode ?? "")"
        var characterSet = CharacterSet.alphanumerics
        characterSet.insert(charactersIn: "-_.!~*'()")
        startPage = startPage.addingPercentEncoding(withAllowedCharacters: characterSet) ?? ""
        guard let url = URL(string: "sslocal://microapp?app_id=\(appId)&start_page=\(startPage)") else { return }
        navigator.push(url, from: targetVC)
    }

    private func loadCurrentAccountChatChatter(metaModel: ChatNavigationBarMetaModel) {
        let currentAccountChatterId = userResolver.userID
        let chat = metaModel.chat
        // 临时方案：匿名场景先去server获取chatChatter的数据，否则数据上可能会出现不同步的情况
        self.chatterAPI?.fetchChatChatters(ids: [currentAccountChatterId], chatId: chat.id, isForceServer: !chat.anonymousId.isEmpty)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chatters) in
                self?.oncallRole = chatters[currentAccountChatterId]?.chatExtra?.oncallRole ?? .unknown
                Self.logger.info("loadCurrentAccountChatChatter oncallRole \(self?.oncallRole.rawValue)")
                self?._rightItems = self?.buildRigthItems(metaModel: metaModel) ?? []
                self?.context.refresh()
            }).disposed(by: disposeBag)
    }

    public override func modelDidChange(model: ChatNavigationBarMetaModel) {
    }

    public override func barStyleDidChange() {
        if let image = oncallMiniProgramButton.imageView?.image {
            oncallMiniProgramButton.setImage(ChatNavigationBarItemTintColor.tintColorFor(image: image,
                                                                                         style: self.context.navigationBarDisplayStyle()), for: .normal)
        }
    }

    private static func addPointerStyle(_ button: UIButton) {
        if #available(iOS 13.4, *) {
            button.lkPointerStyle = PointerStyle(
                effect: .highlight,
                shape: .roundedSize({ (interaction, _) -> (CGSize, CGFloat) in
                    guard let view = interaction.view else {
                        return (.zero, 0)
                    }
                    return (CGSize(width: view.bounds.width + 20, height: 36), 8)
                }))
        }
    }
}
