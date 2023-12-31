//
//  FeedPreviewBasicData.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2023/8/8.
//

import Foundation
import LarkModel
import RustPB
import LarkOpenFeed
import LarkContainer

// feed自身的实体数据
public struct FeedPreviewBasicData: IFeedPreviewBasicData {
    // 是否是临时置顶(目前团队、标签、标记分组不支持)
    public let isTempTop: Bool
    // 所属分组
    public let groupType: Feed_V1_FeedFilter.TypeEnum
    public let bizType: FeedBizType

//    public let feedPreview: FeedPreview
//    // 对应的业务方
//    let feedCardModule: FeedCardBaseModule

    public init(isTempTop: Bool,
                groupType: Feed_V1_FeedFilter.TypeEnum,
                bizType: FeedBizType) {
        self.isTempTop = isTempTop
        self.groupType = groupType
        self.bizType = bizType
    }

    // 生成feed自身的数据
    static func buildBasicData(feedPreview: FeedPreview,
                               feedCardModule: FeedCardBaseModule,
                               userResolver: UserResolver,
                               bizType: FeedBizType,
                               filterType: Feed_V1_FeedFilter.TypeEnum,
                               extraData: [AnyHashable: Any]) -> FeedPreviewBasicData {
        let isTempTop: Bool
        if feedPreview.basicMeta.onTopRankTime > 0 {
            let supportTempTop = FeedFilterTabSourceFactory.source(for: filterType)?.supportTempTop ?? true
            isTempTop = supportTempTop
        } else {
            isTempTop = false
        }
        let basicData = FeedPreviewBasicData(
            isTempTop: isTempTop,
            groupType: filterType,
            bizType: bizType)
        return basicData
    }
}
