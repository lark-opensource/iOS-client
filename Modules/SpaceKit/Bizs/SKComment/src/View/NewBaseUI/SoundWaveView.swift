//
//  SoundWaveView.swift
//  SoundWave
//
//  Created by chenjiahao.gill on 2019/4/26.
//  Copyright © 2019 Gill. All rights reserved.

import UIKit
import SnapKit

/*
protocol SoundWaveViewDateSource: AnyObject {
    func soundWaveViewNextRatio(_ soundWaveView: SoundWaveView) -> CGFloat?
}

class SoundWaveView: UIView {
    struct Layout {
        /// 柱状图的宽度
        static let histogramWidth: CGFloat = 1.5
        /// 柱状图的颜色
        static let histogramColor = UIColor.ud.colorfulBlue
        /// 最小高度比例, 至少也要显示一点东西
        static let minRatio: CGFloat = 0.05
    }

    /// 柱状图之间的间距
    let spacing: CGFloat
    /// 更新速度
    let duration: TimeInterval
    weak var dataSource: SoundWaveViewDateSource?

    /// - Params: spacing: 两个柱状体的间隔
    ///         : duration: 更新速度
    init(spacing: CGFloat,
         duration: TimeInterval = 0.1) {
        self.spacing = spacing
        self.duration = duration
        super.init(frame: .zero)
        self.timer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(_update), userInfo: nil, repeats: true)
        _setupView()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var timer: Timer?
    public func start() {
        timer?.fire()
    }
    public func stop() {
        timer?.invalidate()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.contentSize = frame.size
    }

    private func _setupView() {
        addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.isScrollEnabled = false
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        return view
    }()
    private let contentView: UIView = {
        let view = UIView()
        return view
    }()
}

extension SoundWaveView {
    @objc
    private func _drawLine(with height: CGFloat) {
        let newHeight = height
        // 计算 point
        let x = scrollView.contentSize.width + spacing * 2 + Layout.histogramWidth
        let startY = scrollView.contentSize.height / 2 - newHeight / 2
        let endY = scrollView.contentSize.height / 2 + newHeight / 2
        let startPoint = CGPoint(x: x, y: startY)
        let endPoint = CGPoint(x: x, y: endY)

        // 划线
        let line = CAShapeLayer()
        let path = UIBezierPath()
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        line.path = path.cgPath
        line.strokeColor = Layout.histogramColor.cgColor
        line.lineWidth = Layout.histogramWidth

        // content size
        let oldSize = scrollView.contentSize

        // 平移动画
        let rightOffset = CGPoint(x: scrollView.contentSize.width - scrollView.frame.width, y: 0)

        // 提交动画
        UIScrollView.beginAnimations("scrollAnimation", context: nil)
        // 保证时间大于刷新频率，可以让 scrollView 平滑滚动
        UIScrollView.setAnimationDuration(duration * 2)
        scrollView.layer.addSublayer(line)
        scrollView.contentSize = CGSize(width: oldSize.width + spacing + Layout.histogramWidth, height: oldSize.height)
        scrollView.contentOffset = rightOffset
        UIScrollView.commitAnimations()
    }

    @objc
    private func _update() {
        guard var ratio = self.dataSource?.soundWaveViewNextRatio(self) else { return }
        if ratio >= 1 { ratio = 1 }
        if ratio <= Layout.minRatio { ratio = Layout.minRatio }
        _drawLine(with: frame.height * ratio)
    }
}
*/
