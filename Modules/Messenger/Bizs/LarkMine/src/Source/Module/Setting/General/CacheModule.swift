//
//  CacheModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/20.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import UniverseDesignToast
import LarkActionSheet
import EENavigator
import LarkContainer
import LarkSDKInterface
import LarkOpenSetting
import LarkSettingUI

final class CacheModule: BaseModule {

    var cacheSize: Float = 0

    var cacheState: ClearCacheState = .idle

    enum ClearCacheState {
        case idle
        case clearing
        case calculating
    }

    private var cacheService: UserCacheService?

    override func createSectionProp(_ key: String) -> SectionProp? {
        let str: String
        switch cacheState {
        case .idle:
            let showSize = (cacheSize <= 1) ? 0 : cacheSize // 少于1MB的时候，展示0
            str = BundleI18n.LarkMine.Lark_NewSettings_ClearCacheMobile + "（\(String(format: "%.2f", showSize))MB）"
        case .clearing:
            str = BundleI18n.LarkMine.Lark_Settings_CacheDeleting
        case .calculating:
            str = BundleI18n.LarkMine.Lark_NewSettings_ClearCacheMobile + " （\(BundleI18n.LarkMine.Lark_Legacy_MineSettingCalculate)）"
        }
        let item = TapCellProp(title: str) { [weak self] view in
            self?.clearCache(view)
        }
        return SectionProp(items: [item])
    }

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)

        self.cacheService = try? self.userResolver.resolve(assert: UserCacheService.self)

        clearComplete
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance) // 防止清除太快 没有足够反馈
            .subscribe(onNext: { [weak self] size in
                guard let self = self else { return }
                self.cacheState = .idle
                self.cacheSize = size
                self.context?.reload()
            })
            .disposed(by: disposeBag)
        calculateCache()
    }

    func calculateCache() {
        cacheState = .calculating
        cacheService?.calculateCacheSize()
            .subscribe(onNext: { [weak self] (cacheSize) in
                guard let self = self else { return }
                self.cacheState = .idle
                self.cacheSize = cacheSize
                self.context?.reload()
            })
            .disposed(by: self.disposeBag)
    }

    private let clearComplete = PublishRelay<Float>()

    private func clearCache(_ view: UIView) {
        guard let vc = self.context?.vc else { return }

        let actionSheetAdapter = ActionSheetAdapter()
        let alert = actionSheetAdapter.create(
            level: .normal(
                source: ActionSheetAdapterSource(
                    sourceView: view,
                    sourceRect: view.bounds,
                    arrowDirection: .up)),
            title: BundleI18n.LarkMine.Lark_NewSettings_ClearCacheConfirmDescription)
        actionSheetAdapter.addItem(title: BundleI18n.LarkMine.Lark_NewSettings_ClearCacheConfirm,
                                   textColor: UIColor.ud.functionDangerContentDefault) { [weak self] in
            guard let self = self else { return }
            self.clear()
        }
        actionSheetAdapter.addCancelItem(title: BundleI18n.LarkMine.Lark_Legacy_Cancel)
        self.userResolver.navigator.present(alert, from: vc)
    }

    private func clear() {
        self.cacheState = .clearing
        self.context?.reload()
        self.cacheService?.clearCache()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (cacheSize) in
                self?.clearComplete.accept(cacheSize)
            }, onCompleted: { [weak self] in
                guard let view = self?.context?.vc?.view else { return }
                UDToast.showSuccess(with: BundleI18n.LarkMine.Lark_Legacy_ClearCacheDone, on: view)
            }).disposed(by: self.disposeBag)
        MineTracker.trackCleanCache()
    }
}
