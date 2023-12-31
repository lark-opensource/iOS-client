//
//  LarkInterface+Vote.swift
//  LarkMessengerInterface
//
//  Created by Fan Hui on 2022/4/17.
//

import Foundation
import LarkModel
import EENavigator
import LarkContainer
import LarkSDKInterface
import RustPB

//发起投票页
public struct CreateVoteBody: PlainBody {
    public static let pattern = "//client/vote/createVote"

    public let scene: Vote_V1_VoteScopeContainerType

    public let scopeID: String

    public init(scene: Vote_V1_VoteScopeContainerType, scopeID: String) {
        print("TestTestTest")
        self.scene = scene
        self.scopeID = scopeID
    }
}
