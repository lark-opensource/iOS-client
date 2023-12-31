//
//  Extensions.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/7/14.
//

import UIKit
import Foundation

// swiftlint:disable large_tuple empty_count
extension UIColor {
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red = CGFloat(0)
        var green = CGFloat(0)
        var blue = CGFloat(0)
        var alpha = CGFloat(0)
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return (red, green, blue, alpha)
    }
}

extension DispatchQueue {
    func asyncWithCount(_ count: Int,
                        and interval: TimeInterval,
                        handler: @escaping () -> Void) {
        guard count > 0 else { return }
        let timer = DispatchSource.makeTimerSource(flags: [], queue: self)
        var remain = count
        timer.schedule(deadline: .now(), repeating: interval)
        timer.setEventHandler { [weak self] in
            guard remain > 0 else {
                timer.cancel()
                return
            }

            self?.async { handler() }
            remain -= 1
        }

        timer.resume()
    }
}
