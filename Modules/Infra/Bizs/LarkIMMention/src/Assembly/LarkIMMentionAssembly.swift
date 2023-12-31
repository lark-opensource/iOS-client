//
//  LarkMentionAssembly.swift
//  LarkMention
//
//  Created by Yuri on 2022/5/10.
//

import Foundation
import Swinject
import EENavigator
import AppContainer
import BootManager
import LarkAssembler
import LarkDebugExtensionPoint

public final class LarkIMMentionAssembly: LarkAssemblyInterface {
    public init() {}
#if !LARK_NO_DEBUG
    public func registDebugItem(container: Container) {
        ({ PickerDebugPage() }, SectionType.debugTool)
    }
#endif
}
