//
//  UrgencyWindowViewController.swift
//  LarkUrgent
//
//  Created by 白镜吾 on 2022/10/11.
//

import Foundation
import UIKit
import LarkPushCard
import LKWindowManager

final class UrgencyViewController: LKWindowRootController {
    lazy var floatingBox: UrgencyFloatingBox = UrgencyFloatingBox()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(floatingBox)
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        guard isViewLoaded else { return }
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        coordinator.animate { _ in
            self.floatingBox.remakeBoxConstraints()
            self.view.layoutIfNeeded()
        }
        super.willTransition(to: newCollection, with: coordinator)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        coordinator.animate { _ in
            self.floatingBox.remakeBoxConstraints()
            self.view.layoutIfNeeded()
        }
        super.viewWillTransition(to: size, with: coordinator)
    }

    func post(_ models: [Cardable], animated: Bool) {
        for model in models {
            self.floatingBox.cardArchives.append(model)
            if !self.floatingBox.cardArchives.isEmpty, self.floatingBox.isHidden {
                self.floatingBox.isHidden = false
                self.floatingBox.presentBox(animated: animated)
            }
        }
    }

    func remove(with id: String, animated: Bool, completion: (() -> Void)? = nil) {
        guard let item = self.floatingBox.cardArchives.firstIndex(where: { $0.id == id }) else { return }
        self.floatingBox.cardArchives.remove(at: item)
        if self.floatingBox.cardArchives.isEmpty {
            self.floatingBox.dismissBox(animated: animated, completion: completion)
        }
    }

    func checkVisiableArea(_ point: CGPoint) -> Bool {
        guard !self.floatingBox.isHidden else { return false }
        if self.floatingBox.frame.contains(point) {
            return true
        }
        return false
    }
}
