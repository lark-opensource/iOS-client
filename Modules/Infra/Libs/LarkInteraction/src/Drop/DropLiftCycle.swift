//
//  DropLiftCycle.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/18.
//

import UIKit
import Foundation

public enum DropLifeCycle {
    case sessionDidEnter(UIDropInteraction, UIDropSession)
    case sessionDidUpdate(UIDropInteraction, UIDropSession)
    case sessionDidExit(UIDropInteraction, UIDropSession)
    case sessionDidEnd(UIDropInteraction, UIDropSession)
    case concludeDrop(UIDropInteraction, UIDropSession)
}
