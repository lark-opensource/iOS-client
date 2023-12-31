//
//  EditorToolContainer.swift
//  MailSDK
//
//  Created by majx on 2019/6/18.
//

import Foundation
import UIKit
import SnapKit

private typealias editorConst = EditorToolContainerConst

private struct EditorToolContainerConst {
    static let animDuration: Double = 0.3
}

protocol EditorToolContainerDelegate: AnyObject {

}

/// Mail 工具条(工具条、@框、评论框、etc...)容器 View，仅提供容器能力，逻辑请移至 ☞ MailToolbarManager
class EditorToolContainer: UIView {
    enum AnimationDirection {
        case none
        case rightToLeft
        case leftToRight
    }

    weak var delegate: EditorToolContainerDelegate?

    // MARK: Data
    var preferedHeight: CGFloat {
        return _calculatePreferdHeight()
    }

    private var coverStickConstraints: [Constraint] = []
    private var currentHorizonConstraints: [Constraint] = []
    private var previousHorizonConstraints: [Constraint] = []
    private var initialConstraints: [UIView: [Constraint]] = [:]
    private var lastAnimationDirection: AnimationDirection = .none
    private var _isToolbarVisiable: Bool = true
    private var _shouldRestoreVerticalView: Bool = false

    // MARK: UI Widget
    /// 最顶层显示的 View (如目录悬浮栏)，此 view 会覆盖所有当前工具条，设置后请务必适时移除
    private(set) var coverStickerView: UIView?
    private(set) var currentHorizontalView: UIView?
    private(set) var previousHorizontalView: UIView?
    private(set) var verticalView: UIView?

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if _isToolbarVisiable {
            if let current = currentHorizontalView {
                let pointInCurrent = self.convert(point, to: current)
                let result = current.hitTest(pointInCurrent, with: event)
                if result != nil {
                    return result
                }
            }
            if let current = verticalView {
                let pointInCurrent = self.convert(point, to: current)
                let result = current.hitTest(pointInCurrent, with: event)
                if result != nil {
                    return result
                }
            }
        } else {
            if let current = coverStickerView {
                let pointInCurrent = self.convert(point, to: current)
                let result = current.hitTest(pointInCurrent, with: event)
                if result != nil {
                    return result
                }
            }
        }
        return nil
    }

    /// 装载会显示的视图
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

    /// 卸载会显示的视图
    func eliminateView(_ view: UIView?, verticalView: UIView?) {
        if let view = view {
            initialConstraints.removeValue(forKey: view)
            view.removeFromSuperview()
            view.snp.removeConstraints()
        }
        verticalView?.removeFromSuperview()
    }

    /// 设置当前水平方向的view
    ///
    /// - Parameters:
    ///   - view: 要设置的水平方向的view
    ///   - direction: 水平方向的view，要从什么方向进来
    func setCurrentHorizontalView(_ view: UIView?,
                                  direction: AnimationDirection = .none,
                                  verticalView: UIView?,
                                  completion: (() -> Void)? = nil) {
        setVerticalView(view: verticalView)
        guard view != currentHorizontalView else {
            return
        }

        previousHorizontalView = currentHorizontalView
        previousHorizonConstraints.forEach { $0.deactivate() }
        previousHorizonConstraints = currentHorizonConstraints

        guard let current = view else {
            return
        }

        lastAnimationDirection = direction
        currentHorizontalView = current
        current.isHidden = _isToolbarVisiable ? false : true

        // remove initial constraints
        if let cons = initialConstraints[current] {
            cons.forEach { $0.deactivate() }
        }

        switch direction {
        case .rightToLeft:
            handlAnimation(direction: .rightToLeft, completion: completion)
        case .leftToRight:
            handlAnimation(direction: .leftToRight, completion: completion)
        case .none:
            currentHorizonConstraints = current.snp.prepareConstraints { (make) in
                make.bottom.equalToSuperview()
                make.width.equalToSuperview()
                make.leading.equalTo(self.snp.leading)
            }
            currentHorizonConstraints.forEach { $0.activate() }
            previousHorizontalView?.isHidden = true
            completion?()
        }
    }

    private func setVerticalView(view: UIView?) {
        guard view != verticalView else {
            return
        }
        verticalView?.isHidden = true
        verticalView = view
        view?.isHidden = !_isToolbarVisiable
    }

    func setCoverStickerView(_ view: UIView?, completion: (() -> Void)? = nil) {
        if let view = view {
            // will set cover view
            let shouldAddCover: Bool = (coverStickerView == nil) || (coverStickerView != nil && coverStickerView != view)

            if let coverView = coverStickerView, coverView != view {
                removeCoverView(resotreToolbarVisiable: false)
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
        } else {
            // will remove cover view
            removeCoverView(resotreToolbarVisiable: true)
        }
    }
    
    private func initialLayout(_ view: UIView?) {
        guard let view = view else {
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

    func restoreHorizontalView(completion: (() -> Void)? = nil) {
        switch lastAnimationDirection {
        case .leftToRight:
            setCurrentHorizontalView(previousHorizontalView,
                                     direction: .rightToLeft,
                                     verticalView: verticalView) { [weak self] in
                guard let `self` = self else { return }
                self.previousHorizonConstraints.forEach { $0.deactivate() }
                self.previousHorizonConstraints.removeAll()
                self.initialLayout(self.previousHorizontalView)
                self.previousHorizontalView = nil
                completion?()
            }
        case .rightToLeft:
            setCurrentHorizontalView(previousHorizontalView,
                                     direction: .leftToRight,
                                     verticalView: verticalView) { [weak self] in
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

    func handlAnimation(direction: AnimationDirection, completion: (() -> Void)? = nil) {
        guard let current = currentHorizontalView else {
            return
        }

        guard direction == .rightToLeft || direction == .leftToRight else {
            return
        }

        // 设置动画前的位置
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

        // 设置动画后的位置
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeIntvl.ultraShort) {
            self.currentHorizonConstraints.forEach { $0.deactivate() }
            self.currentHorizonConstraints = self.currentHorizontalView?.snp.prepareConstraints({ (make) in
                make.bottom.equalToSuperview()
                make.width.equalToSuperview()
                make.leading.equalToSuperview()
            }) ?? []

            self.currentHorizonConstraints.forEach { $0.activate() }

            if self._isToolbarVisiable {
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

            UIView.animate(withDuration: timeIntvl.short,
                           animations: {
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }, completion: { _ in
                completion?()
            })
        }
    }

    /// 清空previousView和currentView，慎用以免当前view被清空
    func reset(completion: (() -> Void)? = nil) {
        previousHorizonConstraints.forEach { $0.deactivate() }
        currentHorizonConstraints.forEach { $0.deactivate() }
        currentHorizonConstraints.removeAll()
        previousHorizonConstraints.removeAll()
        initialLayout(previousHorizontalView)
        initialLayout(currentHorizontalView)
        verticalView?.isHidden = true
        verticalView = nil
        currentHorizontalView = nil
        previousHorizontalView = nil
        endEditing(true)
        completion?()
    }
}

extension EditorToolContainer {
    // MARK: Internal supporting method
    /// 移除CoverView，并选择是否恢复工具条可见性
    @inline(__always)
    private func removeCoverView(resotreToolbarVisiable shouldRestore: Bool) {
        guard let coverView = coverStickerView else { return }
        coverView.removeFromSuperview()
        if shouldRestore {
            _updateToolbarInvisible(toHidden: false)
        }
        coverStickConstraints.forEach {
            $0.deactivate()
        }
        coverStickerView = nil
        coverStickConstraints = []
    }

    private func _updateToolbarInvisible(toHidden: Bool) {
        _isToolbarVisiable = !toHidden
        verticalView?.isHidden = toHidden
        currentHorizontalView?.isHidden = toHidden
    }

    private func _calculatePreferdHeight() -> CGFloat {
        let horizontal = currentHorizontalView?.frame.height ?? 0
        let vertical = verticalView?.frame.height ?? 0
        return horizontal + vertical
    }
}
