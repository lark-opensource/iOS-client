//
//  UDButtonGroupView.swift
//  UniverseDesignButton
//
//  Created by Hayden on 2023/2/17.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignFont

public class UDButtonGroupView: UIStackView {

    /// ButtonGroup 中按钮的优先级
    /// - NOTE: 横向排列时，高优先级在右；纵向排列时，高优先级在上。
    public enum ButtonProirity {
        case lowest
        case `default`
        case highest
        case custom(Int)

        var priorityValue: Int {
            switch self {
            case .lowest:               return 0
            case .default:              return 500
            case .highest:              return 1000
            case .custom(let value):    return max(0, min(100, value))
            }
        }
    }

    public struct Configuration {

        public enum LayoutStyle {
            /// 按钮横向排列
            case horizontal
            /// 按钮纵向排列
            case vertical
            /// 按钮优先横向排列，文字被压缩时，切换为纵向排列
            case adaptive
        }

        /// ButtonGroup 中每个 Button 的高度，默认为 48
        public var buttonHeight: CGFloat = 48
        /// Button 横向排布时的间距，默认为 18
        public var horizontalSpacing: CGFloat = 18
        /// Button 纵向排布时的间距，默认为 12
        public var verticalSpacing: CGFloat = 12
        /// Button 的排列方式，默认为 `.adaptive`
        public var layoutStyle: LayoutStyle = .adaptive

        public init() {}
        public static let `default`: Configuration = Configuration()
    }

    private lazy var buttons: [UIButton] = []

    public private(set) var configuration: Configuration

    public init(configuration: Configuration = .default) {
        self.configuration = configuration
        super.init(frame: .zero)
        setup()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        axis = .horizontal
        distribution = .fillEqually
        alignment = .fill
        adjustButtonSpacing()
    }

    public override func insertArrangedSubview(_ view: UIView, at stackIndex: Int) {
        guard let button = view as? UIButton else {
            assertionFailure("请使用 insertButton，并传入 UIButton 类型")
            return
        }
        button.snp.remakeConstraints { make in
            make.height.equalTo(configuration.buttonHeight)
        }
        super.insertArrangedSubview(button, at: stackIndex)
        buttons.insert(button, at: stackIndex)
        setNeedsLayout()
    }

    /*
    public func insertButton(_ button: UIButton, at index: Int) {
        insertArrangedSubview(button, at: index)
    }
     */

    public override func addArrangedSubview(_ view: UIView) {
        guard let button = view as? UIButton else {
            assertionFailure("请使用 addButton，并传入 UIButton 类型")
            return
        }
        button.snp.remakeConstraints { make in
            make.height.equalTo(configuration.buttonHeight)
        }
        super.addArrangedSubview(button)
        buttons.append(button)
        setNeedsLayout()
    }

    public func addButton(_ button: UIButton, priority: ButtonProirity = .default) {
        button.tag = priority.priorityValue
        addArrangedSubview(button)
        sortButtonsIfNeeded()
    }

    public func addUDButton(with configuration: UDButtonUIConifg, priority: ButtonProirity = .default) -> UDButton {
        let button = UDButton(configuration)
        addButton(button, priority: priority)
        return button
    }

    public override func removeArrangedSubview(_ view: UIView) {
        guard let button = view as? UIButton else {
            assertionFailure("请使用 removeButton，并传入 UIButton 类型")
            return
        }
        super.removeArrangedSubview(button)
        removeButton(button)
    }

    public func removeButton(_ button: UIButton) {
        button.removeFromSuperview()
        button.snp.removeConstraints()
        buttons.removeAll(where: { $0 === button })
        setNeedsLayout()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        adjustLayoutStyleIfNeeded()
    }

    public func adjustLayoutStyleIfNeeded() {
        guard configuration.layoutStyle == .adaptive else { return }
        let buttonWidth = getButtonWidth(forAxis: .horizontal)
        let noTruncatedButton = buttons.reduce(true) { partialResult, button in
            !button.isTruncated(byWidth: buttonWidth) && partialResult
        }
        if axis == .horizontal, !noTruncatedButton {
            // 如果是横向布局，且有按钮被压缩，则改为纵向布局
            axis = .vertical
            sortButtonsIfNeeded()
            adjustButtonSpacing()
        } else if axis == .vertical, noTruncatedButton {
            // 如果已经是纵向布局，但是横向布局能够排得下，则改为横向布局
            axis = .horizontal
            sortButtonsIfNeeded()
            adjustButtonSpacing()
        }
    }

    private func getButtonWidth(forAxis axis: NSLayoutConstraint.Axis) -> CGFloat {
        switch axis {
        case .horizontal:
            let buttonCount = CGFloat(arrangedSubviews.count)
            return (bounds.width - (buttonCount - 1) * spacing) / buttonCount
        case .vertical:
            return bounds.width
        @unknown default:
            return bounds.width
        }
    }

    private func adjustButtonSpacing() {
        spacing = (axis == .horizontal) ? configuration.horizontalSpacing : configuration.verticalSpacing
    }

    private func checkIfButtonsProperlySorted() -> Bool {
        let currentButtons = buttons.map { $0.tag }
        if axis == .horizontal {
            // 横向布局时，高优先级按钮在右，采用 < 排序
            return currentButtons.sorted(by: <) == currentButtons
        } else {
            // 纵向布局时，高优先级按钮在上，采用 > 排序
            return currentButtons.sorted(by: >) == currentButtons
        }
    }

    private func sortButtonsIfNeeded() {
        if checkIfButtonsProperlySorted() {
            return
        }
        buttons.forEach { $0.removeFromSuperview() }
        var newButtons = buttons
        buttons.removeAll()
        if axis == .horizontal {
            newButtons.sort(by: { $0.tag < $1.tag })
        } else {
            newButtons.sort(by: { $0.tag > $1.tag })
        }
        newButtons.forEach { addArrangedSubview($0) }
    }
}

private extension UIButton {

    var isTruncated: Bool {
        isTruncated(byWidth: bounds.width)
    }

    func isTruncated(byWidth width: CGFloat) -> Bool {
        guard let title = titleLabel?.text, let font = titleLabel?.font else { return false }
        let titleWidth = title.getWidth(font: font)
        let availableTitleWidth = width - contentEdgeInsets.left - contentEdgeInsets.right
        return titleWidth >= availableTitleWidth
    }
}
