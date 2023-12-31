//
//  FeedPresentAnimationViewController.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/9.
//

import UIKit
import Foundation

protocol FeedPresentAnimationViewController: UIViewController {
    func showAnimation(completion: @escaping () -> Void)
    func hideAnimation(animated: Bool, completion: @escaping () -> Void)
}

extension FeedPresentAnimationViewController {
    func showAnimation(completion: () -> Void) { completion() }
    func hideAnimation(animated: Bool, completion: @escaping () -> Void) { completion() }
}
