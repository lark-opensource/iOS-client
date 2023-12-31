//
//  LarkPrivacyModalView.swift
//  LarkPrivacyAlert
//
//  Created by Saafo on 2020/12/10.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignColor

final class LarkPrivacyModalView: UIView {

    private let launchView = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()?.view

    private let backgroundView: UIView = UIView()

    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgFloat
        if let launchView = launchView {
            self.addSubview(launchView)
            launchView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        }

        backgroundView.backgroundColor = UIColor.ud.bgMask
        self.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
