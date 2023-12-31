//
//  BreadcrumbNavigationView.swift
//  LarkUIKit
//
//  Created by 吴子鸿 on 2017/7/20.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

public protocol BreadcrumbNavigationViewDelegate: AnyObject {
    func tapIndex(index: Int)
}

open class BreadcrumbNavigationView: UIView, NSCopying {
    public weak var delegate: BreadcrumbNavigationViewDelegate?

    private var items: [BreadcrumbItem] = []

    private var rightConstraint: Constraint?

    private var scrollView: UIScrollView!

    public var showAddAnimated: Bool = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
        scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        self.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        self.lu.addBottomBorder()
    }

    public func getTotalItemsNumber() -> Int {
        return self.items.count
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copyObj = BreadcrumbNavigationView(frame: .zero)
        copyObj.setItems(itemTitles: self.items.map({ $0.title }))
        copyObj.showAddAnimated = self.showAddAnimated
        return copyObj
    }

    public func setItems(itemTitles: [String]) {
        clearItems()
        self.scrollView.contentSize = CGSize.zero
        pushItems(titles: itemTitles)
    }

    public func pushItemWithTitles(title: [String]) {
        self.pushItems(titles: title)
    }

    public func popLast(count: Int = 1) {
        self.popLastItems(count: count)
    }

    public func popTo(n: Int) {
        guard n >= 0 && n < items.count else {
            return
        }
        let count = items.count - n
        self.popLastItems(count: count)
    }

    public func clearItems() {
        items.forEach { $0.removeFromSuperview() }
        items.removeAll()
        self.scrollView.contentSize = CGSize.zero
    }

    public func updateItem(at index: Int, color: UIColor) {
        guard index >= 0 && index < items.count else { return }
        items[index].customColor = color
    }

    private func popLastItems(count: Int) {
        guard count >= 1 && count <= items.count else {
            return
        }

        for _ in 0..<count {
            items.popLast()!.removeFromSuperview()
        }

        if !items.isEmpty {
            let item = items.last!
            item.setState(hasNext: false)
            item.snp.remakeConstraints({ (make) in
                make.top.bottom.equalToSuperview()
                make.centerY.equalToSuperview()
                rightConstraint = make.right.equalToSuperview().offset(-7).constraint
                if items.count > 1 {
                    make.left.equalTo(items[items.count - 2].snp.right).offset(8)
                } else {
                    make.left.equalTo(8)
                }
            })
            rightConstraint?.activate()
            UIView.animate(withDuration: 0.25, animations: {
                self.layoutIfNeeded()
            })
        }
    }

    private func pushItems(titles: [String]) {
        guard !titles.isEmpty else {
            return
        }
        if !items.isEmpty {
            rightConstraint?.deactivate()
            items.last!.setState(hasNext: true)
        }
        for i in 0..<titles.count {
            let title = titles[i]
            var initX = CGFloat(0)
            if !items.isEmpty {
                initX = items.last!.frame.origin.x
            }
            let breadcrumbItem = BreadcrumbItem(frame: CGRect(x: initX, y: 0, width: 0, height: self.frame.height))
            breadcrumbItem.tapItem = { [weak self] i in
                self?.didTapItem(index: i)
            }
            breadcrumbItem.button.tag = self.items.count
            breadcrumbItem.setItem(title: title, hasNext: !(i == titles.count - 1), index: self.items.count)
            self.scrollView.addSubview(breadcrumbItem)
            breadcrumbItem.snp.remakeConstraints({ (make) in
                make.top.bottom.equalToSuperview()
                make.centerY.equalToSuperview()
                if items.isEmpty {
                    make.left.equalTo(8)
                } else {
                    make.left.equalTo(items.last!.snp.right).offset(8)
                }
                if i == titles.count - 1 {
                    rightConstraint = make.right.equalTo(-7).constraint
                }
            })
            items.append(breadcrumbItem)
        }
        self.scrollToRight()
        if showAddAnimated == true {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.25, animations: {
                    self.layoutIfNeeded()
                })
            }
        }
    }

    public func scrollToRight(delay: Double = 0.25) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.microseconds(Int(delay * 1000))) {
            guard self.scrollView.contentSize.width > self.scrollView.bounds.width else {
                return
            }
            self.scrollView.setContentOffset(
                CGPoint(
                    x: self.scrollView.contentSize.width - self.scrollView.bounds.width,
                    y: 0
                ),
                animated: true
            )
        }
    }

    public func didTapItem(index: Int) {
        // 点击最新的不返回
        guard index != self.items.count - 1 else {
            return
        }
        self.delegate?.tapIndex(index: index)
    }
}

private final class BreadcrumbItem: UIView {
    let button = UIButton(type: .custom)

    let nextView = UIImageView()

    var tapItem: ((Int) -> Void)?

    private var index: Int = 0

    var title: String = ""

    var customColor: UIColor? {
        didSet {
            guard let color = customColor else { return }
            button.setTitleColor(color, for: .normal)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        nextView.image = Resources.breadcrumbNext
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        self.addSubview(button)
        self.button.snp.makeConstraints { (make) in
            make.left.centerY.equalToSuperview()
        }
        self.button.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)

        self.addSubview(nextView)
        nextView.snp.makeConstraints { (make) in
            make.left.equalTo(button.snp.right).offset(8)
            make.centerY.right.equalToSuperview()
            make.width.equalTo(7)
            make.height.equalTo(10)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setItem(title: String, hasNext: Bool, index: Int) {
        self.title = title
        button.setTitle(title, for: .normal)
        setState(hasNext: hasNext)
        self.index = index
    }

    func setState(hasNext: Bool) {
        if hasNext {
            button.setTitleColor(customColor ?? UIColor.ud.colorfulBlue, for: .normal)
            nextView.snp.updateConstraints({ (make) in
                make.width.equalTo(7)
            })
        } else {
            button.setTitleColor(customColor ?? UIColor.ud.N500, for: .normal)
            nextView.snp.updateConstraints({ (make) in
                make.width.equalTo(0)
            })
        }
    }

    @objc
    private func buttonClick() {
        self.tapItem?(index)
    }
}
