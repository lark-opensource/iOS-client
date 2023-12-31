//
//  LoadingImageViewController.swift
//  UniverseDesignLoadingDev
//
//  Created by Miaoqi Wang on 2020/10/19.
//

import Foundation
import UIKit
import UniverseDesignLoading
import UniverseDesignColor

class LoadingImageViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.neutralColor1
        title = "自定义的图"

        let space = UIView()
        view.addSubview(space)
        space.snp.makeConstraints { (make) in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.3)
        }

        let resource = Bundle.main.path(forResource: "fake_loading", ofType: "json")
        let v = UDLoading.loadingImageView(lottieResource: resource)
        view.addSubview(v)
        v.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(space.snp.bottom)
        }
        let loading = UIBarButtonItem(
            title: "整页Loading",
            style: .plain,
            target: self,
            action: #selector(loadingVC)
        )
        navigationItem.rightBarButtonItem = loading
    }

    @objc
    func loadingVC(_ sender: Any) {
        let vc = UDLoading.loadingImageController()
        vc.title = "预设的图"
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
