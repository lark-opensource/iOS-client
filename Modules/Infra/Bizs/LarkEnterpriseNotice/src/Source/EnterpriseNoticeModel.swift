//
//  EnterpriseNoticeModel.swift
//  LarkEnterpriseNotice
//
//  Created by ByteDance on 2023/4/21.
//

import Foundation
import LarkPushCard

struct EnterpriseNoticeModel: Cardable {

    var id: String

    var priority: LarkPushCard.CardPriority = .normal

    var title: String?

    var buttonConfigs: [LarkPushCard.CardButtonConfig]?

    var icon: UIImage?

    var customView: UIView?

    var duration: TimeInterval?

    var bodyTapHandler: ((LarkPushCard.Cardable) -> Void)?

    var timedDisappearHandler: ((LarkPushCard.Cardable) -> Void)? = nil

    var removeHandler: ((LarkPushCard.Cardable) -> Void)?

    var extraParams: Any?

    func calculateCardHeight(with width: CGFloat) -> CGFloat? {
        guard let view = customView as? EnterpriseNoticeView else {
            return nil
        }
        return view.updateLayout(width: width)
    }
}
