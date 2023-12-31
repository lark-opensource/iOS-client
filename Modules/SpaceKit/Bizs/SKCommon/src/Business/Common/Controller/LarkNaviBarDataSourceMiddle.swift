//
//  DocsNaviBarDataSource.swift
//  SpaceKit
//
//  Created by nine on 2019/10/19.
//

import Foundation
import RxSwift
import RxRelay
import LarkUIKit
import SKUIKit
import SKResource

public enum DocsNaviButtonType {
    case search
    case first
    case second
}

public protocol DocsNaviBarDataSource: UIViewController {
    // Title
    var titleTextBridge: BehaviorRelay<String> { get }
    // 是否在加载中
    var isNaviBarLoadingBridge: BehaviorRelay<Bool> { get }
    // Title旁边的箭头，有Filter的时候需要
    var needShowTitleArrowBridge: BehaviorRelay<Bool> { get }
    // SubFilter文字，以小标签的形式显示
    var subFilterTitleTextBridge: BehaviorRelay<String?> { get }
    // 多租户时，是否显示租户信息
    var showTenantBridge: Bool { get }
    // 提供Button 优先级大于下面的方法
    func larkNaviBarBridge(userDefinedButtonOf type: DocsNaviButtonType) -> UIButton?
    // 提供Button图片数据源
    func larkNaviBarBridge(imageOfButtonOf type: DocsNaviButtonType) -> UIImage?
    // 自定义头像View，如果没有定制（如Feed的badge）可以不实现
    func usingCustomAvatarViewBridge() -> UIView?
}

public extension DocsNaviBarDataSource {
    var isNaviBarLoadingBridge: BehaviorRelay<Bool> { return BehaviorRelay(value: false) }
    var needShowTitleArrowBridge: BehaviorRelay<Bool> { return BehaviorRelay(value: true) }
    var subFilterTitleTextBridge: BehaviorRelay<String?> { return BehaviorRelay(value: nil) }
    var showTenantBridge: Bool { return true }
    func usingCustomAvatarViewBridge() -> UIView? { return nil }
    func larkNaviBarBridge(userDefinedButtonOf type: DocsNaviButtonType) -> UIButton? { return nil }
    func larkNaviBarBridge(imageOfButtonOf type: DocsNaviButtonType) -> UIImage? {
        switch type {
        case .first:
            return BundleResources.SKResource.Common.Icon.icon_create_outlined
        default:
            break
        }
        return nil
    }
}

// swiftlint:disable class_delegate_protocol
public protocol DocsNaviBarDelegate: UIViewController {
    // 点击头像
    func onDefaultAvatarTappedBridge()
    // 点击Title
    func onTitleViewTappedBridge()
    // 点击右侧Button
    func onButtonTappedBridge(on button: UIButton, with type: DocsNaviButtonType)
}
public extension DocsNaviBarDelegate {
    // 点击头像
    func onDefaultAvatarTappedBridge() {}
    // 点击Title
    func onTitleViewTappedBridge() {}
}
