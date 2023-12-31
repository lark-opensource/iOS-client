//
//  DocsToolContainer.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/3/3.
//

import UIKit
import SnapKit
import SKFoundation

private typealias Const = DocsToolContainerConst
private struct DocsToolContainerConst {
    static let animDuration: Double = 0.3
}

protocol DocsToolContainerDelegate: AnyObject {

}

public final class DocsToolContainer: UIView {
    weak var delegate: DocsToolContainerDelegate?

    // MARK: Data
    var preferedHeight: CGFloat {
        return _calculatePreferdHeight()
    }
    private var currentHorizonConstraints: [Constraint] = []
    private var previousHorizonConstraints: [Constraint] = []
    private var coverStickConstraints: [Constraint] = []
    private var lastAnimationDirection: AnimationDirection = .none
    private var initialConstraints: [UIView: [Constraint]] = [:]
    private var _isToolbarVisible: Bool = true
    private var _shouldRestoreVerticalView: Bool = false

    // MARK: UI Widget
    private(set) var currentHorizontalView: UIView?
    private(set) var previousHorizontalView: UIView?
    private(set) var verticalView: UIView?
    private(set) var coverStickerView: UIView?

    private var shouldInterceptEvents: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 装载可能会显示的视图
    func prepareView(_ view: UIView?, verticalView: UIView?) {
        if let view = view {
            addSubview(view)
            if let verticalView = verticalView {
                addSubview(verticalView)
            }
        }
        initialLayout(view)
        verticalView?.isHidden = true
    }

    /// 卸载可能会显示的视图
    func eliminateView(_ view: UIView?, verticalView: UIView?) {
        if let view = view {
            initialConstraints.removeValue(forKey: view)
            view.removeFromSuperview()
            view.snp.removeConstraints()
        }
        verticalView?.removeFromSuperview()
    }

    func setCurrentHorizontalView(_ view: UIView?, direction: AnimationDirection = .none, verticalView: UIView?, completion: (() -> Void)? = nil) {
        setVerticalView(view: verticalView)
        guard view != currentHorizontalView else { return }
        previousHorizontalView = currentHorizontalView
        previousHorizonConstraints.forEach { $0.deactivate() }
        previousHorizonConstraints = currentHorizonConstraints

        guard let current = view else { return }
        lastAnimationDirection = direction
        currentHorizontalView = current
        current.isHidden = _isToolbarVisible ? false : true

        // Remove initial constraints
        if let cons = initialConstraints[current] {
            cons.forEach { $0.deactivate() }
        }
        switch direction {
        case .rightToLeft:
            handlAnimation(direction: .rightToLeft, completion: completion)
        case .leftToRight:
            handlAnimation(direction: .leftToRight, completion: completion)
        case .none:
            previousHorizontalView?.isHidden = true
            currentHorizonConstraints = current.snp.prepareConstraints { (make) in
                make.bottom.equalToSuperview()
                make.width.equalToSuperview()
                make.leading.equalTo(self.snp.leading)
            }
            currentHorizonConstraints.forEach { $0.activate() }
            // 因为这里加完约束就马上做键盘跟随动画了，会导致有个frame=.zero的动画过程（ios14大概率出现）
            self.layoutIfNeeded()
            completion?()
        }
    }

    func setToolbarInvisible(toHidden: Bool) {
        _updateToolbarInvisible(toHidden: toHidden)
    }

    func setCoverStickerView(_ view: UIView?, completion: (() -> Void)? = nil) {
        if let view = view { // Will set cover view
            let shouldAddCover: Bool = (coverStickerView == nil) || (coverStickerView != nil && coverStickerView != view)
            if let coverView = coverStickerView, coverView != view {
                removeCoverView(resotreToolbarVisible: false)
            }
            if shouldAddCover {
                coverStickerView = view
                addSubview(view)
                coverStickConstraints = view.snp.prepareConstraints({ (make) in
                    make.leading.trailing.bottom.equalToSuperview()
                })
                coverStickConstraints.forEach {
                    $0.activate()
                }
                _updateToolbarInvisible(toHidden: true)
                self.layoutIfNeeded()
            }
        } else { // Will remove cover view
            removeCoverView(resotreToolbarVisible: true)
        }
    }

    private func setVerticalView(view: UIView?) {
        guard view != verticalView else {
            return
        }
        verticalView?.isHidden = true
        verticalView = view
        view?.isHidden = _isToolbarVisible ? false : true
    }

    private func initialLayout(_ view: UIView?) {
        guard let view = view else { return }
        if view.superview == nil {
            view.isHidden = true
            return
        }
        if let cons = initialConstraints[view] {
            cons.forEach { $0.activate() }
            view.isHidden = true
        } else {
            let newCons = view.snp.prepareConstraints { (make) in
                make.leading.trailing.bottom.equalToSuperview()
            }
            newCons.forEach { $0.activate() }
            view.isHidden = true
            initialConstraints[view] = newCons
        }
    }

    func handlAnimation(direction: AnimationDirection, completion: (() -> Void)? = nil) {
        guard let current = currentHorizontalView else { return }
        guard direction == .rightToLeft || direction == .leftToRight else { return }
        //设置动画前的位置
        currentHorizonConstraints = current.snp.prepareConstraints { (make) in
            make.bottom.equalToSuperview()
            make.width.equalToSuperview()
            if direction == .rightToLeft {
                make.leading.equalTo(self.snp.trailing)
            } else {
                make.trailing.equalTo(self.snp.leading)
            }
        }
        currentHorizonConstraints.forEach { $0.activate() }
        //设置动画后的位置
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            self.currentHorizonConstraints.forEach { $0.deactivate() }
            self.currentHorizonConstraints = self.currentHorizontalView?.snp.prepareConstraints({ (make) in
                make.bottom.equalToSuperview()
                make.width.equalToSuperview()
                make.leading.equalToSuperview()
            }) ?? []
            self.currentHorizonConstraints.forEach { $0.activate() }

            if self._isToolbarVisible {
                self.previousHorizontalView?.isHidden = false
            }
            self.previousHorizonConstraints.forEach { $0.deactivate() }
            self.previousHorizonConstraints = self.previousHorizontalView?.snp.prepareConstraints({ (make) in
                make.bottom.equalToSuperview()
                make.width.equalToSuperview()
                if direction == .rightToLeft {
                    make.trailing.equalTo(self.snp.leading)
                } else {
                    make.leading.equalTo(self.snp.trailing)
                }
            }) ?? []
            self.previousHorizonConstraints.forEach { $0.activate() }

            UIView.animate(withDuration: Const.animDuration, animations: {
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }, completion: { _ in
                completion?()
            })
        }
    }

    /// 只有点到了当前的水平方向的view，或者垂直方向的view，才认为点击到了
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if _isToolbarVisible {
            if let current = currentHorizontalView {
                let hitView = super.hitTest(point, with: event)
                if hitView?.isKind(of: DocsAttachedToolBar.self) == true {
                    //如果没有其他的响应，被底层拦截了，则不做处理
                   return nil
                }
                let pointInCurrent = self.convert(point, to: current)
                let result = current.hitTest(pointInCurrent, with: event)
                if result != nil { return result }
            }
            if let current = verticalView {
                let pointInCurrent = self.convert(point, to: current)
                let result = current.hitTest(pointInCurrent, with: event)
                if result != nil { return result }
            }
        } else {
            if let current = coverStickerView {
                let pointInCurrent = self.convert(point, to: current)
                let result = current.hitTest(pointInCurrent, with: event)
                if result != nil { return result }
            }
        }
        if shouldInterceptEvents,
           !UserScopeNoChangeFG.LJW.docFix {
            return self
        }
        return nil
    }
        
    func setShouldInterceptEvents(to enable: Bool) {
        self.shouldInterceptEvents = enable
    }

    /// 恢复上次水平工具栏状态
    func restoreHorizontalView(completion: (() -> Void)? = nil) {
        switch lastAnimationDirection {
        case .leftToRight:
            setCurrentHorizontalView(previousHorizontalView, direction: .rightToLeft, verticalView: verticalView) { [weak self] in
                guard let `self` = self else { return }
                self.previousHorizonConstraints.forEach { $0.deactivate() }
                self.previousHorizonConstraints.removeAll()
                self.initialLayout(self.previousHorizontalView)
                self.previousHorizontalView = nil
                completion?()
            }
        case .rightToLeft:
            setCurrentHorizontalView(previousHorizontalView, direction: .leftToRight, verticalView: verticalView) { [weak self] in
                guard let `self` = self else { return }
                self.previousHorizonConstraints.forEach { $0.deactivate() }
                self.previousHorizonConstraints.removeAll()
                self.initialLayout(self.previousHorizontalView)
                self.previousHorizontalView = nil
                completion?()
            }
        default:
            return
        }
    }

    /// 清空previousView和currentView，慎用以免当前view被清空
    func reset(completion: (() -> Void)? = nil) {
        currentHorizonConstraints.forEach { $0.deactivate() }
        previousHorizonConstraints.forEach { $0.deactivate() }
        currentHorizonConstraints.removeAll()
        previousHorizonConstraints.removeAll()
        verticalView?.isHidden = true
        initialLayout(previousHorizontalView)
        initialLayout(currentHorizontalView)
        previousHorizontalView = nil
        currentHorizontalView = nil
        verticalView = nil
        endEditing(true)
        completion?()
    }
}

extension DocsToolContainer {
    private func _calculatePreferdHeight() -> CGFloat {
        let horVal = currentHorizontalView?.frame.height ?? 0
        let verVal = verticalView?.frame.height ?? 0
        return horVal + verVal
    }
}

extension DocsToolContainer {
    // MARK: Internal supporting method
    @inline(__always)
    private func removeCoverView(resotreToolbarVisible shouldRestore: Bool) {
        guard let coverView = coverStickerView else { return }
        coverView.removeFromSuperview()
        if shouldRestore {
            _updateToolbarInvisible(toHidden: false)
        }
        coverStickConstraints.forEach {
            $0.deactivate()
        }
        coverStickConstraints = []
        coverStickerView = nil
    }

    private func _updateToolbarInvisible(toHidden: Bool) {
        _isToolbarVisible = !toHidden
        currentHorizontalView?.isHidden = toHidden
        verticalView?.isHidden = toHidden
    }
}

extension DocsToolContainer {
    enum AnimationDirection {
        case none
        case rightToLeft
        case leftToRight
    }
}
