//
//  AnimationCoordinator.swift
//  ByteView
//
//  Created by kiri on 2023/3/14.
//

import Foundation

final class AnimationCoordinator {
    private var animations: [() -> Void] = []
    private var completions: [(Bool) -> Void] = []

    func animate(animation: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        self.animations.append(animation)
        if let completion = completion {
            self.completions.append(completion)
        }
    }

    func run(withDuration duration: TimeInterval, delay: TimeInterval, options: UIView.AnimationOptions = []) {
        UIView.animate(withDuration: duration, delay: delay, options: options, animations: {
            self.animations.forEach { $0() }
        }, completion: { finished in
            self.completions.forEach { $0(finished) }
        })
    }
}
