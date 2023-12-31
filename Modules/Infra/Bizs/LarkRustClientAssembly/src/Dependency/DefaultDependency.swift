//
//  DefaultDependency.swift
//  LarkRustClientAssembly
//
//  Created by Yiming Qu on 2021/2/3.
//

import Foundation
import Swinject
import RustPB
import ByteWebImage

open class DefaultRustClientDependency: RustClientDependency {

    public init() { }

    public var avatarPath: String {
        LarkImageService.shared.avatarPath
    }
}
