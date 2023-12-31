//
//  DragAnimating.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/18.
//

import UIKit
import Foundation

public final class DragAnimating {

    public typealias LiftAnimation = (UIDragInteraction, UIDragSession) -> Void
    public typealias LiftCompletion = (UIDragInteraction, UIDragSession, UIViewAnimatingPosition) -> Void

    public typealias CancelAnimation = (UIDragInteraction, UIDragItem) -> Void
    public typealias CancelCompletion = (UIDragInteraction, UIDragItem, UIViewAnimatingPosition) -> Void

    public typealias EndAnimation = (UIDragInteraction, UIDragSession, UIDropOperation) -> Void
    public typealias EndCompletion = (UIDragInteraction, UIDragSession, UIDropOperation) -> Void

    var liftAnimations: [LiftAnimation] = []
    var liftCompletions: [LiftCompletion] = []

    var cancelAnimations: [CancelAnimation] = []
    var cancelCompletions: [CancelCompletion] = []

    var endAnimations: [EndAnimation] = []
    var endCompletions: [EndCompletion] = []

    public func addLift(animation: @escaping LiftAnimation) {
        liftAnimations.append(animation)
    }

    public func addLift(completion: @escaping LiftCompletion) {
        liftCompletions.append(completion)
    }

    public func addCancel(animation: @escaping CancelAnimation) {
        cancelAnimations.append(animation)
    }

    public func addCancel(completion: @escaping CancelCompletion) {
        cancelCompletions.append(completion)
    }

    public func addEnd(animation: @escaping EndAnimation) {
        endAnimations.append(animation)
    }

    public func addEnd(completion: @escaping EndCompletion) {
        endCompletions.append(completion)
    }

    public init() {
    }
}
