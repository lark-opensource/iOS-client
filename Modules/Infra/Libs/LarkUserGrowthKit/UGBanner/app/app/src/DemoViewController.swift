//
//  DemoViewController.swift
//  UGContainerDev
//
//  Created by mochangxing on 2021/2/2.
//

import Foundation
import UIKit
import UGContainer
import UGBanner
import ServerPB

class Dependency: PluginContainerDependency {
    func reportEvent(event: ReachPointEvent) {
        print("XXXXXXXX Dependency reportEvent \(event)")
    }
}

class DemoViewController: UIViewController {
    var counter: Int = 0
    let service = PluginContainerServiceImpl(dependency: Dependency())
    var reachPoint: BannerReachPoint?

    lazy var showBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 50, y: 0, width: 100, height: 40)
        button.backgroundColor = UIColor.brown
        button.setTitle("pushShow", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(showClick), for: .touchUpInside)
        return button
    }()

    lazy var pushHide: UIButton = {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 50, y: 50, width: 100, height: 40)
        button.backgroundColor = UIColor.brown
        button.setTitle("pushHide", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(pushHideClick), for: .touchUpInside)
        return button
    }()

    lazy var callHide: UIButton = {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 50, y: 100, width: 150, height: 40)
        button.backgroundColor = UIColor.brown
        button.setTitle("change width", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(updateWidth), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(showBtn)
        self.view.addSubview(pushHide)
        self.view.addSubview(callHide)
        registerPlugin()
        setupReachPoint()
    }

    func registerPlugin() {
    }

    func setupReachPoint() {
        guard let reachPoint: BannerReachPoint = service.obtainReachPoint(reachPointId: "mock") else {
            return
        }
        reachPoint.delegate = self
        self.reachPoint = reachPoint
        self.view.addSubview(reachPoint.bannerView)
        reachPoint.bannerView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    @objc
    func showClick() {
        var title = ServerPB_Ug_reach_material_TextElement()
        title.content = "ReachPoint"
        var subTitle = ServerPB_Ug_reach_material_TextElement()
        subTitle.content = "我们准备了一些教程，希望你看过后能更了解我们的产品"

        var ctaTitle = ServerPB_Ug_reach_material_TextElement()
        ctaTitle.content = "立即邀请"

        var icon = ServerPB_Ug_reach_material_ImageElement()
        icon.cdnImage.url = "https://tosv.byted.org/obj/tos-cn-o-0000/930f403c5062463db4e3abca8f6427fb"

        var buttonLink = ServerPB_Ug_reach_material_TextElement()
        buttonLink.content = "www.baidu.com"

        var normalBanner = ServerPB_Ug_reach_material_NormalBannerMaterial()
        normalBanner.backgroundColor = "EEEEEE"
        normalBanner.title = title
        normalBanner.subTitle = subTitle
        normalBanner.ctaTitle = ctaTitle
        normalBanner.bannerCloseable = true
        normalBanner.bannerIcon = icon
        normalBanner.buttonLink = buttonLink

        normalBanner.layout = .style2
        var bannerMaterial = ServerPB_Ug_reach_material_BannerMaterial()
        bannerMaterial.bannerName = "mock"
        bannerMaterial.normalBanner = normalBanner
        bannerMaterial.bannerType = .normal

        var bannerMaterialCollection = ServerPB_Ug_reach_material_BannerMaterialCollection()
        bannerMaterialCollection.banners = [bannerMaterial]

        do {
            let data = try bannerMaterialCollection.serializedData()
            service.showReachPoint(reachPointId: "mock",
                                   reachPointType: BannerReachPoint.reachPointType,
                                   data: data)
        } catch {
            print("XXXXXXX error: \(error)")
        }
    }

    @objc
    func pushHideClick() {
        print("XXXXXXX push hide: mock reachPoint")
        counter = 0
        reachPoint?.bannerView.snp.updateConstraints({ (make) in
            make.left.equalToSuperview()
        })

        service.hideReachPoint(reachPointId: "mock", reachPointType: BannerReachPoint.reachPointType)
    }

    @objc
    func updateWidth() {
        counter += 1
        reachPoint?.bannerView.snp.updateConstraints({ (make) in
            make.left.equalToSuperview().offset(counter * 10)
        })
    }
}

extension DemoViewController: BannerReachPointDelegate {
    func onShow(bannerView: UIView, bannerData: BannerInfo, reachPoint: BannerReachPoint) {
        print("XXXXXXXXXXXX DemoViewController onShow: \(bannerData)")
    }

    func onHide(bannerView: UIView, bannerData: BannerInfo, reachPoint: BannerReachPoint) {
        print("XXXXXXXXXXXX DemoViewController onHide: \(bannerData)")
    }
}
