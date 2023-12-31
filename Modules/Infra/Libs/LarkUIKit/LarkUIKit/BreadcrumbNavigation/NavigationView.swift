//
//  NavigationView.swift
//  LarkContact
//
//  Created by SolaWing on 2020/11/9.
//

import UIKit
import Foundation
import UniverseDesignBreadcrumb

// 用于在子界面切换的导航容器，使用path控件显示上导航。子VC需要提供title做为标题
open class NavigationView: UIView, UIGestureRecognizerDelegate {
    // 默认只有根视图时不展示导航栏面包屑
    open var alwaysDisplayNavigation: Bool {
        return false
    }

    private let containerView: UIView
    let navigation: UDBreadcrumb

    public init(frame: CGRect, root: UIViewController) {
        containerView = UIView(frame: CGRect(origin: .zero, size: frame.size))
        navigation = UDBreadcrumb(
            config: UDBreadcrumbUIConfig(
                backgroundColor: UIColor.ud.bgBody
            )
        )
        super.init(frame: frame)

        func configNavigation() {
            navigation.backgroundColor = UIColor.ud.bgBody
            navigation.autoresizingMask = .flexibleWidth
            navigation.tapCallback = { [weak self] index in
                self?.tapIndex(index: index)
            }
            navigation.lu.addBottomBorder()
            navigation.frame = CGRect(origin: .zero, size: CGSize(width: frame.width, height: 44))
            self.addSubview(navigation)
        }

        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(containerView)
        configNavigation()
        push(source: root)

        let back = UIPanGestureRecognizer(target: self, action: #selector(back(gesture:)))
        back.delegate = self
        self.addGestureRecognizer(back)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // TODO: lazy load view, avoid load when init
    // MARK: Gesture
    struct InteractiveContext {
        weak var base: NavigationView?
        var container: UIView
        var driven: PercentDrivenInterativeAnimation
        var finish: (Bool) -> Void
    }
    /// use for interactive back gestrue
    var interactiveContext: InteractiveContext?
    static let pushAnimationDuration: CFTimeInterval = 0.35
    @objc
    func back(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            func cancelGesture() {
                // toggle enable to cancel gesture
                gesture.isEnabled = false
                gesture.isEnabled = true
            }
            // 高度可变，所以要实时计算视图, 不能用之前捕获snapshot的方式
            guard let current = self.snapshotView(afterScreenUpdates: true) else { return cancelGesture() }
            current.frame = self.frame
            // 防闪屏
            self.superview?.addSubview(current)
            guard let currentSource = self.pop(), let back = self.snapshotView(afterScreenUpdates: true) else {
                current.removeFromSuperview()
                return cancelGesture()
            }
            current.frame = self.bounds

            // TODO: 优化动画，navigation和VC可以使用不同的动画
            // init state
            let backMask = UIView(frame: back.bounds)
            backMask.backgroundColor = .black
            backMask.alpha = 0.1

            let container = UIView(frame: self.bounds)
            container.addSubview(back)
            container.addSubview(current)
            back.addSubview(backMask)
            self.addSubview(container)

            back.frame.origin.x = back.frame.width * -0.7
            current.layer.shadowColor = UIColor.black.cgColor
            current.layer.shadowOpacity = 0.1
            current.layer.shadowOffset = CGSize(width: -2, height: -1)
            current.layer.shadowRadius = 10
            current.layer.shouldRasterize = true

            let animation = {
                back.frame.origin.x = 0
                backMask.alpha = 0
                current.frame.origin.x = current.frame.width
            }
            let driven = PercentDrivenInterativeAnimation(root: container) // retain cycle before finish
            let context = InteractiveContext(base: self, container: container, driven: driven) { [weak self](success) in
                guard let self = self else { return }
                container.removeFromSuperview()
                if !success {
                    self.push(source: currentSource) // recover if cancel
                }
            }
            self.interactiveContext = context
            driven.beginInteractiveAnimation(duration: Self.pushAnimationDuration)
            UIView.animate(withDuration: Self.pushAnimationDuration, delay: 0, options: .curveLinear, animations: animation)
        case .changed:
            self.interactiveContext?.driven.percent = gesture.translation(in: self).x / self.bounds.width
        case .ended:
            guard let context = self.interactiveContext else { return }
            self.interactiveContext = nil
            // 不更新，防手抖
            // context.driven.percent = gesture.translation(in: self).x / 300
            let speed = gesture.velocity(in: self).x
            let shouldComplete = speed > 300 || (speed > -100 && context.driven.percent > 0.5)
            if shouldComplete {
                context.driven.endInteractiveAnimation(completion: context.finish)
            } else {
                context.driven.cancelInteractiveAnimation(completion: context.finish)
            }
        case .cancelled:
            guard let context = self.interactiveContext else { return }
            self.interactiveContext = nil
            context.driven.cancelInteractiveAnimation(completion: context.finish)
        default:
            assertionFailure("unreachable code!!")
        }
    }

    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // start from the view left edge
        gestureRecognizer.location(in: self).x < 30 && !self.isRoot
    }

    // MARK: Sources Delegate
    public private(set) var sources: [UIViewController] = []
    public var currentSource: UIViewController? { sources.last }
    public var sourceChangedHandler: ((Int) -> Void)?
    var isRoot: Bool { sources.count < 2 }
    private func sourceChanged() {
        navigation.setItems(sources.map { $0.title ?? "  " })
        if alwaysDisplayNavigation {
            navigation.isHidden = false
        } else {
            navigation.isHidden = isRoot
        }
        navigation.layoutIfNeeded()
        navigation.scrollToRightDirectly()
        self.sourceChangedHandler?(sources.count)
    }

    public func push(source: UIViewController) {
        sources.append(source)
        if isRoot, !alwaysDisplayNavigation {
            source.view.frame = self.bounds
        } else {
            var frame = self.bounds
            frame.origin.y = navigation.frame.maxY
            let height = self.bounds.height - frame.minY
            frame.size.height = height < 0 ? 0 : height
            source.view.frame = frame
        }
        source.view.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin]

        containerView.addSubview(source.view)
        sourceChanged()
    }
    func pop() -> UIViewController? {
        if !isRoot {
            let vc = sources.last
            tapIndex(index: sources.count - 2)
            return vc
        }
        return nil
    }

    open func tapIndex(index: Int) {
        let length = index + 1
        if sources.count > length && length > 0 {
            // back to the navigation source
            repeat {
                if let v = sources.popLast() { v.view.removeFromSuperview() }
            } while sources.count > length
            sourceChanged()
        }
     }
}
