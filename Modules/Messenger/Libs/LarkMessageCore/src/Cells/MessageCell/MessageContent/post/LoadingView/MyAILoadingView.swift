//
//  MyAILoadingView.swift
//  LarkAI
//
//  Created by 李勇 on 2023/5/25.
//

import Foundation
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignTheme
import Lottie

/// 文本、富文本消息，"..."加载动画
final public class MyAILoadingView: UIView {
    /// 8：圆点大小，6：圆点间隔
    static let size = CGSize(width: 36.auto(), height: 8.auto())
    /// 内容只包含三个点，大小固定，没有周围padding
    static public func createView() -> MyAILoadingView {
        let loadingView = MyAILoadingView(frame: CGRect(origin: .zero, size: MyAILoadingView.size))

        let bundle = BundleConfig.LarkMessageCoreBundle
        let path = bundle.path(forResource: "Lottie/three_point_loading/data", ofType: "json") ?? ""

        let lottie = LOTAnimationView(filePath: path)
        lottie.backgroundColor = UIColor.clear
        lottie.loopAnimation = true
        lottie.play()
        loadingView.addSubview(lottie)
        lottie.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        /*
         // 依次添加三个圆点
         let pointViewSize = CGSize(width: MyAILoadingView.size.height, height: MyAILoadingView.size.height)
         let pointOneView = PointAnimationView(frame: CGRect(origin: .zero, size: pointViewSize))
         pointOneView.tag = 1
         pointOneView.addAnimation(times: [0, 0.13, 0.29, 0.51, 0.67], values: [1.0, 0.4, 0.2, 0.2, 1.0], duration: 0.67)
         loadingView.addSubview(pointOneView)
         let pointTwoView = PointAnimationView(frame: CGRect(origin: CGPoint(x: 14.auto(), y: 0), size: pointViewSize))
         pointTwoView.tag = 2
         pointTwoView.addAnimation(times: [0, 0.13, 0.29, 0.51, 0.67], values: [0.2, 1, 0.4, 0.2, 0.2], duration: 0.67)
         loadingView.addSubview(pointTwoView)
         let pointThreeView = PointAnimationView(frame: CGRect(origin: CGPoint(x: 28.auto(), y: 0), size: pointViewSize))
         pointThreeView.tag = 3
         pointThreeView.addAnimation(times: [0, 0.13, 0.29, 0.51, 0.67], values: [0.2, 0.2, 1, 0.4, 0.2], duration: 0.67)
         loadingView.addSubview(pointThreeView)
         */
        return loadingView
    }
}

/// 圆点动画
final class PointAnimationView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.iconN2
        self.layer.cornerRadius = frame.size.width / 2
        self.layer.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 添加透明度动画，times：哪些时间点需要改变透明度，values：透明度需要改变为多少，duration：动画时长
    func addAnimation(times: [CGFloat], values: [CGFloat], duration: CGFloat) {
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.values = values
        opacityAnimation.keyTimes = times.map({ NSNumber(value: $0 / duration) })
        opacityAnimation.duration = duration
        // 不能设置为paced，会导致后面两个点的透明度动画是一致的，不知道什么问题
        // opacityAnimation.calculationMode = .paced
        opacityAnimation.timingFunctions = [CAMediaTimingFunction(name: .easeOut)]
        opacityAnimation.repeatCount = .infinity
        opacityAnimation.isRemovedOnCompletion = false
        self.layer.add(opacityAnimation, forKey: "opacityAnimation")
    }
}
