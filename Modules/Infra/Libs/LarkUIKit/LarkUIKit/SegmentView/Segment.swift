//
//  Segment.swift
//  LarkUIKit
//
//  Created by 吴子鸿 on 2017/7/24.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

@objc
public protocol Segment {
    /*
     当前点击了第几个button，用于响应value changed 事件后获取数据
     **/
    var currentSelectedIndex: Int { get }

    var height: CGFloat { get set }
    var width: CGFloat { get set }

    /*
     清理当前导航的items
     **/
    func clearAllItems()

    /*
     添加导航条的items
     **/
    func addItems(titles: [String])

    /*
     清空并重新设置当前导航条的items
     **/
    func setItems(titles: [String])

    /*
     设置当前选中的index
     **/
    func setSelectedItem(index: Int, isScrolling: Bool)

    /*
     移除第at个item
     **/
    func removeItem(at: Int)

    /*
     插入title到at
     **/
    func insertItem(title: String, at: Int)

    /*
     获取到当前的Control
     **/
    func getControlView() -> UIControl

    /*
     设置导航条偏移，用于显示动画效果，子类需实现
     **/
    func setOffset(offset: CGFloat, isDragging: Bool)

    /*
     在屏幕旋转后更新UI
    **/
    func updateUI(width: CGFloat)

    func updateItem(title: String, index: Int)

    var tapTo: ((Int) -> Void)? { get set }
}

enum Cons {
    static var width: CGFloat { 2.0 }
    static var height: CGFloat { 2.0 }
}

open class StandardSegment: UIControl, Segment {
    public private(set) var contentView = UIStackView()
    private var horizontalInset: CGFloat = 16
    private var bottomViewFullWidth: CGFloat = 0
    public var buttonItems: [UIButton] = []
    public var tapTo: ((Int) -> Void)?

    /// index变化回调，第一个参数是oldValue, 第二个参数是newValue
    public var selectedIndexDidChangeBlock: ((Int, Int) -> Void)?
    public var selectedIndexWillChangeBlock: ((Int, Int) -> Void)?

    public var currentSelectedIndex = 0 {
        didSet {
            selectedIndexDidChangeBlock?(oldValue, currentSelectedIndex)
        }
    }

    // config
    public enum BottomLineStyle {
        case `default`, adjust
    }

    public var lineStyle: StandardSegment.BottomLineStyle = .default
    public var height: CGFloat = 36
    public var width: CGFloat = UIScreen.main.bounds.width {
        didSet { spacing = 32 / 750 * width }
    }

    public var titleFont: UIFont = UIFont.systemFont(ofSize: 15)
    public var titleFontBold: UIFont = UIFont.boldSystemFont(ofSize: 15)
    public var titleNormalColor = UIColor.ud.N900
    public var titleSelectedColor = UIColor.ud.colorfulBlue
    public var bottomViewColor = UIColor.ud.L300 {
        didSet {
            buttomView.backgroundColor = bottomViewColor
        }
    }

    public var spacing = 32 / 750 * UIScreen.main.bounds.size.width {
        didSet { contentView.spacing = spacing }
    }

    var buttomView: UIView = UIView()

    public init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.N00

        addSubview(buttomView)
        buttomView.snp.makeConstraints({ (make) in
            make.width.equalTo(0)
            make.height.equalTo(Cons.height)
            make.bottom.equalToSuperview()
            make.centerX.equalTo(0)
        })
        setupBottomSubViews()

        addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(horizontalInset)
            $0.top.bottom.equalToSuperview()
        }

        contentView.axis = .horizontal
        contentView.alignment = .fill
        contentView.distribution = .fillEqually
        contentView.spacing = spacing
    }

    public convenience init(withHeight height: CGFloat) {
        self.init()
        self.height = height
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func getControlView() -> UIControl {
        return self
    }

    public func addItems(titles: [String]) {
        for i in 0..<titles.count {
            let button = createButton()
            button.setTitle(titles[i], for: .normal)
            contentView.addArrangedSubview(button)
            self.buttonItems.append(button)
        }
        setSelectedItem(index: currentSelectedIndex)
        resetItemTags()
    }

    private func resetItemTags() {
        for (index, item) in buttonItems.enumerated() {
            item.tag = index
        }
        refreshBottomViewFullWidth()
        setButtomView(index: currentSelectedIndex)
    }

    public func setItems(titles: [String]) {
        self.spacing = 32 / 750 * width
        self.clearAllItems()
        addItems(titles: titles)
        resetItemTags()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        let rect = self.buttomView.bounds
        let maskPath = UIBezierPath(roundedRect: rect,
                                    byRoundingCorners: [UIRectCorner.topLeft, UIRectCorner.topRight],
                                    cornerRadii: CGSize(width: 2.0, height: 2.0))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = rect
        maskLayer.path = maskPath.cgPath
        self.buttomView.layer.mask = maskLayer
        self.buttomView.clipsToBounds = true
    }

    public func updateItem(title: String, index: Int) {
        if index < 0 || index >= buttonItems.count {
            return
        }

        let button = self.buttonItems[index]
        button.setTitle(title, for: .normal)
        resetItemTags()
    }

    public func setSelectedItem(index: Int, isScrolling: Bool = false) {
        guard index < buttonItems.count && index >= 0 else {
            return
        }
        buttonItems.forEach { $0.setTitleColor(self.titleNormalColor, for: .normal) }
        buttonItems[index].setTitleColor(self.titleSelectedColor, for: .normal)
        (0...buttonItems.count-1).map { i in
            buttonItems[i].titleLabel?.font =  i == index ? self.titleFontBold : self.titleFont
        }
        currentSelectedIndex = index
        if !isScrolling {
            setButtomView(index: index)
        }
    }

    public func clearAllItems() {
        while !buttonItems.isEmpty {
            removeItem(at: buttonItems.count - 1)
        }
    }

    public func removeItem(at: Int) {
        guard at < self.buttonItems.count && at >= 0 else {
            return
        }
        self.buttonItems.remove(at: at).removeFromSuperview()

        resetItemTags()

        if currentSelectedIndex >= at {
            setSelectedItem(index: currentSelectedIndex - 1)
        } else {
            setSelectedItem(index: currentSelectedIndex)
        }
    }

    public func insertItem(title: String, at: Int) {
        guard at >= 0 else {
            return
        }
        let button = createButton()
        button.setTitle(title, for: .normal)
        self.addSubview(button)
        if at < self.buttonItems.count {
            self.buttonItems.insert(button, at: at)
        } else {
            self.buttonItems.append(button)
        }
        if currentSelectedIndex >= at {
            setSelectedItem(index: currentSelectedIndex + 1)
        } else {
            setSelectedItem(index: currentSelectedIndex)
        }
    }

    /*
     按钮点击后触发事件
     **/
    @objc
    private func tapButton(sender: UIButton) {
        self.selectedIndexWillChangeBlock?(currentSelectedIndex, sender.tag)
        self.tapTo?(sender.tag)
    }

    private func createButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(tapButton(sender:)), for: .touchUpInside)
        button.titleLabel?.font = self.titleFont
        button.setTitleColor(self.titleNormalColor, for: .normal)
        return button
    }

    public func setOffset(offset: CGFloat, isDragging: Bool) {
        // 设置buttomView偏移量参考的item index
        let index = Int(floor(offset))
        // 控制滑动范围
        guard offset >= 0 &&
            index + 1 <= self.buttonItems.count else {
            return
        }
        let hasNextBtn = index < self.buttonItems.count - 1
        let ratio = offset - CGFloat(index)
        let offsetX = hasNextBtn ? (self.buttonItems[index + 1].center.x - self.buttonItems[index].center.x) * ratio : 0
        let leftButtonWidth = self.buttonItems[index].titleLabel?.bounds.width ?? 0
        let rightButtonWidth = hasNextBtn ? (self.buttonItems[index + 1].titleLabel?.bounds.width ?? 0) : 0
        let bottomWidth = leftButtonWidth + (rightButtonWidth - leftButtonWidth) * ratio
        /* 避免在屏幕旋转的时候导致滑动条划出屏幕或者划到其他标签的问题 */
        let centerXLocation = self.buttonItems[index].snp.centerX
        let rectWidth = self.lineStyle == .default ? bottomWidth : self.bottomViewFullWidth
        buttomView.snp.remakeConstraints { make in
            make.width.equalTo(rectWidth)
            make.centerX.equalTo(centerXLocation).offset(offsetX)
            make.height.equalTo(Cons.height)
            make.bottom.equalToSuperview()
        }

        // 选中最接近当前偏移量的button
        let nearIndex = Int(round(offset))
        if nearIndex != currentSelectedIndex {
            setSelectedItem(index: nearIndex, isScrolling: true)
        }
    }

    @inline(__always)
    private func refreshBottomViewFullWidth() {
        let count = CGFloat(self.buttonItems.count)
        bottomViewFullWidth = (width - 2 * horizontalInset - (count - 1) * spacing) / count
    }

    private func setButtomView(index: Int) {
        var bottomWidth: CGFloat = 0
        if let titleLabel = self.buttonItems[index].titleLabel, let text = titleLabel.text {
            bottomWidth = text.lu.width(font: titleLabel.font, height: titleLabel.bounds.height)
        }

        let rectWidth = self.lineStyle == .default ? bottomWidth : self.bottomViewFullWidth
        let centerXLocation = self.buttonItems[index].snp.centerX
        buttomView.snp.remakeConstraints { make in
            make.width.equalTo(rectWidth)
            make.centerX.equalTo(centerXLocation)
            make.height.equalTo(Cons.height)
            make.bottom.equalToSuperview()
        }
    }

    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.layer.shadowColor = UIColor.ud.color(38, 50, 71, 0.05).cgColor
        self.layer.shadowOpacity = 1
        self.layer.shadowOffset = CGSize(width: 0, height: 1.5)
        self.layer.shadowPath = UIBezierPath(rect: CGRect(x: 0, y: rect.height - 3, width: rect.width, height: 3)).cgPath
    }

    public func updateUI(width: CGFloat) {
        self.width = width
        // 更新选中条宽度
        refreshBottomViewFullWidth()
        // 保证转动屏幕后的选中部分在中心处
        setSelectedItem(index: currentSelectedIndex)
    }

    private func setupBottomSubViews() {
        buttomView.backgroundColor = .clear

        let leftCornerView = createLeftCornerView()
        leftCornerView.backgroundColor = UIColor.ud.primaryContentDefault
        buttomView.addSubview(leftCornerView)
        leftCornerView.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
            make.width.equalTo(Cons.width)
            make.height.equalTo(Cons.height)
        }

        let rightCornerView = createRightCornerView()
        rightCornerView.backgroundColor = UIColor.ud.primaryContentDefault
        buttomView.addSubview(rightCornerView)
        rightCornerView.snp.makeConstraints { make in
            make.right.top.equalToSuperview()
            make.width.equalTo(Cons.width)
            make.height.equalTo(Cons.height)
        }

        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.primaryContentDefault
        buttomView.addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.left.equalTo(leftCornerView.snp.right)
            make.right.equalTo(rightCornerView.snp.left)
            make.top.equalToSuperview()
            make.height.equalTo(Cons.height)
        }
    }

    private func createLeftCornerView() -> UIView {
        let rect = CGRect(x: 0, y: 0, width: Cons.width, height: Cons.height)
        let maskPath = UIBezierPath(arcCenter: CGPoint(x: Cons.width, y: Cons.height),
                                    radius: Cons.height,
                                    startAngle: CGFloat(Double.pi),
                                    endAngle: CGFloat(Double.pi / 2 * 3),
                                    clockwise: true)
        maskPath.addLine(to: CGPoint(x: Cons.width, y: Cons.height))

        let maskLayer = CAShapeLayer()
        maskLayer.frame = rect
        maskLayer.path = maskPath.cgPath

        let view = UIView()
        view.layer.mask = maskLayer
        return view
    }

    private func createRightCornerView() -> UIView {
        let rect = CGRect(x: 0, y: 0, width: Cons.width, height: Cons.height)
        let maskPath = UIBezierPath(arcCenter: CGPoint(x: 0, y: Cons.height),
                                    radius: Cons.height,
                                    startAngle: CGFloat(Double.pi / 2 * 3),
                                    endAngle: 0,
                                    clockwise: true)
        maskPath.addLine(to: CGPoint(x: 0, y: Cons.height))

        let maskLayer = CAShapeLayer()
        maskLayer.frame = rect
        maskLayer.path = maskPath.cgPath

        let view = UIView()
        view.layer.mask = maskLayer
        return view
    }
}
