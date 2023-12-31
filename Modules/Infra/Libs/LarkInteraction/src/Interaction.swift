//
//  Interaction.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/18.
//

import UIKit
import Foundation

public protocol Interaction: NSObjectProtocol {
    var uiInteraction: UIInteraction { get }

    var view: UIView? { get }

    var platforms: [UIUserInterfaceIdiom] { get }
}

extension Interaction {
    public var view: UIView? {
        return uiInteraction.view
    }

    public var platforms: [UIUserInterfaceIdiom] {
        return [.phone, .pad]
    }
}
