//
//  MomentsTranslateNotification.swift
//  Moment
//
//  Created by ByteDance on 2022/10/14.
//

import Foundation
import RustPB
import RxSwift
import LarkRustClient

protocol MomentsTranslateNotification: AnyObject {
    func transEntityTranslationResultToTranslationInfo(oldInfo: RawData.TranslationInfo,
                                                       result: RustPB.Moments_V1_EntityTranslationResult) -> RawData.TranslationInfo
    var rxTranslateEntities: PublishSubject<RustPB.Moments_V1_PushTranslateEntitiesNotification> { get }
    var rxTranslateUrlPreview: PublishSubject<RustPB.Moments_V1_PushTranslateUrlPreviewsNotification> { get }
    var rxHideTranslation: PublishSubject<RustPB.Moments_V1_PushHideTranslationNotification> { get }
}

class MomentsTranslateNotificationHandler: MomentsTranslateNotification {
    var rxTranslateEntities: RxSwift.PublishSubject<RustPB.Moments_V1_PushTranslateEntitiesNotification> = .init()

    var rxTranslateUrlPreview: RxSwift.PublishSubject<RustPB.Moments_V1_PushTranslateUrlPreviewsNotification> = .init()

    var rxHideTranslation: RxSwift.PublishSubject<RustPB.Moments_V1_PushHideTranslationNotification> = .init()

    init(client: RustService) {
        client.register(pushCmd: .momentsPushTranslateEntitiesNotification) { [weak self] nofInfo in
            guard let self = self else { return }
            do {
                let rustBody = try RustPB.Moments_V1_PushTranslateEntitiesNotification(serializedData: nofInfo)
                self.rxTranslateEntities.onNext(rustBody)
            } catch {
                assertionFailure("serialize update noti payload failed")
            }
        }

        client.register(pushCmd: .momentsPushTranslateURLPreviewsNotification) { [weak self] nofInfo in
            guard let self = self else { return }
            do {
                let rustBody = try RustPB.Moments_V1_PushTranslateUrlPreviewsNotification(serializedData: nofInfo)
                self.rxTranslateUrlPreview.onNext(rustBody)
            } catch {
                assertionFailure("serialize update noti payload failed")
            }
        }

        client.register(pushCmd: .momentsPushHideTranslationNotification) { [weak self] nofInfo in
            guard let self = self else { return }
            do {
                let rustBody = try RustPB.Moments_V1_PushHideTranslationNotification(serializedData: nofInfo)
                self.rxHideTranslation.onNext(rustBody)
            } catch {
                assertionFailure("serialize update noti payload failed")
            }
        }
    }

    func transEntityTranslationResultToTranslationInfo(oldInfo: RawData.TranslationInfo,
                                                       result: RustPB.Moments_V1_EntityTranslationResult) -> RawData.TranslationInfo {
        var translationInfo = oldInfo
        translationInfo.translateStatus = result.translateStatus
        translationInfo.contentTranslation = result.contentTranslation
        translationInfo.targetLanguage = result.targetLanguage
        translationInfo.manualLanguage = result.manualLanguage
        return translationInfo
    }
}
