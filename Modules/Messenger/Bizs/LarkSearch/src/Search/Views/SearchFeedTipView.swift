//
//  FeedBackView.swift
//  LarkSearch
//
//  Created by SolaWing on 2021/6/3.
//

import UIKit
import Foundation
import SnapKit
import RxSwift
import RxCocoa
import EditTextView
import EENavigator
import LarkUIKit
import RustPB
import LarkSearchCore
import LKCommonsLogging
import ServerPB
import UniverseDesignToast
import UniverseDesignIcon

/// 搜索入口反馈视图
final class SearchFeedTipView: UIView {
    let tipLabel = UILabel()
    var startTime = Date()
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.ud.bgBody

        tipLabel.font = .systemFont(ofSize: 14)
        tipLabel.textColor = UIColor.ud.textTitle
        tipLabel.textAlignment = .center
        tipLabel.numberOfLines = 2
        let text = NSMutableAttributedString(string: BundleI18n.LarkSearch.Lark_Search_ResultFeedback)
        text.append(NSAttributedString(string: " "))
        text.append(NSAttributedString(string: BundleI18n.LarkSearch.Lark_Search_GiveFeedbackForQuestion, attributes: [.foregroundColor: UIColor.ud.textLinkNormal]))
        tipLabel.attributedText = text

        self.addSubview(tipLabel)

        tipLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(12)
            $0.left.greaterThanOrEqualToSuperview()
            $0.right.lessThanOrEqualToSuperview()
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    let defaultHeight: CGFloat = 72
    let fixedHeight: CGFloat = 48
    override var intrinsicContentSize: CGSize { .init(width: UIView.noIntrinsicMetric, height: defaultHeight) }

    // MARK: 外部控制复用API
    static func updateVisiblily(in scrollView: UIScrollView, from: CGFloat, to: CGFloat, show: () -> Void, current: SearchFeedTipView?, hideCompletion: (() -> Void)? = nil) {
        func shouldShowFeedBackView() -> Bool {
            // 向下滑动, 在第二屏末尾出现feedback, 或者最底部出现
            guard to > from else { return false }
            let secondScreen = scrollView.frame.height
            let change = from...to
            // 底部换成固定展示的view.. 不滑动弹出
            // let bottom = max(scrollView.contentSize.height - scrollView.frame.height, 10) // 0的话可能导致启动触发。需要用户上划才触发
            if change ~= secondScreen {
                show()
                return true
            }
            return false
        }
        func mayHideFeedBackView() {
            guard let v = current, v.state == .show else { return }
            // 出现后，滑动后消失. 2s buffer避免过快消失
            if abs(v.startTime.timeIntervalSinceNow) > 2 {
                v.hide(animated: true, completion: hideCompletion)
            }
        }
        if !shouldShowFeedBackView() {
            mayHideFeedBackView()
        }
    }

    // 配合下面的show和hide使用, 控制展示状态
    enum State {
    case invisible // 不可见
    case show // 展示中
    case hiding // 隐藏中
    }
    var state = State.invisible
    func show(in superview: UIView, animated: Bool = true, autoHide: TimeInterval = 0, completion: (() -> Void)? = nil) {
        defer {
            if autoHide > 0 {
                DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + autoHide) { [startTime = startTime, weak self] in
                    guard let self = self, startTime == self.startTime else { return } // 防提前hide
                    self.hide(animated: true, completion: completion)
                }
            }
        }
        guard self.state != .show else {
            self.startTime = Date()
            return // 重复展示刷新startTime
        }
        self.state = .show

        var frame = superview.bounds
        frame.origin.y = frame.size.height
        frame.size.height = defaultHeight
        self.frame = frame
        self.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        superview.addSubview(self)
        self.startTime = Date()

        frame.origin.y -= frame.size.height
        let layout = { self.frame = frame }

        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .beginFromCurrentState, animations: layout)
        } else {
            layout()
        }
    }
    func hide(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard self.state == .show else { return }
        if animated {
            var frame = self.frame
            frame.origin.y += frame.size.height
            UIView.animate(withDuration: 0.25, delay: 0, options: .beginFromCurrentState) {
                self.state = .hiding
                self.frame = frame
            } completion: { _ in
                // 考虑打断的情况
                if self.state == .hiding {
                    self.removeFromSuperview()
                    self.state = .invisible
                    completion?()
                }
            }
        } else {
            self.removeFromSuperview()
            self.state = .invisible
            completion?()
        }
    }
}
