//
//  EventEditTimeZoneView.swift
//  Calendar
//
//  Created by Miao Cai on 2020/3/14.
//

import UIKit
import UniverseDesignIcon
import Foundation
import SnapKit

protocol EventEditTimeZoneViewData {
    // 时区名
    var timeZoneName: String { get }
    // 时区tip
    var timeZoneTip: String? { get }  // 参与人时区不同时的提示
    var isClickable: Bool { get }
    var isVisible: Bool { get }
    var timezoneDiffTip: String? { get }  // 设备时区跟日程时区不同时的提示
}

// 日程编辑时区view容器：
// ------中国标准时间
// ------参与者位于不同时区
final class EventEditTimeZoneView: UIControl, ViewDataConvertible {
    private let nameView = EventEditCellLikeView()
    // 参与人时区不同时的提示
    private let tipView = TipView(textColor: .ud.udtokenTagTextSBlue, bgColor: .ud.udtokenTagBgBlue)
    // 设备时区与日程时区不同时的提示
    private let timezoneDiffTipView = TipView(textColor: .ud.udtokenTagNeutralTextNormal, bgColor: .ud.udtokenTagNeutralBgNormal)
    // 参与人和你的时区不一致提示 展示回调
    var invalidWarningDisplayCallback: (() -> Void)?

    var clickHandler: (() -> Void)?
    // tipView上一次isHidden的状态
    private var tipViewIsLastHidden: Bool = false

    private lazy var stackview: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 6
        return stack
    }()

    var viewData: EventEditTimeZoneViewData? {
        didSet {
            isHidden = !(viewData?.isVisible ?? false)
            guard let viewData = viewData, !isHidden else { return }

            isUserInteractionEnabled = viewData.isClickable

            nameView.content = .title(.init(
                text: viewData.timeZoneName,
                color: isUserInteractionEnabled ? UIColor.ud.textCaption : UIColor.ud.textDisabled,
                font: UIFont.cd.regularFont(ofSize: 14)
            ))

            if let tip = viewData.timeZoneTip, !tip.isEmpty {
                tipView.isHidden = false
                tipView.setContentText(with: tip)
                // 这里保证每一次隐藏到显示只回调一次
                if tipViewIsLastHidden == true {
                    invalidWarningDisplayCallback?()
                }
            } else {
                tipView.isHidden = true
            }
            self.tipViewIsLastHidden = tipView.isHidden

            if let timezoneDiffTip = viewData.timezoneDiffTip, !timezoneDiffTip.isEmpty {
                timezoneDiffTipView.setContentText(with: timezoneDiffTip)
                timezoneDiffTipView.isHidden = false
            } else {
                timezoneDiffTipView.isHidden = true
            }
            if tipView.isHidden, timezoneDiffTipView.isHidden {
                stackview.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(-8)
                }
            } else {
                stackview.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(-12)
                }
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
        addTarget(self, action: #selector(handleClick), for: .touchUpInside)
        let container = UIView()
        addSubview(container)
        container.backgroundColor = .ud.bgFloat
        container.addSubview(nameView)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        nameView.icon = .empty
        nameView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalTo(4)
            $0.height.equalTo(22)
        }
        nameView.isUserInteractionEnabled = false
        nameView.contentInset = EventEditUIStyle.Layout.contentLeftPadding
        nameView.backgroundColors = EventEditUIStyle.Color.cellBackgrounds

        container.addSubview(stackview)
        stackview.snp.makeConstraints {
            $0.left.equalToSuperview().inset(EventEditUIStyle.Layout.eventEditContentLeftMargin)
            $0.right.equalToSuperview().inset(16)
            $0.top.equalTo(nameView.snp.bottom).offset(4)
            $0.bottom.equalToSuperview().offset(-10)
        }

        stackview.addArrangedSubview(timezoneDiffTipView)
        stackview.addArrangedSubview(tipView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func handleClick() {
        clickHandler?()
    }
}

// 具有背景色的文本view
fileprivate class TipView: UIView {
    private lazy var content: UILabel = {
        let label = UILabel()
        label.textColor = .ud.udtokenTagTextBlue
        label.font = UIFont.cd.mediumFont(ofSize: 12)
        label.numberOfLines = 0
        return label
    }()
    // 显示背景色的view
    private lazy var innerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        return view
    }()

    init(textColor: UIColor, bgColor: UIColor) {
        super.init(frame: .zero)
        addSubview(innerView)
        innerView.backgroundColor = bgColor
        innerView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
        innerView.addSubview(content)
        content.textColor = textColor
        content.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4))
        }
    }

    func setContentText(with text: String) {
        content.text = text
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        content.preferredMaxLayoutWidth = self.frame.width - 8
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
