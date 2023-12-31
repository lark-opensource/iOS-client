//
//  MinutesInviteSearchViewModel.swift
//  Minutes
//
//  Created by panzaofeng on 2021/6/16.
//  Copyright © 2021年 panzaofeng. All rights reserved.
//

import UIKit
import SnapKit
import MinutesFoundation
import MinutesNetwork

public final class MinutesAddParticipantSearchViewModel {

    public var minutes: Minutes

    let participantAddUUID: String = UUID().uuidString

    var selectedItems = [Participant]()

    public init(minutes: Minutes) {
        self.minutes = minutes
    }
}
