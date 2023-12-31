//
//  LKStarRateView.swift
//  LarkChat
//
//  Created by bytedance on 2020/9/13.
//

import Foundation
import UIKit
import UniverseDesignIcon

public protocol LKStarRateViewDelegate: AnyObject {
    /// 返回星星评分的分值
    func starRate(view starRateView: LKStarRateView, count: Float)
}

public struct LKStarRateViewConfig {
    /// 星星总数, 默认为5
    public var numOfStar: Int = 5
    /// 当前分数, 默认为0
    public var currentNumOfStar: Float = 0
    /// 是否为整星评分
    public var integerStar: Bool = true
    /// 是否可滑动
    public var userPanEnabled: Bool = true
    /// 跟随时间, 默认0.1秒
    public var followDuration: TimeInterval = 0.1
    /// 星星之间的间隙
    public var gap: CGFloat = 12
    /// 星星的边长
    public var starEdge: CGFloat = 36
    /// 未打分时候星星的图片
    public var darkImage: UIImage = {
        return UDIcon.getIconByKey(.collectFilled, size: CGSize(width: 36, height: 36)).ud.withTintColor(UIColor.ud.N90015)
    }()
    /// 点亮之后的星星的图片
    public var lightImage: UIImage = {
        return UDIcon.getIconByKey(.collectFilled, size: CGSize(width: 36, height: 36)).ud.withTintColor(UIColor.ud.colorfulYellow)
    }()
}

public final class LKStarRateView: UIView {
    public weak var delegate: LKStarRateViewDelegate?
    private var config: LKStarRateViewConfig
    /// 是否整星
    private var integerStar: Bool {
        didSet {
            showStarRate()
        }
    }
    /// 当前的星星数量
    private var currentStarCount: Float {
        didSet {
            showStarRate()
        }
    }
    /// 星星总数量
    private var numberOfStars: Int
    /// 默认跟随时间为0.1秒
    private var followDuration: TimeInterval
    /// 是否可滑动
    private var userPanEnabled: Bool {
        didSet {
            if userPanEnabled {
                let pan = UIPanGestureRecognizer(target: self,
                                                 action: #selector(starPan(_:)))
                addGestureRecognizer(pan)
            }
        }
    }

    /// 星星容器视图
    private var starForegroundView: UIView?
    private var starBackgroundView: UIView?

    // MARK: - 对象实例化
    override convenience init(frame: CGRect) {
        self.init(frame: frame,
                  config: LKStarRateViewConfig())
    }

    init(frame: CGRect, config: LKStarRateViewConfig) {
        self.config = config
        self.numberOfStars = config.numOfStar
        self.currentStarCount = config.currentNumOfStar
        self.integerStar = config.integerStar
        self.userPanEnabled = config.userPanEnabled
        self.followDuration = config.followDuration
        super.init(frame: frame)
        /// 布局子视图
        setUpSubViews()

        /// 显示评分
        showStarRate()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 绘制星星UI
    private func starViewWithImage(_ image: UIImage) -> UIView {
        let starView = UIView(frame: bounds)
        starView.clipsToBounds = true
        /// 添加星星
        for index in 0..<numberOfStars {
            let imageView = UIImageView(frame: CGRect(x: CGFloat(index) * (config.starEdge + config.gap),
                                                      y: 0,
                                                      width: config.starEdge,
                                                      height: config.starEdge))
            imageView.image = image
            starView.addSubview(imageView)
        }
        return starView
    }

    /// 布局视图
    private func setUpSubViews() {
        clipsToBounds = true

        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(starTap(_:)))
        addGestureRecognizer(tap)

        starBackgroundView = starViewWithImage(config.darkImage)
        starBackgroundView.flatMap { addSubview($0) }

        starForegroundView = starViewWithImage(config.lightImage)
        starForegroundView.flatMap { addSubview($0) }
    }

    /// 显示评分
    private func showStarRate() {
        self.userPanEnabled = config.userPanEnabled
        UIView.animate(withDuration: self.followDuration, animations: {
            if !self.integerStar {
                /// 非整星评分
                self.starForegroundView?.frame = CGRect(x: 0,
                                                        y: 0,
                                                        width: self.bounds.width / CGFloat(self.numberOfStars) * CGFloat(self.currentStarCount),
                                                        height: self.bounds.height)
            } else {
                /// 整星评分
                self.starForegroundView?.frame = CGRect(x: 0,
                                                        y: 0,
                                                        width: self.bounds.width / CGFloat(self.numberOfStars) * CGFloat(ceil(self.currentStarCount)),
                                                        height: self.bounds.height)
            }
        })
    }

    // MARK: - 手势交互
    /// 滑动评分
    @objc
    func starPan(_ recognizer: UIPanGestureRecognizer) {
        let offX: CGFloat = recognizer.location(in: self).x
        currentStarCount = Float(offX) / Float(bounds.width) * Float(numberOfStars)
        returnScore()
    }
    /// 点击评分
    @objc
    func starTap(_ recognizer: UITapGestureRecognizer) {
        let OffX = recognizer.location(in: self).x
        currentStarCount = Float(OffX) / Float(bounds.width) * Float(numberOfStars)
        returnScore()
    }

    // MARK: - 协议回调/返回星星数
    private func returnScore() {
        var newScore: Float = integerStar ? Float(ceil(self.currentStarCount)) : currentStarCount
        if newScore > Float(numberOfStars) {
            newScore = Float(numberOfStars)
        } else if newScore < 0 {
            newScore = 0
        }
        /// 协议代理
        delegate?.starRate(view: self, count: newScore)
    }
}
