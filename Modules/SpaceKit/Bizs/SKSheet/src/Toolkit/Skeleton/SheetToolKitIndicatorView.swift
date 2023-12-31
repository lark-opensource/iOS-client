//
//  SheetToolKitIndicatorView.swift
//  SpaceKit
//
//  Created by huayufan on 2020/12/18.
//

import UIKit
import SKFoundation


final class SheetToolKitIndicatorView: UIView {
    
    struct Item {
        var begin: CGFloat
        var end: CGFloat
        var idx: Int
    }
    
    private var lineLayer = CAShapeLayer()
    private var bezierPath = UIBezierPath()
    private var items = [Int: Item]()
    /// scrollView的宽
    private(set) var pageWidth: CGFloat = 0
    /// 第一个子视图和最后一个子视图之间的长度
    private(set) var contentWidth: CGFloat = 0
    
    var lineWidth: CGFloat = 0 {
        didSet {
            self.lineLayer.lineWidth = lineWidth
            self.lineLayer.cornerRadius = lineWidth / 2
        }
    }
    
    var color: UIColor = UIColor.ud.colorfulBlue {
        didSet {
            self.lineLayer.strokeColor = color.cgColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSublayer()
    }
    
    private func setupSublayer() {
        lineLayer.construct {
            $0.cornerRadius = 1
            $0.lineWidth = 2
            $0.fillColor = UIColor.clear.cgColor
            $0.strokeColor = color.cgColor
            $0.lineCap = .round
            $0.speed = 2
        }
        layer.addSublayer(lineLayer)
    }
    
   
    func update(pageWidth: CGFloat, buttonFrames: [CGRect], titleWidths: [CGFloat]) {
        guard buttonFrames.count != 0, buttonFrames.count == titleWidths.count else {
            return
        }
        
        self.pageWidth = pageWidth
        items.removeAll()
        bezierPath.removeAllPoints()
        let floor = buttonFrames[0].minX + (buttonFrames[0].width - titleWidths[0]) / 2
        for (i, combin) in zip(buttonFrames, titleWidths).enumerated() {
            let frame = combin.0
            let width = combin.1
            let x = frame.minX + (frame.width - width) / 2 - floor
            items[i] = Item(begin: x, end: x + width, idx: i)
        }
        guard let first = items[0], let last = items[buttonFrames.count - 1] else {
            return
        }
        contentWidth = last.end - first.begin
        bezierPath.move(to: CGPoint(x: floor + first.begin, y: 0))
        bezierPath.addLine(to: CGPoint(x: floor + contentWidth, y: 0))
        lineLayer.path = bezierPath.cgPath
        lineLayer.strokeStart = 0
        lineLayer.strokeEnd = (first.end - first.begin) / contentWidth
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


extension SheetToolKitIndicatorView {
    
    // 实时滚动处理
    func scrollViewDidScroll(offset: CGFloat) {
        
        let index = Int(offset / pageWidth)
        guard let item = items[index] else { return }
        let currentBegin = item.begin
        let currentEnd = item.end
        let nextItem = items[index + 1]
        let nextBegin = nextItem?.begin ?? item.begin
        let nextEnd = nextItem?.end ?? item.end
        var relativeDelta = offset - CGFloat(index) * pageWidth
        var end: CGFloat = 0
        var start: CGFloat = 0
        var delta = nextEnd - currentEnd
        if relativeDelta <= pageWidth / 2.0 {
            delta = (relativeDelta / (pageWidth / 2.0)) * delta
            end = currentEnd + delta
            lineLayer.strokeStart = currentBegin / contentWidth
            lineLayer.strokeEnd = end / contentWidth
            
        } else {
            delta = nextBegin - currentBegin
            relativeDelta -= pageWidth / 2
            delta = (relativeDelta / (pageWidth / 2)) * delta
            start = currentBegin + delta
            lineLayer.strokeStart = start / contentWidth
            lineLayer.strokeEnd = nextEnd / contentWidth
        }
    }
    
    func reset(to index: Int) {
        guard let current = items[index] else {
            return
        }
        lineLayer.strokeStart = current.begin / contentWidth
        lineLayer.strokeEnd = current.end / contentWidth
    }
    
}
