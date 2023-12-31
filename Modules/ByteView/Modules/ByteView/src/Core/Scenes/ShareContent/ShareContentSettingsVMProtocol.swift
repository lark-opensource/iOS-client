//
//  ShareContentSettingsVMProtocol.swift
//  ByteView
//
//  Created by Tobb Huang on 2021/5/27.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import Action
import ByteViewNetwork
import ByteViewSetting

enum ShareContentScenario {
    case inMeet
    case local
}

protocol ShareContentSettingsVMProtocol {

    var accountInfo: AccountInfo { get }

    var scenario: ShareContentScenario { get }

    var shareScreenTitle: Driver<String> { get }

    var shareScreenTitleColor: Driver<UIColor> { get }

    var shareScreenIcon: Driver<UIImage?> { get }

    var shareScreenIconBackgroundColor: Driver<UIColor> { get }

    var whiteboardTitle: Driver<String> { get }

    var whiteboardTitleColor: Driver<UIColor> { get }

    var whiteboardIcon: Driver<UIImage?> { get }

    var whiteboardIconBackgroundColor: Driver<UIColor> { get }

    func showShareScreenAlert()

    func didTapShareWhiteboard()

    var canSharingDocs: Bool { get }

    var canSharingDocsObservable: Observable<Bool> { get }

    var shouldReloadWhiteboardItemObservable: Observable<Bool> { get }

    func generateSearchViewModel(isSearch: Bool) -> SearchShareDocumentsVMProtocol

    func generateCreateAndShareViewModel() -> NewShareSettingsVMProtocol

    var shareContentEnabledConfig: ShareContentEnabledConfig { get }

    /// 正在识别超声波
    var isLoadingObservable: Observable<Bool> { get }

    var showTip: Bool { get }

    var ccmDependency: CCMDependency { get }

    func checkShowChangeAlert(isWhiteBoard: Bool) -> Bool

    var httpClient: HttpClient { get }

    var setting: MeetingSettingManager { get }

    var hasShowUltrawaveTip: Bool { get set }
}

extension ShareContentSettingsVMProtocol {
    var showTip: Bool { false }
    func checkShowChangeAlert(isWhiteBoard: Bool) -> Bool {
        false
    }
    var shouldReloadWhiteboardItemObservable: Observable<Bool> {
        Observable<Bool>.just(false)
    }
}

extension ShareContentSettingsVMProtocol where Self: ShareContentSettingsViewModel {
    var canSharingDocs: Bool {
        return true
    }

    var canSharingDocsObservable: Observable<Bool> {
        return .just(true)
    }

    var isLoadingObservable: Observable<Bool> {
        return .just(false)
    }
}
