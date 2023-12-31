//
//  CountdownView.swift
//  Calendar
//
//  Created by harry zou on 2019/4/14.
//

import UIKit
import CalendarFoundation
final class CountdownView: UIView {
    let realCountdownView: RealCountdownView
    let scale: CGFloat
    let redius: CGFloat

    override var intrinsicContentSize: CGSize {
        return CGSize(width: redius * 2 * scale, height: redius * 2 * scale)
    }

    init(redius: CGFloat,
         lineWidth: CGFloat,
         secondsLeft: Double,
         totalSeconds: Int,
         scale: CGFloat) {
        self.realCountdownView = RealCountdownView(redius: redius, lineWidth: lineWidth, secondsLeft: secondsLeft, totalSeconds: totalSeconds)
        self.scale = scale
        self.redius = redius
        super.init(frame: .zero)
        addSubview(realCountdownView)
        realCountdownView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        realCountdownView.transform = CGAffineTransform(scaleX: scale, y: scale)
    }

    func update(secondsLeft: Double, totalSeconds: Int) {
        realCountdownView.update(secondsLeft: secondsLeft, totalSeconds: totalSeconds)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func distanceToUpItem(width: CGFloat) -> CGFloat {
        switch width {
        case 375:
            return 40
        case 320:
            return 30
        case 414:
            return 80
        default:
            assertionFailureLog("让UI赶紧适配新尺寸")
            return 40
        }
    }

    func distanceToButton(width: CGFloat) -> CGFloat {
        switch width {
        case 375:
            return 32
        case 320:
            return 22
        case 414:
            return 52
        default:
            assertionFailureLog("让UI赶紧适配新尺寸")
            return 40
        }
    }
}

final class RealCountdownView: UIView {

    private let oneDegree: CGFloat = CGFloat.pi / 180

    private let lineWidth: CGFloat
    private let outerRedius: CGFloat
    private var secondsLeft: Double
    private var totalSeconds: Int

    private var topLayer = CALayer()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.cd.dinBoldFont(ofSize: 50)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private let hintLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.cd.regularFont(ofSize: 16)
        label.textColor = UIColor.ud.textCaption
        label.text = BundleI18n.Calendar.Calendar_Takeover_TipsToTake
        return label
    }()

    override var intrinsicContentSize: CGSize {
        return CGSize(width: outerRedius * 2, height: outerRedius * 2)
    }

    /// - Parameters:
    ///   - redius: 倒计时圈外半径
    ///   - lineWidth: 倒计时圈宽度
    ///   - secondsLeft: 还剩多少秒
    init(redius: CGFloat,
         lineWidth: CGFloat,
         secondsLeft: Double,
         totalSeconds: Int) {
        self.outerRedius = redius
        self.lineWidth = lineWidth
        self.secondsLeft = secondsLeft
        self.totalSeconds = totalSeconds
        super.init(frame: CGRect(x: 0, y: 0, width: redius * 2, height: redius * 2 ))
        drawBottomCircle()
        topLayer.frame = self.bounds
        layer.addSublayer(topLayer)
        updateTopCircle()
        layout(timeLabel: timeLabel)
        layout(hintLabel: hintLabel)
    }

    func layout(timeLabel: UIView) {
        addSubview(timeLabel)
        timeLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(74)
        }
    }

    func layout(hintLabel: UIView) {
        addSubview(hintLabel)
        hintLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(139)
        }
    }

    func update(secondsLeft: Double, totalSeconds: Int) {
        self.secondsLeft = secondsLeft
        self.totalSeconds = totalSeconds
        updateTopCircle()
        timeLabel.text = seconds2Timestamp(intSeconds: Int(secondsLeft))
        if secondsLeft == 0 {
            timeLabel.textColor = UIColor.ud.textDisable
            hintLabel.text = BundleI18n.Calendar.Calendar_Takeover_TipsToTakeTwo
        } else {
            timeLabel.textColor = UIColor.ud.textTitle
            hintLabel.text = BundleI18n.Calendar.Calendar_Takeover_TipsToTake
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func getEndAngle(secondsLeft: Double, totalSeconds: Int) -> CGFloat {
        let totalSeconds = Double(totalSeconds)
        let startDegree: CGFloat = 3.43
        let endDegree: CGFloat = 357.5
        if secondsLeft < 0 || secondsLeft > totalSeconds {
            assertionFailureLog()
            return CGFloat.pi * 3 / 2
        }
        if secondsLeft == 0 || secondsLeft == 1 {
            return CGFloat.pi * 3 / 2
        }
        if secondsLeft == 2 {
            return CGFloat.pi * -1 / 2 + endDegree * oneDegree
        }
        var degree: CGFloat = 0.0
        var degreePerSecond: CGFloat = 360.0 / CGFloat(totalSeconds)
        if secondsLeft > totalSeconds - 10 {
            degreePerSecond = (10 * degreePerSecond - startDegree) / 10
            degree = startDegree + CGFloat(totalSeconds - secondsLeft) * degreePerSecond
        } else if secondsLeft < 10 {
            degreePerSecond = (degreePerSecond * 10 - 360 + endDegree) / 9
            degree = endDegree - CGFloat(secondsLeft - 1) * degreePerSecond
        } else {
            degree = CGFloat(totalSeconds - secondsLeft) * degreePerSecond
        }
        return CGFloat.pi * -1 / 2 + degree * oneDegree
    }

    func drawBottomCircle() {
        let layer = CAShapeLayer()
        layer.frame = self.bounds
        self.layer.addSublayer(layer)
        let path = UIBezierPath()
        let endAngle = CGFloat.pi * -1 / 2
        UIGraphicsBeginImageContext(self.bounds.size)
        path.addArc(withCenter: CGPoint(x: outerRedius, y: outerRedius),
                    radius: outerRedius - lineWidth / 2,
                    startAngle: CGFloat.pi * 3 / 2,
                    endAngle: endAngle,
                    clockwise: false)
        path.stroke()
        UIGraphicsEndImageContext()
        layer.path = path.cgPath
        layer.ud.setFillColor(UIColor.clear, bindTo: self)
        layer.ud.setStrokeColor(UIColor.ud.lineBorderCard, bindTo: self)
        layer.lineWidth = lineWidth
        layer.lineCap = .butt
    }

    func getBackgroundLayer() -> CALayer {
        let layer = CAGradientLayer()
        layer.frame = self.bounds
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.colors = [UIColor.ud.P400.cgColor, UIColor.ud.W400.cgColor]
        return layer
    }

    func updateTopCircle() {
        topLayer.removeFromSuperlayer()
        if secondsLeft == 0 {
            return
        }
        let maskLayer = CountDownCircleLayer(startColor: UIColor.ud.P400,
                                             endColor: UIColor.ud.W400,
                                             endAngle: getEndAngle(secondsLeft: secondsLeft, totalSeconds: totalSeconds),
                                             outerRedius: outerRedius,
                                             lineWidth: lineWidth,
                                             isLastSecond: secondsLeft == 1,
                                             size: self.bounds.size,
                                             bindTo: self)
        maskLayer.frame = self.bounds
        maskLayer.opacity = 1
        let backGroundLayer = getBackgroundLayer()
        backGroundLayer.masksToBounds = false
        backGroundLayer.mask = maskLayer
        maskLayer.setNeedsDisplay()
        topLayer = backGroundLayer
        self.layer.addSublayer(topLayer)
    }

    func seconds2Timestamp(intSeconds: Int) -> String {
        let mins: Int = intSeconds / 60
        let secs: Int = intSeconds % 60

    let strTimestamp: String = String(format: "%02d", mins) + ":" + String(format: "%02d", secs)
        return strTimestamp
    }
}
