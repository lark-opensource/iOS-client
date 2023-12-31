//
//  MomentsNoticeReactionVC.swift
//  Moment
//
//  Created by bytedance on 2021/2/22.
//

import UIKit
import Foundation
import LarkUIKit

final class MomentsNoticeReactionVC: MomentsNoticeBaseVC {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func dequeueReusableSkeletonCellWithTableView(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: NoticeReactionSkeletonViewCell.identifier, for: indexPath)
    }

    override func listDidAppear() {
        Tracer.trackCommunityNotificationPageView(type: .emoji)
        MomentsTracer.trackNotificationPageViewWith(isInteraction: false, circleId: nil)
    }
}
