//
//  DriveSDKLocalFilePreviewAbilityImpl.swift
//  CCMMod
//
//  Created by bupozhuang on 2022/4/12.
//

import Foundation
#if LarkMail
 import LarkMailInterface
#endif
import LarkContainer
import Swinject
import RxSwift
import SKFoundation
import SpaceInterface
import EENavigator
import UIKit

// 调用外部注入的本地文件预览能力，目前仅支持调用mail注入的eml预览能力，后续可扩展
class DriveSKDLocalFilePreviewAbilityImpl: DriveSDKLocalFilePreviewAbility {
    private let resolver: Resolver?
    init(resolver: Resolver?) {
        self.resolver = resolver
    }
    
    func openFile(from path: URL, from: NavigatorFrom) {
#if LarkMail
        guard let r = resolver else {
            spaceAssertionFailure("resolver is nil")
            return
        }
        guard let impl = r.resolve(LarkMailInterface.self) else {
            spaceAssertionFailure("DriveSDKLocalFilePreviewAbility: no LarkMailInterface impl")
            return
        }
        impl.openEMLFromPath(path, from: from)
#endif
    }
    func previewVC(with path: URL) -> UIViewController? {
#if LarkMail
        guard let r = resolver else {
            spaceAssertionFailure("resolver is nil")
            return nil
        }
        guard let impl = r.resolve(LarkMailInterface.self) else {
            spaceAssertionFailure("DriveSDKLocalFilePreviewAbility: no LarkMailInterface impl")
            return nil
        }
        return impl.getEMLPreviewController(path)
#else
        return nil
#endif
    }
}
