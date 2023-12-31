//
//  LoadingSwitch.swift
//  LarkUIKit
//
//  Created by zc09v on 2017/11/22.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

public enum SwitchBehaviourType {
    case normal
    case waitCallback
}

open class LoadingSwitch: UISwitch {
    public var valueWillChanged: ((_ to: Bool) -> Void)?
    public var valueChanged: ((Bool) -> Void)?

    private var isOnStatus: Bool = false

    private var behaviourType: SwitchBehaviourType

    private let indicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(frame: .zero)
        view.color = UIColor.ud.colorfulBlue
        return view
    }()

    public convenience init() {
        self.init(behaviourType: .normal)
    }

    public init(behaviourType: SwitchBehaviourType) {
        self.behaviourType = behaviourType
        super.init(frame: .zero)

        var circleView: UIView?
        if let firstView = self.subviews.first {
            for ges in firstView.gestureRecognizers ?? [] {
                ges.cancelsTouchesInView = false
            }
            for subView in firstView.subviews where subView is UIImageView {
                circleView = subView
                break
            }
        }
        if let circleView = circleView {
            circleView.addSubview(indicator)
            let pointY = self.convert(CGPoint(x: 0, y: self.center.y), to: circleView).y
            indicator.snp.makeConstraints({ (make) in
                make.centerX.equalToSuperview()
                make.centerY.equalTo(pointY)
            })
        }
        self.addTarget(self, action: #selector(handleChange), for: .valueChanged)
    }

    @objc
    func handleChange() {
        switch behaviourType {
        case .normal:
            isOnStatus = self.isOn
            self.valueChanged?(self.isOn)
        case .waitCallback:
            break
        }
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch behaviourType {
        case .normal:
            self.valueWillChanged?(!isOnStatus)
        case .waitCallback:
            if !indicator.isAnimating {
                self.indicator.startAnimating()
                self.valueWillChanged?(!isOnStatus)
            }
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch behaviourType {
        case .normal:
            break
        case .waitCallback:
            self.setOn(isOnStatus, animated: true)
        }
    }

    public override func setOn(_ on: Bool, animated: Bool) {
        super.setOn(on, animated: animated)
        isOnStatus = on
    }

    public func setOn(_ on: Bool, inLoading: Bool, animated: Bool) {
        self.setOn(on, animated: animated)
        switch behaviourType {
        case .normal:
            break
        case .waitCallback:
            if inLoading {
                if !indicator.isAnimating {
                    self.indicator.startAnimating()
                }
            } else {
                self.indicator.stopAnimating()
                self.valueChanged?(isOnStatus)
            }
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
