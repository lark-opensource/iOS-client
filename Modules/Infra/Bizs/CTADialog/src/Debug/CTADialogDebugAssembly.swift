//
//  CTADialogDebugAssemble.swift
//  CTADialog
//
//  Created by aslan on 2023/10/10.
//

#if !LARK_NO_DEBUG

import Foundation
import LarkAssembler
import LarkDebugExtensionPoint
import LarkContainer

public class CTADialogDebugAssembly: LarkAssemblyInterface {

    public init() {}

    public func registDebugItem(container: Container) {
        ({ () in CTADialogDebugItem(resolver: container) }, SectionType.debugTool)
    }
}

#endif
