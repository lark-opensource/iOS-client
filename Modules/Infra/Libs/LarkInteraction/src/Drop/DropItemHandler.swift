//
//  DropItemHandler.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/18.
//

import UIKit
import Foundation

public final class DropItemHandler {

    public typealias HandleDragSessionBlock = (UIDropInteraction, UIDropSession) -> Void

    public typealias HandleSessionDidUpdateBlock = (UIDropInteraction, UIDropSession) -> UIDropProposal

    public typealias CanHandleBlock = (UIDropInteraction, UIDropSession) -> Bool

    public var handleDragSession: HandleDragSessionBlock = { _, _ in }
    public var handleSessionDidUpdate: HandleSessionDidUpdateBlock = { _, _ in return UIDropProposal(operation: .copy) }
    public var canHandle: CanHandleBlock = { _, _ in return false }

}
