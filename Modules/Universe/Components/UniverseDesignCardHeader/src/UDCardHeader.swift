//
//  UDCardHeader.swift
//  UniverseDesignCardHeader
//
//  Created by Siegfried on 2021/8/26.
//

import Foundation
import UIKit
import UniverseDesignColor
import SnapKit
import FigmaKit
import UniverseDesignTheme

// swiftlint:disable all
/// 通用消息卡片组件
///
/// 组件主要用来给IM、日历、会议等功能提供消息卡片的头部样式。
/// 消息卡片提供最大尺寸600px*140px头部背景配色、在卡片尺寸缩放时裁切背景，即背景不会随卡片尺寸缩放进行缩放。
open class UDCardHeader: UIView {
    /// 重写layerClass
    open override class var layerClass: AnyClass {
        return UDCardHeaderLayer.self
    }

    /// 替换 layer 为自定义 UDCardHeaderLayer
    var udLayer: UDCardHeaderLayer {
        return self.layer as! UDCardHeaderLayer
    }

    /// 卡片布局类型，默认normal使用即可
    open var layoutType: UDCardLayoutType

    /// 设置消息卡片背景色
    open var colorHue: UDCardHeaderHue {
        didSet {
            self.udLayer.setColorHue(colorHue, bindTo: self)
        }
    }

    // MARK: 初始化

    /// 创建使用内置规范颜色的消息卡片
    /// - parameters:
    ///   - colorHue: 消息卡片的色相，包含背景色及文本颜色
    ///   - layoutType: 消息卡片布局，使用默认值即可
    public init(colorHue: UDCardHeaderHue, layoutType: UDCardLayoutType = .normal) {
        self.colorHue = colorHue
        self.layoutType = layoutType
        super.init(frame: .zero)
        setup()
    }

    /// 创建使用自定义颜色的消息卡片
    ///
    /// - parameters:
    ///   - color: 消息卡片背景色
    ///   - textColor: 消息卡片文本颜色
    ///   - layoutType: 消息卡片布局，使用默认值即可
    public init(color: UIColor, textColor: UIColor, layoutType: UDCardLayoutType = .normal) {
        self.colorHue = UDCardHeaderHue(color: color, textColor: textColor)
        self.layoutType = layoutType
        super.init(frame: .zero)
        setup()
    }

    /// 创建根据frame初始化的消息卡片
    public override init(frame: CGRect) {
        self.colorHue = .blue
        self.layoutType = .normal
        super.init(frame: frame)
        setup()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        if case .top = layoutType {
            udLayer.setTopMaskPosition()
        } else {
            udLayer.setNormalMaskPosition()
        }
    }

    private func setup() {
        setAppearance()
    }

    private func setAppearance() {
        self.clipsToBounds = true
        self.layer.masksToBounds = true
        self.udLayer.setColorHue(self.colorHue, bindTo: self)
    }
}

class UDCardHeaderLayer: CALayer {

    /// 设置Layer的背景色、蒙板颜色
    func setColorHue(_ layerColorHue: UDCardHeaderHue, bindTo bindView: UIView) {
        self.ud.setBackgroundColor(layerColorHue.color, bindTo: bindView)
        self.leftMaskOval.ud.setFillColor(layerColorHue.maskColor, bindTo: bindView)
        self.midMaskOval.ud.setFillColor(layerColorHue.maskColor, bindTo: bindView)
        self.rightMaskOval.ud.setFillColor(layerColorHue.maskColor, bindTo: bindView)
    }

    /// 设置常规蒙板椭圆位置
    func setNormalMaskPosition() {
        leftMaskOval.position = CGPoint(x: Cons.leftOvalMoveOnX, y: Cons.leftOvalMoveOnY)
        midMaskOval.position = CGPoint(x:  Cons.midOvalMoveOnX, y: Cons.midOvalMoveOnY)
        rightMaskOval.position = CGPoint(x: Cons.rightOvalMoveOnX, y: Cons.rightOvalMoveOnY)
        midMaskOval.setAffineTransform(rotationTransform)
    }

    /// 设置顶部转发消息椭圆位置
    func setTopMaskPosition() {
        leftMaskOval.position = CGPoint(x: Cons.leftOvalMoveOnX, y: Cons.leftOvalMoveOnY + self.bounds.height)
        rightMaskOval.position = CGPoint(x:  Cons.midOvalMoveOnX, y: Cons.midOvalMoveOnY + self.bounds.height)
        midMaskOval.position = CGPoint(x:  Cons.midOvalMoveOnX, y: Cons.midOvalMoveOnY + self.bounds.height)
        midMaskOval.setAffineTransform(rotationTransform)
    }

    // 椭圆Rect
    private lazy var leftRect = CGRect(x: 0, y: 0, width: Cons.leftOvalWidth, height: Cons.leftOvalheight)
    private lazy var midRect = CGRect(x: 0, y: 0, width: Cons.midOvalWidth, height: Cons.midOvalheight)
    private lazy var rightRect = CGRect(x: 0, y: 0, width: Cons.rightOvalWidth, height: Cons.rightOvalheight)
    private lazy var rotationTransform = CGAffineTransform(rotationAngle: CGFloat(Cons.midOvalRotationDeg))
    private let bgLayer: CALayer = CALayer()

    // MARK: Components
    /// 左侧椭圆
    private lazy var leftMaskOval = MaskOvalLayer(rect: leftRect, blur: Cons.leftOvalblur)
    /// 中间椭圆
    private lazy var midMaskOval = MaskOvalLayer(rect: midRect, blur: Cons.midOvalblur)
    /// 右侧椭圆
    private lazy var rightMaskOval = MaskOvalLayer(rect: rightRect, blur: Cons.rightOvalblur)

    private lazy var blurView: BackgroundBlurView = {
        let blurView = BackgroundBlurView()
        blurView.fillOpacity = 0.1
        blurView.blurRadius = 70
        return blurView
    }()

    /// 重写 init() 方法
    override init() {
        super.init()
        bgLayer.addSublayer(leftMaskOval)
        bgLayer.addSublayer(midMaskOval)
        bgLayer.addSublayer(rightMaskOval)
//        bgLayer.addSublayer(blurView.layer)
        super.addSublayer(bgLayer)
    }

    override func layoutSublayers() {
        super.layoutSublayers()
//        blurView.layer.frame = self.bounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 重写Layer索引
    override var sublayers: [CALayer]? {
        get {
            guard let sublayers = super.sublayers else {
                return nil
            }
            return Array(sublayers.suffix(from: 1))
        }
        set {
            assert(true)
        }
    }

    /// 重写插入Layer方法 at
    override func insertSublayer(_ layer: CALayer, at idx: UInt32) {
        super.insertSublayer(layer, at: idx + 1)
    }

    /// 重写插入Layer方法 below
    override func insertSublayer(_ layer: CALayer, below sibling: CALayer?) {
        if let sibling = sibling, let index = sublayers?.firstIndex(where: { $0 == sibling }) {
            super.insertSublayer(layer, at: UInt32(index) + 1)
            return
        }
        super.insertSublayer(layer, at: 1)
    }

    /// 重写插入Layer方法 above
    override func insertSublayer(_ layer: CALayer, above sibling: CALayer?) {
        if let sibling = sibling, let index = sublayers?.lastIndex(where: { $0 == sibling }) {
            super.insertSublayer(layer, at: UInt32(index) + 2)
            return
        }
        super.addSublayer(layer)
    }
}

//// MARK: 绘制椭圆
class MaskOvalLayer: CAShapeLayer {

    /// 替换CAShapeLayer
    override init(layer: Any) {
        super.init(layer: layer)
        guard layer is MaskOvalLayer else { return }
    }

    /// 初始化背景的椭圆蒙版
    ///
    /// - parameters:
    ///   - ovalBackgroundColor: 椭圆颜色
    ///   - rect: 椭圆形状
    ///   - blur: 椭圆模糊程度
    init(ovalBackgroundColor: UIColor = UIColor.ud.N00, rect: CGRect, blur: CGFloat) {
        super.init()
//        let ovalPath = UIBezierPath(ovalIn: rect)
//        self.path = ovalPath.cgPath
//        self.fillColor = ovalBackgroundColor.cgColor
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UDCardHeader {
    /// 卡片布局
    ///
    /// 如消息卡片 上半部分为IM消息转发，下半部分为开放平台字段，则上半部分消息卡片类型为top，下半部分类型为normal，默认为normal
    public enum UDCardLayoutType {
        /// 常规默认参数
        case normal
        /// 特化参数，拼接消息卡片时，上半部分视图,如转发、回复部分
        case top
    }
}

// MARK: 字段配置
fileprivate enum Cons {
    /// 左侧椭圆宽度
    static var leftOvalWidth: CGFloat { 360 }
    /// 左侧椭圆高度
    static var leftOvalheight: CGFloat { 120 }
    /// 中间椭圆宽度
    static var midOvalWidth: CGFloat { 280 }
    /// 中间椭圆高度
    static var midOvalheight: CGFloat { 320 }
    /// 右侧椭圆宽度
    static var rightOvalWidth: CGFloat { 360 }
    /// 右侧椭圆高度
    static var rightOvalheight: CGFloat { 120 }
    /// 左侧椭圆横向偏移
    static var leftOvalMoveOnX: CGFloat { -200 }
    /// 左侧椭圆纵向偏移
    static var leftOvalMoveOnY: CGFloat { 36 }
    /// 中间椭圆横向偏移
    static var midOvalMoveOnX: CGFloat { 220 }
    /// 中间椭圆默认纵向偏移
    static var midOvalMoveOnY: CGFloat { -200 }
    /// 中间椭圆旋转角度
    static var midOvalRotationDeg: Double { -50 }
    /// 右侧椭圆横向偏移
    static var rightOvalMoveOnX: CGFloat { 416 }
    /// 右侧椭圆纵向偏移
    static var rightOvalMoveOnY: CGFloat { 41 }
    /// 左侧椭圆的模糊度
    static var leftOvalblur: CGFloat { 60 }
    /// 中间椭圆的模糊度
    static var midOvalblur: CGFloat { 70 }
    /// 右侧椭圆的模糊度
    static var rightOvalblur: CGFloat { 60 }
}
// swiftlint:enable all
