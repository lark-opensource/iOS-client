//
//  WindowFactory.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/9/12.
//

import Foundation
import LarkContainer
import LarkSecurityComplianceInterface

class WindowFactory: WindowService {
    let userResolver: UserResolver
    
    init(resolver: UserResolver) {
        self.userResolver = resolver
    }
    
    func createLSCWindow(frame: CGRect) -> UIWindow {
        return LSCWindow(resolver: userResolver, frame: frame)
    }
    
    func isLSCWindow(_ window: UIWindow) -> Bool {
        return window.isKind(of: LSCWindow.self)
    }
}
