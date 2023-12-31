//
//  PostCellCanHandleLongPress.swift
//  Moment
//
//  Created by zc09v on 2021/5/24.
//

//产品设计，帖子cell部分区域不响应长按，具体规则在此处实现
import UIKit
import Foundation
protocol PostCellCanHandleLongPress {
    //返回是否处理及长按区域对应视图的key
    func canHandle(cell: MomentCommonCell, location: CGPoint) -> (canHandle: Bool, key: String?)
}

extension PostCellCanHandleLongPress {
    func canHandle(cell: MomentCommonCell, location: CGPoint) -> (canHandle: Bool, key: String?) {
        if let thumbUp = cell.getView(by: MomentsActionBarComponentConstant.thumbsUpKey.rawValue),
           thumbUp.bounds.contains(cell.convert(location, to: thumbUp)) {
            return (true, key: MomentsActionBarComponentConstant.thumbsUpKey.rawValue)
        } else if let reply = cell.getView(by: MomentsActionBarComponentConstant.replykey.rawValue),
                  reply.bounds.contains(cell.convert(location, to: reply)) {
            return (false, key: MomentsActionBarComponentConstant.replykey.rawValue)
        } else if let forward = cell.getView(by: MomentsActionBarComponentConstant.forwardKey.rawValue),
                  forward.bounds.contains(cell.convert(location, to: forward)) {
            return (false, key: MomentsActionBarComponentConstant.forwardKey.rawValue)
        } else if let more = cell.getView(by: MomentsActionBarComponentConstant.moreKey.rawValue),
                  more.bounds.contains(cell.convert(location, to: more)) {
            return (false, key: MomentsActionBarComponentConstant.moreKey.rawValue)
        } else if let lastReadTip = cell.getView(by: RecommendMomentPostCellComponent.lastReadTipComponentkey),
                  lastReadTip.bounds.contains(cell.convert(location, to: lastReadTip)) {
            return (false, key: RecommendMomentPostCellComponent.lastReadTipComponentkey)
        }

        return (canHandle: true, key: nil)
    }
}
