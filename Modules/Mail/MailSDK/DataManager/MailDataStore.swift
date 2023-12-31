//
//  MailDataStore.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/9/14.
//

import Foundation
import RxSwift
import LKCommonsLogging
import ThreadSafeDataStructure

var Store: MailDataStore {
    return MailDataStore.shared
}

/// Mail业务内零时的通用上下文信息
class MailSharedContext {
    var markEnterThreadId: String? = nil
}

class MailDataStore {
    fileprivate static let shared = MailDataStore()
    let disposeBag = DisposeBag()

    let settingData: MailSettingManager = MailSettingManager()

    let sharedContext: SafeAtomic<MailSharedContext> = SafeAtomic(MailSharedContext(), with: .recursiveLock)

    static let logger = Logger.log(MailDataStore.self, category: "Module.MailDataStore")

    var fetcher: DataService? {
        return MailDataServiceFactory.commonDataService
    }

    /// MailEditorLoader 迁移到了用户容器内，Store 还未迁移，兼容逻辑
    weak var editorLoader: MailEditorLoader?

    // MARK: life Circle
    init() {
        NotificationCenter.default.rx.notification(Notification.Name.Mail.MAIL_SDK_CLEAN_DATA)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] noti in
                guard let `self` = self else { return }
                self.handleUserChanged()
            }).disposed(by: disposeBag)
    }

    func handleMailAccountChanged() {
        // Clear account related cache
        MailTagDataManager.shared.clear()
        editorLoader?.clear()
        sharedContext.value = MailSharedContext()
        Store.settingData.cleanCache()

        /// 切账号时清除预加载的读信webView
        MailMessageListViewsPool.reset()
    }
    
    func handleUserChanged() {
        Store.settingData.resetClientStatus() // 兼容切租户的场景，重置单例标记位
        self.handleMailAccountChanged()
    }
}
