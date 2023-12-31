//
//  KAEMMLauncherDelegate.swift
//  KAEMMLauncherDelegate
//
//  Created by kongkaikai on 2021/8/18.
//
#if !IS_NOT_DEFAULT
import Foundation
import LarkAccountInterface
import Swinject

public final class KAEMMLauncherDelegate: LauncherDelegate {
    public var name: String { "KAEMMLauncherDelegate" }
    public init(container: Container) {}
}

/// 默认实现，为了编译可以过
final class KAVPNWrapper: KAVPNWrapperInterface {}
#endif
