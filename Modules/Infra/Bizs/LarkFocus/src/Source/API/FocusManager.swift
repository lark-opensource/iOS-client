//
//  FocusManager.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/13.
//

import Foundation
import UIKit
import RustPB
import LarkGuide
import LarkEmotion
import LarkStorage
import LarkContainer
import LarkSDKInterface
import LarkFeatureGating
import LarkAccountInterface
import LKCommonsLogging
import LarkFocusInterface

public final class FocusManager: UserResolverWrapper {

    // MARK: - Logs

    public static let logger = Logger.log(FocusManager.self, category: "FocusManager")

    // MARK: - Singleton
    public let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    // MARK: - FeatureGating

    /// 个人状态强化提示是否可用
    public var isStatusNoteEnabled: Bool {
        self.userResolver.fg.staticFeatureGatingValue(with: "core.status.note")
    }
    // MARK: - EmotionService

    /// 通过 iconKey 获取 emotion 图标
    public static func getFocusIcon(byKey iconKey: String) -> UIImage? {
        return EmotionResouce.shared.imageBy(key: iconKey)
    }

    @ScopedInjectedLazy
    private var userSettings: UserGeneralSettings?

    /// 当前是否为 24 小时制
    public var is24Hour: Bool {
        return userSettings?.is24HourTime.value ?? false
    }

    // MARK: - Onboarding

    @ScopedInjectedLazy private var guideManager: NewGuideService?

    static let onboardingShownNotification = Notification.Name("FocusOnboardingShown")
    private let guideKey = "all_im_status_setting"

    private lazy var globalStore = KVStores.Focus.global()
    private lazy var userStore = KVStores.Focus.user(id: userResolver.userID)

    public var isOnboardingShown: Bool {
        get {
            #if DEBUG
            globalStore[KVKeys.Focus.onBoarding]
            #else
            !(guideManager?.checkShouldShowGuide(key: guideKey) ?? false)
            #endif
        }
        set {
            guard newValue == true else { return }
            #if DEBUG
            globalStore[KVKeys.Focus.onBoarding] = newValue
            #else
            guideManager?.didShowedGuide(guideKey: guideKey)
            #endif
            NotificationCenter.default.post(name: FocusManager.onboardingShownNotification, object: nil)
        }
    }

    // MARK: - Record Expand Item

    @KVBinding(to: \FocusManager.userStore, key: KVKeys.Focus.expandStatus)
    internal var expandStatusID: Int64

    // MARK: - Status Management

    lazy var dataService = FocusDataService(userResolver: userResolver)

}
