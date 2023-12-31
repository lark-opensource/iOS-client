//
//  BaseModule.swift
//  LarkOpenSetting
//
//  Created by panbinghua on 2022/7/4.
//

import Foundation
import UIKit
import RxSwift
import LarkFoundation
import LKCommonsLogging
import LarkStorage
import LarkSettingUI
import LarkContainer
import EENavigator

open class BaseModule: NSObject {

    public let disposeBag = DisposeBag()
    public var key: String = ""
    public let userResolver: UserResolver

    public var context: ModuleContext?

    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    public lazy var _userStore: KVStore = {
        SettingKVStore(realStore: KVStores.udkv(space: .user(id: self.userResolver.userID), domain: Domain.biz.setting))
    }()

    // MARK: life circle
    private var lifeCircleActionDict = [LifeCircleState: () -> Void]()

    public func removeStateListener(_ state: LifeCircleState) {
        lifeCircleActionDict[state] = nil
    }

    public func addStateListener(_ state: LifeCircleState, action: @escaping () -> Void) {
        if lifeCircleActionDict[state] != nil {
            SettingLoggerService.logger(.module(key)).info("life/addStateListener: already register life circle: \(state)")
        }
        lifeCircleActionDict[state] = action
    }

    final func onState(_ state: LifeCircleState) {
        if let cb = lifeCircleActionDict[state] {
            SettingLoggerService.logger(.module(key)).info("life/\(state)")
            cb()
        }
    }

    // MARK: generate prop
    public var onRegisterDequeueViews: ((UITableView) -> Void)?

    open func createSectionPropList(_ key: String) -> [SectionProp] {
        return []
    }
    open func createSectionProp(_ key: String) -> SectionProp? {
        return nil
    }
    open func createHeaderProp(_ key: String) -> HeaderFooterType? {
        return nil
    }
    open func createFooterProp(_ key: String) -> HeaderFooterType? {
        return nil
    }
    open func createCellProps(_ key: String) -> [CellProp]? {
        return nil
    }
}

open class ModuleContext {
    public weak var vc: UIViewController?

    public var info = [String: Any]()

    public var reload: () -> Void = {
#if DEBUG
        fatalError("LarkOpenSetting: shold implement reload().")
#endif
    }

    public var reloadImmediately: () -> Void = {
#if DEBUG
        fatalError("LarkOpenSetting: shold implement reloadImmediately().")
#endif
    }

    public init() {}
}

extension BaseModule {
    public func goToSetting() {
        guard !Utils.isiOSAppOnMacSystem else {
            SettingLoggerService.logger(.module(key)).info("goToSetting: failed due to isiOSAppOnMacSystem")
            return
        }
        DispatchQueue.main.async {
            if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}
