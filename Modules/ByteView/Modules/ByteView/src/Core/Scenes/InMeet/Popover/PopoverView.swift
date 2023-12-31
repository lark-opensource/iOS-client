//
//  PopoverView.swift
//  ByteView
//
//  Created by wulv on 2021/12/31.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignColor

enum PopoverLayoutConfigure {
    /// 箭头离指向的距离
    case arrowToSource(CGFloat)
    /// 箭头高度
    case arrowHeight(CGFloat)
    /// 箭头宽度
    case arrowWidth(CGFloat)
    /// 瞄边宽度
    case lineWidth(CGFloat)
}

class PopoverView: UIView {

    struct Layout {
        var arrowToSource: CGFloat = 0.0
        var arrowHeight: CGFloat = 8.0
        var arrowWidth: CGFloat = 16.0
        var lineWidth: CGFloat = 1.0
    }

    private (set) var layout = Layout()

    private lazy var arrowView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: layout.arrowWidth, height: layout.arrowHeight))
        view.backgroundColor = .clear
        view.layer.addSublayer(triangleLayer)
        triangleLayer.ud.setStrokeColor(.ud.lineBorderCard, bindTo: view)
        triangleLayer.ud.setFillColor(.ud.N00, bindTo: view)
        return view
    }()

    private lazy var triangleLayer: CAShapeLayer = {
        let trianglePath = UIBezierPath()
        trianglePath.lineWidth = layout.lineWidth
        var point = CGPoint(x: 0, y: layout.arrowHeight)
        trianglePath.move(to: point)
        point = CGPoint(x: layout.arrowWidth * 0.5, y: 0)
        trianglePath.addLine(to: point)
        point = CGPoint(x: layout.arrowWidth, y: layout.arrowHeight)
        trianglePath.addLine(to: point)

        let triangleLayer = CAShapeLayer()
        triangleLayer.path = trianglePath.cgPath
        return triangleLayer
    }()

    private lazy var container: UIView = {
       let view = UIView()
        view.backgroundColor = UIColor.ud.N00
        view.layer.cornerRadius = 10.0
        view.layer.shadowOpacity = 1.0
        view.layer.masksToBounds = true
        view.layer.shadowOffset = CGSize(width: 0, height: 5)
        view.layer.shadowRadius = 2
        view.layer.borderWidth = layout.lineWidth
        view.layer.ud.setBorderColor(.ud.N300)
        view.layer.ud.setShadow(type: .s4Down)
        return view
    }()

    var lastArrowCenterX: CGFloat = 0
    weak var sourceView: UIView?

    /// - Parameters:
    ///     - sourceView: 箭头指向的视图，默认nil，代表无箭头
    ///     - contentView: 自定义的内容视图
    ///     - configures: 自定义箭头尺寸、瞄边宽度
    init(frame: CGRect = .zero, sourceView: UIView? = nil, contentView: UIView, with configures: [PopoverLayoutConfigure]?) {
        super.init(frame: frame)
        config(with: configures ?? [])
        backgroundColor = .clear

        container.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.sourceView = sourceView
        addSubview(arrowView)
        arrowView.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if sourceView == nil || sourceView?.isHidden == true {
            // 无箭头
            guard !arrowView.isHidden else { return }
            arrowView.isHidden = true
            container.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else if let sourceView = sourceView, !sourceView.isHidden {
            // 有箭头
            DispatchQueue.main.async {
                self.arrowView.isHidden = false
                let centerX = self.arrowCenterX(by: sourceView)
                guard self.lastArrowCenterX != centerX else { return }
                self.lastArrowCenterX = centerX
                self.arrowView.snp.remakeConstraints { make in
                    make.top.equalTo(sourceView.snp.bottom).offset(self.layout.arrowToSource)
                    make.size.equalTo(CGSize(width: self.layout.arrowWidth, height: self.layout.arrowHeight))
                    make.centerX.equalTo(centerX)
                }
                self.container.snp.remakeConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                    make.top.equalTo(self.arrowView.snp.bottom).offset(-self.layout.lineWidth)
                }
            }
        }
    }

    private func config(with configures: [PopoverLayoutConfigure]) {
        configures.forEach { config in
            switch config {
            case let .arrowToSource(value):
                self.layout.arrowToSource = value
            case let .arrowWidth(value):
                self.layout.arrowWidth = value
            case let .arrowHeight(value):
                self.layout.arrowHeight = value
            case let .lineWidth(value):
                self.layout.lineWidth = value
            }
        }
    }

    private func arrowCenterX(by source: UIView) -> CGFloat {
        let rect = convert(source.frame, from: source.superview)
        let centerX = rect.minX + rect.width * 0.5
        return centerX
    }
}
