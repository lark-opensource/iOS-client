//
//  BitableHomeSegment.swift
//  SKBitable
//
//  Created by justin on 2023/9/18.
//

import Foundation
import UIKit
import LarkUIKit
import UniverseDesignColor


open class BitableHomeSegment: UIControl, Segment {
    public private(set) var contentView = UIStackView()
    private var selectLineFullWidth: CGFloat = 0
    private var bottomLineHeight: CGFloat = 2.0
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
    public var height: CGFloat = 40
    public var width: CGFloat = UIScreen.main.bounds.width

    public var titleFont: UIFont = UIFont.systemFont(ofSize: 14)
    public var titleFontBold: UIFont = UIFont.boldSystemFont(ofSize: 14)
    public var titleNormalColor = UDColor.textCaption
    public var titleSelectedColor = UDColor.textTitle
    
    private lazy var bottomLine : UIView = {
        let bottomLine = UIView()
        bottomLine.backgroundColor = UDColor.lineDividerDefault
        bottomLine.isUserInteractionEnabled = false
        return bottomLine
    }()
    
    private lazy var selectLine : UIView = {
        let selectLine = UIView()
        selectLine.layer.cornerRadius = 1
        selectLine.layer.masksToBounds = true
        selectLine.backgroundColor = UDColor.primaryContentDefault
        selectLine.isUserInteractionEnabled = false
        return selectLine
    }()

    public init() {
        super.init(frame: .zero)
        self.backgroundColor = UDColor.bgBody
        self.lineStyle = .adjust
        
        addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.bottom.equalToSuperview()
        }
        contentView.axis = .horizontal
        contentView.alignment = .fill
        contentView.distribution = .fillEqually
        contentView.spacing = CGFloat(0.0)
        
        
        addSubview(bottomLine)
        bottomLine.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1.0)
        }
        
        addSubview(selectLine)
        selectLine.snp.makeConstraints({ (make) in
            make.width.equalTo(0)
            make.height.equalTo(self.bottomLineHeight)
            make.bottom.equalToSuperview()
            make.centerX.equalTo(0)
        })
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
        refreshSelectLineFullWidth()
        setButtomView(index: currentSelectedIndex)
    }

    public func setItems(titles: [String]) {
        self.clearAllItems()
        addItems(titles: titles)
        resetItemTags()
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
        (0...buttonItems.count-1).forEach { i in
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
        let rectWidth = self.lineStyle == .default ? bottomWidth : self.selectLineFullWidth
        selectLine.snp.remakeConstraints { make in
            make.width.equalTo(rectWidth)
            make.centerX.equalTo(centerXLocation).offset(offsetX)
            make.height.equalTo(self.bottomLineHeight)
            make.bottom.equalToSuperview()
        }

        // 选中最接近当前偏移量的button
        let nearIndex = Int(round(offset))
        if nearIndex != currentSelectedIndex {
            setSelectedItem(index: nearIndex, isScrolling: true)
        }
    }

    @inline(__always)
    private func refreshSelectLineFullWidth() {
        if self.buttonItems.isEmpty {
            return
        }
        let count = CGFloat(self.buttonItems.count)
        selectLineFullWidth = width / count
    }

    private func setButtomView(index: Int) {
        var bottomWidth: CGFloat = 0
        if let titleLabel = self.buttonItems[index].titleLabel, let text = titleLabel.text {
            bottomWidth = text.lu.width(font: titleLabel.font, height: titleLabel.bounds.height)
        }

        let rectWidth = self.lineStyle == .default ? bottomWidth : self.selectLineFullWidth
        let centerXLocation = self.buttonItems[index].snp.centerX
        selectLine.snp.remakeConstraints { make in
            make.width.equalTo(rectWidth)
            make.centerX.equalTo(centerXLocation)
            make.height.equalTo(self.bottomLineHeight)
            make.bottom.equalToSuperview()
        }
    }

    public func updateUI(width: CGFloat) {
        self.width = width
        // 更新选中条宽度
        refreshSelectLineFullWidth()
        // 保证转动屏幕后的选中部分在中心处
        setSelectedItem(index: currentSelectedIndex)
    }
}
