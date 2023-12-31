//
//  MultiEditCountdownTipsView.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2022/8/15.
//

import UIKit
import Foundation
import UniverseDesignColor
import LarkMessageBase

final class MultiEditCountdownTipsView: UIView, KeyboardTipsView {
    var deadline: TimeInterval
    var multiEditTimer: Timer?
    private func startMultiEditTimer() {
        self.multiEditTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0,
                                   target: TimerProxy(self),
                                   selector: #selector(updateMultiEditCountdown),
                                   userInfo: nil,
                                   repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        timer.fireDate = Date()
        self.multiEditTimer = timer
    }

    @objc
    private func updateMultiEditCountdown() {
        //剩余时间
        let timeRemaining = Date(timeIntervalSince1970: .init(deadline)).timeIntervalSince(Date())
        if timeRemaining <= 0 {
            label.text = BundleI18n.LarkMessageCore.Lark_IM_EditMessage_EditingTimeDue_Text
            multiEditTimer?.invalidate()
            multiEditTimer = nil
            return
        }
        label.text = BundleI18n.LarkMessageCore.Lark_IM_EditMessage_PleaseFinishEditingInNumSeconds_Text(Int(timeRemaining))
    }

    func suggestHeight(maxWidth: CGFloat) -> CGFloat {
        //view高度20，上边距8
        return 28
    }

    lazy var label: UILabel = {
        let label = UILabel()
        label.textColor = .ud.functionDangerContentDefault
        label.font = .systemFont(ofSize: 14)
        label.text = BundleI18n.LarkMessageCore.Lark_IM_EditMessage_PleaseFinishEditingInNumSeconds_Text(60)
        return label
    }()
    deinit {
        multiEditTimer?.invalidate()
    }
    init(deadline: TimeInterval,
         scene: KeyboardTipScene) {
        self.deadline = deadline
        super.init(frame: .zero)
        addSubview(label)
        label.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(scene == .compose ? 12 : 8)
        }
        backgroundColor = .ud.bgBodyOverlay
        startMultiEditTimer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class TimerProxy: NSObject {
    weak var target: NSObjectProtocol?

    init(_ target: NSObjectProtocol) {
        self.target = target
        super.init()
    }

    override func responds(to aSelector: Selector!) -> Bool {
        return target?.responds(to: aSelector) ?? false
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return target
    }
}
