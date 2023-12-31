//
//  TransparentCircleHoleOnOverlayView.swift
//  UDDemo
//
//  Created by houjihu on 2021/4/8.
//

import Foundation
import UIKit

/// 带有右侧透明圆孔的视图
final class TransparentCircleHoleOnOverlayView: UIView {
    /// 元素水平间距
    let horizontalSpacing: CGFloat?

    /// 初始化
    /// - Parameter horizontalSpacing: 元素水平间距。可选参数，如果为nil则不显示圆角，用于处理最后一个视图
    init(horizontalSpacing: CGFloat? = nil) {
        self.horizontalSpacing = horizontalSpacing
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// eclipse mask
    private lazy var eclipsePath: UIBezierPath? = {
        // 从右下角的交点开始，先顺时针画左侧长弧线，再逆时针补充右侧短弧线
        // 相关计算请参考：https://bytedance.feishu.cn/docs/doccnbZDNj9cyn0C5szZ2jznotd
        guard let horizontalSpacing = horizontalSpacing else {
            return nil
        }
        let spacing = horizontalSpacing
        let radius = bounds.width / 2.0

        let footPointToLeftCircleCenter: CGFloat = (4 * radius * radius + 3 * spacing * spacing - 10 * radius * spacing) / (4 * radius - 4 * spacing)
        let alphaCornerRadian: CGFloat = CGFloat(acos(footPointToLeftCircleCenter / radius))
        let leftCircleCenter: CGPoint = CGPoint(x: radius, y: radius)
        let leftCircleStartRadian: CGFloat = alphaCornerRadian
        let leftCircleEndRadian: CGFloat = CGFloat.pi * 2 - alphaCornerRadian

        let footPointToRightCircleCenter: CGFloat = 2 * radius - 2 * spacing - footPointToLeftCircleCenter
        let betaCornerRadian: CGFloat = CGFloat(acos(footPointToRightCircleCenter / (radius + spacing)))
        let rightCircleCenter: CGPoint = CGPoint(x: radius * 3 - spacing * 2, y: radius)
        let rightCircleStartRadian: CGFloat = CGFloat.pi + betaCornerRadian
        let rightCircleEndRadian: CGFloat = CGFloat.pi - betaCornerRadian

        let path = UIBezierPath(arcCenter: leftCircleCenter,
                                radius: radius,
                                startAngle: leftCircleStartRadian,
                                endAngle: leftCircleEndRadian,
                                clockwise: true)
        path.addArc(withCenter: rightCircleCenter,
                    radius: radius + spacing,
                    startAngle: rightCircleStartRadian,
                    endAngle: rightCircleEndRadian,
                    clockwise: false)
        path.close()
        return path
    }()

    // MARK: - Drawing
    override func layoutSubviews() {
        superview?.layoutSubviews()

        guard let eclipsePath = self.eclipsePath else {
            return
        }

        let layer = CAShapeLayer()
        layer.path = eclipsePath.cgPath
        self.layer.mask = layer
    }
}
