//
//  NetDiagnoseHeaderColorView.swift
//  LarkMine
//
//  Created by huanglx on 2022/1/5.
//

import Foundation
import UIKit
import LarkUIKit

final class NetDiagnoseHeaderGradientView: UIView {
    private let colorView = GradientView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        //渐变背景
        colorView.locations = [0.0, 1.0]
        colorView.direction = .vertical
        colorView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        self.addSubview(colorView)
        colorView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func set(status: NetDiagnoseStatus) {
        switch status {
        case .unStart:
            self.colorView.colors = [UIColor.ud.primaryContentDefault.withAlphaComponent(1), UIColor.ud.primaryContentDefault.withAlphaComponent(0.8)]
        case .running: break
        case .normal:
            UIView.animate(withDuration: 0.4, animations: {
                self.colorView.colors = [UIColor.ud.functionSuccessContentDefault.withAlphaComponent(1), UIColor.ud.functionSuccessContentDefault.withAlphaComponent(0.8)]
            })
        case .error:
            UIView.animate(withDuration: 0.4, animations: {
                self.colorView.colors = [UIColor.ud.functionWarningContentDefault.withAlphaComponent(1), UIColor.ud.functionWarningContentDefault.withAlphaComponent(0.8)]
            })
        }
    }
}
