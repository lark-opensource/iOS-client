//
//  AnswerFeedbackReasonView.swift
//  LarkAIInfra
//
//  Created by 李勇 on 2023/6/16.
//

import Foundation
import SnapKit
import RxSwift
import RxCocoa
import EditTextView
import EENavigator
import LarkUIKit
import RustPB
import ServerPB
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignButton
import UniverseDesignInput

/// 用于存放踩原因
final class AnswerFeedbackReasonView: UIView {
    typealias ReasonType = AIFeedbackConfig.FeedbackReason
    /// 选项的开始Y值
    private static var itemStartY: CGFloat { 0 }
    /// 每个选项的高度
    private static var itemHeight: CGFloat { 36 }
    /// 垂直方向上的间距
    private static var itemSpaceing: CGFloat { 8 }
    var reasons: [ReasonType] = [] {
        didSet { invalidLayout() }
    }
    /// 存储用户选中的原因
    private(set) var selected: Set<ReasonType> = []
    /// 用户原因发生了变化
    var selectedChange: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        // 高度不够时需要隐藏对应的视图
        self.clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var _reasonBtns: [UIButton] = [] {
        didSet {
            assert(Thread.isMainThread, "should occur on main thread!")
            if !oldValue.isEmpty {
                for btn in oldValue {
                    btn.removeFromSuperview()
                }
            }
            if !_reasonBtns.isEmpty {
                for btn in _reasonBtns {
                    self.addSubview(btn)
                }
            }
        }
    }
    private func makeReaonsButton() -> UIButton {
        let btn = ReasonButton(frame: .zero)
        btn.addTarget(self, action: #selector(touch(button:)), for: .touchUpInside)
        return btn
    }

    /// lastWidth用于从远端拉取原因后，更新一次高度
    private var lastWidth: CGFloat = -1
    private func invalidLayout() {
        lastWidth = -1
        self.setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        doLayout(width: self.bounds.width)
    }

    /// 计算出来的内容总高度
    private(set) var preferHeight: CGFloat = 0
    @discardableResult
    func doLayout(width boundsWidth: CGFloat) -> CGFloat {
        if lastWidth == boundsWidth { return preferHeight }
        defer { lastWidth = boundsWidth }

        func dequeBtn(i: Int) -> UIButton {
            let btn: UIButton
            if i < _reasonBtns.count {
                btn = _reasonBtns[i]
            } else {
                btn = makeReaonsButton()
            }
            btn.tag = i
            return btn
        }

        var buttons: [UIButton] = []
        defer { _reasonBtns = buttons }

        // create and layout reasons
        let itemStartX: CGFloat = 16
        var itemStartY = Self.itemStartY

        func nextFrame(width: CGFloat) -> CGRect {
            let currItemStartY = itemStartY; itemStartY += (Self.itemHeight + Self.itemSpaceing)
            return CGRect(x: itemStartX, y: currItemStartY, width: boundsWidth - 2 * itemStartX, height: Self.itemHeight)
        }
        for (i, reason) in reasons.enumerated() {
            let btn = dequeBtn(i: i)
            btn.setTitle(reason.name, for: .normal)
            btn.sizeToFit()
            let frame = nextFrame(width: btn.frame.width)
            btn.frame = frame
            btn.isSelected = selected.contains(reason)
            buttons.append(btn)
        }
        if let button = buttons.last {
            preferHeight = button.frame.maxY
        } else {
            preferHeight = 0
        }
        return preferHeight
    }

    @objc
    private func touch(button: UIButton) {
        button.isSelected = !button.isSelected
        let tag = button.tag
        if tag < self.reasons.count {
            if button.isSelected {
                self.selected.insert(self.reasons[tag])
            } else {
                self.selected.remove(self.reasons[tag])
            }
            self.selectedChange?()
        }
    }
}

final class ReasonButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.titleLabel?.font = .systemFont(ofSize: 16)
        self.setTitleColor(UIColor.ud.textTitle, for: .normal)
        self.setTitleColor(UIColor.ud.primaryContentDefault, for: .selected)
        self.layer.cornerRadius = 18
        self.layer.borderWidth = 1
        self.clipsToBounds = true
        configByState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet { configByState() }
    }

    func configByState() {
        if isSelected {
            self.backgroundColor = UIColor.ud.B50
            self.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
        } else {
            self.backgroundColor = UIColor.ud.bgFloat
            self.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        }
    }
}
