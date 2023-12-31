//
//  LarkShareContainerInterface.swift
//  LarkShareContainer
//
//  Created by shizhengyu on 2020/12/29.
//

import Foundation
import RxSwift
import EENavigator

public enum LifeCycleEvent {
    case initial
    case willAppear
    case didAppear
    case willDisappear
    case didDisappear
    case switchTab(target: ShareTabType)
    case clickClose
    case clickCopyForLink
    case clickSaveForQRCode
    case clickShare
    case shareSuccess
    case shareFailure
}

public struct LarkShareContainterBody: PlainBody {
    public static var pattern: String = "//client/share/container"

    public let title: String
    public let selectedShareTab: ShareTabType
    public let circleAvatar: Bool
    public let contentProvider: (ShareTabType) -> Observable<TabContentMeterial>
    public let tabMaterials: [TabMaterial]
    public let lifeCycleObserver: ((LifeCycleEvent, ShareTabType) -> Void)?

    public init(
        title: String,
        selectedShareTab: ShareTabType,
        circleAvatar: Bool = true,
        contentProvider: @escaping (ShareTabType) -> Observable<TabContentMeterial>,
        tabMaterials: [TabMaterial],
        lifeCycleObserver: ((LifeCycleEvent, ShareTabType) -> Void)? = nil
    ) {
        self.title = title
        self.selectedShareTab = selectedShareTab
        self.circleAvatar = circleAvatar
        self.contentProvider = contentProvider
        self.tabMaterials = tabMaterials
        self.lifeCycleObserver = lifeCycleObserver
    }
}
