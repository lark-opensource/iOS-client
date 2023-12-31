//
//  LoadPlaceHolderViewController.swift
//  LarkUIKitDemo
//
//  Created by zc09v on 2018/4/24.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit

class LoadPlaceHolderViewController: BaseUIViewController {
    private let smallLoadingContent: UIView = UIView()
    private let smallLoading: SmallLoadingView = SmallLoadingView()
    private var loadViews: [UIView] = []
    private var offset: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        let loadingView = LoadingPlaceholderView(frame: .zero)
        loadingView.isHidden = false
        self.view.addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        let failView = LoadFailPlaceholderView()
        failView.isHidden = true
        self.view.addSubview(failView)
        failView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        let retryView = LoadFaildRetryView()
        retryView.isHidden = true
        self.view.addSubview(retryView)
        retryView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        let button = UIButton(type: .system)
        button.setTitle("Change Load View", for: .normal)
        button.backgroundColor = UIColor.red
        button.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
        self.view.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-15)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(50)
        }

        loadViews.append(loadingView)
        loadViews.append(failView)
        loadViews.append(retryView)

        view.addSubview(smallLoadingContent)
        smallLoadingContent.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
            maker.height.equalTo(200)
        }
        smallLoading.frame = CGRect(x: 20, y: 60, width: 20, height: 20)
        smallLoadingContent.addSubview(smallLoading)
        smallLoadingContent.backgroundColor = UIColor.black
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.bringSubviewToFront(smallLoadingContent)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        smallLoading.animationView.play()
    }

    @objc
    private func buttonClicked() {
        offset += 1
        offset %= loadViews.count
        loadViews.enumerated().forEach { (offset, view) in
            if self.offset == offset {
                view.isHidden = false
            } else {
                view.isHidden = true
            }
        }
    }
}
