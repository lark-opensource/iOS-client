//
//  FakeDependencyController.swift
//  LarkTourDev
//
//  Created by Meng on 2020/6/19.
//

import UIKit
import Foundation
import LarkUIKit

class FakeDependencyController: BaseUIViewController {
    private let descriptionLabel = UILabel(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Colors.random()
        view.addSubview(descriptionLabel)

        descriptionLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = .boldSystemFont(ofSize: 16.0)
        descriptionLabel.text = description
        if #available(iOS 13.0, *) {
            descriptionLabel.textColor = .label
        } else {
            descriptionLabel.textColor = .black
        }
    }
}
