//
//  TemplateLoadingView.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2022/1/28.
//  


import UIKit
import SkeletonView

class TemplateLoadingView: UIView {
    lazy var lineViews = [UIView]()
    lazy var circleView = UIView()
    let leftOffset: CGFloat = 0
    let lineHeight: CGFloat = 8
    var paddingV: CGFloat = 8
    var width: CGFloat = 0
    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.N00
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func addSKLineView(width: CGFloat, paddingV: CGFloat) {
        self.width = width
        self.paddingV = paddingV
        for _ in 0..<4 {
            let label = getASKLineView()
            self.addSubview(label)
            lineViews.append(label)
        }
        self.addSubview(circleView)

        setLinesLayoutWhenVertical()

        lineViews.append(circleView)
        backgroundColor = .clear
    }

    func setSKAnimateStart(_ start: Bool) {
        lineViews.forEach { (label) in
            label.isHidden = !start
            start ? label.startSkeletonAnimation() : label.stopSkeletonAnimation()
        }
    }

    func setLineViewSKable(_ label: UIView) {
        label.isSkeletonable = true
        let skeletonGradient = SkeletonGradient(baseColor: UIColor.ud.N100, secondaryColor: UIColor.ud.N300)
        label.showAnimatedGradientSkeleton(usingGradient: skeletonGradient)
    }

    func setLinesLayoutWhenVertical() {
        let circleWidth: CGFloat = 24
        circleView.layer.cornerRadius = circleWidth / 2.0
        circleView.layer.masksToBounds = true
        circleView.frame = CGRect(x: leftOffset, y: 0, width: circleWidth, height: circleWidth)
        setLineViewSKable(circleView)
        let paddingH: CGFloat = 6
        let line1Width: CGFloat = width - circleWidth - paddingH
        let widths: [CGFloat] = [line1Width,
                                 line1Width * (60.0 / 94.0),
                                 width,
                                 width]
        
        let linesX: [CGFloat] = [circleWidth + paddingH, circleWidth + paddingH, 0, 0]
        for (index, label) in lineViews.enumerated() {
            label.frame = CGRect(x: linesX[index],
                                 y: (lineHeight + paddingV) * CGFloat(index),
                                 width: widths[index],
                                 height: lineHeight)

            setLineViewSKable(label)
        }
    }

    func getASKLineView() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: lineHeight)
        label.numberOfLines = 1
        label.layer.cornerRadius = 2
        label.layer.masksToBounds = true
        return label
    }
}
