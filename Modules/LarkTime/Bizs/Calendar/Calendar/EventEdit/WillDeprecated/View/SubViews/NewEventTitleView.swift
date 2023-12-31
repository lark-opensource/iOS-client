//
//  NewEventTitleView.swift
//  Calendar
//
//  Created by zhuchao on 2017/12/4.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import CalendarFoundation
final class NewEventTitleView: UIView {

    private var leftItem: UIView = UIView()
    private var rightItem: UIView = UIView()

    /// initialize
    func commonInit() {
        self.addLeftItem(item: self.leftItem)
        self.addRightItem(item: self.rightItem)
        self.backgroundColor = UIColor.ud.bgBody
    }

    init() {
        super.init(frame: .zero)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    private func addLeftItem(item: UIView) {
        self.addSubview(item)
        item.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(CGSize(width: 60, height: 40))
        }
    }

    private func addRightItem(item: UIView) {
        self.addSubview(item)
        item.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(NewEventViewUIStyle.Margin.rightMargin)
        }
    }

    func transformLeftItem(item: UIButton?, oldItem: UIView?, animated: Bool) {
        self.transFormItem(positionItem: self.leftItem,
                           newItem: item,
                           currentItem: oldItem,
                           animated: animated)
    }

    func transformLeftItem(item: UIButton?, oldItem: UIView?, progress: Float) -> () -> Void {
        return self.transFormItem(positionItem: self.leftItem,
                                  newItem: item,
                                  currentItem: oldItem,
                                  progress: progress)
    }

    func transformRightItem(item: UIButton?, oldItem: UIView?, animated: Bool) {
        self.transFormItem(positionItem: self.rightItem,
                           newItem: item,
                           currentItem: oldItem,
                           animated: animated)
    }

    func transformRightItem(item: UIButton?, oldItem: UIView?, progress: Float) -> () -> Void {
        return self.transFormItem(positionItem: self.rightItem,
                                  newItem: item,
                                  currentItem: oldItem,
                                  progress: progress)
    }

    private func transFormItem(positionItem: UIView, newItem: UIButton?, currentItem: UIView?, animated: Bool) {
        if animated {
            UIView.animate(withDuration: NewEventViewUIStyle.animationDuration, animations: {
                _ = self.transFormItem(positionItem: positionItem, newItem: newItem, currentItem: currentItem, progress: 1.0)
            }) { _ in
                currentItem?.removeFromSuperview()
                currentItem?.alpha = 1.0
            }
        } else {
            self.transFormItem(positionItem: positionItem,
                               newItem: newItem,
                               currentItem: currentItem,
                               progress: 1.0)()
        }
    }

    private func transFormItem(positionItem: UIView,
                               newItem: UIButton?,
                               currentItem: UIView?,
                               progress: Float) -> () -> Void {
        guard progress >= 0.0, progress <= 1.0 else {
            assertionFailureLog()
            return {}
        }
        if let newItem = newItem {
            newItem.alpha = 0.0
            self.addSubview(newItem)
            newItem.snp.remakeConstraints { (make) in
                make.edges.equalTo(positionItem)
            }
        }
        currentItem?.alpha = CGFloat(1.0 - progress)
        newItem?.alpha = CGFloat(progress)
        return {
            currentItem?.removeFromSuperview()
            currentItem?.alpha = 1.0
        }
    }
}
