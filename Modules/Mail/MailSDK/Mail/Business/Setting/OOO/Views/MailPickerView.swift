//
//  MailPickerView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/2/23.
//

import Foundation
import UIKit
import LarkUIKit

class MailOOODatePickerCell: UIView {
    let label = UILabel()
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
        // assertLog(self.bounds.width > 0 && self.bounds.height > 0)
        label.font = UIFont.systemFont(ofSize: 17)
        label.textAlignment = .center
        label.textColor = UIColor.ud.textTitle
        self.addSubview(label)
        label.snp.makeConstraints({make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        })
    }
}

class MailPickerView: UIView, InfiniteScrollViewDelegate, UIScrollViewDelegate {

    let firstScrollView = InfiniteScrollView()
    let secondScrollView = InfiniteScrollView()
    let thirdScrollView = InfiniteScrollView()
    var topGradientView: UIView = .init()
    var bottomGradientView: UIView = .init()
    /// picker的列数，子类复写可自定义列数
    var numberOfRow: Int = 5
    private let yInset: CGFloat = 8.0
    let invalidTextColor = UIColor.ud.textDisabled
    let normalTextColor = UIColor.ud.textTitle

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
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

        self.updateCellUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard Display.pad else {
            return
        }
        firstScrollViewFrame()
        secondScrollViewFrame()
        thirdScrollViewFrame()
    }

    func resetScrollViews() {
        firstScrollView.reset()
        secondScrollView.reset()
        thirdScrollView.reset()
        updateCellUI()
    }

    func killScroll() {
        self.firstScrollView.killScroll()
        self.secondScrollView.killScroll()
        self.thirdScrollView.killScroll()
    }

    private func updateCellUI() {
        self.layoutIfNeeded()
        [firstScrollView, secondScrollView, thirdScrollView].forEach({ scrollView in
            scrollView.layoutVisibleViews()
            self.regulateCenterCell(scrollView: scrollView)
        })
    }

    func scrollViewFrame(index: Int) -> CGRect {
        assertionFailure("子类实现")
        return .zero
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard self.superview != nil else {
            return
        }
    }

    // MARK: scroll view delegate
    func infiniteScrollView(scrollView: InfiniteScrollView, viewForIndex index: Int) -> UIView {
        let cell = MailOOODatePickerCell(frame: CGRect(x: 0.0, y: 0.0,
                                                width: scrollView.bounds.width / CGFloat(numberOfRow),
                                                height: scrollView.bounds.height))
        return cell
    }

    func infiniteScrollView(scrollView: InfiniteScrollView, willDisplay view: UIView, at index: Int) {
        assertionFailure("子类实现")
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            guard let scrollView = scrollView as? InfiniteScrollView else { return }
            self.scrollEndScroll(scrollView: scrollView)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let scrollView = scrollView as? InfiniteScrollView else { return }
        updateCellcellScale(scrollView: scrollView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
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
        scrollView.updateCellcellScale()
    }

    private func regulateCenterCell(scrollView: InfiniteScrollView) {
        guard let cell = scrollView.visibleViews.first(where: { $0.tag == 0 }) else {
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

    func centerCell(of scrollView: InfiniteScrollView) -> UIView? {
        guard let centerCell = scrollView.visibleViews.first(where: { (cell) -> Bool in
            let cellFrame = cell.convert(cell.bounds, to: self)
            return cellFrame.contains(scrollView.center)
        }) else {
            return nil
        }
        return centerCell
    }

    private func getCenterCellHeight() -> CGFloat {
        if let maxRowHeight = [firstScrollView, secondScrollView, thirdScrollView].map({ $0.bounds.height }).sorted().last {
            return maxRowHeight / CGFloat(numberOfRow)
        }
        return 48
    }

    private func getGradientCoverHeight() -> CGFloat {
        /// 渐变层覆盖除中间cell以外的选项
        let cellHeight = getCenterCellHeight()
        let coverHeight = (self.bounds.height - cellHeight) / 2
        return coverHeight > 0 ? coverHeight : 50
    }

    func addTopCover() -> UIView {
        // assertLog(self.bounds.height > 0 && self.bounds.width > 0)
        let gradientImage = UIImage.cd.verticalGradientImage(fromColor: UIColor.ud.bgBody.withAlphaComponent(1.0),
                                                             toColor: UIColor.ud.bgBody.withAlphaComponent(0.0),
                                                             size: CGSize(width: self.bounds.width, height: getGradientCoverHeight()),
                                                             locations: [0.0, 1.0])
        let gradientView = UIImageView(image: gradientImage)
        gradientView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        gradientView.isUserInteractionEnabled = false
        gradientView.sizeToFit()
        self.addSubview(gradientView)
        return gradientView
    }

    func addBottomCover() -> UIView {
        // assertLog(self.bounds.height > 0 && self.bounds.width > 0)

        let gradientImage = UIImage.cd.verticalGradientImage(fromColor: UIColor.ud.bgBody.withAlphaComponent(0.0),
                                                             toColor: UIColor.ud.bgBody.withAlphaComponent(1.0),
                                                             size: CGSize(width: Display.width, height: getGradientCoverHeight()),
                                                             locations: [0.0, 1.0])
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

    func changeCenterCellLabelColor(isInvalid: Bool, scrollView: InfiniteScrollView) {
        for view in scrollView.visibleViews {
            if let cell = view as? MailOOODatePickerCell {
                cell.label.textColor = normalTextColor
            }
        }
        guard let centerCell = self.centerCell(of: scrollView), let cell = centerCell as? MailOOODatePickerCell else {
            assertionFailure()
            return
        }
        let textColor = isInvalid ? invalidTextColor : normalTextColor
        cell.label.textColor = textColor
    }
}
