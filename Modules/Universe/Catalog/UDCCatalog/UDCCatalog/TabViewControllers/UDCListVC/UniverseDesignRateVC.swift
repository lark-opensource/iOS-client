//
//  UniverseDesignRateVC.swift
//  UDCCatalog
//
//  Created by 姚启灏 on 2021/2/25.
//  Copyright © 2021 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignRate
import UniverseDesignIcon
import UniverseDesignColor
import SnapKit

class UniverseDesignRateVC: UIViewController {
    var rateView: UDRateView?

    var riotView: UDRateView?

    var blueRiotView: UDRateView?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "UniverseDesignRate"

        let rate = UDRateView()
        rateView = rate
        self.view.addSubview(rate)

        var config = rate.config
        config.itemImage = UDIcon.collectFilled
        config.dragStep = .half
        rate.update(config: config)

        rate.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(100)
        }

        rate.setRateText("请点击进行评分")
        rate.delegate = self

        let riot = UDRateView()
        riotView = riot
        self.view.addSubview(riot)

        config = riot.config
        config.itemImage = UDIcon.thumbsupFilled
        config.dragStep = .half
        riot.update(config: config)

        riot.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(rate.snp.bottom).offset(100)
        }

        riot.setRateText("请点击进行评分")
        riot.delegate = self

        let blueRiot = UDRateView()
        blueRiotView = blueRiot
        self.view.addSubview(blueRiot)

        config = blueRiot.config
        config.itemImage = UDIcon.thumbsupFilled
        config.dragStep = .half
        config.selectedColor = UDColor.primaryContentDefault
        blueRiot.update(config: config)

        blueRiot.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(riot.snp.bottom).offset(100)
        }

        blueRiot.setRateText("请点击进行评分")
        blueRiot.delegate = self
    }
}

extension UniverseDesignRateVC: UDRateViewDelegate {
    func rateView(_ rateView: UDRateView, didSelectedStep step: Double) {
        if step <= 0 {
            rateView.setRateText("请点击进行评分")
        } else if step <= 1 {
            rateView.setRateText("非常不满意，各方面都很差")
        } else if step <= 2 {
            rateView.setRateText("不满意，比较差")
        } else if step <= 3 {
            rateView.setRateText("一般，还需改善")
        } else if step <= 4 {
            rateView.setRateText("比较满意，仍可改善")
        } else {
            rateView.setRateText("非常满意，无可挑剔")
        }
    }
}
