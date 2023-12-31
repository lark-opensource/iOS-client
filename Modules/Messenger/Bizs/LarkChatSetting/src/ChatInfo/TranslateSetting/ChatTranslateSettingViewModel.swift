//
//  ChatTranslateSettingViewModel.swift
//  LarkChatSetting
//
//  Created by bytedance on 3/23/22.
//

import UIKit
import Foundation
import EENavigator
import ServerPB
import LarkRustClient
import LarkSDKInterface
import RxSwift
import RxCocoa
import LKCommonsLogging
import LarkModel
import UniverseDesignToast
import LarkCore
import LarkUIKit
import LKCommonsTracker
import LarkMessengerInterface
import LarkFeatureGating
import LarkAccountInterface
import LarkContainer
import LarkOpenChat
import LarkKAFeatureSwitch

final class ChatTranslateSettingViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    fileprivate static let logger = Logger.log(ChatTranslateSettingViewModel.self, category: "Module.IM.LarkChatSetting")
    private var chat: Chat
    private var pushChat: Observable<Chat>
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    private(set) var items = [ChatSettingClickableSectionModel]()
    private let disposeBag = DisposeBag()
    weak var targetVC: UIViewController?

    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?

    lazy var paragraphStyle: NSMutableParagraphStyle = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = 20
        paragraphStyle.minimumLineHeight = 20
        paragraphStyle.lineSpacing = 0
        return paragraphStyle
    }()
    lazy var arrtibutesForNormalText: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                                       .paragraphStyle: paragraphStyle,
                                                                       .foregroundColor: UIColor.ud.textPlaceholder]
    lazy var arrtibutesForLink: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                                 .paragraphStyle: paragraphStyle,
                                                                 .foregroundColor: UIColor.ud.textLinkNormal]
    var clickDescriptionOfChatInfoAutoTranslateModelURL = "clickDescriptionOfChatInfoAutoTranslateModel"

    var reloadData: Driver<Void> { _reloadData.asDriver(onErrorJustReturn: ()) }
    private var _reloadData = PublishSubject<Void>()

    init(resolver: UserResolver, chat: Chat, pushChat: Observable<Chat>) {
        self.chat = chat
        self.pushChat = pushChat
        self.userResolver = resolver
        items = structureItems()

        pushChat.filter { [weak self] in
            return $0.id == self?.chat.id
        }
        .subscribe(onNext: { [weak self] chat in
            self?.handleNewChatModel(chat: chat)
        }).disposed(by: disposeBag)
    }

    private func handleNewChatModel(chat: Chat) {
        if chat.typingTranslateSetting.isOpen != self.chat.typingTranslateSetting.isOpen ||
            chat.typingTranslateSetting.targetLanguage != self.chat.typingTranslateSetting.targetLanguage ||
            chat.isAutoTranslate != self.chat.isAutoTranslate {
            self.chat = chat
            items = structureItems()
            _reloadData.onNext(())
        }
    }

    private func structureItems() -> [ChatSettingClickableSectionModel] {
        let sections: [ChatSettingClickableSectionModel] = [
            autoTranslateSection(),
            realTimeTranslateSection()
        ].compactMap { $0 == nil ? $0 : $0?.items.isEmpty == true ? nil : $0 }
        return sections
    }

    private func autoTranslateSection() -> ChatSettingClickableSectionModel? {
        guard userResolver.userID != chat.id, userResolver.fg.staticFeatureGatingValue(with: .init(switch: .suiteTranslation)) else {
            return nil
        }
        let chatInfoAutoTranslateItem = ChatInfoAutoTranslateModel(
                type: .autoTranslate,
                cellIdentifier: ChatInfoAutoTranslateCell.lu.reuseIdentifier,
                style: .auto,
                title: BundleI18n.LarkChatSetting.Lark_Legacy_AutoTranslation,
                descriptionText: "",
                status: self.chat.isAutoTranslate
            ) { [weak self] (_, isOn) in
                guard let self = self else { return }
                NewChatSettingTracker.imChatSettingAutoTranslationSwitch(isOn: isOn, isAdmin: self.chat.isGroupAdmin ?? false, chat: self.chat)
                self.toAutoTranslateControlDidChanged(state: isOn)
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = 20
        paragraphStyle.minimumLineHeight = 20
        paragraphStyle.lineSpacing = 0
        var description = NSMutableAttributedString(string: BundleI18n.LarkChatSetting.Lark_IM_AutoTranslation_TranslateAllMessagesReceived_EditSettings_Desc + " ",
                                                    attributes: arrtibutesForNormalText)
        var clickableTextArrtibutes = arrtibutesForLink
        clickableTextArrtibutes[.link] = self.clickDescriptionOfChatInfoAutoTranslateModelURL
        var clickableText = NSAttributedString(string: BundleI18n.LarkChatSetting.Lark_IM_AutoTranslation_TranslateAllMessagesReceived_EditSettings_Button,
                                                      attributes: clickableTextArrtibutes)
        description.append(clickableText)
        return ChatSettingClickableSectionModel(description: description, items: [chatInfoAutoTranslateItem])
    }
    private func realTimeTranslateSection() -> ChatSettingClickableSectionModel? {
        guard userResolver.fg.staticFeatureGatingValue(with: "im.chat.manual_open_translate") else { return nil }
        var items = [ChatSettingCellVMProtocol]()
        let realTimeTranslateItem = ChatInfoAutoTranslateModel(
                type: .autoTranslate,
                cellIdentifier: ChatInfoAutoTranslateCell.lu.reuseIdentifier,
                style: .auto,
                title: BundleI18n.LarkChatSetting.Lark_IM_TranslationAsYouTypeSettings_Title,
                descriptionText: "",
                status: self.chat.typingTranslateSetting.isOpen
            ) { [weak self] (_, isOn) in
                guard let self = self else { return }
                NewChatSettingTracker.trackIsTypingTranslation(chat: self.chat, turnOn: isOn, translationLanguage: self.chat.typingTranslateSetting.targetLanguage)
                self.realTimeTranslateControlDidChanged(state: isOn)
        }
        items.append(realTimeTranslateItem)
        let languageKey = chat.typingTranslateSetting.targetLanguage
        let languageName = self.userGeneralSettings?.translateLanguageSetting.getTrgLanguageI18nStringFor(languageKey) ?? ""
        if chat.typingTranslateSetting.isOpen {
            let targetLanguageItem = ChatInfoNickNameModel(
                type: .nickName,
                cellIdentifier: ChatInfoNickNameCell.lu.reuseIdentifier,
                style: .auto,
                title:
                    BundleI18n.LarkChatSetting.Lark_IM_TranslationAsYouTypeSettings_TranslateInto_Title,
                name: languageName
            ) { [weak self] _ in
                guard let self = self,
                      let targetVC = self.targetVC else { return }
                var body = LanguagePickerBody(chatId: self.chat.id, currentTargetLanguage: self.chat.typingTranslateSetting.targetLanguage)
                body.targetLanguageChangeCallBack = { [weak self] (chat) in
                    guard let self = self else { return }
                    NewChatSettingTracker.trackIsTypingTranslation(chat: self.chat, turnOn: true, translationLanguage: chat.typingTranslateSetting.targetLanguage)
                    self.chat = chat
                    self.items = self.structureItems()
                    self._reloadData.onNext(())
                }
                body.closeRealTimeTranslateCallBack = { [weak self] (chat) in
                    guard let self = self else { return }
                    self.chat = chat
                    self.items = self.structureItems()
                    self._reloadData.onNext(())
                }
                self.navigator.present(body: body, from: targetVC)
            }
            items.append(targetLanguageItem)
        }
        let description = NSAttributedString(string: BundleI18n.LarkChatSetting.Lark_IM_TranslationAsYouTypeSettings_TranslateContentsAsYouType_Desc, attributes: arrtibutesForNormalText)
        return ChatSettingClickableSectionModel(description: description, items: items)
    }

    // MARK: - 自动翻译
    private func toAutoTranslateControlDidChanged(state: Bool) {
        let chatId = chat.id
        self.chatAPI?.updateChat(chatId: chatId, isAutoTranslate: state)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chat) in
                guard let self = self else { return }
                self.chat = chat
                self.items = self.structureItems()
            }, onError: { [weak self](error) in
                guard let self = self else { return }
                /// 把服务器返回的错误显示出来
                let showMessage = BundleI18n.LarkChatSetting.Lark_Setting_PrivacySetupFailed
                if let view = self.targetVC?.viewIfLoaded {
                    UDToast.showFailure(with: showMessage, on: view, error: error)
                }

                Self.logger.error("change toAutoTranslateControl failed", additionalData: ["chatId": self.chat.id], error: error)
                self._reloadData.onNext(())
            }).disposed(by: self.disposeBag)
    }

    // MARK: - 边写边译
    private func realTimeTranslateControlDidChanged(state: Bool) {
        let chatId = chat.id
        self.chatAPI?.updateChat(chatId: chatId, isRealTimeTranslate: state, realTimeTranslateLanguage: chat.typingTranslateSetting.targetLanguage)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chat) in
                guard let self = self else { return }
                self.chat = chat
                self.items = self.structureItems()
                self._reloadData.onNext(())
            }, onError: { [weak self](error) in
                guard let self = self else { return }
                /// 把服务器返回的错误显示出来
                let showMessage = BundleI18n.LarkChatSetting.Lark_Setting_PrivacySetupFailed
                if let view = self.targetVC?.viewIfLoaded {
                    UDToast.showFailure(with: showMessage, on: view, error: error)
                }

                Self.logger.error("change realTimeTranslateControl failed", additionalData: ["chatId": self.chat.id], error: error)
                self._reloadData.onNext(())
            }).disposed(by: self.disposeBag)
    }
}

//文本中包含可点击内容，无法直接复用CommonSectionModel
struct ChatSettingClickableSectionModel {

    var description: NSAttributedString?
    var items: [ChatSettingCellVMProtocol]

    init(description: NSAttributedString? = nil,
                items: [ChatSettingCellVMProtocol] = []) {
        self.description = description
        self.items = items
    }

    @inline(__always)
    var numberOfRows: Int { items.count }

    @inline(__always)
    func item(at row: Int) -> ChatSettingCellVMProtocol? {
        _fastPath(row < numberOfRows) ? items[row] : nil
    }
}

extension Array where Iterator.Element == ChatSettingClickableSectionModel {
    @inline(__always)
    var numberOfSections: Int { count }

    @inline(__always)
    func section(at index: Int) -> ChatSettingClickableSectionModel? {
        _fastPath(index < numberOfSections) ? self[index] : nil
    }

    @inline(__always)
    func sectionFooter(at index: Int) -> NSAttributedString? {
        section(at: index)?.description
    }

    @inline(__always)
    func numberOfRows(in section: Int) -> Int {
        self.section(at: section)?.numberOfRows ?? 0
    }

    func item(at indexPath: IndexPath) -> GroupSettingItemProtocol? {
        if let section = self.section(at: indexPath.section), var item = section.item(at: indexPath.row) {
            item.style = style(for: item, at: indexPath.row, total: section.numberOfRows)
            return item
        }
        return nil
    }

    func style(for item: ChatSettingCellVMProtocol, at index: Int, total: Int) -> ChatSettingSeparaterStyle {
        if _fastPath(item.style == .auto) {
            if _slowPath(index == total - 1) {
                return .none
            }
            return .half
        } else {
            return item.style
        }
    }
}
