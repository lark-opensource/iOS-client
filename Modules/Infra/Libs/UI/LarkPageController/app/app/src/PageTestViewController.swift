//
//  TestViewController.swift
//  PageListTest
//
//  Created by kongkaikai on 2018/12/10.
//  Copyright © 2018 kongkaikai. All rights reserved.
//

import Foundation
import UIKit
import LarkPageController

class TestPageSegmentCell: PageSegmentCell {
    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(label)
        label.textAlignment = .center
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var frame: CGRect {
        didSet {
            label.frame = self.bounds
        }
    }
}

class PageTestViewController: PageViewController {
    var count: Int = Int.random(in: 10...40)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.dataSource = self
        self.register(
            PageTestTableController.self,
            forControllerWithReuseIdentifier: NSStringFromClass(PageTestTableController.self))
        self.segmentHeight = 40
        self.topOffset = 15
        self.headerMinHeight = 20

        self.headerView.backgroundColor = UIColor.red.withAlphaComponent(0.4)

        let segmentControl = PageSegmentControl()
        segmentControl.register(
            TestPageSegmentCell.self,
            forCellWithReuseIdentifier: NSStringFromClass(TestPageSegmentCell.self))
        segmentControl.dataSource = self

        let item = segmentControl.itemsView
        if let superView = segmentControl.itemsView.superview {
            func makeConstraints(_ attribute: NSLayoutConstraint.Attribute,
                                 constant: CGFloat,
                                 toItem: Any?) -> NSLayoutConstraint {
                return NSLayoutConstraint(
                    item: item,
                    attribute: attribute,
                    relatedBy: .equal,
                    toItem: toItem,
                    attribute: attribute,
                    multiplier: 1,
                    constant: constant)
            }

            item.addConstraint(makeConstraints(.height, constant: 28, toItem: nil))
            item.superview?.addConstraints(
                [makeConstraints(.left, constant: 0, toItem: superView),
                 makeConstraints(.right, constant: 0, toItem: superView),
                 makeConstraints(.bottom, constant: 0, toItem: superView)])
        }

        self.segmentControl = segmentControl

        // 取消下面代码的注释显示EmptyView
        // self.emptyView.isHidden = false
        // self.emptyView.backgroundColor = UIColor.lu.red1

        let tap = UITapGestureRecognizer(target: self, action: #selector(close_))
        tap.numberOfTapsRequired = 1
        headerView.addGestureRecognizer(tap)
    }

    @objc
    private func close_() {
        playDisApperAnimation(autoDismiss: true, completion: nil)
    }
}

extension PageTestViewController: PageViewControllerDataSource {
    func numberOfPage(in segmentController: PageViewController) -> Int {
        return count
    }

    func segmentController(_ controller: PageViewController,
                           controllerAt index: Int) -> PageViewController.InnerController? {
        return controller.dequeueReusableConrtoller(
            withReuseIdentifier: NSStringFromClass(PageTestTableController.self))
    }
}

extension PageTestViewController: SegmentControlDataSource {
    func numberOfPage(in control: PageSegmentControl) -> Int {
        return count
    }

    func segmentControl(_ control: PageSegmentControl, cellAt index: Int) -> PageSegmentCell {
        let cell = control.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(TestPageSegmentCell.self),
                                               for: index)
        cell.backgroundColor = UIColor(
            red: .random(in: 0.5...1),
            green: .random(in: 0.5...1),
            blue: .random(in: 0.5...1), alpha: 1)
        (cell as? TestPageSegmentCell)?.label.text = "\(index)"
        return cell
    }
}
