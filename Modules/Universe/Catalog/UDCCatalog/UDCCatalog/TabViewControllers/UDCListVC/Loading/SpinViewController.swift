//
//  DemoViewController.swift
//  UniverseDesignLoadingDev
//
//  Created by Miaoqi Wang on 2020/10/15.
//

import Foundation
import UIKit
import UniverseDesignLoading
import UniverseDesignColor

class SpinViewController: UIViewController {

    var originY: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.neutralColor1
        navigationController?.navigationBar.isTranslucent = false
        test()
    }

    func addBackView(origin: CGPoint, color: UIColor) -> UIView {
        let back = UIView(frame: CGRect(origin: origin, size: CGSize(width: view.bounds.width, height: 80)))
        back.backgroundColor = color
        view.addSubview(back)
        return back
    }

    func newBack(color: UIColor) -> UIView {
        let bk = addBackView(origin: CGPoint(x: 0, y: originY), color: color)
        originY += bk.bounds.height + 16
        return bk
    }
}

extension SpinViewController {
    func test() {
        let spin1 = UDLoading.presetSpin(
            color: .primary,
            loadingText: "加载中...",
            textDistribution: .horizonal
        )
        newBack(color: UIColor.ud.neutralColor1).addSubview(spin1)
        spin1.snp.makeConstraints { (make) in
            make.center.equalToSuperview()

        }

//        let spin2 = UDLoading.presetSpin(
//            color: .neutralWhite,
//            loadingText: "Loading...",
//            textDistribution: .vertial
//        )
//        newBack(color: UIColor.ud.neutralColor7).addSubview(spin2)
//        spin2.snp.makeConstraints { (make) in
//            make.center.equalToSuperview()
//        }
//
//        let spin3 = UDLoading.presetSpin(
//            color: .neutralGray,
//            loadingText: "Loading...",
//            textDistribution: .horizonal)
//        newBack(color: UIColor.ud.neutralColor1).addSubview(spin3)
//        spin3.snp.makeConstraints { (make) in
//            make.center.equalToSuperview()
//        }
//
//        let spin4 = UDSpin(
//            config: UDSpinConfig(
//                indicatorConfig: UDSpinIndicatorConfig(
//                    size: 12,
//                    color: UIColor.ud.alertColor4,
//                    circleDegree: 0.9,
//                    animationDuration: 3.0
//                ),
//                textLabelConfig: UDSpinLabelConfig(
//                    text: "Custom Spin",
//                    font: .systemFont(ofSize: 12.0),
//                    textColor: UIColor.ud.alertColor4)
//            )
//        )
//        newBack(color: UIColor.ud.successColor5).addSubview(spin4)
//        spin4.snp.makeConstraints { (make) in
//            make.center.equalToSuperview()
//        }
//
//
//
//        let largeSpin = UDLoading.presetSpin(
//            color: .neutralGray,
//            size: .large,
//            loadingText: "Loading..."
//        )
//
//        largeSpin.addToCenter(on: newBack(color: UIColor.ud.neutralColor1))
    }
}
