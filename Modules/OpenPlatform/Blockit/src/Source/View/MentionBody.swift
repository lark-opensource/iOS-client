//
//  MentionBody.swift
//  Blockit
//
//  Created by 夏汝震 on 2020/10/25.
//

import EENavigator

public struct MentionBody: PlainBody {

    public static let pattern = "//client/mention"
    public let blockit: BlockitService
    public let context: String?
    public let extra: [String: Any]?

    public typealias MentionSelectedHandler = (_ selectItems: [MentionItem]) -> Void
    public typealias MentionCancelHandler = () -> Void

    public var completion: MentionSelectedHandler?
    public var cancel: MentionCancelHandler?

    public init(blockit: BlockitService,
                context: String?,
                extra: [String: Any]?,
                complete: MentionSelectedHandler? = nil,
                cancel: MentionCancelHandler? = nil) {
        self.blockit = blockit
        self.context = context
        self.extra = extra
        self.completion = complete
        self.cancel = cancel
    }
}
