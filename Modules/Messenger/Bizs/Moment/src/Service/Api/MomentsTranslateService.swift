//
//  MomentsTranslateService.swift
//  Moment
//
//  Created by ByteDance on 2022/10/9.
//

import Foundation
import RunloopTools
import RustPB
import LarkContainer
import RxSwift
import RxCocoa
import LarkSDKInterface
import LarkAI
import LarkMessengerInterface
import EENavigator
import ThreadSafeDataStructure
import LarkRichTextCore
import LKCommonsLogging
import UniverseDesignToast
import LarkFeatureGating
import TangramService
import LarkSetting
import LarkModel

protocol MomentsTranslateService {
    func translateByUser(entity: RawData.TranslateTargetEntity,
                         manualTargetLanguage: String?,
                         from: NavigatorFrom?)
    func autoTranslateIfNeed(entity: RawData.TranslateTargetEntity)
    func autoTranslateIfNeed(entityId: String,
                             entityType: RawData.EntityType,
                             contentLanguages: [String],
                             currentTranslateInfo: RawData.TranslationInfo,
                             richText: RawData.RichText,
                             inlinePreviewEntities: InlinePreviewEntityBody,
                             urlPreviewHangPointMap: [String: Basic_V1_UrlPreviewHangPoint],
                             isSelfOwner: Bool)
    func hideTranslation(entity: RawData.TranslateTargetEntity)
    func changeTranslationLanguage(entity: RawData.TranslateTargetEntity,
                                   from: NavigatorFrom)
    func showTranslateFeedbackView(content: String,
                                   translation: String,
                                   targetLanguage: String,
                                   from: NavigatorFrom)
}

class MomentsTranslateServiceImp: NSObject, MomentsTranslateService, UserResolverWrapper {
    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    private static let logger = Logger.log(MomentsTranslateServiceImp.self, category: "Module.Moments.MomentsTranslateService")

    private var checkedPostSet: SafeSet<String> = SafeSet<String>([], synchronization: .semaphore)
    private var checkedCommentSet: SafeSet<String> = SafeSet<String>([], synchronization: .semaphore)

    @ScopedInjectedLazy private var translateAPI: MomentsTranslateAPI?
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    @ScopedInjectedLazy private var translateFeedbackService: TranslateFeedbackService?
    @ScopedInjectedLazy private var fgService: FeatureGatingService?

    private var disposeBag = DisposeBag()

    private lazy var selectLanguageCenter: SelectTargetLanguageTranslateCenter = {
        return SelectTargetLanguageTranslateCenter(userResolver: userResolver,
                                                   selectTargetLanguageTranslateCenterdelegate: self,
                                                   translateLanguageSetting: self.userGeneralSettings?.translateLanguageSetting ?? .init())
    }()

    /// 等待发请求的消息
    private var entityWaitContexts: Set<Moments_V1_EntityTranslationContext> = Set()
    private var urlPreviewWaitContexts: Set<Moments_V1_UrlPreviewTranslationContext> = Set()

    func showTranslateFeedbackView(content: String,
                                   translation: String,
                                   targetLanguage: String,
                                   from: NavigatorFrom) {
        guard let fromVC = from.fromViewController else { return }
        translateFeedbackService?.showTranslateFeedbackForSelectText(selectText: content,
                                                                    translateText: translation,
                                                                    targetLanguage: targetLanguage,
                                                                    extraParam: [:],
                                                                    fromVC: fromVC)
    }

    func hideTranslation(entity: RawData.TranslateTargetEntity) {
        hideTranslation(entityId: entity.id,
                        entityType: entity.type)
    }

    private func hideTranslation(entityId: String, entityType: RawData.EntityType) {
        self.translateAPI?.hideTranslation(entityId: entityId, entityType: entityType)
            .subscribe(onNext: { (_) in
            }, onError: { _ in
            }).disposed(by: self.disposeBag)
    }

    func changeTranslationLanguage(entity: RawData.TranslateTargetEntity,
                                   from: NavigatorFrom) {
        changeTranslationLanguage(entityId: entity.id,
                                  entityType: entity.type,
                                  contentLanguages: entity.contentLanguages,
                                  currentTranslateInfo: entity.translationInfo,
                                  richText: entity.richText,
                                  inlinePreviewEntities: entity.inlinePreviewEntities,
                                  urlPreviewHangPointMap: entity.urlPreviewHangPointMap,
                                  from: from)
    }

    private func changeTranslationLanguage(entityId: String,
                                           entityType: RawData.EntityType,
                                           contentLanguages: [String],
                                           currentTranslateInfo: RawData.TranslationInfo,
                                           richText: RawData.RichText,
                                           inlinePreviewEntities: InlinePreviewEntityBody,
                                           urlPreviewHangPointMap: [String: Basic_V1_UrlPreviewHangPoint],
                                           from: NavigatorFrom) {
        self.selectLanguageCenter.showSelectDrawer(translateContext: .moments(context: .init(entityId: entityId,
                                                                                             entityType: entityType,
                                                                                             contentLanguages: contentLanguages,
                                                                                             currentTranslateInfo: currentTranslateInfo,
                                                                                             richText: richText,
                                                                                             inlinePreviewEntities: inlinePreviewEntities, urlPreviewHangPointMap: urlPreviewHangPointMap,
                                                                                             from: from)),
                                                   from: from)
    }

    func translateByUser(entity: RawData.TranslateTargetEntity,
                         manualTargetLanguage: String?,
                         from: NavigatorFrom?) {
        translateByUser(entityInfo: (id: entity.id, type: entity.type),
                        manualTargetLanguage: manualTargetLanguage,
                        ignoreLastManualLanguage: entity.translateFail, //如果之前是翻译失败的，则无视之前的手动翻译语言
                        contentLanguages: entity.contentLanguages,
                        currentTranslateInfo: entity.translationInfo,
                        richText: entity.richText,
                        inlinePreviewEntities: entity.inlinePreviewEntities,
                        urlPreviewHangPointMap: entity.urlPreviewHangPointMap,
                        from: from)
    }

    private func translateByUser(entityInfo: (id: String, type: RawData.EntityType),
                                 manualTargetLanguage: String?,
                                 ignoreLastManualLanguage: Bool, //无视之前的手动翻译语言
                                 contentLanguages: [String],
                                 currentTranslateInfo: RawData.TranslationInfo,
                                 richText: RawData.RichText,
                                 inlinePreviewEntities: InlinePreviewEntityBody,
                                 urlPreviewHangPointMap: [String: Basic_V1_UrlPreviewHangPoint],
                                 from: NavigatorFrom?) {
        let entityId = entityInfo.id
        let entityType = entityInfo.type
        if contentLanguages.count == 1 {
            if manualTargetLanguage == nil,
               let from = from,
               contentLanguages.first == getTargetLanguage(of: currentTranslateInfo, ignoreManualLanguage: ignoreLastManualLanguage) {
                changeTranslationLanguage(entityId: entityId,
                                          entityType: entityType,
                                          contentLanguages: contentLanguages,
                                          currentTranslateInfo: currentTranslateInfo,
                                          richText: richText,
                                          inlinePreviewEntities: inlinePreviewEntities,
                                          urlPreviewHangPointMap: urlPreviewHangPointMap,
                                          from: from)
                return
            }
        }

        let targetLanguage = manualTargetLanguage ?? getTargetLanguage(of: currentTranslateInfo, ignoreManualLanguage: ignoreLastManualLanguage)
        var context = Moments_V1_EntityTranslationContext()
        context.entityID = entityId
        context.entityType = entityType
        context.currentTranslateStatus = currentTranslateInfo.translateStatus
        context.targetLanguage = targetLanguage
        self.translateAPI?.translateEntities(entitiesContexts: [context], isAutoTranslate: false)
            .subscribe(onNext: { (_) in
            }, onError: { [weak from] error in
                Self.logger.error("amanual translate entity fail, entityID: \(entityId), entityType: \(entityType)", error: error)
                DispatchQueue.main.async {
                    if let view = from?.fromViewController?.view {
                        UDToast.showFailure(with: BundleI18n.Moment.Moments_UnableToTranslateTryLater_Toast, on: view)
                    }
                }
            }).disposed(by: self.disposeBag)

        var urlPreviewTranslation = [String: String]()
        for (key, value) in richText.elements where value.tag == .a {
            if let point = urlPreviewHangPointMap[key],
               let inlineEntity = inlinePreviewEntities[point.previewID],
               let title = inlineEntity.title {
                urlPreviewTranslation[point.previewID] = title
            } else {
                urlPreviewTranslation["\(entityId)-\(key)"] = value.property.anchor.textContent
            }
        }
        if urlPreviewTranslation.isEmpty {
            return
        }
        var urlContext = Moments_V1_UrlPreviewTranslationContext()
        urlContext.entityID = entityId
        urlContext.entityType = entityType
        urlContext.targetLanguage = targetLanguage
        urlContext.urlPreviewTranslation = urlPreviewTranslation
        self.translateAPI?.translateUrlPreviews(translateContexts: [urlContext], isAutoTranslate: false)
            .subscribe(onNext: { (_) in
            }, onError: { error in
                Self.logger.error("amanual translate url fail, entityID: \(entityId), entityType: \(entityType)", error: error)
            }).disposed(by: self.disposeBag)

    }

    func autoTranslateIfNeed(entity: RawData.TranslateTargetEntity) {
        autoTranslateIfNeed(entityId: entity.id,
                            entityType: entity.type,
                            contentLanguages: entity.contentLanguages,
                            currentTranslateInfo: entity.translationInfo,
                            richText: entity.richText,
                            inlinePreviewEntities: entity.inlinePreviewEntities,
                            urlPreviewHangPointMap: entity.urlPreviewHangPointMap,
                            isSelfOwner: entity.isSelfOwner)
    }

    func autoTranslateIfNeed(entityId: String,
                             entityType: RawData.EntityType,
                             contentLanguages: [String],
                             currentTranslateInfo: RawData.TranslationInfo,
                             richText: RawData.RichText,
                             inlinePreviewEntities: InlinePreviewEntityBody,
                             urlPreviewHangPointMap: [String: Basic_V1_UrlPreviewHangPoint],
                             isSelfOwner: Bool) {
        let fgValue = (try? userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "moments.client.translation") ?? false

        guard fgValue else { return }
        let targetLanguage = getTargetLanguage(of: currentTranslateInfo)
        func succeedTranslated() -> Bool {
            if !currentTranslateInfo.hasContentTranslation {
                return false
            }
            if !currentTranslateInfo.contentTranslation.elements.isEmpty {
                return true
            }
            for (_, urlTranslation) in currentTranslateInfo.urlPreviewTranslation {
                if !urlTranslation.isEmpty {
                    return true
                }
            }
            return false
        }
        if succeedTranslated(),
           currentTranslateInfo.targetLanguage == targetLanguage {
            return
        }

        if contentLanguages.count == 1,
           //特化：有url的一律跳过这个判断，因为当前无法判断url标题的语言
           !richText.hasParsedURL {
            if contentLanguages.first?.lowercased() == "not_lang" {
                return
            }
            if contentLanguages.first == targetLanguage,
               currentTranslateInfo.hasContentTranslation {
                //源语言和目标语言一致 且触发过翻译的 不再触发自动翻译（但仍可以手动翻译，因为源语言识别的不是很准确）
                return
            }
        }

        if !richText.canBeTranslatedInMoment(fgService: fgService) {
            return
        }

        switch currentTranslateInfo.translateStatus {
        case.manual:
            break
        case .hidden:
            return
        case .noOperation:
            guard !isSelfOwner,
                  (userGeneralSettings?.translateLanguageSetting.momentsSwitch ?? false)else { return }
        }

        // 丢入waitContexts合并请求
        var context = Moments_V1_EntityTranslationContext()
        context.entityID = entityId
        context.entityType = entityType
        context.currentTranslateStatus = currentTranslateInfo.translateStatus
        context.targetLanguage = targetLanguage
        self.entityWaitContexts.insert(context)

        var urlPreviewTranslation = [String: String]()
        for (key, value) in richText.elements where value.tag == .a {
            if let point = urlPreviewHangPointMap[key],
               let inlineEntity = inlinePreviewEntities[point.previewID],
               let title = inlineEntity.title {
                urlPreviewTranslation[point.previewID] = title
            } else {
                urlPreviewTranslation["\(entityId)-\(key)"] = value.property.anchor.textContent
            }
        }
        if !urlPreviewTranslation.isEmpty {
            var urlContext = Moments_V1_UrlPreviewTranslationContext()
            urlContext.entityID = entityId
            urlContext.entityType = entityType
            urlContext.targetLanguage = targetLanguage
            urlContext.urlPreviewTranslation = urlPreviewTranslation
            self.urlPreviewWaitContexts.insert(urlContext)
        }

        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(putContexts), object: nil)
        self.perform(#selector(putContexts), with: nil, afterDelay: 0.3)

    }

    @objc
    private func putContexts() {
        let tempEntityContexts = Array(self.entityWaitContexts)
        self.entityWaitContexts = Set()
        // 进行自动检测请求
        self.translateAPI?.translateEntities(entitiesContexts: tempEntityContexts, isAutoTranslate: true)
            .subscribe(onNext: { (_) in
            }, onError: { error in
                Self.logger.warn("auto translate entity fail", error: error)
            }).disposed(by: self.disposeBag)

        let tempUrlPreviewContexts = Array(self.urlPreviewWaitContexts)
        self.urlPreviewWaitContexts = Set()
        self.translateAPI?.translateUrlPreviews(translateContexts: tempUrlPreviewContexts, isAutoTranslate: true)
            .subscribe(onNext: { (_) in
            }, onError: { error in
                Self.logger.warn("auto translate url fail", error: error)
            }).disposed(by: self.disposeBag)
    }

    private func getTargetLanguage(of translateInfo: RawData.TranslationInfo, ignoreManualLanguage: Bool = false) -> String {
        if !translateInfo.manualLanguage.isEmpty,
           !ignoreManualLanguage {
            return translateInfo.manualLanguage
        }
        return userGeneralSettings?.translateLanguageSetting.targetLanguage ?? ""
    }
}

extension MomentsTranslateServiceImp: SelectTargetLanguageTranslateCenterDelegate {
    func finishSelect(translateContext: LarkAI.TranslateContext, targetLanguage: String) {
        if case .moments(let context) = translateContext {
            self.translateByUser(entityInfo: (id: context.entityId, type: context.entityType),
                                 manualTargetLanguage: targetLanguage,
                                 ignoreLastManualLanguage: false,
                                 contentLanguages: context.contentLanguages,
                                 currentTranslateInfo: context.currentTranslateInfo,
                                 richText: context.richText,
                                 inlinePreviewEntities: context.inlinePreviewEntities,
                                 urlPreviewHangPointMap: context.urlPreviewHangPointMap,
                                 from: context.from)
        }
    }
}

protocol MomentsTranslateAPI {
    func hideTranslation(entityId: String, entityType: RawData.EntityType) -> Observable<Void>
    func translateEntities(entitiesContexts: [Moments_V1_EntityTranslationContext], isAutoTranslate: Bool) -> Observable<Void>
    func translateUrlPreviews(translateContexts: [Moments_V1_UrlPreviewTranslationContext], isAutoTranslate: Bool) -> Observable<Void>
}

extension RustApiService: MomentsTranslateAPI {

    func hideTranslation(entityId: String, entityType: RawData.EntityType) -> Observable<Void> {
        var request = RustPB.Moments_V1_HideTranslationRequest()
        request.entityID = entityId
        request.entityType = entityType
        return client.sendAsyncRequest(request).map { (_: RustPB.Moments_V1_HideTranslationResponse) -> Void in
            return
        }
    }

    func translateEntities(entitiesContexts: [Moments_V1_EntityTranslationContext], isAutoTranslate: Bool) -> Observable<Void> {
        var request = RustPB.Moments_V1_TranslateEntitiesRequest()
        request.entitiesContexts = entitiesContexts
        request.isAutoTranslate = isAutoTranslate
        return client.sendAsyncRequest(request).map { (_: RustPB.Moments_V1_TranslateEntitiesResponse) -> Void in
            return
        }
    }
    func translateUrlPreviews(translateContexts: [Moments_V1_UrlPreviewTranslationContext], isAutoTranslate: Bool) -> Observable<Void> {
        var request = RustPB.Moments_V1_TranslateUrlPreviewsRequest()
        request.translateContexts = translateContexts
        request.isAutoTranslate = isAutoTranslate
        return client.sendAsyncRequest(request).map { (_: RustPB.Moments_V1_TranslateUrlPreviewsResponse) -> Void in
            return
        }
    }
}
