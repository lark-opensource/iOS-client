//
//  MailCommonDataMananger.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/11/23.
//

import Foundation
import RxSwift

class MailCommonDataMananger {
    static let shared = MailCommonDataMananger()
    private let disposeBag = DisposeBag()

    // observable
    @DataManagerValue<MailMigrationChange> var migrationChange

    @DataManagerValue<ShareMailPermissionChange> var sharePermissionChange

    @DataManagerValue<MailUnreadThreadCountChange> var unreadCountChange

    @DataManagerValue<MailBatchEndChange> var batchEndChange

    @DataManagerValue<MailBatchResultChange> var batchResultChange

    @DataManagerValue<MailSyncEventChange> var syncEventChange

    @DataManagerValue<MailDownloadPushChange> var downloadPushChange

    @DataManagerValue<MailUploadPushChange> var uploadPushChange

    @DataManagerValue<MailMixSearchPushChange> var mixSearchPushChange
    
    @DataManagerValue<MailAddressUpdatePushChange> var mailAddressUpdatePush

    @DataManagerValue<MailPreloadProgressPushChange> var mailPreloadProgressChange
    
    @DataManagerValue<MailAITaskStatusPushChange> var mailAITaskStatusPush
    
    @DataManagerValue<MailDownloadProgressPushChange> var downloadProgressChange
    
    @DataManagerValue<MailCleanCachePushChange> var cleanCachePushChange

    init() {
        bindPush()
    }
}

extension MailCommonDataMananger {
    func bindPush() {
        PushDispatcher
            .shared
            .migrationChange
            .subscribe(onNext: { [weak self] (change) in
                switch change {
                case .migrationChange(let change):
                    self?.handleMigrationChange(change: change)
                }
            }).disposed(by: disposeBag)

        PushDispatcher
            .shared
            .mailChange
            .subscribe(onNext: { [weak self] (change) in
                switch change {
                case .sharePermissonChange(let persmisson):
                    self?.handlePermissionChange(change: persmisson)
                default: break
                }
            }).disposed(by: disposeBag)

        PushDispatcher
            .shared
            .unreadCountChange
            .subscribe(onNext: { [weak self] (change) in
                switch change {
                case .unreadThreadCount(let unread):
                    self?.handleUnreadThreadCountChange(change: unread)
                }
            }).disposed(by: disposeBag)

        PushDispatcher
            .shared
            .batchChange
            .subscribe(onNext: { [weak self] (change) in
                switch change {
                case .batchEndChange(let batch):
                    self?.$batchEndChange.accept(batch)
                case .batchResultChange(let batch):
                    self?.$batchResultChange.accept(batch)
                }
            }).disposed(by: disposeBag)

        PushDispatcher
            .shared
            .syncEventChange
            .subscribe(onNext: { [weak self] change in
                switch change {
                case .syncEventChange(let value):
                    self?.$syncEventChange.accept(value)
                }
        }).disposed(by: disposeBag)

        PushDispatcher
            .shared
            .downloadPushChange
            .subscribe(onNext: { [weak self] change in
                switch change {
                case .downloadPushChange(let value):
                    self?.$downloadPushChange.accept(value)
                }
        }).disposed(by: disposeBag)

        PushDispatcher
            .shared
            .uploadPushChange
            .subscribe(onNext: { [weak self] change in
                switch change {
                case .uploadPushChange(let value):
                    self?.$uploadPushChange.accept(value)
                }
        }).disposed(by: disposeBag)

        PushDispatcher
            .shared
            .mixSearchPushChange
            .subscribe(onNext: { [weak self] change in
                switch change {
                case .mixSearchPushChange(let value):
                    self?.$mixSearchPushChange.accept(value)
                }
        }).disposed(by: disposeBag)

        PushDispatcher
            .shared
            .mailPreloadProgressChange
            .subscribe(onNext: { [weak self] change in
                self?.$mailPreloadProgressChange.accept(change)
        }).disposed(by: disposeBag)
        
        PushDispatcher.shared.downloadProgressPush.subscribe(onNext: {[weak self] change in
            self?.$downloadProgressChange.accept(change)
        }).disposed(by: disposeBag)
        
        PushDispatcher.shared.cleanCachePush.subscribe(onNext: {[weak self] change in
            self?.$cleanCachePushChange.accept(change)
        }).disposed(by: disposeBag)
    }
}

extension MailCommonDataMananger {
    func handleMigrationChange(change: MailMigrationChange) {
        self.$migrationChange.accept(change)
    }

    func handlePermissionChange(change: ShareMailPermissionChange) {
        self.$sharePermissionChange.accept(change)
    }

    func handleUnreadThreadCountChange(change: MailUnreadThreadCountChange) {
        self.$unreadCountChange.accept(change)
    }
}
