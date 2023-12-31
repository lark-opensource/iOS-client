//
//  PickerView.swift
//  Calendar
//
//  Created by zhuchao on 2017/12/22.
//  Copyright © 2017年 EE. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import CalendarFoundation

public final class GradientColorConfig {
    public var pickerTopGradient: (UIColor, UIColor)
    public var pickerBottomGradient: (UIColor, UIColor)
    init() {
        pickerTopGradient = (DarkMode.pickerTopGradient.top,
                             DarkMode.pickerTopGradient.bottom)
        pickerBottomGradient = (DarkMode.pickerBottomGradient.top,
                                DarkMode.pickerBottomGradient.bottom)
    }
}

open class PickerView: UIView, InfiniteScrollViewDelegate, UIScrollViewDelegate {

    public let firstScrollView = InfiniteScrollView()
    public let secondScrollView = InfiniteScrollView()
    public let thirdScrollView = InfiniteScrollView()
    public var gradientColorConfig = GradientColorConfig() {
        didSet {
            self.topGradientView.removeFromSuperview()
            self.bottomGradientView.removeFromSuperview()
            self.topGradientView = self.addTopCover()
            self.bottomGradientView = self.addBottomCover()
        }
    }
    var topGradientView: UIView = .init()
    var bottomGradientView: UIView = .init()
    private let yInset: CGFloat = 8.0

    private let cellScale: CGFloat = 0.85

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    func commonInit() {
        self.backgroundColor = UIColor.ud.bgBody
        self.addFirstScrollView()
        self.addSecondScrollView()
        self.addThirdScrollView()
        self.topGradientView = self.addTopCover()
        self.bottomGradientView = self.addBottomCover()
        addSeparateLines()
        self.updateCellUI()
    }

    public func addSeparateLines() {
        func makeLine() -> UIView {
            let line = UIView()
            line.bounds = CGRect(origin: .zero, size: CGSize(width: bounds.width, height: 0.5))
            line.backgroundColor = UIColor.ud.lineBorderCard
            return line
        }
        let topLine = makeLine()
        topLine.frame = CGRect(origin: CGPoint(x: 0, y: 55.5), size: topLine.bounds.size)
        addSubview(topLine)

        let bottomLine = makeLine()
        bottomLine.frame = CGRect(origin: CGPoint(x: 0, y: 102.5), size: topLine.bounds.size)
        addSubview(bottomLine)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard Display.pad else {
            return
        }
        firstScrollViewFrame()
        secondScrollViewFrame()
        thirdScrollViewFrame()
    }

    public func resetScrollViews() {
        self.firstScrollView.reset()
        self.secondScrollView.reset()
        self.thirdScrollView.reset()
        self.updateCellUI()
    }

    public func killScroll() {
        self.firstScrollView.killScroll()
        self.secondScrollView.killScroll()
        self.thirdScrollView.killScroll()
    }

    private func updateCellUI() {
        self.layoutIfNeeded()
        self.updateCellcellScale(scrollView: self.thirdScrollView)
        self.updateCellcellScale(scrollView: self.firstScrollView)
        self.updateCellcellScale(scrollView: self.secondScrollView)
        self.regulateCenterCell(scrollView: self.firstScrollView)
        self.regulateCenterCell(scrollView: self.secondScrollView)
        self.regulateCenterCell(scrollView: self.thirdScrollView)
    }

    open func scrollViewFrame(index: Int) -> CGRect {
        assertionFailureLog("子类实现")
        return .zero
    }

    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard self.superview != nil else {
            return
        }
    }

    // MARK: scroll view delegate
    public func infiniteScrollView(scrollView: InfiniteScrollView, viewForIndex index: Int) -> UIView {
        let cell = DatePickerCell(frame: CGRect(x: 0.0, y: 0.0, width: scrollView.bounds.width / 3.0, height: scrollView.bounds.height))
        cell.label.transform = CGAffineTransform(scaleX: self.cellScale, y: self.cellScale).rotated(by: -(CGFloat.pi / 2.0))
        return cell
    }

    open func infiniteScrollView(scrollView: InfiniteScrollView, willDisplay view: UIView, at index: Int) {
        assertionFailureLog("子类实现")
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            guard let scrollView = scrollView as? InfiniteScrollView else { return }
            self.scrollEndScroll(scrollView: scrollView)
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let scrollView = scrollView as? InfiniteScrollView else { return }
        self.updateCellcellScale(scrollView: scrollView)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let scrollView = scrollView as? InfiniteScrollView else { return }
        self.scrollEndScroll(scrollView: scrollView)
    }

    open func scrollEndScroll(scrollView: InfiniteScrollView) {
        guard let centerCell = self.centerCell(of: scrollView) else {
            return
        }
        self.recenterDatePickerCell(scrollView: scrollView, centerCellFrame: centerCell.convert(centerCell.bounds, to: self))
    }

    private func recenterDatePickerCell(scrollView: InfiniteScrollView, centerCellFrame: CGRect) {
        let distance = scrollView.center.y - (centerCellFrame.origin.y + centerCellFrame.size.height / 2.0)
        var offSet = scrollView.contentOffset
        offSet.x -= distance
        scrollView.setContentOffset(offSet, animated: true)
    }

    private func updateCellcellScale(scrollView: InfiniteScrollView) {
        let cellScaleRect = scrollView.frame.insetBy(dx: 0, dy: 40)
        for cell in scrollView.visibleViews {
            let cellFrame = cell.convert(cell.bounds, to: self)
            let intersection = cellFrame.intersection(cellScaleRect)
            guard intersection.size.height > 0 else { continue }
            let calculatedcellScale = cellScale + (1.0 - self.cellScale) * intersection.size.height / cellFrame.size.height
            guard let cell = cell as? DatePickerCell else { continue }
            let transform = CGAffineTransform(scaleX: calculatedcellScale, y: calculatedcellScale).rotated(by: -(CGFloat.pi / 2.0))
            guard cell.label.transform != transform else { continue }
            cell.label.transform = transform
        }
    }

    private func regulateCenterCell(scrollView: InfiniteScrollView) {
        guard let cell = scrollView.visibleViews.first(where: { $0.tag == 0 }) else {
            assertionFailureLog()
            return
        }
        let cellFrame = cell.convert(cell.bounds, to: self)
        let distance = scrollView.center.y - (cellFrame.origin.y + cellFrame.size.height / 2.0)
        var offSet = scrollView.contentOffset
        offSet.x -= distance
        scrollView.setContentOffset(offSet, animated: false)
        return
    }

    private func center(rect: CGRect) -> CGPoint {
        return CGPoint(x: rect.origin.x + rect.size.width / 2.0, y: rect.origin.y + rect.size.height / 2.0)
    }

    public func centerCell(of scrollView: InfiniteScrollView) -> UIView? {
        guard let centerCell = scrollView.visibleViews.first(where: { (cell) -> Bool in
            let cellFrame = cell.convert(cell.bounds, to: self)
            return cellFrame.contains(scrollView.center)
        }) else {
            return nil
        }
        return centerCell
    }

    func addTopCover() -> UIView {
        assertLog(self.bounds.height > 0 && self.bounds.width > 0)
        let gradientImage = UIImage.cd.verticalGradientImage(fromColor: gradientColorConfig.pickerTopGradient.0,
                                                             toColor: gradientColorConfig.pickerTopGradient.1,
                                                             size: CGSize(width: self.bounds.width, height: 50),
                                                             locations: [0.3, 1.0])
        let gradientView = UIImageView(image: gradientImage)
        gradientView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        gradientView.isUserInteractionEnabled = false
        gradientView.sizeToFit()
        self.addSubview(gradientView)
        return gradientView
    }

    func addBottomCover() -> UIView {
        assertLog(self.bounds.height > 0 && self.bounds.width > 0)
        let gradientImage = UIImage.cd.verticalGradientImage(fromColor: gradientColorConfig.pickerBottomGradient.0,
                                                             toColor: gradientColorConfig.pickerBottomGradient.1,
                                                             size: CGSize(width: bounds.width, height: 50),
                                                             locations: [0.0, 0.7])
        let gradientView = UIImageView(image: gradientImage)
        gradientView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        gradientView.isUserInteractionEnabled = false
        gradientView.sizeToFit()
        var frame = gradientView.frame
        frame.origin.y = self.bounds.height - frame.height
        gradientView.frame = frame
        self.addSubview(gradientView)
        return gradientView
    }

    func firstScrollViewFrame() {
        guard self.bounds.width > 0 else {
            return
        }
        let firstFrame = self.scrollViewFrame(index: 1).insetBy(dx: 0, dy: self.yInset)
        firstScrollView.frame = CGRect(x: 0, y: 0, width: firstFrame.width, height: firstFrame.height)
        firstScrollView.center = self.center(rect: firstFrame)
    }

    func addFirstScrollView() {
        let firstFrame = self.scrollViewFrame(index: 1).insetBy(dx: 0, dy: self.yInset)
        firstScrollView.frame = CGRect(x: 0, y: 0, width: firstFrame.height, height: firstFrame.width)
        firstScrollView.center = self.center(rect: firstFrame)
        firstScrollView.dataSource = self
        firstScrollView.delegate = self
        firstScrollView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2.0)
        self.addSubview(firstScrollView)
    }

    func secondScrollViewFrame() {
        guard self.bounds.width > 0 else {
            return
        }
        let secondFrame = self.scrollViewFrame(index: 2).insetBy(dx: 0, dy: self.yInset)
        secondScrollView.frame = CGRect(x: 0, y: 0, width: secondFrame.width, height: secondFrame.height)
        secondScrollView.center = self.center(rect: secondFrame)
    }

    func addSecondScrollView() {
        let secondFrame = self.scrollViewFrame(index: 2).insetBy(dx: 0, dy: self.yInset)
        secondScrollView.frame = CGRect(x: 0, y: 0, width: secondFrame.height, height: secondFrame.width)
        secondScrollView.center = self.center(rect: secondFrame)
        secondScrollView.dataSource = self
        secondScrollView.delegate = self
        secondScrollView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2.0)
        self.addSubview(secondScrollView)
    }

    func thirdScrollViewFrame() {
        guard self.bounds.width > 0 else {
            return
        }
        let thirdFrame = self.scrollViewFrame(index: 3).insetBy(dx: 0, dy: self.yInset)
        thirdScrollView.frame = CGRect(x: 0, y: 0, width: thirdFrame.width, height: thirdFrame.height)
        thirdScrollView.center = self.center(rect: thirdFrame)
    }

    func addThirdScrollView() {
        let thirdFrame = self.scrollViewFrame(index: 3).insetBy(dx: 0, dy: self.yInset)
        thirdScrollView.frame = CGRect(x: 0, y: 0, width: thirdFrame.height, height: thirdFrame.width)
        thirdScrollView.center = self.center(rect: thirdFrame)
        thirdScrollView.dataSource = self
        thirdScrollView.delegate = self
        thirdScrollView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2.0)
        self.addSubview(thirdScrollView)
    }

    public func recycledNumber(withBenchmark mark: Int, offSet: Int, modNumber: Int) -> Int {
        var mark = (mark + offSet) % modNumber
        if mark < 0 { mark += modNumber }
        if mark == 0 {
            mark = modNumber
        }
        return mark
    }

    public func changeTextColor(isInvalid: Bool) {
        changeCenterCellLabelColor(isInvalid: isInvalid, scrollView: firstScrollView)
        changeCenterCellLabelColor(isInvalid: isInvalid, scrollView: secondScrollView)
        changeCenterCellLabelColor(isInvalid: isInvalid, scrollView: thirdScrollView)
    }

    func changeCenterCellLabelColor(isInvalid: Bool, scrollView: InfiniteScrollView) {
        for view in scrollView.visibleViews {
            if let cell = view as? DatePickerCell {
                cell.label.textColor = UIColor.ud.textTitle
            }
        }
        guard let centerCell = self.centerCell(of: scrollView), let cell = centerCell as? DatePickerCell else {
            assertionFailureLog()
            return
        }
        let textColor = isInvalid ? UIColor.ud.colorfulRed : UIColor.ud.textTitle
        cell.label.textColor = textColor
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            if #available(iOS 13.0, *) {
                if let previousTraitCollection = previousTraitCollection,
                   previousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
                   self.topGradientView.removeFromSuperview()
                   self.bottomGradientView.removeFromSuperview()
                   self.topGradientView = self.addTopCover()
                   self.bottomGradientView = self.addBottomCover()
                }
            }
        }

}

public final class DatePickerCell: UIView {
    public let label = UILabel()
    var dateComponent = DateComponents()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    func commonInit() {
        // 初始化需要有frame
        assertLog(self.bounds.width > 0 && self.bounds.height > 0)
        label.font = UIFont.systemFont(ofSize: 20)
        label.textAlignment = .center
        label.textColor = UIColor.ud.textTitle
        self.addSubview(label)
        label.snp.makeConstraints({make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        })
    }
}

public protocol PickerColumnScrollViewDelegate: AnyObject {
    func columnView(columnView: PickerColumnScrollView, willDisplay cell: PickerColumnCell, at index: Int)
}

public class PickerColumnScrollView: UIView, InfiniteScrollViewDelegate, UIScrollViewDelegate {

    let scrollView = InfiniteScrollView()

    private let cellScale: CGFloat = 0.85

    weak var delegate: PickerColumnScrollViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutScrollView(scrollView)
    }

    private func layoutScrollView(_ scrollView: InfiniteScrollView) {
        scrollView.frame = CGRect(x: 0, y: 0, width: self.bounds.height, height: self.bounds.width)
        scrollView.dataSource = self
        scrollView.delegate = self
        scrollView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2.0)
        scrollView.center = CGPoint(x: self.bounds.width / 2.0, y: self.bounds.height / 2.0)
        self.addSubview(scrollView)
        DispatchQueue.main.async {
            self.updateCellcellScale(scrollView: scrollView)
            self.regulateCenterCell(scrollView: scrollView)
        }
    }

    // MARK: scroll view delegate
    public func infiniteScrollView(scrollView: InfiniteScrollView, viewForIndex index: Int) -> UIView {
        let cell = PickerColumnCell(frame: CGRect(x: 0.0, y: 0.0, width: scrollView.bounds.width / 3.0, height: scrollView.bounds.height))
        cell.label.transform = CGAffineTransform(scaleX: self.cellScale, y: self.cellScale).rotated(by: -(CGFloat.pi / 2.0))
        return cell
    }

    public func infiniteScrollView(scrollView: InfiniteScrollView, willDisplay view: UIView, at index: Int) {
        guard let cell = view as? PickerColumnCell else {
            return
        }
        delegate?.columnView(columnView: self, willDisplay: cell, at: index)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            guard let scrollView = scrollView as? InfiniteScrollView else { return }
            self.scrollEndScroll(scrollView: scrollView)
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let scrollView = scrollView as? InfiniteScrollView else { return }
        self.updateCellcellScale(scrollView: scrollView)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let scrollView = scrollView as? InfiniteScrollView else { return }
        self.scrollEndScroll(scrollView: scrollView)
    }

    func scrollEndScroll(scrollView: InfiniteScrollView) {
        guard let centerCell = self.centerCell(of: scrollView) else {
            return
        }
        self.recenterDatePickerCell(scrollView: scrollView, centerCellFrame: centerCell.convert(centerCell.bounds, to: self))
    }

    private func recenterDatePickerCell(scrollView: InfiniteScrollView, centerCellFrame: CGRect) {
        let distance = scrollView.center.y - (centerCellFrame.origin.y + centerCellFrame.size.height / 2.0)
        var offSet = scrollView.contentOffset
        offSet.x -= distance
        scrollView.setContentOffset(offSet, animated: true)
    }

    private func updateCellcellScale(scrollView: InfiniteScrollView) {
        let cellScaleRect = scrollView.frame.insetBy(dx: 0, dy: 40)
        guard let cells = scrollView.visibleViews as? [PickerColumnCell] else {
            return
        }
        for cell in cells {
            let cellFrame = cell.convert(cell.bounds, to: self)
            let intersection = cellFrame.intersection(cellScaleRect)
            guard intersection.size.height > 0 else { continue }
            let calculatedcellScale = cellScale + (1.0 - self.cellScale) * intersection.size.height / cellFrame.size.height
            let transform = CGAffineTransform(scaleX: calculatedcellScale, y: calculatedcellScale).rotated(by: -(CGFloat.pi / 2.0))
            guard cell.label.transform != transform else { continue }
            cell.label.transform = transform
        }
    }

    private func regulateCenterCell(scrollView: InfiniteScrollView) {
        guard let cell = scrollView.visibleViews.first(where: { $0.tag == 0 }) else {
            assertionFailureLog()
            return
        }
        let cellFrame = cell.convert(cell.bounds, to: self)
        let distance = scrollView.center.y - (cellFrame.origin.y + cellFrame.size.height / 2.0)
        var offSet = scrollView.contentOffset
        offSet.x -= distance
        scrollView.setContentOffset(offSet, animated: false)
        return
    }

    func centerCell(of scrollView: InfiniteScrollView) -> UIView? {
        guard let centerCell = scrollView.visibleViews.first(where: { (cell) -> Bool in
            let cellFrame = cell.convert(cell.bounds, to: self)
            return cellFrame.contains(scrollView.center)
        }) else {
            return nil
        }
        return centerCell
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class PickerColumnCell: UIView {
    let label = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    func commonInit() {
        // 初始化需要有frame
        assertLog(self.bounds.width > 0 && self.bounds.height > 0)
        label.font = UIFont.systemFont(ofSize: 20)
        label.textAlignment = .center
        backgroundColor = .clear
        label.frame = CGRect(x: 0, y: 0, width: self.bounds.height + 35, height: self.bounds.width + 20)
        label.center = CGPoint(x: self.bounds.width / 2.0, y: self.bounds.height / 2.0)
        self.addSubview(label)
    }
}

public final class NumberColumnView: PickerColumnScrollView, PickerColumnScrollViewDelegate {

    private let currentNumber: Int
    private let modNumber: Int
    private let interval: Int
    private let is12HourStyle: Bool
    private let isDoubleDigit: Bool
    public var selectedAction: ((Int) -> Void)?

    public init(frame: CGRect,
         currentNumber: Int,
         modNumber: Int,
         interval: Int,
         isDoubleDigit: Bool, is12HourStyle: Bool = false) {
        self.currentNumber = currentNumber
        self.isDoubleDigit = isDoubleDigit
        self.modNumber = modNumber
        self.interval = interval
        self.is12HourStyle = is12HourStyle
        super.init(frame: frame)
        self.delegate = self
    }

    public func changeColor(isInvalid: Bool) {
        for view in scrollView.visibleViews {
            if let cell = view as? PickerColumnCell {
                cell.label.textColor = UIColor.ud.textTitle
            }
        }
        guard let centerCell = self.centerCell(of: scrollView), let cell = centerCell as? PickerColumnCell else {
            assertionFailure()
            return
        }
        let textColor = isInvalid ? UIColor.ud.colorfulRed : UIColor.ud.textTitle
        cell.label.textColor = textColor
    }

    public func getCenterCellText() -> Int? {
        guard let centerCell = self.centerCell(of: scrollView), let cell = centerCell as? PickerColumnCell else {
            assertionFailure()
            return nil
        }
        guard let text = cell.label.text, let result = Int(text) else {
            return nil
        }
        return result
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func numberWithOffset(_ offSet: Int) -> Int {
        var mark = (currentNumber + offSet) % modNumber
        if mark < 0 { mark += modNumber }
        if is12HourStyle, mark == 0 {
            mark = modNumber
        }
        return mark
    }

    public func columnView(columnView: PickerColumnScrollView,
                    willDisplay cell: PickerColumnCell,
                    at index: Int) {
        let number = numberWithOffset(index * interval)
        let text: String
        if isDoubleDigit {
            text = String(format: "%02d", number)
        } else {
            text = "\(number)"
        }
        cell.label.text = text
    }

    public override func scrollEndScroll(scrollView: InfiniteScrollView) {
        super.scrollEndScroll(scrollView: scrollView)
        guard let centerCell = self.centerCell(of: scrollView) else {
            return
        }
        selectedAction?(numberWithOffset(centerCell.tag * interval))
    }

    public func selectedNumber() -> Int {
        super.scrollEndScroll(scrollView: scrollView)
        guard let centerCell = self.centerCell(of: scrollView) else {
            assertionFailureLog()
            return 0
        }
        return numberWithOffset(centerCell.tag * interval)
    }
}
