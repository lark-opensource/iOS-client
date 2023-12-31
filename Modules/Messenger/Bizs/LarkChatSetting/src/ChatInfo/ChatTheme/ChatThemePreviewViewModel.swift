//
//  ChatThemePreviewViewModel.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2022/12/22.
//

import Foundation
import UIKit
import RustPB
import RxCocoa
import RxSwift
import ServerPB
import LarkModel
import LarkStorage
import EENavigator
import ByteWebImage
import LarkContainer
import LarkMessageBase
import LarkMessageCore
import LarkSDKInterface
import LKCommonsTracker
import LKCommonsLogging
import LarkAssetsBrowser
import UniverseDesignTheme
import UniverseDesignToast
import LarkAccountInterface
import LarkMessengerInterface
import LarkSetting

class ChatThemePreviewViewModel: UserResolverWrapper {
    fileprivate static let logger = Logger.log(ChatThemePreviewViewModel.self, category: "Module.IM.LarkChatSetting")

    // 外部服务
    private let chatterManager: ChatterManagerProtocol
    private let chatAPI: ChatAPI
    private let imageAPI: ImageAPI
    private let resourceAPI: ResourceAPI

    let pushCenter: PushNotificationCenter
    var reloadData: Driver<Void> { _reloadData.asDriver(onErrorJustReturn: ()) }
    var currentChatter: Chatter {
        chatterManager.currentChatter
    }
    var scene: ChatThemeScene {
        theme.componentScene
    }
    weak var targetVC: UIViewController?
    private let disposeBag = DisposeBag()
    private var _reloadData = PublishSubject<Void>()
    private(set) var items: [ChatThemePreviewItem] = []
    private(set) var title: String
    private let confirmHandler: (() -> Void)?
    private let cancelHandler: (() -> Void)?
    private(set) var config: ChatThemePreviewConfig
    private let user: User

    private var isLarkDarkMode: Bool {
        if #available(iOS 13.0, *) {
            return UDThemeManager.getRealUserInterfaceStyle() == .dark
        } else {
            return false
        }
    }
    private let chatId: String
    private var theme: ServerPB_Entities_ChatTheme
    private(set) var scope: Im_V2_ChatThemeType
    // 是否有个人设置的背景
    private let hasPersonalTheme: Bool
    // 是否取消个人背景
    private let isResetPernalTheme: Bool
    // 是否重设当前背景
    private let isResetCurrentTheme: Bool

    let userResolver: UserResolver

    init(userResolver: UserResolver,
         title: String,
         chatId: String,
         theme: ServerPB_Entities_ChatTheme,
         scope: Im_V2_ChatThemeType,
         hasPersonalTheme: Bool,
         isResetPernalTheme: Bool,
         isResetCurrentTheme: Bool,
         confirmHandler: (() -> Void)?,
         cancelHandler: (() -> Void)?
    ) throws {
        self.userResolver = userResolver
        self.pushCenter = try userResolver.userPushCenter
        self.chatterManager = try userResolver.resolve(assert: ChatterManagerProtocol.self)
        self.chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        self.imageAPI = try userResolver.resolve(assert: ImageAPI.self)
        self.resourceAPI = try userResolver.resolve(assert: ResourceAPI.self)
        self.user = try userResolver.resolve(assert: PassportUserService.self).user

        self.title = title
        self.theme = theme
        self.chatId = chatId
        self.scope = scope
        self.hasPersonalTheme = hasPersonalTheme
        self.isResetPernalTheme = isResetPernalTheme
        self.isResetCurrentTheme = isResetCurrentTheme
        self.confirmHandler = confirmHandler
        self.cancelHandler = cancelHandler
        self.config = ChatThemePreviewConfig(fgService: try? userResolver.resolve(assert: FeatureGatingService.self))
        items = structureItems()
        self.config.isSelectDarkMode = isLarkDarkMode
        self.config.isDarkMode = self.config.isSelectDarkMode || self.isLarkDarkMode
    }

    func cancel() {
        self.cancelHandler?()
    }

    // 确认按钮事件
    func confrim(style: ChatBgImageStyle) {
        guard let vc = targetVC else { return }
        let toast = UDToast.showDefaultLoading(on: vc.view)
        // 重设当前背景不走网络请求，直接返回
        if isResetCurrentTheme {
            toast.remove()
            // 先dismiss当前页面再跳转回chat页面（通过confirmHandler）
            vc.dismiss(animated: true) { [weak self] in
                self?.confirmHandler?()
            }
            return
        }
        // 是否重设背景
        let isReset = self.isResetPernalTheme
        let preProcessObservable: Observable<Void>
        if case .image(let img) = style, isReset == false {
            let data = img.bt.originData ?? Data()
            preProcessObservable = imageAPI.uploadImageV2(data: data, imageType: .chatThemeImage).map { [weak self] key in
                self?.theme.backgroundEntity.imageKey = key
            }
        } else {
            preProcessObservable = .just(())
        }
        preProcessObservable
            .flatMap { [weak self] _ -> Observable<Im_V2_SetChatThemeResponse> in
                guard let self = self, let themeData = try? self.theme.serializedData() else { return .empty() }
                return self.chatAPI.updateChatTheme(chatId: self.chatId,
                                                    themeId: self.theme.id,
                                                    theme: themeData,
                                                    isReset: isReset,
                                                    scope: self.scope)
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak vc] res in
                guard let self = self, let vc = vc else { return }
                // 本地push ChatTheme刷新chat页面的主题
                switch self.scope {
                case .personalChatTheme:
                    self.pushCenter.post(ChatTheme(chatId: self.chatId, style: style, scene: self.scene))
                case .groupChatTheme:
                    // 没有个人设置的背景去更新当前群背景
                    if self.hasPersonalTheme == false {
                        self.pushCenter.post(ChatTheme(chatId: self.chatId, style: style, scene: self.scene))
                    }
                case .unknownChatThemeType:
                    break
                @unknown default:
                    break
                }
                // 预加载图
                switch style {
                case .image:
                    // 解析res的theme
                    if let themeID = res.entity.chats[self.chatId]?.themeID,
                       let themeData = res.entity.chatThemes[themeID],
                       let theme = try? ServerPB_Entities_ChatTheme(serializedData: themeData) {
                        // 异步加载图片
                        let img = ByteImageView()
                        var pass = ImagePassThrough()
                        pass.key = theme.backgroundEntity.imageKey
                        pass.fsUnit = theme.backgroundEntity.fsunit
                        img.bt.setLarkImage(with: .default(key: theme.backgroundEntity.imageKey), passThrough: pass)
                    }
                default:
                    break
                }
                // 先dismiss当前页面再跳转回chat页面（通过confirmHandler）
                vc.dismiss(animated: true) { [weak self] in
                    self?.confirmHandler?()
                }
            }, onError: { [weak self, weak vc] (error) in
                if let window = vc?.view.window {
                    vc?.dismiss(animated: false)
                    toast.showFailure(with: BundleI18n.LarkChatSetting.Lark_Legacy_ErrorMessageTip, on: window, error: error)
                }
                self?.cancelHandler?()
            }).disposed(by: disposeBag)
    }

    // darkmode变化
    func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.config.isSelectDarkMode = isLarkDarkMode
        items = structureItems()
        self._reloadData.onNext(())
    }

    func toogleIsSelectDarkMode() {
        config.isSelectDarkMode.toggle()
        items = structureItems()
        self._reloadData.onNext(())
    }

    private func structureItems() -> [ChatThemePreviewItem] {
        let tipItem = ChatThemePreviewTipItem(
            title: BundleI18n.LarkChatSetting.Lark_IM_WallpaperPreviewJustNow_Text,
            config: config,
            componentTheme: ChatComponentThemeManager.getComponentTheme(scene: theme.componentScene))
        let firstMsgItemComponentTheme = ChatComponentThemeManager.getComponentTheme(scene: theme.componentScene, isMe: false)
        let firstMsgItem = ChatThemePreviewMessageItem(
            cellIdentifier: ChatThemePreviewMessageCell.lu.reuseIdentifier,
            content: BundleI18n.LarkChatSetting.Lark_IM_WallpaperPreviewWhenWillItStart_Text,
            nameAndDesc: "\(BundleI18n.LarkChatSetting.Lark_IM_WallpaperPreviewMeiLi_Text)｜\(BundleI18n.LarkChatSetting.Lark_IM_WallpaperPreviewAimHigh_Text)",
            isFromMe: false,
            image: Resources.fakeUser5,
            userId: user.userID,
            config: config,
            componentTheme: firstMsgItemComponentTheme)
        let line = currentChatter.description_p.text.isEmpty ? "" : "｜"
        let secondMsgItemComponentTheme = ChatComponentThemeManager.getComponentTheme(scene: theme.componentScene, isMe: true)
        let cellIdentifier = config.supportLeftRight ?
            ChatThemePreviewMessageReverseCell.lu.reuseIdentifier :
            ChatThemePreviewMessageCell.lu.reuseIdentifier
        let secondMsgItem = ChatThemePreviewMessageItem(
            cellIdentifier: cellIdentifier,
            content: BundleI18n.LarkChatSetting.Lark_IM_WallpaperPreviewWithinThisWeek_Text,
            nameAndDesc: "\(user.name)\(line)\(currentChatter.description_p.text)",
            isFromMe: true,
            avatarKey: user.avatarKey,
            userId: user.userID,
            config: config,
            componentTheme: secondMsgItemComponentTheme)
        let items: [ChatThemePreviewItem] = [tipItem, firstMsgItem, secondMsgItem]
        return items
    }
}

struct ChatThemePreviewConfig {
    var fgService: FeatureGatingService?
    init(fgService: FeatureGatingService?) {
        self.fgService = fgService
    }

    var supportLeftRight: Bool { KVPublic.Setting.chatSupportAvatarLeftRight(fgService: fgService).value() }

    var isDarkMode = false
    var isSelectDarkMode: Bool = false {
        didSet {
            self.isDarkMode = isSelectDarkMode
        }
    }
}

struct ChatThemePreviewColorManger {
    static func getColor(color: UIColor,
                         config: ChatThemePreviewConfig) -> UIColor {
        let isLight = !config.isDarkMode
        return isLight ? color.alwaysLight : color.alwaysDark
    }
}
