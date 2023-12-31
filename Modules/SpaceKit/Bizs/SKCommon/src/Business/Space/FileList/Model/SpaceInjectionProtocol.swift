//
//  SpaceInjectionProtocol.swift
//  SKCommon
//
//  Created by guoqp on 2020/7/1.
//

import Foundation
import SKFoundation

// MARK: Folder
public protocol SubFolderVCProtocol: SKTypeAccessible {
    func isSubFolderViewController(_ viewController: UIViewController) -> Bool
}
