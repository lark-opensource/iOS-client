//
//  WAMenuContext.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/19.
//

import Foundation
import LarkUIKit

@objc
final class WAMenuContext: NSObject, MenuContext {
    private(set) weak var container: WAContainer?

    init(container: WAContainer?) {
        self.container = container
        super.init()
    }
}
