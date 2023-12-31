//
//  RefreshView.swift
//  Common
//
//  Created by Da Lei on 2018/1/19.
//

import UIKit
import Lottie
import ESPullToRefresh
import SKResource
import UniverseDesignColor

public protocol RefreshViewDelegate: AnyObject {
    func stateDidChange(view: ESRefreshComponent, state: ESRefreshViewState)
}

extension RefreshViewDelegate {
    func stateDidChange(view: ESRefreshComponent, state: ESRefreshViewState) {}
}


struct DigitAnimation {
    var animationView: LOTAnimationView
    var digit: Int
}

public final class RefreshView: UIView {

    public weak var delegate: RefreshViewDelegate?
    // MARK: variables

    // progress of different numbers in forward/backward direction
    private let forwardProgressArray: [CGFloat] = [0.0, 0.14000000, 0.24100000, 0.33000000, 0.41013934, 0.49000000, 0.57050000, 0.65850000, 0.75000000, 0.8540000]
    private let backwardProgressArray: [CGFloat] =  [0.0, 0.14550000, 0.25000000, 0.34200000, 0.43000000, 0.51050000, 0.59000000, 0.67050000, 0.76000000, 0.8620000]
    // array that contains animaions of all digits
    private var digitAnimationArray = [DigitAnimation]()

    // number that the view shows
    public var number: Int = 0 {
        didSet {
            self.setDigitAnimationByNumber(number, isHidden: false)
        }
    }

    // view that contains all numbers
    let numberView: UIView = {
        let numberView = UIView()
        return numberView
    }()

    let topMaskView: UIImageView = {
        let topMaskView = UIImageView()
        topMaskView.image = BundleResources.SKResource.DocsApp.refreshMask_top.withRenderingMode(.alwaysTemplate)
        topMaskView.tintColor = UDColor.bgBody
        return topMaskView
    }()

    let bottomMaskView: UIImageView = {
        let bottomMaskView = UIImageView()
        bottomMaskView.image = BundleResources.SKResource.DocsApp.refreshMask_bottom.withRenderingMode(.alwaysTemplate)
        bottomMaskView.tintColor = UDColor.bgBody
        return bottomMaskView
    }()

    // label for description wording
    public let descriptionLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.textColor = UDColor.textCaption
        descriptionLabel.font = UIFont.systemFont(ofSize: 11)
        descriptionLabel.alpha = 0.0
        return descriptionLabel
    }()

    // view for header part
    public let refreshHeaderView: RefreshHeaderView = {
        let refreshHeaderView = RefreshHeaderView()
        return refreshHeaderView
    }()

    // MARK: functions

    // initialization
    convenience public init(number: Int) {
        self.init(number: number, refreshTips: BundleI18n.SKResource.Doc_List_RefreshDocTips)
    }

    public init(number: Int, refreshTips descriptionStr: String) {
        // TODO:
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 80))
        self.number = number
        self.refreshHeaderView.delegate = self
        self.descriptionLabel.text = descriptionStr
        self.doInitUI()

    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func doInitUI() {
        self.addSubview(numberView)
        numberView.snp.makeConstraints { (make) in
            make.top.bottom.left.right.equalTo(self)
        }

        self.addSubview(topMaskView)
        topMaskView.snp.makeConstraints { (make) in
            make.centerX.equalTo(self)
            make.top.equalTo(self)
            make.width.equalTo(self)
            make.height.equalTo(15)
        }

        self.addSubview(bottomMaskView)
        bottomMaskView.snp.makeConstraints { (make) in
            make.centerX.equalTo(self)
            make.bottom.equalTo(self).offset(-30)
            make.width.equalTo(self)
            make.height.equalTo(15)
        }

        self.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self)
            make.top.equalTo(self).offset(39.5)
        }

        self.setDigitAnimationByNumber(self.number, isHidden: true)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let width: CGFloat = 15.0
        // height/width in refreshBack&Forward.json is 40/16
        let scale: CGFloat = 40.0 / 16.0
        let itemSpacing: CGFloat = -1.0
        let numberCount = self.digitAnimationArray.count
        let horizontalMargin: CGFloat = (self.bounds.size.width - CGFloat(numberCount) * width - CGFloat(numberCount - 1) * itemSpacing) / 2.0

        for index in 0..<self.digitAnimationArray.count {
            let animateView = self.digitAnimationArray[index].animationView
            animateView.frame = CGRect(x: CGFloat(index) * (width + itemSpacing) + horizontalMargin,
                                       y: 7.0,
                                       width: width,
                                       height: width * scale)
        }
    }

//    public func updateWidth(_ newWidth: CGFloat) {
//        let oldFrame = frame
//        frame = CGRect(x: oldFrame.minX, y: oldFrame.minY, width: newWidth, height: oldFrame.height)
//    }

//    public func prepareShowNumber() {
//        self.digitAnimationArray.forEach { $0.animationView.alpha = 1 }
//    }

    // add(if needed) and set animation views to a certain number
    func setDigitAnimationByNumber(_ number: Int, isHidden: Bool) {
        let digitCountOfNumber = self.digitCountOfNumber(number)
        // if the count of digits has changed, need to remove all animation views and add new ones
        let needToResetAnimationView: Bool = (digitCountOfNumber != self.digitAnimationArray.count)

        if needToResetAnimationView {
            // clear digits&animations of the old number
            for digitAnimation in self.digitAnimationArray {
                digitAnimation.animationView.removeFromSuperview()
            }
            self.digitAnimationArray.removeAll()
        }

        var numberTemp = number
        var divisor = Int(pow(10.0, Double(digitCountOfNumber - 1)))
        for index in 0..<digitCountOfNumber {
            let digit = numberTemp / divisor
            numberTemp %= divisor
            divisor /= 10

            if needToResetAnimationView {
                // add new animation views
                var animationView: LOTAnimationView?
                if index % 2 == 0 {
                    // the even ones should roll forward
                    animationView = AnimationViews.refreshForward
                } else {
                    // the odd ones should roll backward
                    animationView = AnimationViews.refreshBackward
                }
                if animationView != nil {
                    let digitAnimation = DigitAnimation(animationView: animationView!, digit: digit)
                    self.digitAnimationArray.append(digitAnimation)
                    self.numberView.addSubview(animationView!)
                    animationView!.autoReverseAnimation = false
                    if isHidden {
                        animationView!.alpha = 0
                    }
                }
            }

            // set all animation views to certain digit and stop the animation
            self.digitAnimationArray[index].digit = digit
            if index % 2 == 0 {
                // the even ones should roll forward
                self.digitAnimationArray[index].animationView.animationProgress = forwardProgressArray[digit]
            } else {
                // the odd ones should roll backward
                self.digitAnimationArray[index].animationView.animationProgress = backwardProgressArray[digit]
            }
        }

        self.setNeedsLayout()
        self.layoutIfNeeded()
    }

    func digitCountOfNumber(_ number: Int) -> Int {
        if number == 0 {
            return 1
        }

        var numberTemp = number
        var count = 0
        while numberTemp != 0 {
            count += 1
            numberTemp /= 10
        }

        return count
    }

    public func showRefreshView(shouldShow: Bool) {
        let alpha: CGFloat = shouldShow ? 1.0 : 0
        UIView.animate(withDuration: 0.1) {
            for digitAnimation in self.digitAnimationArray {
                digitAnimation.animationView.alpha = alpha
            }
        }
    }

    public func showDescriptionLabel(shouldShow: Bool) {
        let alpha: CGFloat = shouldShow ? 1.0 : 0
        UIView.animate(withDuration: 0.1) {
            self.descriptionLabel.alpha = alpha
        }
    }

    public func startRolling() {
        for digitAnimation in digitAnimationArray {
            digitAnimation.animationView.play()
        }
    }

    public func stopRolling() {
        for digitAnimation in digitAnimationArray {
            digitAnimation.animationView.stop()
        }
    }
}

// MARK: RefreshHeaderViewDelegate

extension RefreshView: RefreshHeaderViewDelegate {
    func refreshAnimationBegin(view: ESRefreshComponent) {
    }

    func refreshAnimationEnd(view: ESRefreshComponent) {
        self.showRefreshView(shouldShow: false)
        self.showDescriptionLabel(shouldShow: false)
    }

    func progressDidChange(view: ESRefreshComponent, progress: CGFloat) {
        // alpha of numbers changes linearly in [40, 60]
        let alpha = (progress * self.refreshHeaderView.trigger - 40.0) / (60.0 - 40.0)
        for digitAnimation in digitAnimationArray {
            digitAnimation.animationView.alpha = alpha
        }

        // digits start rolling in [60, ...]
        let offset = progress * refreshHeaderView.trigger
        guard offset >= 60 else {
            self.setDigitAnimationByNumber(self.number, isHidden: false)
            return
        }
        // 1000 表示第一位数字转玩一轮所需的滑动量
        // 调小数字可以加快整体的动画速度
        let gestureProgress = (offset - 60) / 1000
        updateAnimation(progress: gestureProgress)
    }

    private func updateAnimation(progress: CGFloat) {
        for (index, animation) in digitAnimationArray.enumerated() {
            let initialProgress: CGFloat
            if index % 2 == 0 {
                initialProgress = forwardProgressArray[animation.digit]
            } else {
                initialProgress = backwardProgressArray[animation.digit]
            }
            // progress * index 让后续的数字转动更快
            // 可以按需补充一个系数或调整算法从而改变各位数的动画速度比例
            let updatedProgress = initialProgress + progress * CGFloat(index + 1)
            animation.animationView.animationProgress = updatedProgress.truncatingRemainder(dividingBy: 1)
        }
    }

    func stateDidChange(view: ESRefreshComponent, state: ESRefreshViewState) {
        delegate?.stateDidChange(view: view, state: state)
        if state == .refreshing {
            startRolling()
        }
    }
}
