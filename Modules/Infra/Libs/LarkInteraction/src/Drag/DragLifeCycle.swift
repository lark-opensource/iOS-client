//
//  DragLifeCycle.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/18.
//

import UIKit
import Foundation

public enum DragLifeCycle {
    case sessionWillBegin(UIDragInteraction, UIDragSession)
    case sessionWillAdd(UIDragInteraction, UIDragSession, [UIDragItem], UIDragInteraction)
    case sessionDidMove(UIDragInteraction, UIDragSession)
    case sessionWillEnd(UIDragInteraction, UIDragSession, UIDropOperation)
    case sessionDidEnd(UIDragInteraction, UIDragSession, UIDropOperation)
    case sessionDidTransferItems(UIDragInteraction, UIDragSession)
    case sessionCancel(UIDragInteraction, UIDragSession)
}
