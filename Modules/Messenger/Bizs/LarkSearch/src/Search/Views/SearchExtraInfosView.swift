//
//  SearchExtraInfosView.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/12/19.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
import RustPB

// extraInfosView 解决设计师要求，每段有最小展示比例，不能使用系统的自动压缩
final class SearchExtraInfosView: UIView {
    var containerStackView: UIStackView = {
        let containerStackView = UIStackView()
        containerStackView.axis = .horizontal
        containerStackView.alignment = .center
        containerStackView.distribution = .fill
        containerStackView.spacing = 0
        containerStackView.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        containerStackView.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        return containerStackView
    }()
    var extraInfoLabels: [SearchExtraInfoLabel] = []
    var extraInfos: [Search_V2_ExtraInfoBlock] = []
    var extraInfoSeparator: String = ""
    var separatorSingleLineWidth: CGFloat = 0
    var ratios: [CGFloat] = [] // 前后两段比例，比如3:2 为 [3, 2] 空则使用系统默认压缩
    var textTotalWidth: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        addSubview(containerStackView)
        containerStackView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
    }

    func prepareForReuse() {
        extraInfos = []
        extraInfoSeparator = ""
        ratios = []
        separatorSingleLineWidth = 0
        textTotalWidth = 0
        containerStackView.btd_removeAllSubviews()
        for view in containerStackView.arrangedSubviews {
            containerStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        extraInfoLabels = []
    }

    func updateExtraInfos(extraInfos: [Search_V2_ExtraInfoBlock], extraInfoSeparator: String, ratios: [CGFloat] = []) {
        prepareForReuse()
        guard !extraInfos.isEmpty else { return }
        self.extraInfos = extraInfos
        self.extraInfoSeparator = extraInfoSeparator
        if ratios.count == extraInfos.count {
            self.ratios = ratios
        }
        for (index, item) in extraInfos.enumerated() {
            let extraLabel = SearchExtraInfoLabel()
            if ratios.count == extraInfos.count {
                // 增加优先级逻辑原因见下文 updateTotalWidth方法
                let priority = UILayoutPriority(UILayoutPriority.defaultHigh.rawValue + Float(ratios[index]))
                extraLabel.setContentCompressionResistancePriority(priority, for: .horizontal)
                extraLabel.setContentHuggingPriority(priority, for: .horizontal)
            }
            extraLabel.updateView(extraInfoBlock: item)
            extraLabel.sizeToFit()
            containerStackView.addArrangedSubview(extraLabel)
            extraInfoLabels.append(extraLabel)
            textTotalWidth += extraLabel.singleLineLength()
            if !extraInfoSeparator.isEmpty && index < extraInfos.count - 1 {
                let separatorLabel = SearchExtraInfoLabel()
                separatorLabel.text = extraInfoSeparator
                separatorLabel.sizeToFit()
                separatorLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
                separatorLabel.setContentHuggingPriority(.required, for: .horizontal)
                separatorSingleLineWidth = separatorLabel.singleLineLength()
                textTotalWidth += separatorSingleLineWidth
                containerStackView.addArrangedSubview(separatorLabel)
            }
        }
    }

    func updateTotalWidth(totalWidth: CGFloat) {
        // 自动布局，系统压缩
        guard !ratios.isEmpty else { return }
        guard ratios.count == extraInfos.count else { return }
        guard textTotalWidth > totalWidth else { return }

        // 自定义最小展示比例
        // 注意取整，防止出现 0.333334 + 0.666667 > 1 导致异常省略的问题
        let separatorTotalWidth = ceil(CGFloat(extraInfos.count - 1) * separatorSingleLineWidth)
        let textRealTotalWidth = floor(totalWidth - separatorTotalWidth)
        if textRealTotalWidth < 0 {
            return
        }
        let ratioTotal = ratios.reduce(0, +)
        let widthCoefficient = textRealTotalWidth / ratioTotal

        for (index, item) in extraInfoLabels.enumerated() {
            var minWidth = ratios[index] * widthCoefficient
            minWidth = minWidth > item.singleLineLength() ? item.singleLineLength() : floor(minWidth)
            item.snp.remakeConstraints { make in
                // 总宽度 > 所有minWidth相加时，会有多个进入greater的逻辑中，但是具体哪个label，可以大多少，由系统决定
                // 为了防止页面刷新过程中出现的跳变，必须给每个label设置确定的拉伸压缩优先级
                make.width.greaterThanOrEqualTo(minWidth)
                make.height.equalToSuperview()
            }
        }
    }
}
