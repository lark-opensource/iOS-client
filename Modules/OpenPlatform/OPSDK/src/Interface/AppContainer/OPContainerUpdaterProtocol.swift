//
//  OPContainerUpdaterProtocol.swift
//  OPSDK
//
//  Created by yinyuan on 2020/12/17.
//

import Foundation

@objc public protocol OPContainerUpdaterProtocol {
    
    func applyUpdateIfNeeded(_ beforeReloadBlock: (()->Void)?) -> Bool
    
}
