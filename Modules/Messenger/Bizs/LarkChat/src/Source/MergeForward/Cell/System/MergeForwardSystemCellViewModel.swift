//
//  MergeForwardSystemCellViewModel.swift
//  LarkChat
//
//  Created by 李勇 on 2019/11/13.
//

import Foundation
import LarkMessageCore
import LarkModel
import LarkMessageBase

final class MergeForwardSystemCellViewModel: SystemCellViewModel<MergeForwardContext>, HasCellConfig {
    var cellConfig: ChatCellConfig = ChatCellConfig()
    override var isUserInteractionEnabled: Bool {
        return self.context.mergeForwardType == .targetPreview ? false : true
    }
}
