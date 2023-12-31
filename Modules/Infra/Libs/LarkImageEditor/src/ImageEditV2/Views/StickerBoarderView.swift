//
//  StickerBoarderView.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/7/16.
//

import Foundation
import LarkUIKit
import UIKit

class StickerBoarderView: UIView, UIGestureRecognizerDelegate {
    private let ruSquare = UIView()
    private let ldSquare = UIView()
    private let lineLayer = CAShapeLayer()

    private lazy var luSquare = UIView()
    private lazy var rdSquare = UIView()
    private lazy var clearView = UIView()
    private lazy var containerView = UIView()

    private var boarderType: BoarderViewType

    private(set) var isBoardHidden = false

    init(with type: BoarderViewType = .rect) {
        boarderType = type

        super.init(frame: .zero)

        type == .rect ? setupForRect() : setupForLine()
    }

    private func setupForRect() {
        addSubview(containerView)
        containerView.backgroundColor = .clear
        containerView.snp.makeConstraints { make in make.edges.equalToSuperview() }

        containerView.addSubview(clearView)
        clearView.backgroundColor = .clear
        clearView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(7)
        }
        clearView.layer.borderWidth = 2
        clearView.layer.ud.setBorderColor(.ud.primaryContentDefault)

        [luSquare, ruSquare, ldSquare, rdSquare].forEach {
            containerView.addSubview($0)
            $0.backgroundColor = .ud.primaryContentDefault
            $0.snp.makeConstraints { make in
                make.size.equalTo(16)
            }
            $0.layer.ud.setBorderColor(.ud.primaryOnPrimaryFill)
            $0.layer.borderWidth = 2
            $0.layer.cornerRadius = 8
        }

        luSquare.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
        }
        ruSquare.snp.makeConstraints { make in
            make.right.top.equalToSuperview()
        }
        ldSquare.snp.makeConstraints { make in
            make.left.bottom.equalToSuperview()
        }
        rdSquare.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview()
        }
    }

    private func setupForLine() {
        addSubview(containerView)
        containerView.backgroundColor = .clear
        containerView.snp.makeConstraints { make in make.edges.equalToSuperview() }

        [ruSquare, ldSquare].forEach {
            containerView.addSubview($0)
            $0.backgroundColor = .ud.primaryContentDefault
            $0.bounds.size = .init(width: 16, height: 16)
            $0.layer.ud.setBorderColor(.ud.primaryOnPrimaryFill)
            $0.layer.borderWidth = 2
            $0.layer.cornerRadius = 8
        }

        lineLayer.lineWidth = 2
        lineLayer.strokeColor = UIColor.ud.primaryContentDefault.cgColor

        containerView.layer.addSublayer(lineLayer)
    }

    private func animateShow() {
        isBoardHidden = false
        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.containerView.alpha = 1
                       })
    }

    private func animateHiddenWithDelay() {
        UIView.animate(withDuration: 0.25,
                       delay: 0.3,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
                        self?.containerView.alpha = 0
                       },
                       completion: { [weak self] _ in
                        self?.isBoardHidden = true
                       })
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIRotationGestureRecognizer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// internal apis
extension StickerBoarderView {
    enum BoarderViewType {
        case line
        case rect
    }

    enum TouchType {
        case inRect
        case inLineHead
        case inLineTail
    }

    func temporaryShow() {
        animateShow()
        animateHiddenWithDelay()
    }

    func hidden() {
        isBoardHidden = true
        containerView.alpha = 0
    }

    func show() {
        isBoardHidden = false
        containerView.alpha = 1
    }

    func updateLine(startPosition: CGPoint, endPosition: CGPoint) {
        let startPointInContainer = convert(startPosition, to: containerView)
        let endPointInContainer = convert(endPosition, to: containerView)
        ldSquare.center = startPointInContainer
        ruSquare.center = endPointInContainer

        let linePath = UIBezierPath()
        linePath.move(to: startPointInContainer)
        linePath.addLine(to: endPointInContainer)
        lineLayer.path = linePath.cgPath
    }

    func checkPointInView(_ point: CGPoint) -> TouchType {
        switch boarderType {
        case .rect: return .inRect
        case .line:
            if ruSquare.frame.insetBy(dx: -30, dy: -30).contains(point) {
                return .inLineHead
            } else if ldSquare.frame.insetBy(dx: -30, dy: -30).contains(point) {
                return .inLineTail
            } else { return .inRect }
        }
    }
}
