//
//  SelectCountryNumberViewController.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/11/13.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import LarkSDKInterface

final class SelectCountryNumberViewController: UIViewController {
    lazy var bgView = UIView()
    lazy var selectCountryNumberView = SelectCountryNumberView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        self.bgView.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.45)
        self.bgView.lu.addTapGestureRecognizer(action: #selector(dismissVC), target: self, touchNumber: 1)
        self.view.addSubview(bgView)
        self.view.addSubview(selectCountryNumberView)

        bgView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        selectCountryNumberView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 310, height: 460))
        }
    }

    @objc
    func dismissVC() {
        self.dismiss(animated: false, completion: nil)
    }

    func setDatasource(hotDatasource: [LarkSDKInterface.MobileCode],
                       allDatasource: [LarkSDKInterface.MobileCode], selectAction: ((_ number: String) -> Void)?) {
        self.selectCountryNumberView.setDatasource(hotDatasource: hotDatasource, allDatasource: allDatasource)
        self.selectCountryNumberView.selectAction = selectAction
    }
}
