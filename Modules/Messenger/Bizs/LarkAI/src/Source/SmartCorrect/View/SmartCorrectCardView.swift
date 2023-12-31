//
//  SmartCorrectCardView.swift
//  LarkAI
//
//  Created by ZhangHongyun on 2021/5/28.
//

import Foundation
import UIKit
import UniverseDesignColor

final class SmartCorrectCardView: UIView {

    var selectedActionCallback: (() -> Void)?
    var abandonActionCallback: (() -> Void)?

    /// 纠正的内容
    private let content: String
    private let tapPoint: CGPoint

    private let wrapperView: UIView = UIView()

    private lazy var contentButton: UIButton = {
        let contentButton = UIButton(type: .custom)
        contentButton.setTitle(content, for: .normal)
        contentButton.setTitleColor(UIColor.ud.G600, for: .normal)
        contentButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        contentButton.titleLabel?.textAlignment = .center
        contentButton.addTarget(self, action: #selector(selectedAction), for: .touchUpInside)
        return contentButton
    }()

    private lazy var lineView: UIView = {
        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.lineDividerDefault
        return lineView
    }()

    private lazy var abandonButton: UIButton = {
        let abandonButton = UIButton(type: .custom)
        abandonButton.setImage(Resources.smart_correct_abandon, for: .normal)
        abandonButton.setImage(Resources.smart_correct_abandon, for: .selected)
        abandonButton.addTarget(self, action: #selector(abandonAction), for: .touchUpInside)
        return abandonButton
    }()

    init(content: String,
         tapPoint: CGPoint) {
        self.content = content
        self.tapPoint = tapPoint
        super.init(frame: .zero)
        setUpSubViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setUpSubViews() {
        isUserInteractionEnabled = true
        backgroundColor = .clear
        addSubview(wrapperView)

        wrapperView.addSubview(abandonButton)
        abandonButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.width.equalTo(60)
            make.height.equalTo(48)
            make.centerY.equalToSuperview()
        }

        wrapperView.addSubview(lineView)
        lineView.snp.makeConstraints { (make) in
            make.right.equalTo(abandonButton.snp.left)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 1, height: 24))
        }

        let contentWidth = (contentButton.titleLabel?.sizeThatFits(CGSize(width: 0.0, height: 20)).width ?? 0.0) + 40
        wrapperView.addSubview(contentButton)
        contentButton.snp.makeConstraints { (make) in
            make.right.equalTo(lineView.snp.left)
            make.width.equalTo(contentWidth)
            make.height.equalTo(48)
            make.centerY.equalToSuperview()
        }

        wrapperView.snp.makeConstraints { (make) in
            make.top.equalTo(contentButton)
            make.height.equalTo(48)
            make.left.equalTo(contentButton)
            make.right.equalTo(abandonButton)
        }

        snp.makeConstraints { (make) in
            make.edges.equalTo(wrapperView)
        }

        drawCardBorder(with: contentWidth + 62, height: 52)
    }

    private func drawCardBorder(with width: CGFloat, height: CGFloat) {
        let cornerX = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.convert(self.tapPoint, to: self).x ?? width / 2
        let borderPath = UIBezierPath()
        borderPath.move(to: CGPoint(x: 0, y: 8))
        borderPath.addQuadCurve(to: CGPoint(x: 8, y: 0), controlPoint: CGPoint(x: 0, y: 0))
        borderPath.addLine(to: CGPoint(x: width - 8, y: 0))
        borderPath.addQuadCurve(to: CGPoint(x: width, y: 8), controlPoint: CGPoint(x: width, y: 0))
        borderPath.addLine(to: CGPoint(x: width, y: height - 12))
        borderPath.addQuadCurve(to: CGPoint(x: width - 8, y: height - 4), controlPoint: CGPoint(x: width, y: height - 4))
        borderPath.addLine(to: CGPoint(x: cornerX + 3.5, y: height - 4))
        borderPath.addLine(to: CGPoint(x: cornerX, y: height))
        borderPath.addLine(to: CGPoint(x: cornerX - 3.5, y: height - 4))
        borderPath.addLine(to: CGPoint(x: 8, y: height - 4))
        borderPath.addQuadCurve(to: CGPoint(x: 0, y: height - 4 - 8), controlPoint: CGPoint(x: 0, y: height - 4))
        borderPath.close()

        let borderLayer = CAShapeLayer()
        borderLayer.path = borderPath.cgPath
        borderLayer.strokeColor = UIColor.ud.lineBorderCard.cgColor
        borderLayer.fillColor = UIColor.ud.bgFloat.cgColor
        let layerCount: UInt32 = UInt32(layer.sublayers?.count ?? 1)
        layer.insertSublayer(borderLayer, at: layerCount - 1)
    }

    // MARK: Actions
    @objc
    func selectedAction() {
        selectedActionCallback?()
    }

    @objc
    func abandonAction() {
        abandonActionCallback?()
    }
}
