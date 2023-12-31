//
//  ThreadSystemCellViewModel.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/3/11.
//

import Foundation
import LarkModel
import LarkMessageCore
import LarkMessageBase
import RustPB
import LarkSDKInterface

final class ThreadSystemCellViewModel: SystemCellViewModel<ThreadContext> {
    private var threadMessage: ThreadMessage

    init(metaModel: ThreadMessageMetaModel, context: ThreadContext) {
        self.threadMessage = metaModel.threadMessage
        super.init(metaModel: metaModel, context: context)
    }

    func update(rootMessage: Message) {
        self.threadMessage.rootMessage = rootMessage
        self.update(metaModel: metaModel)
    }
}

extension ThreadSystemCellViewModel: HasThreadMessage {
    func getThreadMessage() -> ThreadMessage {
        return self.threadMessage
    }

    func getThread() -> RustPB.Basic_V1_Thread {
        return self.threadMessage.thread
    }

    func getRootMessage() -> Message {
        return self.threadMessage.rootMessage
    }
}
