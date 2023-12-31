//
//  DemoViewController.swift
//  UGContainerDev
//
//  Created by mochangxing on 2021/2/2.
//

import Foundation
import UIKit
import UGContainer
import ServerPB

class DemoViewController: UIViewController {
    let service = PluginContainerServiceImpl(dependency: Dependency())
    var reachPoint: MockReachPoint?

    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 20, y: 300, width: 200, height: 25))
        label.font = UIFont.systemFont(ofSize: 18)
        label.numberOfLines = 0
        label.textColor = .white
        label.backgroundColor = .black
        label.lineBreakMode = .byWordWrapping
        return label
    }()

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
        button.frame = CGRect(x: 50, y: 100, width: 100, height: 40)
        button.backgroundColor = UIColor.brown
        button.setTitle("pushHide", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(pushHideClick), for: .touchUpInside)
        return button
    }()

    lazy var callHide: UIButton = {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 50, y: 200, width: 100, height: 40)
        button.backgroundColor = UIColor.brown
        button.setTitle("callHide", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(callHideClick), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(showBtn)
        self.view.addSubview(pushHide)
        self.view.addSubview(callHide)
        self.view.addSubview(titleLabel)
        registerPlugin()
        setupReachPoint()
    }

    func registerPlugin() {
        service.registerReachPointType(MockReachPoint.self)
    }

    func setupReachPoint() {
        guard let reachPoint: MockReachPoint = service.obtainReachPoint(reachPointId: "mock", reachPointType: MockReachPoint.reachPointType) else {
            return
        }
        reachPoint.delegate = self
        self.reachPoint = reachPoint
    }

    @objc
    func showClick() {
        var request = ServerPB_Guide_SetBannerStatusRequest()
        let bannerKey = "\(CACurrentMediaTime())"
        print("XXXXXXX btn click: \(bannerKey)")
        request.bannerKey = bannerKey
        do {
            let data = try request.serializedData()
            service.showReachPoint(reachPointId: "mock",
                                   reachPointType: MockReachPoint.reachPointType,
                                   data: data)
        } catch {
            print("XXXXXXX error: \(error)")
        }
    }

    @objc
    func pushHideClick() {
        print("XXXXXXX push hide: mock reachPoint")
        service.hideReachPoint(reachPointId: "mock", reachPointType: MockReachPoint.reachPointType)
    }

    @objc
    func callHideClick() {
        print("XXXXXXX push hide: mock reachPoint")
        reachPoint?.hide()
    }
}

extension DemoViewController: MockReachPointDelegate {
    func onShow(data: ServerPB_Guide_SetBannerStatusRequest) -> Bool {
        print("XXXXXXXXXXXX DemoViewController onShow: \(data)")
        self.titleLabel.isHidden = false
        self.titleLabel.text = data.bannerKey
        return true
    }

    func onHide() -> Bool {
        guard !self.titleLabel.isHidden else {
            return false
        }
        self.titleLabel.isHidden = true
        print("XXXXXXXXXXXX  DemoViewController onHide")
        return true
    }
}
