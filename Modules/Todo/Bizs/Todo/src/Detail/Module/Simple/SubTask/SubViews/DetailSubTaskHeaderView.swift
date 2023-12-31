//
//  DetailSubTaskHeaderView.swift
//  Todo
//
//  Created by baiyantao on 2022/7/28.
//

import Foundation
import UniverseDesignProgressView
import UniverseDesignFont

struct DetailSubTaskHeaderViewData {
    var numerator: Int32 = 0
    var denominator: Int32 = 0
}

extension DetailSubTaskHeaderViewData {
    var headerHeight: CGFloat {
        return DetailSubTask.headerHeight
    }
}

final class DetailSubTaskHeaderView: UIView {

    var viewData: DetailSubTaskHeaderViewData? {
        didSet {
            guard let data = viewData else { return }
            progressLabel.text = getProgressText(data: data)
            progressView.setProgress(CGFloat(data.numerator) / CGFloat(data.denominator), animated: true)
        }
    }

    private lazy var progressLabel = getProgressLabel()
    private lazy var progressView = getProgressView()

    init() {
        super.init(frame: .zero)

        let containerView = UIView()
        addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalToSuperview().offset(6)
        }

        containerView.addSubview(progressLabel)
        containerView.addSubview(progressView)

        progressLabel.snp.makeConstraints {
            $0.left.top.bottom.equalToSuperview()
        }
        progressView.snp.makeConstraints {
            $0.left.equalTo(progressLabel.snp.right).offset(12)
            $0.centerY.equalTo(progressLabel)
            $0.width.equalTo(50)
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // UD Progress 组件必须上屏后设置才生效，已经反馈，先暂时这样解决
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let data = self.viewData {
                self.progressView.setProgress(CGFloat(data.numerator) / CGFloat(data.denominator), animated: false)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getProgressText(data: DetailSubTaskHeaderViewData = DetailSubTaskHeaderViewData()) -> String {
        "\(data.numerator) / \(data.denominator)"
    }

    private func getProgressLabel() -> UILabel {
        let label = UILabel()
        label.font = UDFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textTitle
        label.text = getProgressText()
        return label
    }

    private func getProgressView() -> UDProgressView {
        let config = UDProgressViewUIConfig(barMetrics: .regular)
        let layoutConfig = UDProgressViewLayoutConfig(linearBigCornerRadius: 5, linearProgressRegularHeight: 10)
        let view = UDProgressView(config: config, layoutConfig: layoutConfig)
        return view
    }
}
