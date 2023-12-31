//
//  CipherManager.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2022/1/14.
//  


import Foundation
import RxSwift
import RustPB
import LarkRustClient
import SKFoundation
import SKWikiV2
import SKCommon
import SKDrive
import SKBitable
import SKInfra
import SKWorkspace
import LarkContainer

final public class PushCipherChangedEventHandler: BaseRustPushHandler<RustPB.Basic_V1_PushCipherChangeEventRequest> {
    private let disposeBag = DisposeBag()
    public override func doProcessing(message: RustPB.Basic_V1_PushCipherChangeEventRequest) {
        guard LKFeatureGating.cipherDeleteEnable else {
            DocsLogger.info("CCM企业密钥fg关闭")
            return
        }
        DocsLogger.info("收到企业密钥变更消息：\(message)")
        guard message.events.contains(where: { $0.business == .ccm && !$0.changedIds.isEmpty }) else {
            return
        }
        DocsLogger.info("CCM企业密钥发生变更")
        NotificationCenter.default.post(name: .Docs.cipherChanged, object: nil)
        clearCache()
    }
    private func clearCache() {
        if let newCache = DocsContainer.shared.resolve(NewCacheAPI.self) {
            newCache.cacheClean(maxSize: 0, ageLimit: 0, isUserTrigger: false).subscribe(onNext: { (result) in
                if !result.completed {
                    DocsLogger.error("NewCacheAPI clean fail")
                }
            }).disposed(by: disposeBag)
        } else {
            DocsLogger.error("can't get NewCacheAPI instance")
        }
        
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        if let wikiBase = userResolver.resolve(WikiStorageBase.self) {
            wikiBase.deleteDB()
        } else {
            DocsLogger.error("can't get WikiStorageBase instance")
        }
        
        if let btAttachCache = DocsContainer.shared.resolve(BTUploadAttachCacheCleanable.self) {
            btAttachCache.clean()
        } else {
            DocsLogger.error("can't get BTUploadAttachCacheCleanable instance")
        }
        if let driveCache = DocsContainer.shared.resolve(DriveCacheServiceBase.self) {
            driveCache.deleteAll(completion: nil)
        } else {
            DocsLogger.error("can't get DriveCacheServiceBase instance")
        }
        let template = TemplateDataProvider()
        template.deleteAllCustomTemplates()
        template.deleteAllBusinessTemplates()
    }
}
