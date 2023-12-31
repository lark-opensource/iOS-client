//
//  MessageURLPreviewService.swift
//  LarkSDKInterface
//
//  Created by 袁平 on 2022/2/10.
//

import Foundation
import RustPB
import LarkModel

/// 负责处理Message及Push的Entity上缺失的预览及template
public protocol MessageURLPreviewService {
    /// pullMessage & pushMessage时：对缺失的entity & templates进行拉取
    func fetchMissingURLPreviews(messages: [Message])

    /// 收到URL中台预览推送时，需要主动拉取懒加载的预览
    func fetchNeedReloadURLPreviews(needLoadIDs: [String: Im_V1_PushMessagePreviewsRequest.PreviewPair])

    func handleURLPreviews(entities: [URLPreviewEntity])

    /// 处理从Message接口同步返回的预览数据
    func handleURLTemplates(templates: [String: Basic_V1_URLPreviewTemplate])
}
