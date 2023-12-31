//
//  ChatRestrictedModeModuleViewModel.swift
//  LarkChatSetting
//
//  Created by ByteDance on 2023/2/14.
//

import Foundation
import RxSwift
import LarkContainer
import LarkModel
import LarkCore
import LarkSDKInterface
import LarkFeatureGating
import UniverseDesignToast
import LKCommonsLogging
import LarkAccountInterface

class RestrictedModeModuleViewModel: ChatSettingModuleViewModel, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    private static let logger = Logger.log(RestrictedModeModuleViewModel.self, category: "Module.IM.RestrictedModeModuleViewModel")

    private lazy var restrictedModeService: RestrictedModeService? = {
        guard let chatAPI = self.chatAPI else {
            return nil
        }
        return RestrictedModeService(chatAPI: chatAPI, chat: self.chat)
    }()

    var items: [CommonCellItemProtocol] = []

    var reloadObservable: Observable<Void> {
        reloadSubject.asObservable()
    }

    private var chat: Chat {
        return self.chatPushWrapper.chat.value
    }

    private var reloadSubject = PublishSubject<Void>()
    weak var targetVC: UIViewController?
    private let chatPushWrapper: ChatPushWrapper
    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy private var chatAPI: ChatAPI?

    private lazy var enableRestrictedModeSetting: Bool = {
        return self.chat.type == .p2P &&
        !chat.isSingleBot &&
        chat.chatterId != userResolver.userID &&
        !chat.isCrypto &&
        userResolver.fg.staticFeatureGatingValue(with: "im.chat.p2p_restrictedmode")
    }()

    init(resolver: UserResolver,
         chatPushWrapper: ChatPushWrapper,
         targetVC: UIViewController?) {
        self.chatPushWrapper = chatPushWrapper
        self.targetVC = targetVC
        self.userResolver = resolver
    }

    func structItems() {
        guard enableRestrictedModeSetting, self.restrictedModeService?.hasRestrictedMode ?? false else {
            self.items = []
            return
        }
        self.items = [preventMessageLeakItem(),
                      forbiddenMessageCopyForward(),
                      forbiddenDownloadResource(),
                      forbiddenScreenCapture(),
                      messageBurnTime()].compactMap { $0 }
    }

    func startToObserve() {
        if enableRestrictedModeSetting {
            self.restrictedModeService?.switchStatusChange
                .observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
                    self?.structItems()
                    self?.reloadSubject.onNext(())
                }).disposed(by: self.disposeBag)
        }
        self.chatPushWrapper.chat
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                if !(self?.items.isEmpty ?? false) {
                    self?.structItems()
                    self?.reloadSubject.onNext(())
                }
            }).disposed(by: self.disposeBag)
    }

    // 防泄密模式
    private func preventMessageLeakItem() -> GroupSettingItemProtocol? {
        return self.restrictedModeService?.preventMessageLeakItem(chat: self.chat, settingChange: { [weak self] result, status in
            self?.parsingUserOperation(result, logMessage: "preventMessage switch set faild \(status)",
                                       errorHandler: { [weak self] in
                self?.reloadSubject.onNext(())
            })
        })
    }

    // 禁止拷贝转发
    private func forbiddenMessageCopyForward() -> GroupSettingItemProtocol? {
        return self.restrictedModeService?.forbiddenMessageCopyForward(chat: self.chat, settingChange: { [weak self] result, status in
            self?.parsingUserOperation(result,
                                      logMessage: "forbiddenMessageForward set faild \(status)",
                                       errorHandler: { [weak self] in
                self?.reloadSubject.onNext(())
            })
        })
    }

    // 禁止下载
    private func forbiddenDownloadResource() -> GroupSettingItemProtocol? {
        return self.restrictedModeService?.forbiddenDownloadResource(chat: self.chat, settingChange: { [weak self] result, status in
            self?.parsingUserOperation(result,
                                      logMessage: "forbiddenDownloadResource set faild \(status)",
                                       errorHandler: { [weak self] in
                self?.reloadSubject.onNext(())
            })
        })
    }

    // 禁止截图/录屏
    private func forbiddenScreenCapture() -> GroupSettingItemProtocol? {
        return self.restrictedModeService?.forbiddenScreenCapture(chat: self.chat, settingChange: { [weak self] result, status in
            self?.parsingUserOperation(result,
                                      logMessage: "forbiddenDownloadResource set faild \(status)",
                                       errorHandler: { [weak self] in
                self?.reloadSubject.onNext(())
            })
        })
    }

    private func messageBurnTime() -> GroupSettingItemProtocol? {
        return self.restrictedModeService?.burnTime(chat: self.chat, tapHandler: { [weak self] in
            guard let self = self, let vc = self.targetVC, let chatAPI = self.chatAPI, !self.chat.displayInThreadMode else {
                return
            }
            Self.logger.info("chat restrictedModeSetting messageBurnTimeItemClick \(self.chat.id) \(self.chat.restrictedBurnTime.description(closeStatusText: "close"))")
            let selectTimeVC = BurnMessageTimeSelectViewcontroller(selectedTime: self.chat.restrictedBurnTime,
                                                                   chatId: self.chat.id,
                                                                   chatAPI: chatAPI)
            self.userResolver.navigator.push(selectTimeVC, from: vc)
        })
    }

    // rusult parse
    private func parsingUserOperation<T>(
        _ result: Observable<T>,
        logMessage: String,
        succeedMessage: String? = nil,
        errorMessage: String? = nil,
        errorHandler: (() -> Void)? = nil
    ) {
        let chatId = self.chat.id
        result.observeOn(MainScheduler.instance).subscribe(onNext: { _ in
            if let succeedMessage = succeedMessage, let view = self.targetVC?.viewIfLoaded {
                UDToast.showSuccess(with: succeedMessage, on: view)
            }
        }, onError: { [weak self] (error) in
            Self.logger.error(
                logMessage,
                additionalData: ["chatId": chatId],
                error: error)
            errorHandler?()
            guard let view = self?.targetVC?.viewIfLoaded else { return }
            if let errorMessage = errorMessage {
                UDToast.showFailure(with: errorMessage, on: view, error: error)
            } else {
                UDToast.showFailureIfNeeded(on: view, error: error)
            }
        }).disposed(by: disposeBag)
    }
}
