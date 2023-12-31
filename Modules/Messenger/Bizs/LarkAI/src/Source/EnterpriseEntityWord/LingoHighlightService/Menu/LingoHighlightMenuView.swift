//
//  LingoHighlightMenuView.swift
//  LarkAI
//
//  Created by ByteDance on 2023/5/25.
//

import Foundation
import UIKit
import UniverseDesignColor

final class LingoHighlightMenuView: UIView {

    var selectedActionCallback: (() -> Void)?
    var abandonActionCallback: (() -> Void)?

    private let content: String
    private let tapPoint: CGPoint
    private var contentWidth: CGFloat = 0
    private var abandonWidth: CGFloat = 0
    private weak var textView: UITextView?

    private let wrapperView: UIView = UIView()

    private lazy var contentButton: UIButton = {
        let contentButton = UIButton(type: .custom)
        contentButton.setTitle(content, for: .normal)
        contentButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        contentButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        contentButton.titleLabel?.textAlignment = .center
        contentButton.addTarget(self, action: #selector(selectedAction), for: .touchUpInside)
        return contentButton
    }()

    private lazy var lineView: UIView = {
        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.lineBorderComponent
        return lineView
    }()

    private lazy var abandonButton: UIButton = {
        let abandonButton = UIButton(type: .custom)
        abandonButton.setTitle(BundleI18n.LarkAI.Lark_Lingo_IMInputField_WordMeaningUnclearHover_IgnoreButton, for: .normal)
        abandonButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        abandonButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        abandonButton.titleLabel?.textAlignment = .center
        abandonButton.addTarget(self, action: #selector(abandonAction), for: .touchUpInside)
        return abandonButton
    }()

    init(content: String,
         tapPoint: CGPoint,
         textView: UITextView?) {
        self.content = content
        self.tapPoint = tapPoint
        self.textView = textView
        super.init(frame: .zero)
        setUpSubViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setUpSubViews() {
        isUserInteractionEnabled = true
        backgroundColor = UIColor.ud.bgBodyOverlay
        addSubview(wrapperView)

        wrapperView.addSubview(contentButton)
        self.contentWidth = (contentButton.titleLabel?.sizeThatFits(CGSize(width: 0.0, height: 20)).width ?? 0.0) + 32
        contentButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.width.equalTo(contentWidth)
            make.height.equalTo(40)
            make.centerY.equalToSuperview()
        }

        wrapperView.addSubview(abandonButton)
        self.abandonWidth = (abandonButton.titleLabel?.sizeThatFits(CGSize(width: 0.0, height: 20)).width ?? 0.0) + 32
        abandonButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.width.equalTo(abandonWidth)
            make.height.equalTo(40)
            make.centerY.equalToSuperview()
        }

        wrapperView.addSubview(lineView)
        lineView.snp.makeConstraints { (make) in
            make.right.equalTo(abandonButton.snp.left)
            make.left.equalTo(contentButton.snp.right)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 0.5, height: 40))
        }

        wrapperView.snp.makeConstraints { (make) in
            make.top.equalTo(contentButton)
            make.height.equalTo(40)
            make.left.equalTo(contentButton)
            make.right.equalTo(abandonButton)
        }

        snp.makeConstraints { (make) in
            make.edges.equalTo(wrapperView)
        }
    }

    public func drawCardBorder() {
        let width: CGFloat = self.contentWidth + self.abandonWidth + 2
        let height: CGFloat = 46
        let cornerX = self.textView?.convert(self.tapPoint, to: self).x ?? width
        let borderPath = UIBezierPath()
        borderPath.move(to: CGPoint(x: 0, y: 8))
        borderPath.addQuadCurve(to: CGPoint(x: 8, y: 0), controlPoint: CGPoint(x: 0, y: 0))
        borderPath.addLine(to: CGPoint(x: width - 8, y: 0))
        borderPath.addQuadCurve(to: CGPoint(x: width, y: 8), controlPoint: CGPoint(x: width, y: 0))
        borderPath.addLine(to: CGPoint(x: width, y: height - 8 - 6))
        borderPath.addQuadCurve(to: CGPoint(x: width - 8, y: height - 6), controlPoint: CGPoint(x: width, y: height - 6))
        borderPath.addLine(to: CGPoint(x: cornerX + 6, y: height - 6))
        borderPath.addLine(to: CGPoint(x: cornerX, y: height))
        borderPath.addLine(to: CGPoint(x: cornerX - 6, y: height - 6))
        borderPath.addLine(to: CGPoint(x: 8, y: height - 6))
        borderPath.addQuadCurve(to: CGPoint(x: 0, y: height - 6 - 8), controlPoint: CGPoint(x: 0, y: height - 6))
        borderPath.close()

        let borderLayer = CAShapeLayer()
        borderLayer.path = borderPath.cgPath
        borderLayer.ud.setStrokeColor(UIColor.ud.lineBorderComponent, bindTo: self)
        borderLayer.lineWidth = 0.5
        borderLayer.ud.setFillColor(UIColor.ud.bgBodyOverlay, bindTo: self)
        let layerCount: UInt32 = UInt32(layer.sublayers?.count ?? 1)
        layer.insertSublayer(borderLayer, at: layerCount - 1)
        self.layer.cornerRadius = 8.0
        self.layer.ud.setShadow(type: .s4Down)
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
