//
//  UnifiedContactTenantHeaderView.swift
//  LarkContact
//
//  Created by mochangxing on 2019/9/24.
//

import Foundation
import UIKit
import SnapKit

final class UnifiedContactTenantHeaderView: UIView {
    private lazy var centerRectView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.ud.N400
        view.layer.cornerRadius = 4
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(centerRectView)
        centerRectView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(20)
            make.width.equalTo(38)
            make.height.equalTo(5)
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
