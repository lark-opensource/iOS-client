//
//  MinutesHomeTrashBody.swift
//  MinutesNavigator
//
//  Created by chenlehui on 2021/7/13.
//

import Foundation
import EENavigator

public struct MinutesHomeTrashBody: PlainBody {
    public static var pattern: String = "//client/minutes/trash"

    public let fromSource: MinutesHomeFromSource

    public init(fromSource: MinutesHomeFromSource) {
        self.fromSource = fromSource
    }
}
