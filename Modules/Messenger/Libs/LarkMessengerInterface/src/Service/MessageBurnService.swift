//
//  MessageBurnService.swift
//  LarkMessengerInterface
//
//  Created by ByteDance on 2023/2/15.
//

import Foundation
import LarkModel
import LarkSDKInterface

public protocol MessageBurnService {
    func isBurned(message: Message) -> Bool
}
