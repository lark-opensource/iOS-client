//
//  MinutesHomeSharedBody.swift
//  Minutes
//
//  Created by admin on 2021/2/24.
//

import Foundation
import EENavigator

public struct MinutesHomeSharedBody: PlainBody {
    public static var pattern: String = "//client/minutes/shared"

    public let fromSource: MinutesHomeFromSource

    public init(fromSource: MinutesHomeFromSource) {
        self.fromSource = fromSource
    }
}
