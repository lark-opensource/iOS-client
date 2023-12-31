//
//  MinutesClipBody.swift
//  Minutes
//
//  Created by panzaofeng on 2022/5/14.
//

import Foundation
import EENavigator
import MinutesFoundation
import MinutesInterface
import MinutesNetwork

public struct MinutesClipBody: PlainBody {
    public static let pattern = "//client/minutes/clip"
    let minutes: Minutes
    let source: MinutesSource?
    let destination: MinutesDestination?

    public init(minutes: Minutes, source: MinutesSource?, destination: MinutesDestination?) {
        self.minutes = minutes
        self.source = source
        self.destination = destination
    }
}
