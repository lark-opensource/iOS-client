//
//  ChatThemeViewModel.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2022/12/20.
//

import UIKit
import Foundation
import RustPB
import RxCocoa
import RxSwift
import ServerPB
import LarkUIKit
import EENavigator
import ByteWebImage
import LarkContainer
import LarkSDKInterface
import LKCommonsTracker
import LKCommonsLogging
import LarkLocalizations
import LarkAssetsBrowser
import UniverseDesignToast
import UniverseDesignColor
import LarkMessengerInterface

protocol ChatThemeDelegate: AnyObject {
    func actionTakePhoto(_ completion: ((UIImage, UIViewController) -> Void)?, cancel: (() -> Void)?)
}

class ChatThemeViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    fileprivate static let logger = Logger.log(ChatThemeViewModel.self, category: "Module.IM.LarkChatSetting")

    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    @ScopedInjectedLazy private var imageAPI: ImageAPI?

    weak var targetVC: UIViewController?
    weak var delegate: ChatThemeDelegate?
    var reloadData: Driver<Void> { _reloadData.asDriver(onErrorJustReturn: ()) }
    var collectionReloadData: Driver<Void> { _collectionReloadData.asDriver(onErrorJustReturn: ()) }
    var hasMoreData: Bool = false
    // 和服务端约定，默认背景id为1
    private let systemThemeId: Int64 = 1
    private let disposeBag = DisposeBag()
    private var _reloadData = PublishSubject<Void>()
    private var _collectionReloadData = PublishSubject<Void>()
    private(set) var items: [CommonSectionModel] = []
    private let chatId: String
    private(set) var title: String
    private let scene: ChatThemeBody.Scene
    private var themeType: Im_V2_ChatThemeType {
        switch self.scene {
        case .personal:
            return .personalChatTheme
        case .group:
            return .groupChatTheme
        }
    }
    private(set) var themes: [ChatThemeItemCellModel] = []
    // 分页标记
    private var pos: Int64?
    // 是否设置了个人主题
    private var hasPersonalTheme = false

    init(userResolver: UserResolver,
         chatId: String,
         title: String,
         scene: ChatThemeBody.Scene) {
        self.userResolver = userResolver
        self.chatId = chatId
        self.title = title
        self.scene = scene
        initData()
        items = structureItems()
    }

    private func initData() {
        themes.append(getDefaultTheme())
    }

    private func getDefaultTheme() -> ChatThemeItemCellModel {
        // 添加默认数据
        var defaultTheme = ChatThemeItemCellModel()
        defaultTheme.bgImageStyle = .defalut
        defaultTheme.themeId = self.systemThemeId
        defaultTheme.componentScene = .defaultScene
        defaultTheme.desciption = BundleI18n.LarkChatSetting.Lark_IM_WallpaperDefault_Text
        return defaultTheme
    }

    func fetchData() {
        // 首次拉取系统推荐列表
        self.chatAPI?.fetchChatThemeListRequest(chatID: chatId,
                                               themeType: themeType,
                                               limit: nil,
                                               pos: pos)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] res in
                guard let self = self else { return }
                self.pos = res.nextPos
                self.hasMoreData = res.hasMore_p
                self.firstFetchData(res: res)
            }).disposed(by: disposeBag)
    }

    func loadMoreData() {
        // 拉取系统推荐列表 loadmore
        self.chatAPI?.fetchChatThemeListRequest(chatID: chatId,
                                               themeType: themeType,
                                               limit: nil,
                                               pos: pos)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] res in
                guard let self = self else { return }
                self.pos = res.nextPos
                self.hasMoreData = res.hasMore_p
                self.appendLoadMoreData(res: res)
            }).disposed(by: disposeBag)
    }

    // 转换pb到cellvm
    private func transformThemeFrom(chatTheme: ServerPB_Entities_ChatTheme) -> ChatThemeItemCellModel? {
        var theme = ChatThemeItemCellModel()
        switch chatTheme.backgroundEntity.mode {
            // 系统背景
        case .originMode:
            theme.bgImageStyle = .defalut
            // 纯色图背景
        case .colorMode:
            let colorInfo = chatTheme.backgroundEntity.color
            var color: UIColor?
            if colorInfo.hasUdToken, let udColor = UDColor.getValueByBizToken(token: colorInfo.udToken) {
                color = udColor
            } else if colorInfo.hasLightColor, colorInfo.hasDarkColor {
                let rgbColor = UIColor.ud.rgb(colorInfo.lightColor) & UIColor.ud.rgb(colorInfo.darkColor)
                color = rgbColor
            }
            if let color = color {
                theme.bgImageStyle = .color(color)
            }
            // 图片背景
        case .imageMode:
            theme.bgImageStyle = .key(chatTheme.backgroundEntity.imageKey, chatTheme.backgroundEntity.fsunit)
        @unknown default:
            break
        }
        theme.themeId = chatTheme.id
        theme.componentScene = chatTheme.componentScene
        let currentLang = LanguageManager.currentLanguage.localeIdentifier.lowercased()
        theme.desciption = chatTheme.i18NName[currentLang] ?? chatTheme.name
        // 无style无法展示，因此这里过滤掉
        switch theme.bgImageStyle {
        case .unknown:
            return nil
        default:
            return theme
        }
    }

    private func appendLoadMoreData(res: RustPB.Im_V2_GetChatThemeListResponse) {
        // 添加系统推荐主题列表
        let newThemes = getRecommendThemes(res: res)
        // 数据同步
        self.themes.append(contentsOf: newThemes)
        // 刷新数据
        self._collectionReloadData.onNext(())
    }

    // 获取系统推荐主题列表
    private func getRecommendThemes(res: RustPB.Im_V2_GetChatThemeListResponse) -> [ChatThemeItemCellModel] {
        // 获取当前选中的id
        let selectId = getSelectId(res: res)
        let themes = res.themeItems.compactMap { item -> ChatThemeItemCellModel? in
            if let data = res.chatThemes[item.themeID],
               let chatTheme = try? ServerPB_Entities_ChatTheme(serializedData: data),
               var theme = transformThemeFrom(chatTheme: chatTheme) {
                theme.isSelected = selectId == theme.themeId
                return theme
            }
            return nil
        }
        return themes
    }

    // collection item点击
    func collectionItemTapped(model: ChatThemeItemCellModel) {
        var theme = ServerPB_Entities_ChatTheme()
        if let id = model.themeId {
            theme.id = id
        }
        switch model.bgImageStyle {
        case .defalut:
            theme.backgroundEntity.mode = .originMode
        case .color(let color):
            theme.backgroundEntity.mode = .colorMode
        case .image:
            theme.backgroundEntity.mode = .imageMode
        case .key(let key, let unit):
            theme.backgroundEntity.mode = .imageMode
            theme.backgroundEntity.imageKey = key
            theme.backgroundEntity.fsunit = unit
        case .unknown:
            break
        }
        theme.componentScene = model.componentScene
        // 个人背景页下点击群背景实际上是将个人背景置为空
        let isResetPernalTheme = model.scene == .group && self.scene == .personal
        let isResetCurrentTheme = model.isSelected == true
        if let vc = self.targetVC {
            self.jumpToPreviewPage(chatId: self.chatId,
                                   style: model.bgImageStyle,
                                   theme: theme,
                                   isResetPernalTheme: isResetPernalTheme,
                                   isResetCurrentTheme: isResetCurrentTheme,
                                   vc: vc)
        }
    }

    // 获取当前选中的id
    private func getSelectId(res: RustPB.Im_V2_GetChatThemeListResponse) -> Int64? {
        // 获取当前选中的id
        var selectId: Int64?
        switch self.scene {
        case .group:
            if res.hasGroupUsedThemeID {
                selectId = res.groupUsedThemeID
            }
        case .personal:
            if res.hasUserUsedThemeID {
                selectId = res.userUsedThemeID
            }
        }
        return selectId
    }

    private func firstFetchData(res: RustPB.Im_V2_GetChatThemeListResponse) {
        var themes: [ChatThemeItemCellModel] = []
        // 添加默认主题
        var defaultTheme = getDefaultTheme()
        // 默认背景有三种场景： 1. 没选过 2. 个人场景选人 3. 群场景选了
        defaultTheme.isSelected = (!res.hasGroupUsedThemeID && !res.hasUserUsedThemeID) ||
            (self.scene == .personal && res.userUsedThemeID == self.systemThemeId) ||
            (self.scene == .group && res.groupUsedThemeID == self.systemThemeId)
        themes.append(defaultTheme)

        let hasPersonalTheme = res.hasUserUsedThemeID && res.userUsedThemeID != 0
        let hasGroupUsedThemeID = res.hasGroupUsedThemeID && res.groupUsedThemeID != 0
        self.hasPersonalTheme = hasPersonalTheme
        // 添加群设置的主题
        if hasGroupUsedThemeID,
           let data = res.chatThemes[res.groupUsedThemeID],
           let chatTheme = try? ServerPB_Entities_ChatTheme(serializedData: data),
           scene == .personal || chatTheme.themeType == .customizeTheme,
           var theme = transformThemeFrom(chatTheme: chatTheme) {
            theme.desciption = scene == .group ? BundleI18n.LarkChatSetting.Lark_IM_WallpaperCustom_Text : BundleI18n.LarkChatSetting.Lark_IM_GroupWallpaper_Button
            theme.scene = .group
            switch scene {
            case .group:
                theme.isSelected = true
            case .personal:
                theme.isSelected = !res.hasUserUsedThemeID
            }
            themes.append(theme)
        }

        // 添加个人设置的主题
        if hasPersonalTheme,
           let data = res.chatThemes[res.userUsedThemeID],
           let chatTheme = try? ServerPB_Entities_ChatTheme(serializedData: data),
           var theme = transformThemeFrom(chatTheme: chatTheme),
           scene == .personal,
           chatTheme.themeType == .customizeTheme {
            theme.isSelected = true
            theme.scene = .personal
            theme.desciption = BundleI18n.LarkChatSetting.Lark_IM_WallpaperCustom_Text
            themes.append(theme)
        }

        // 添加系统推荐主题列表
        let newThemes = getRecommendThemes(res: res)
        themes.append(contentsOf: newThemes)
        // 数据同步
        self.themes = themes
        // 刷新数据
        self._collectionReloadData.onNext(())
    }

    private func structureItems() -> [CommonSectionModel] {
        let sections: [CommonSectionModel] = [
            configSection()
        ].compactMap { $0 == nil ? $0 : $0?.items.isEmpty == true ? nil : $0 }
        return sections
    }

    private func configSection() -> CommonSectionModel {
        let chatId = self.chatId
        // 从相册选择
        let chatThemeFromAlbumItem = ChatThemeFromAlbumItem(
            type: .chatThemeFromAlbum,
            cellIdentifier: ChatThemeFromAlbumCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_IM_WallpaperChooseFromAlbum_Button,
            arrowSize: CGSize(width: 14, height: 14)) { [weak self] _ in
                guard let `self` = self else { return }
                self.showPhotoLibrary()
        }
        // 拍一张
        let chatThemeShootPhotoItem = ChatThemeShootPhotoItem(
            type: .chatThemeShootPhoto,
            cellIdentifier: ChatThemeShootPhotoCell.lu.reuseIdentifier,
            style: .auto,
            title: BundleI18n.LarkChatSetting.Lark_IM_WallpaperTakePhoto_Button,
            arrowSize: CGSize(width: 14, height: 14)) { [weak self] _ in
                guard let `self` = self else { return }
                guard let vc = self.targetVC else {
                    assertionFailure("lose targetVC")
                    return
                }
                let complete: (UIImage, UIViewController) -> Void = { [weak vc, weak self] (image, picker) in
                    guard let vc = vc else { return }
                    let hud = UDToast.showLoading(on: picker.view)
                    // 明暗检测
                    self?.styleDetect(image: image) { [weak vc, weak picker, weak self] res in
                        guard let vc = vc else { return }
                        switch res {
                        case .success(let style):
                            hud.remove()
                            var theme = ServerPB_Entities_ChatTheme()
                            theme.backgroundEntity.mode = .imageMode
                            switch style {
                            case .light:
                                theme.componentScene = .bright
                            case .dark:
                                theme.componentScene = .dark
                            @unknown default:
                                break
                            }
                            self?.jumpToPreviewPage(chatId: chatId,
                                                    style: .image(image),
                                                    theme: theme,
                                                    picker: picker,
                                                    pickerPage: .shot,
                                                    vc: vc)
                        case .failure(let error):
                            if let window = picker?.view.window {
                                hud.showFailure(with: BundleI18n.LarkChatSetting.Lark_Legacy_ErrorMessageTip, on: window, error: error)
                                picker?.dismiss(animated: true, completion: nil)
                            }
                        }
                    }
                }
                self.delegate?.actionTakePhoto(complete, cancel: nil)
        }
        let section = CommonSectionModel(items: [chatThemeFromAlbumItem,
                                                 chatThemeShootPhotoItem])
        return section
    }
}

extension ChatThemeViewModel {
    /// 从相册选择
    private func showPhotoLibrary() {
        guard let vc = self.targetVC else {
            assertionFailure("lose targetVC")
            return
        }
        let chatId = self.chatId
        let picker = ImagePickerViewController(assetType: .imageOnly(maxCount: 1))
        picker.showSingleSelectAssetGridViewController()
        picker.imagePickerFinishSelect = { (picker, result) in
            guard let asset = result.selectedAssets.first else { return }
            let hud = UDToast.showLoading(on: picker.view)
            guard self.isSupportImageType(asset.imageType) else {
                hud.showTips(with: BundleI18n.LarkChatSetting.Lark_IM_WallpaperWrongFormat_Toast, on: picker.view)
                return
            }
            DispatchQueue.global().async {
                let originSize = asset.originSize
                var targeSize = originSize
                let maxSize = CGSize(width: 1620, height: 2160)
                // 图片降采样
                if originSize.height * originSize.width > maxSize.width * maxSize.height {
                    let ratio = sqrt(maxSize.width * maxSize.height / originSize.height / originSize.width)
                    let targetHeight = floor(ratio * originSize.height)
                    let targetWidth = floor(ratio * originSize.width)
                    targeSize = CGSize(width: targetWidth, height: targetHeight)
                }
                guard let image = asset.imageWithSize(size: targeSize) else {
                    UDToast.showTips(with: BundleI18n.LarkChatSetting.Lark_Legacy_ErrorMessageTip, on: picker.view)
                    return
                }
                // 明暗检测
                self.styleDetect(image: image) { [weak vc, weak picker] res in
                    guard let vc = vc, let picker = picker else { return }
                    switch res {
                    case .success(let style):
                        hud.remove()
                        var theme = ServerPB_Entities_ChatTheme()
                        theme.backgroundEntity.mode = .imageMode
                        switch style {
                        case .light:
                            theme.componentScene = .bright
                        case .dark:
                            theme.componentScene = .dark
                        @unknown default:
                            break
                        }
                        // 跳转到预览页
                        self.jumpToPreviewPage(chatId: chatId,
                                                style: .image(image),
                                                theme: theme,
                                                picker: picker,
                                                pickerPage: .album,
                                                vc: vc)
                    case .failure(let error):
                        hud.showFailure(with: BundleI18n.LarkChatSetting.Lark_Legacy_ErrorMessageTip, on: picker.view, error: error)
                    }
                }
            }
        }
        picker.imagePikcerCancelSelect = { (picker, _) in
            picker.dismiss(animated: true, completion: nil)
        }
        picker.modalPresentationStyle = .fullScreen
        vc.present(picker, animated: true, completion: nil)
    }

    // 图片明暗检测接口
    private func styleDetect(image: UIImage,
                             _ complete: @escaping (Result<Media_V1_ImageStyleDetectResponse.ImageStyle, Error>) -> Void) {
        if let data = image.bt.originData {
            imageAPI?.imageStyleDetectRequest(image: data)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { res in
                    complete(.success(res.style))
                }, onError: { error in
                    complete(.failure(error))
                }).disposed(by: disposeBag)
            return
        }
        complete(.success(.light))
    }

    // 某些类型暂不支持选中
    private func isSupportImageType(_ type: ImageFileFormat) -> Bool {
        let supportTypes: [ImageFileFormat] = [.jpeg, .webp, .png, .heic]
        return supportTypes.contains(type)
    }

    // 跳转到预览页
    private func jumpToPreviewPage(chatId: String,
                                   style: ChatBgImageStyle,
                                   theme: ServerPB_Entities_ChatTheme,
                                   isResetPernalTheme: Bool = false,
                                   isResetCurrentTheme: Bool = false,
                                   picker: UIViewController? = nil,
                                   pickerPage: PickerPage? = nil,
                                   vc: UIViewController) {
        DispatchQueue.main.async { [self] in
            let scope: Im_V2_ChatThemeType
            switch self.scene {
            case .personal:
                scope = .personalChatTheme
            case .group:
                scope = .groupChatTheme
            }
            var previewBody = ChatThemePreviewBody(style: style,
                                                   title: BundleI18n.LarkChatSetting.Lark_IM_WallpaperPreview_Title,
                                                   chatId: chatId,
                                                   theme: theme,
                                                   scope: scope,
                                                   hasPersonalTheme: self.hasPersonalTheme,
                                                   isResetPernalTheme: isResetPernalTheme,
                                                   isResetCurrentTheme: isResetCurrentTheme)
            // 有picker需要处理picker的dissmiss，无picker直接跳转到预览页
            if let picker = picker, let pickerPage = pickerPage {
                let confirmHandler: (() -> Void)? = { [weak vc, userResolver] in
                    if let vc = vc {
                        userResolver.navigator.push(body: ChatControllerByIdBody(chatId: chatId), from: vc)
                    }
                }
                previewBody.confirmHandler = confirmHandler
                switch pickerPage {
                // 相册页面不dismiss
                case .album:
                    userResolver.navigator.present(body: previewBody,
                                             wrap: LkNavigationController.self,
                                             from: picker)
                // 拍照页面直接dismiss掉
                case .shot:
                    picker.dismiss(animated: false) { [weak vc, userResolver] in
                        if let vc = vc {
                            userResolver.navigator.present(body: previewBody,
                                                     wrap: LkNavigationController.self,
                                                     from: vc)
                        }
                    }
                }
            } else {
                let confirmHandler: (() -> Void)? = { [weak vc, userResolver] in
                    if let vc = vc {
                        userResolver.navigator.push(body: ChatControllerByIdBody(chatId: chatId), from: vc)
                    }
                }
                previewBody.confirmHandler = confirmHandler
                userResolver.navigator.present(body: previewBody,
                                         wrap: LkNavigationController.self,
                                         from: vc)
            }
        }
    }
}

enum PickerPage {
    // 相册
    case album
    // 拍照页面
    case shot
}
