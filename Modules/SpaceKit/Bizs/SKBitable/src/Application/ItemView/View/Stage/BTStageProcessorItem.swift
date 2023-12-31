//
//  BTStageDetailInfoCell.swift
//  SKBitable
//
//  Created by X-MAN on 2023/5/29.
//

import Foundation
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignButton
import UniverseDesignIcon
import SKResource
import SKCommon
import SKBrowser

fileprivate enum BackgroundStyle {
    case firstPlain // 第一个非选中状态
    case firstBoader // 第一个非选中状态
    case centerPlain // 中间非选中
    case centerBoader // 中间选中
    case lastPlain // 最后一个非选中
    case lastBoarder // 第一个选中
}

fileprivate final class ProcessBackgorundView: UIView {
    
    private let inset: CGFloat = 4.0
    private let contentHeight: CGFloat = 36.0
    private var style: BackgroundStyle = .centerPlain
    private var strokeColor: UIColor = .clear
    private var fillColor: UIColor = .clear
    /// 高度限制36
    override init(frame: CGRect) {
        super.init(frame: .zero)
        layer.backgroundColor = UIColor.clear.cgColor
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func drawFirst(in rect: CGRect, isBoarder: Bool) {
        let originWidth = 114.0
        let additionWidth = rect.width - originWidth - inset
        let path = UIBezierPath()
        path.lineWidth = 2.0
        path.move(to: CGPoint(x: inset / 2, y: 10.2 + inset / 2))
        path.addCurve(to: CGPoint(x: 0.9 + inset / 2, y: 2.9 + inset / 2),
                      controlPoint1: CGPoint(x: inset / 2, y: 6.3 + inset / 2),
                      controlPoint2: CGPoint(x: inset / 2, y: 4.3 + inset / 2))
        path.addCurve(to: CGPoint(x: 2.9 + inset / 2, y: 0.9 + inset / 2),
                      controlPoint1: CGPoint(x: 1.4 + inset / 2, y: 2.1 + inset / 2),
                      controlPoint2: CGPoint(x: 2.1 + inset / 2, y: 1.4 + inset / 2))
        path.addCurve(to: CGPoint(x: 10.2 + inset / 2, y: inset / 2),
                      controlPoint1: CGPoint(x: 4.3 + inset / 2, y: inset / 2),
                      controlPoint2: CGPoint(x: 6.3 + inset / 2, y: inset / 2))
        path.addLine(to: CGPoint(x: additionWidth + 104.8 + inset / 2, y: inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 106.6 + inset / 2, y: 0.2 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 105.7 + inset / 2, y: inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 106.2 + inset / 2, y: inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 107.2 + inset / 2, y: 0.6 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 106.8 + inset / 2, y: 0.3 + inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 107 + inset / 2, y: 0.4 + inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 108 + inset / 2, y: 2.2 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 107.5 + inset / 2, y: 0.9 + inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 107.6 + inset / 2, y: 1.3 + inset / 2))
        path.addLine(to: CGPoint(x: additionWidth + 113.8 + inset / 2, y: 17.4 + inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 113.9 + inset / 2, y: 17.9 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 113.9 + inset / 2, y: 17.6 + inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 113.9 + inset / 2, y: 17.8 + inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 113.9 + inset / 2, y: 18.1 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 113.9 + inset / 2, y: 18 + inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 113.9 + inset / 2, y: 18 + inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 113.8 + inset / 2, y: 18.6 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 113.9 + inset / 2, y: 18.2 + inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 113.9 + inset / 2, y: 18.4 + inset / 2))
        path.addLine(to: CGPoint(x: additionWidth + 108 + inset / 2, y: 33.8 + inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 107.2 + inset / 2, y: 35.4 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 107.6 + inset / 2, y: 34.7 + inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 107.5 + inset / 2, y: 35.1 + inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 106.6 + inset / 2, y: 35.8 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 107 + inset / 2, y: 35.6 + inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 106.8 + inset / 2, y: 35.7 + inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 104.8 + inset / 2, y: 36 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 106.2 + inset / 2, y: 36 + inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 105.7 + inset / 2, y: 36 + inset / 2))
        path.addLine(to: CGPoint(x: 10.2 + inset / 2, y: 36 + inset / 2))
        path.addCurve(to: CGPoint(x: 2.9 + inset / 2, y: 35.1 + inset / 2),
                      controlPoint1: CGPoint(x: 6.3 + inset / 2, y: 36 + inset / 2),
                      controlPoint2: CGPoint(x: 4.3 + inset / 2, y: 36 + inset / 2))
        path.addCurve(to: CGPoint(x: 0.9 + inset / 2, y: 33.1 + inset / 2),
                      controlPoint1: CGPoint(x: 2.1 + inset / 2, y: 34.6 + inset / 2),
                      controlPoint2: CGPoint(x: 1.4 + inset / 2, y: 33.9 + inset / 2))
        path.addCurve(to: CGPoint(x: inset / 2, y: 25.8 + inset / 2),
                      controlPoint1: CGPoint(x: inset / 2, y: 31.7 + inset / 2),
                      controlPoint2: CGPoint(x: inset / 2, y: 29.7 + inset / 2))
        path.addLine(to: CGPoint(x: inset / 2, y: 18 + inset / 2))
        path.addLine(to: CGPoint(x: inset / 2, y: 10.2 + inset / 2))
        fillColor.setFill()
        path.fill()
        isBoarder ? strokeColor.setStroke() : fillColor.setStroke()
        path.stroke()
        path.close()
    }
    
    private func drawCenter(in rect: CGRect, isBoarder: Bool)  {
        let originWidth = 114.0
        let additionWidth = rect.width - originWidth - inset
        let path = UIBezierPath()
        path.lineWidth = 2.0
        path.move(to: CGPoint(x: 1.8 + inset / 2, y: 4.6 + inset / 2))
        path.addCurve(to: CGPoint(x: 1 + inset / 2, y: 1.4 + inset / 2),
                      controlPoint1: CGPoint(x: 1.1 + inset / 2, y: 2.9 + inset / 2),
                      controlPoint2: CGPoint(x: 0.8 + inset / 2, y: 2.1 + inset / 2))
        path.addCurve(to: CGPoint(x: 1.6 + inset / 2, y: 0.4 + inset / 2),
                      controlPoint1: CGPoint(x: 1.1 + inset / 2, y: 1 + inset / 2),
                      controlPoint2: CGPoint(x: 1.3 + inset / 2, y: 0.7 + inset / 2))
        path.addCurve(to: CGPoint(x: 4.9 + inset / 2, y: 0 + inset / 2),
                      controlPoint1: CGPoint(x: 2.2 + inset / 2, y: inset / 2),
                      controlPoint2: CGPoint(x: 3.1 + inset / 2, y: inset / 2))
        path.addLine(to: CGPoint(x: additionWidth + 104.8 + inset / 2, y: inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 106.6 + inset / 2, y: 0.2 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 105.7 + inset / 2, y: inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 106.2 + inset / 2, y: inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 107.2 + inset / 2, y: 0.6 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 106.8 + inset / 2, y: 0.3 + inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 107 + inset / 2, y: 0.4 + inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 108 + inset / 2, y: 2.2 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 107.5 + inset / 2, y: 0.9 + inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 107.6 + inset / 2, y: 1.3 + inset / 2))
        path.addLine(to: CGPoint(x: additionWidth + 113.8 + inset / 2, y: 17.4 + inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 113.9 + inset / 2, y: 17.9 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 113.9 + inset / 2, y: 17.6 + inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 113.9 + inset / 2, y: 17.8 + inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 113.9 + inset / 2, y: 18.1 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 113.9 + inset / 2, y: 18 + inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 113.9 + inset / 2, y: 18 + inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 113.8 + inset / 2, y: 18.6 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 113.9 + inset / 2, y: 18.2 + inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 113.9 + inset / 2, y: 18.4 + inset / 2))
        path.addLine(to: CGPoint(x: additionWidth + 108 + inset / 2, y: 33.8 + inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 107.2 + inset / 2, y: 35.4 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 107.6 + inset / 2, y: 34.7 + inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 107.5 + inset / 2, y: 35.1 + inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 106.6 + inset / 2, y: 35.8 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 107 + inset / 2, y: 35.6 + inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 106.8 + inset / 2, y: 35.7 + inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 104.8 + inset / 2, y: 36 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 106.2 + inset / 2, y: 36 + inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 105.7 + inset / 2, y: 36 + inset / 2))
        path.addLine(to: CGPoint(x: 4.9 + inset / 2, y: 36 + inset / 2))
        path.addCurve(to: CGPoint(x: 1.6 + inset / 2, y: 35.6 + inset / 2),
                      controlPoint1: CGPoint(x: 3.1 + inset / 2, y: 36 + inset / 2),
                      controlPoint2: CGPoint(x: 2.2 + inset / 2, y: 36 + inset / 2))
        path.addCurve(to: CGPoint(x: 1 + inset / 2, y: 34.6 + inset / 2),
                      controlPoint1: CGPoint(x: 1.3 + inset / 2, y: 35.3 + inset / 2),
                      controlPoint2: CGPoint(x: 1.1 + inset / 2, y: 35 + inset / 2))
        path.addCurve(to: CGPoint(x: 1.8 + inset / 2, y: 31.4 + inset / 2),
                      controlPoint1: CGPoint(x: 0.8 + inset / 2, y: 33.9 + inset / 2),
                      controlPoint2: CGPoint(x: 1.1 + inset / 2, y: 33.1 + inset / 2))
        path.addLine(to: CGPoint(x: 6.6 + inset / 2, y: 18.6 + inset / 2))
        path.addCurve(to: CGPoint(x: 6.8 + inset / 2, y: 18.1 + inset / 2),
                      controlPoint1: CGPoint(x: 6.7 + inset / 2, y: 18.4 + inset / 2),
                      controlPoint2: CGPoint(x: 6.8 + inset / 2, y: 18.2 + inset / 2))
        path.addCurve(to: CGPoint(x: 6.8 + inset / 2, y: 17.9 + inset / 2),
                      controlPoint1: CGPoint(x: 6.8 + inset / 2, y: 18 + inset / 2),
                      controlPoint2: CGPoint(x: 6.8 + inset / 2, y: 18 + inset / 2))
        path.addCurve(to: CGPoint(x: 6.6 + inset / 2, y: 17.4 + inset / 2),
                      controlPoint1: CGPoint(x: 6.8 + inset / 2, y: 17.8 + inset / 2),
                      controlPoint2: CGPoint(x: 6.7 + inset / 2, y: 17.6 + inset / 2))
        path.addLine(to: CGPoint(x: 1.8 + inset / 2, y: 4.6 + inset / 2))
        fillColor.setFill()
        path.fill()
        isBoarder ? strokeColor.setStroke() : fillColor.setStroke()
        path.stroke()
        path.close()
    }

    private func drawLast(in rect: CGRect, isBoarder: Bool) {
        let originWidth = 107.14
        let additionWidth = rect.width - originWidth - inset
        let path = UIBezierPath()
        path.lineWidth = 2.0
        path.move(to: CGPoint(x: 1.8 + inset / 2, y: 4.6 + inset / 2))
        path.addCurve(to: CGPoint(x: 1 + inset / 2, y: 1.4 + inset / 2),
                      controlPoint1: CGPoint(x: 1.1 + inset / 2, y: 2.9 + inset / 2),
                      controlPoint2: CGPoint(x: 0.8 + inset / 2, y: 2.1 + inset / 2))
        path.addCurve(to: CGPoint(x: 1.6 + inset / 2, y: 0.4 + inset / 2),
                      controlPoint1: CGPoint(x: 1.1 + inset / 2, y: 1 + inset / 2),
                      controlPoint2: CGPoint(x: 1.3 + inset / 2, y: 0.7 + inset / 2))
        path.addCurve(to: CGPoint(x: 4.9 + inset / 2, y: inset / 2),
                      controlPoint1: CGPoint(x: 2.2 + inset / 2, y: inset / 2),
                      controlPoint2: CGPoint(x: 3.1 + inset / 2, y: inset / 2))
        path.addLine(to: CGPoint(x: additionWidth + 96.9 + inset / 2, y: inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 104.3 + inset / 2, y: 0.9 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 100.9 + inset / 2, y: inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 102.8 + inset / 2, y: inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 106.3 + inset / 2, y: 2.9 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 105.1 + inset / 2, y: 1.4 + inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 105.8 + inset / 2, y: 2.1 + inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 107.1 + inset / 2, y: 10.2 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 107.1 + inset / 2, y: 4.3 + inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 107.1 + inset / 2, y: 6.3 + inset / 2))
        path.addLine(to: CGPoint(x: additionWidth + 107.1 + inset / 2, y: 18 + inset / 2))
        path.addLine(to: CGPoint(x: additionWidth + 107.1 + inset / 2, y: 25.8 + inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 106.3 + inset / 2, y: 33.1 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 107.1 + inset / 2, y: 29.7 + inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 107.1 + inset / 2, y: 31.7 + inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 104.3 + inset / 2, y: 35.1 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 105.8 + inset / 2, y: 33.9 + inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 105.1 + inset / 2, y: 34.6 + inset / 2))
        path.addCurve(to: CGPoint(x: additionWidth + 96.9 + inset / 2, y: 36 + inset / 2),
                      controlPoint1: CGPoint(x: additionWidth + 102.8 + inset / 2, y: 36 + inset / 2),
                      controlPoint2: CGPoint(x: additionWidth + 100.9 + inset / 2, y: 36 + inset / 2))
        path.addLine(to: CGPoint(x: 4.9 + inset / 2, y: 36 + inset / 2))
        path.addCurve(to: CGPoint(x: 1.6 + inset / 2, y: 35.6 + inset / 2),
                      controlPoint1: CGPoint(x: 3.1 + inset / 2, y: 36 + inset / 2),
                      controlPoint2: CGPoint(x: 2.2 + inset / 2, y: 36 + inset / 2))
        path.addCurve(to: CGPoint(x: 1 + inset / 2, y: 34.6 + inset / 2),
                      controlPoint1: CGPoint(x: 1.3 + inset / 2, y: 35.3 + inset / 2),
                      controlPoint2: CGPoint(x: 1.1 + inset / 2, y: 35 + inset / 2))
        path.addCurve(to: CGPoint(x: 1.8 + inset / 2, y: 31.4 + inset / 2),
                      controlPoint1: CGPoint(x: 0.8 + inset / 2, y: 33.9 + inset / 2),
                      controlPoint2: CGPoint(x: 1.1 + inset / 2, y: 33.1 + inset / 2))
        path.addLine(to: CGPoint(x: 6.6 + inset / 2, y: 18.6 + inset / 2))
        path.addCurve(to: CGPoint(x: 6.8 + inset / 2, y: 18.1 + inset / 2),
                      controlPoint1: CGPoint(x: 6.7 + inset / 2, y: 18.4 + inset / 2),
                      controlPoint2: CGPoint(x: 6.8 + inset / 2, y: 18.2 + inset / 2))
        path.addCurve(to: CGPoint(x: 6.8 + inset / 2, y: 17.9 + inset / 2),
                      controlPoint1: CGPoint(x: 6.8 + inset / 2, y: 18 + inset / 2),
                      controlPoint2: CGPoint(x: 6.8 + inset / 2, y: 18 + inset / 2))
        path.addCurve(to: CGPoint(x: 6.6 + inset / 2, y: 17.4 + inset / 2),
                      controlPoint1: CGPoint(x: 6.8 + inset / 2, y: 17.8 + inset / 2),
                      controlPoint2: CGPoint(x: 6.7 + inset / 2, y: 17.6 + inset / 2))
        path.addLine(to: CGPoint(x: 1.8 + inset / 2, y: 4.6 + inset / 2))
        fillColor.setFill()
        path.fill()
        isBoarder ? strokeColor.setStroke() : fillColor.setStroke()
        path.stroke()
        path.close()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard rect.width > 0, rect.height > 0 else {
            return
        }
        reDraw(in: rect)
    }
    
    func reDraw(in rect: CGRect) {
        switch style {
        case .firstPlain:
            drawFirst(in: rect,isBoarder: false)
        case .firstBoader:
            drawFirst(in: rect, isBoarder: true)
        case .centerPlain:
            drawCenter(in: rect, isBoarder: false)
        case .centerBoader:
            drawCenter(in: rect, isBoarder: true)
        case .lastPlain:
            drawLast(in: rect, isBoarder: false)
        case .lastBoarder:
            drawLast(in: rect, isBoarder: true)
        }
    }
    
    func config(with style: BackgroundStyle, fillColor: UIColor, strokeColor: UIColor) {
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.style = style
        setNeedsDisplay()
    }
}

final class BTStageProcessorItemView: UICollectionViewCell {
    
    enum Style {
        case first
        case center
        case last
    }
    
    private lazy var containerView: ProcessBackgorundView = {
        let view = ProcessBackgorundView()
        return view
    }()
    
    private lazy var stageItem: BTStageItemView = {
        let stageItem = BTStageItemView(with: .normal)
        return stageItem
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        contentView.addSubview(containerView)
        containerView.addSubview(stageItem)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        stageItem.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview().offset(-4)
            make.leading.greaterThanOrEqualToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
        }
    }
    
    static func width(text: String, isCurrent: Bool = false) -> CGFloat {
        return 43 + BTStageItemView.width(with: text, style: .big)
    }
    
    func config(_ model: BTStageModel, style: Style, progressingColor: UIColor?) {
        let isCurrent = model.isCurrent
        stageItem.configInDetail(name: model.name, status: model.status, bold: isCurrent)
        stageItem.backgroundColor = .clear
        let containerStyle: BackgroundStyle
        let strockColor: UIColor = UDColor.textLinkHover
        let fillColor: UIColor
        switch model.status {
            case .finish:
                fillColor = UDColor.functionSuccess400
            case .pending:
                fillColor = UDColor.N200
            case .progressing:
                fillColor = progressingColor ?? UDColor.B100
        }
        switch style {
        case .first:
            containerStyle = isCurrent ? .firstBoader : .firstPlain
        case .center:
            containerStyle = isCurrent ? .centerBoader : .centerPlain
        case .last:
            containerStyle = isCurrent ? .lastBoarder : .lastPlain
        }
        containerView.config(with: containerStyle, fillColor: fillColor, strokeColor: strockColor)
    }
    
}
