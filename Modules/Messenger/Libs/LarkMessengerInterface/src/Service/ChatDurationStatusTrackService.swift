//
//  ChatDurationStatusTrackService.swift
//  LarkMessengerInterface
//
//  Created by bytedance on 3/30/22.
//

import Foundation
import LarkModel

public protocol ChatDurationStatusTrackService {
    //在VC didAppear时标记为true，didDisappear时标记为false
    func markIfViewControllerIsAppear(value: Bool)

    //标记视图的window是否被(视频会议等)遮挡
    func markIfViewIsNotShow(value: Bool)

    func setGetChatBlock(block: @escaping () -> Chat?)
}
