//
//  TabEventView.swift
//  AnimatedTabBar
//
//  Created by Meng on 2019/10/19.
//

import Foundation
import UIKit

protocol TabEventRecognizer: AnyObject {
    func recognizeTapEventHandler(for gesture: UITapGestureRecognizer) -> TabEventHandler?
    func recognizePanEventHandler(for gesture: UIPanGestureRecognizer) -> TabEventHandler?
}

public protocol TabEventHandler: AnyObject {
    func handleTapEvent(for gesture: UITapGestureRecognizer)
    func handlePanEvent(for gesture: UIPanGestureRecognizer)
}

extension TabEventHandler {
    func handleTapEvent(for gesture: UITapGestureRecognizer) {}
    func handlePanEvent(for gesture: UIPanGestureRecognizer) {}
}

extension TabEventView {
    enum Event {
        static let extensionHeight: CGFloat = 10.0
    }
}

final class TabEventView: UIView {

    weak var eventRecognizer: TabEventRecognizer?

    private weak var panHandler: TabEventHandler?

    private lazy var tapGesture: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
    }()

    private lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        gesture.minimumNumberOfTouches = 1
        gesture.maximumNumberOfTouches = 1
        return gesture
    }()

    init() {
        super.init(frame: .zero)
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(panGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let location = convert(point, to: self)
        let extensionHeight: CGFloat = TabBarDebugConfig.enable ? TabBarDebugConfig.eventExtensionHeight : Event.extensionHeight
        // bigger than bigger
        let rect = CGRect(x: bounds.minX, y: bounds.minY - extensionHeight,
                          width: bounds.width, height: bounds.height + extensionHeight)
        if rect.contains(location) {
            return true
        }
        return super.point(inside: point, with: event)
    }

    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        guard let tapHandler = eventRecognizer?.recognizeTapEventHandler(for: gesture) else { return }
        tapHandler.handleTapEvent(for: gesture)
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            panHandler = eventRecognizer?.recognizePanEventHandler(for: gesture)
            panHandler?.handlePanEvent(for: gesture)
        case .changed, .possible:
            panHandler?.handlePanEvent(for: gesture)
        case .ended, .cancelled, .failed:
            panHandler?.handlePanEvent(for: gesture)
            panHandler = nil
        @unknown default:
            assertionFailure()
        }
    }
}
