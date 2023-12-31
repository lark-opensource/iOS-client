//
//  WorkTopicBody.swift
//  ActionPanel
//
//  Created by 袁平 on 2020/10/13.
//

import EENavigator

public struct WorkTopicBody: PlainBody {
    public static let pattern = "//client/worktopic"
    public let blockInfo: BlockInfo
    public let blockit: BlockitService
    public let context: String?
    public let extra: [String: Any]?

    public init(blockInfo: BlockInfo, blockit: BlockitService, context: String?, extra: [String: Any]?) {
        self.blockInfo = blockInfo
        self.blockit = blockit
        self.context = context
        self.extra = extra
    }
}
