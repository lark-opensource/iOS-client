//
//  UniversalCardContextServices.swift
//  UniversalCardInterface
//
//  Created by ByteDance on 2023/8/10.
//

import Foundation
public protocol UniversalCardContextManagerProtocol {
    func getContext(key: String) -> UniversalCardContext?
    func setContext(key: String, context: UniversalCardContext)
    func removeContext(key: String)
}
