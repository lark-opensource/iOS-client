//
//  MinutesDetailBody.swift
//  ByteView
//
//  Created by panzaofen.cn on 2021/1/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import EENavigator
import MinutesFoundation
import MinutesNetwork
import MinutesInterface


public struct MinutesDetailBody: PlainBody {
    public static let pattern = "//client/minutes/detail"
    let minutes: Minutes
    let source: MinutesSource?
    let destination: MinutesDestination?

    public init(minutes: Minutes, source: MinutesSource?, destination: MinutesDestination?){
        self.minutes = minutes
        self.source = source
        self.destination = destination
    }
}
