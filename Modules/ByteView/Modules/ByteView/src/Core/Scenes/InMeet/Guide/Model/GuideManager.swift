//
//  GuideManager.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/8/10.
//

import Foundation

// 以下方法均在主线程回调
protocol GuideManagerDelegate: AnyObject {
    func guideCanShow(_ guide: GuideDescriptor) -> Bool
    func guideShouldRemove(_ guide: GuideDescriptor)
}

extension GuideManagerDelegate {
    func guideShouldRemove(_ guide: GuideDescriptor) {}
}

class GuideManager {
    private static let logger = Logger.ui
    static let shared = GuideManager()
    @RwAtomic
    var guides: [GuideDescriptor] = []
    private let listeners = Listeners<GuideManagerDelegate>()

    private init() {}

    func checkGuide() {
        Util.runInMainThread {
            self.next()
        }
    }

    func request(guide: GuideDescriptor) {
        if guides.contains(where: { $0.type == guide.type }) {
            Self.logger.info("Duplicated guide request for type \(guide.type.rawValue). Ignored.")
            return
        }
        guides.append(guide)
        Util.runInMainThread {
            self.next()
        }
    }

    func dismissGuide(with type: GuideType) {
        if currentShowingGuide?.type == type, let guide = guides.first(where: { $0.type == type }) {
            Util.runInMainThread { [weak self] in
                self?.listeners.forEach { $0.guideShouldRemove(guide) }
            }
        }
        removeGuide(with: type)
    }

    var currentShowingGuide: GuideDescriptor? {
        if let first = guides.first, first.isShowing {
            return first
        }
        return nil
    }

    func addListener(_ listener: GuideManagerDelegate) {
        listeners.addListener(listener)
        Util.runInMainThread {
            self.next()
        }
    }

    private func removeGuide(with type: GuideType) {
        guides.removeAll { $0.type == type }
        Util.runInMainThread {
            self.next()
        }
    }

    private func next() {
        guard let guide = guides.first, !guide.isShowing else { return }
        let guideType = guide.type
        var isShowing = false
        listeners.forEach {
            // 一个 guideType 只由一个对象处理，一旦某个对象处理并显示了该 guide，后续的均忽略
            isShowing = isShowing || $0.guideCanShow(guide)
        }
        if isShowing {
            guide.isShowing = true
            // inject removeGuide
            let sureAction = guide.sureAction
            let afterSureAction = guide.afterSureAction
            guide.sureAction = { [weak self] in
                sureAction?()
                self?.removeGuide(with: guideType)
                // 增加dispatch方法以确保sureAction与afterSureAction不同时执行，确保hitTest对afterSureAction不产生影响
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    afterSureAction?()
                }
            }
            // handle auto-dismiss
            if let duration = guide.duration {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    self.dismissGuide(with: guideType)
                }
            }
        } else {
            // 没人监听或处理时不直接移除，而是移到队列尾部，直到有处理者可以处理，或者被调用者取消显示。
            if guides.count <= 1 {
                // 如果队列除了这一个以外没别的了，暂时 pending
                return
            }
            guides.append(guides.removeFirst())
        }
    }
}
