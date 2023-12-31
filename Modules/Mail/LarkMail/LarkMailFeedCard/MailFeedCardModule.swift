//
//  MailFeedCardModule.swift
//  LarkMail
//
//  Created by ByteDance on 2023/9/11.
//

import LarkOpenFeed
import LarkFeedBase
import RustPB
import LarkModel
import LarkContainer
import LarkFeed

class MailFeedCardModule: FeedCardBaseModule {

    // [必须实现]表明自己是xx业务类
    override var type: FeedPreviewType {
        return .mailFeed
    }
    
    // [必须实现] 关联业务的实体数据
    override func bizData(feedPreview: FeedPreview) -> FeedPreviewBizData {
        var shortcutChannel = Basic_V1_Channel()
        shortcutChannel.id = model.id
        shortcutChannel.type = .appFeed
        let data = FeedPreviewBizData(entityId: feedPreview.id, shortcutChannel: shortcutChannel)
        return data
    }
    

    // [必须实现] feed card 被点击时
    override func didSelectCell(feedPreview: FeedPreview,
                                filterType: Feed_V1_FeedFilter.TypeEnum,
                                bizType: FeedBizType,
                                from: UIViewController) {
        feedCardContext.userResolver.navigator.showDetailOrPush(url,
                                          context: context,
                                          wrap: LkNavigationController.self,
                                          from: from)
    }

    // mute操作，由各业务实现
    override func setMute(feedPreview: FeedPreview,
                          filterType: Feed_V1_FeedFilter.TypeEnum,
                          bizType: FeedBizType) -> Single<Void> {
        dependency.api.changeMute(feedId: feedPreview.id, to: !feedPreview.isRemind) ?? .just(())
    }

    // 用于返回 cell 拖拽手势
    override func supportDragScene(feedPreview: FeedPreview,
                                   filterType: Feed_V1_FeedFilter.TypeEnum,
                                   bizType: FeedBizType) -> Scene? {
        let scene = LarkSceneManager.Scene(
            key: "Docs",
            id: feedPreview.docURL,
            title: feedPreview.name,
            userInfo: [:],
            windowType: "docs",
            createWay: "drag")
        return scene
    }
}
