//
//  maskStyleManager.swift
//  Action
//
//  Created by sniper on 2018/11/20.
//

import Foundation
import UIKit

protocol MaskStyleManager: AnyObject {
    /// The overlay managed by the styleManager.
    var maskView: MaskView? { get set }

    /// Show/hide the overlay.
    ///
    /// - Parameters:
    ///   - show: `true` to show the overlay, `false` to hide.
    ///   - duration: duration of the animation
    ///   - completion: a block to execute after compleion.
    func showOverlay(_ show: Bool, withDuration duration: TimeInterval,
                     completion: ((Bool) -> Void)?)

    /// Show/hide the cutout.
    ///
    /// - Parameters:
    ///   - show: `true` to show the overlay, `false` to hide.
    ///   - duration: duration of the animation
    ///   - completion: a block to execute after compleion.
    func showCutout(_ show: Bool, withDuration duration: TimeInterval,
                    completion: ((Bool) -> Void)?)
}
