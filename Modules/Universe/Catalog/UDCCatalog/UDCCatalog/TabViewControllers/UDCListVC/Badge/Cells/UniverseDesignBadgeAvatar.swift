//
//  UniverseDesignBadgeAvatar.swift
//  UDCCatalog
//
//  Created by Meng on 2020/10/28.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit

class UniverseDesignBadgeAvatar: UIView {
    let image = UIImageView(image: #imageLiteral(resourceName: "ttmoment.jpeg"))

    init() {
        super.init(frame: .zero)

        addSubview(image)
        self.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 48.0, height: 48.0))
        }
        image.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        image.clipsToBounds = true
        image.layer.cornerRadius = 24.0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
