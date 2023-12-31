//
//  AudioPlayable.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/16.
//

import Foundation
import LarkModel
import LarkMessengerInterface
import RustPB

protocol AudioPlayable: AnyObject {
    var audioKey: String { get }
    var audioLength: TimeInterval { get }
    var state: AudioPlayMediatorStatus { get set }
    var fromId: String { get }
    var meRead: Bool { get }
    var messageId: String { get }
    var messageCid: String { get }
    var position: Int32 { get }
    var positionBadgeCount: Int32 { get }
    var channel: RustPB.Basic_V1_Channel { get }
    var authToken: String? { get }
}
