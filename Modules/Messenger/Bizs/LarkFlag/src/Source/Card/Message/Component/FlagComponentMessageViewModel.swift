//
//  FlagMessageComponentCellViewModel.swift
//  LarkFlag
//
//  Created by ByteDance on 2022/10/19.
//

import Foundation
import RustPB
import LarkModel
import LarkContainer

class FlagMessageComponentCellViewModel: FlagMessageCellViewModel {
    var componentViewModel: FlagListMessageComponentViewModel

    override public class var identifier: String {
        return String(describing: FlagMessageComponentCellViewModel.self)
    }

    override public var identifier: String {
        return Self.identifier
    }

    init(userResolver: UserResolver, flag: Feed_V1_FlagItem, content: MessageFlagContent, dataDependency: FlagDataDependency, componentViewModel: FlagListMessageComponentViewModel) {
        self.componentViewModel = componentViewModel
        super.init(userResolver: userResolver, flag: flag, content: content, dataDependency: dataDependency)
    }

    override public var needAuthority: Bool {
        return false
    }
}
