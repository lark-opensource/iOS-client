//
//  AssetBrowserTranslateHandler.swift
//  LarkCore
//
//  Created by shizhengyu on 2020/3/24.
//

import Foundation
import LarkModel
import LarkMessengerInterface
import ThreadSafeDataStructure
import LKCommonsLogging
import LarkUIKit
import LarkAssetsBrowser
import LarkImageEditor
import LarkContainer
import LarkStorage

final class AssetBrowserTranslateHandler: LKAssetBrowserTranslateService {

    private static let logger = Logger.log(AssetBrowserTranslateHandler.self,
                                           category: "LarkCore.AssetBrowserTranslateHandler")

    /// 缓存翻译检测结果，采用LRU，默认容量100
    private static let detectResultCache = SafeLRUDictionary<String, ImageTranslationAbility>()
    private let canTranslateImage: Bool
    /// 外部实现的检测处理
    private let translateDetectBlock: ([String], @escaping ([ImageTranslationAbility]?, Error?) -> Void) -> Void
    /// 外部实现的翻译处理
    private let translateHandler: ((LKDisplayAsset, ImageTranslationAbility, (() -> Void)?, @escaping (LKDisplayAsset?, Error?) -> Void) -> Void)
    /// 外部实现的翻译中断
    private let cancelTranslateHandler: CancelTranslateBlock
    private let userResolver: UserResolver

    public init(canTranslateImage: Bool,
                translateDetectBlock: @escaping ([String], @escaping ([ImageTranslationAbility]?, Error?) -> Void) -> Void,
                translateHandler: @escaping (LKDisplayAsset, ImageTranslationAbility, (() -> Void)?, @escaping (LKDisplayAsset?, Error?) -> Void) -> Void,
                cancelTranslateHandler: @escaping CancelTranslateBlock,
                userResolver: UserResolver) {
        self.canTranslateImage = canTranslateImage
        self.translateDetectBlock = translateDetectBlock
        self.translateHandler = translateHandler
        self.cancelTranslateHandler = cancelTranslateHandler
        self.userResolver = userResolver
    }
    private lazy var translateService: NormalTranslateService? = {
        return (try? userResolver.resolve(assert: NormalTranslateService.self))
    }()

    func detectTranslationAbilityIfNeeded(assets: [LKDisplayAsset], completion: @escaping (Bool) -> Void) {
        guard canTranslateImage else {
            completion(false)
            return
        }

        let filteredAssets = assets.filter { (asset) -> Bool in
            /// 首先过滤掉detect结果缓存中已有的assetKeys
            var notCached: Bool = true
            if let key = asset.originalImageKey {
                notCached = Self.detectResultCache.getValue(for: key, update: false) == nil
            }
            return notCached
        }

        /// 对于译图属性的asset，直接加入detect结果缓存，无须进行请求
        let translatedAssetAbilitys = filteredAssets
            .filter { $0.translateProperty == .translated }
            .reduce([:], { (result, asset) -> [String: ImageTranslationAbility] in
                var mergeResult = result
                var ability = ImageTranslationAbility()
                ability.canTranslate = true
                if let key = asset.originalImageKey {
                    mergeResult[key] = ability
                }
                return mergeResult
            })
        translatedAssetAbilitys.forEach { (key, value) in
            Self.detectResultCache[key] = value
            if let enableDetachResultDic = self.translateService?.enableDetachResultDic(), enableDetachResultDic {
                self.translateService?.detachResultDic[key] = value
            }
        }

        let filteredAssetKeys = filteredAssets.filter { $0.translateProperty == .origin }.map { $0.originalImageKey ?? "" }

        if filteredAssetKeys.isEmpty {
            completion(false)
            return
        }

        AssetBrowserTranslateHandler.logger.info("detectTranslationAbilityIfNeeded assetKeys >> \(filteredAssetKeys)")

        translateDetectBlock(filteredAssetKeys) { [weak self] (translateAbilities, error) in
            guard let `self` = self else {
                completion(false)
                return
            }
            if error == nil, let abilities = translateAbilities {
                /// 如果assetKeys与server得到的translateAbilities数量不一致，则统一不处理，等待下一次检测时再补充检测数据
                if filteredAssetKeys.count != abilities.count {
                    completion(false)
                    return
                }
                for (index, assetKey) in filteredAssetKeys.enumerated() {
                    Self.detectResultCache[assetKey] = translateAbilities?[index] ?? ImageTranslationAbility()
                    if let enableDetachResultDic = self.translateService?.enableDetachResultDic(), enableDetachResultDic {
                        self.translateService?.detachResultDic[assetKey] = translateAbilities?[index] ?? ImageTranslationAbility()
                    }
                }
                completion(true)
            } else if let err = error {
                completion(false)
                AssetBrowserTranslateHandler.logger.error("detectTranslationAbility fail, error >> \(err.localizedDescription)")
            } else {
                completion(false)
                AssetBrowserTranslateHandler.logger.error("detectTranslationAbility fail, translateAbilities is nil")
            }
        }
    }

    func assetTranslationAbility(assetKey: String) -> AssetTranslationAbility? {
        guard canTranslateImage else { return nil }

        if assetKey.isEmpty {
            return AssetTranslationAbility.transform(imageTranslationAbility: ImageTranslationAbility())
        }
        let result: AssetTranslationAbility?
        if let imageTranslationAbility = Self.detectResultCache[assetKey] {
            result = AssetTranslationAbility.transform(imageTranslationAbility: imageTranslationAbility)
        } else if let enableDetachResultDic = self.translateService?.enableDetachResultDic(), enableDetachResultDic, let imageTranslationAbility = self.translateService?.detachResultDic[assetKey] {
            Self.detectResultCache[assetKey] = imageTranslationAbility
            result = AssetTranslationAbility.transform(imageTranslationAbility: imageTranslationAbility)
        } else {
            result = nil
        }
        AssetBrowserTranslateHandler.logger.info("get assetTranslationAbility by assetKey >> \(assetKey), result: \(result?.canTranslate)")
        return result
    }

    func translateAsset(asset: LKDisplayAsset,
                        languageConflictSideEffect: (() -> Void)?,
                        completion: @escaping (LKDisplayAsset?, Error?) -> Void) {

        AssetBrowserTranslateHandler.logger.info("translateAsset.oldAsset >> \(asset.originalImageKey)")
        guard let originImageKey = asset.originalImageKey else { return }
        let translateAbility = Self.detectResultCache[originImageKey] ?? self.translateService?.detachResultDic[originImageKey] ?? ImageTranslationAbility()
        AssetBrowserTranslateHandler.logger.info("translateAsset.oldAsset.srcLanguage >> \(translateAbility.srcLanguage)")

        translateHandler(asset, translateAbility, languageConflictSideEffect) { [weak self] (newAsset, error) in
            guard let `self` = self else { return }

            if let err = error {
                AssetBrowserTranslateHandler.logger.error("translateAsset.error >> \(err.localizedDescription)")
            } else if let newAsset = newAsset {
                AssetBrowserTranslateHandler.logger.info("translateAsset.newAsset >> \(newAsset.originalImageKey)")
                /// 翻译后的asset理论上肯定也支持回到原asset，因此也需要加入detectResultCache，以防止以下badCase：
                /// 用户进行翻译操作后，图片被替换，虽然此次不会触发detect，但是会在下一波diff检测中被误带上
                if case .translated = newAsset.translateProperty {
                    var translationAbility = ImageTranslationAbility()
                    translationAbility.canTranslate = true
                    if let newKey = newAsset.originalImageKey {
                        Self.detectResultCache[newKey] = translateAbility
                        if let enableDetachResultDic = self.translateService?.enableDetachResultDic(), enableDetachResultDic {
                            self.translateService?.detachResultDic[newKey] = translateAbility
                        }
                    }
                }

                /// 翻译后 asset 也需要携带原始 asset 的 extra 信息
                /// 如果新 asset extra 里面已经有相同 key 数据，则不进行覆盖
                var extraInfo = newAsset.extraInfo
                asset.extraInfo.forEach { key, value in
                    if extraInfo[key] == nil {
                        extraInfo[key] = value
                    }
                }

                /// 翻译后的DLP信息依然使用之前的
                extraInfo[DisplayAssetSecurityExtraInfoKey] = asset.extraInfo[DisplayAssetSecurityExtraInfoKey]

                newAsset.extraInfo = extraInfo

                /// 进入查看器时的译图操作回到原图时，应该对原图自动发起一次检测
                /// 防止返回原图时没有ability(包含srcLanguage)
                if case .origin = newAsset.translateProperty {
                    self.detectTranslationAbilityIfNeeded(assets: [newAsset], completion: { _ in })
                }
            }

            completion(newAsset, error)
        }
    }

    func mainLanguage() -> String? {
        let userResolver = Container.shared.getCurrentUserResolver()
        return KVPublic.AI.mainLanguage.value(forUser: userResolver.userID)
    }

    func cancelCurrentTranslate() {
        cancelTranslateHandler()
    }
}

extension AssetTranslationAbility {
    static func transform(imageTranslationAbility: ImageTranslationAbility) -> AssetTranslationAbility {
        return AssetTranslationAbility(canTranslate: imageTranslationAbility.canTranslate,
                                       srcLanguage: imageTranslationAbility.srcLanguage)
    }
}
