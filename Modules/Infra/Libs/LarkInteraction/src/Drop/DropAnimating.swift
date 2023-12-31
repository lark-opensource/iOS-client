//
//  DropAnimating.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/18.
//

import UIKit
import Foundation

public final class DropAnimating {

    public typealias DropAnimation = (UIDropInteraction, UIDragItem) -> Void
    public typealias DropCompletion = (UIDropInteraction, UIDragItem, UIViewAnimatingPosition) -> Void

    var dropAnimations: [DropAnimation] = []
    var dropCompletions: [DropCompletion] = []

    public func add(animation: @escaping DropAnimation) {
        dropAnimations.append(animation)
    }

    public func add(completion: @escaping DropCompletion) {
        dropCompletions.append(completion)
    }

    public init() {
    }
}
