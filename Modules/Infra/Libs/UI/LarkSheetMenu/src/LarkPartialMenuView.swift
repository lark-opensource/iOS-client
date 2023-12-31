//
//  LarkPartialMenuView.swift
//  LarkSheetMenu
//
//  Created by Zigeng on 2023/2/3.
//

import Foundation
import UIKit

/// 部分选择状态的悬浮菜单
class PartialView: UIView {
    var vMargin: CGFloat

    public init(vMargin: CGFloat) {
        self.vMargin = vMargin
        super.init(frame: .zero)
        self.backgroundColor = .ud.bgFloat
        self.layer.ud.setShadow(type: .s5Down)
        self.layer.cornerRadius = 10
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var cells: [PartialMenuCell] = []

    override func layoutSubviews() {
        if frame.origin != self.point {
            reLayout(sourceRect: self.sourceRect)
        } else {
            super.layoutSubviews()
        }
    }

    func setSubCells(dataSource: [LarkSheetMenuActionItem]) {
        cells.forEach {
            $0.snp.removeConstraints()
            $0.removeFromSuperview()
        }
        cells = dataSource.map { item in
            let cell = PartialMenuCell()
            cell.setCell(item, width: 300)
            return cell
        }
        cells.forEach { cell in
            self.addSubview(cell)
        }
        for (index, cell) in cells.enumerated() {
            cell.snp.makeConstraints { make in
                make.width.equalToSuperview()
            }
            if cells.count == 1 {
                cell.snp.makeConstraints { make in
                    make.top.equalToSuperview().offset(4)
                    make.bottom.equalToSuperview().offset(-4)
                }
                break
            }
            if index == 0 {
                cell.snp.makeConstraints { make in
                    make.top.equalToSuperview().offset(4)
                }
            } else if index == cells.count - 1 {
                cell.snp.makeConstraints { make in
                    make.top.equalTo(cells[index - 1].snp.bottom)
                    make.bottom.equalToSuperview().offset(-4)
                }
            } else {
                cell.snp.makeConstraints { make in
                    make.top.equalTo(cells[index - 1].snp.bottom)
                }
            }
        }
        self.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(210)
            make.width.greaterThanOrEqualTo(136)
        }
    }

    private var sourceRect = CGRect.zero
    private var point: CGPoint?
    public func reLayout(sourceRect: CGRect) {
        self.sourceRect = sourceRect
        guard let window = self.window else { return }
        let margin: CGFloat = 9
        /// 水平位置: 左右安全间距均为16
        if sourceRect.midX - frame.width / 2 < 16 {
            self.frame.origin.x = 16
        } else if sourceRect.midX + frame.width / 2 > window.bounds.width - 16 {
            self.frame.origin.x = window.bounds.width - 16 - self.frame.width
        } else {
            self.frame.origin.x = sourceRect.midX - frame.width / 2
        }
        /// 垂直位置: 上安全间距32, 下安全间距180, 优先放下面
        if sourceRect.maxY + frame.height + margin < window.bounds.maxY - 180 {
            self.frame.origin.y = sourceRect.maxY + margin
        } else if sourceRect.minY - frame.height - 32 - margin > 0 {
            self.frame.origin.y = sourceRect.minY - frame.height - margin
        } else {
            self.frame.origin.y = window.bounds.maxY - frame.height - 180
        }
        point = self.frame.origin
    }
}

class PartialMenuCell: UIView {
    static var reuseIdentifier = "LarkSheetMenuCell"

    private lazy var label = UILabel()
    private lazy var icon = UIImageView()
    private var isGrey = false
    private lazy var action: (() -> Void)? = nil
    private lazy var disableAction: (() -> Void)? = nil

    @objc
    private func didTap() {
        isGrey ? disableAction?() : action?()
    }

    public init() {
        super.init(frame: .zero)
        self.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(20)
        }
        label.numberOfLines = 2
        self.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(icon.snp.right).offset(12)
            make.right.equalToSuperview().offset(-16)
        }
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        self.snp.makeConstraints { make in
            make.height.equalTo(label.snp.height).offset(26)
        }
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public func setCell(_ item: LarkSheetMenuActionItem, width: CGFloat) {
        self.label.text = item.text
        self.icon.image = item.icon
        self.action = item.tapAction
        self.isGrey = item.isGrey
        self.disableAction = item.tapAction
        self.icon.alpha = item.isGrey ? 0.3 : 1
        self.label.textColor = item.isGrey ? .ud.iconDisabled : .ud.textTitle
    }
}
