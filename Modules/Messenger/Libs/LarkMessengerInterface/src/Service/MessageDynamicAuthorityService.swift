//
//  MessageDynamicAuthorityService.swift
//  LarkMessengerInterface
//
//  Created by ByteDance on 2023/2/16.
//

import Foundation
import LarkModel

public protocol MessageDynamicAuthorityService: AnyObject {
    var delegate: MessageDynamicAuthorityDelegate? { get set }
    var dynamicAuthorityEnum: DynamicAuthorityEnum { get }
    func performAfterAuthorityAllow(identify: String, action: @escaping (() -> Void))
    func reGetAuthorityIfNeed()
}

public protocol MessageDynamicAuthorityDelegate: AnyObject {
    var needAuthority: Bool { get }
    var authorityMessage: Message? { get }
    func updateUIWhenAuthorityChanged()
}
