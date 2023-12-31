//
//  ParticipantAdjustPositionAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation

class ParticipantAdjustPositionAction: BaseParticipantAction {

    override var title: String { I18n.View_G_AdjustParticipantInThisPosition }

    override var show: Bool { provider?.heterization.hasChangeOrder ?? false }

}
