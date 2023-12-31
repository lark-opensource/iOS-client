//
//  NickNameRefreshButton.swift
//  Moment
//
//  Created by liluobin on 2021/5/24.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignLoading

final class NickNameRefreshButton: UIButton {
    var imageInfo: (normal: UIImage?, highlighted: UIImage?, selected: UIImage?)?
    private var isLoading = false
    let centerOffSetRatio: CGFloat
    private lazy var spin: UDSpin = {
        let indicatorConfig = UDSpinIndicatorConfig(size: 15, color: UIColor.ud.primaryColor6)
        let spinConfig = UDSpinConfig(indicatorConfig: indicatorConfig, textLabelConfig: nil)
        let spin = UDSpin(config: spinConfig)
        return spin
    }()

    init(centerOffSetRatio: CGFloat = 1) {
        self.centerOffSetRatio = centerOffSetRatio
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        spin.isUserInteractionEnabled = false
        addSubview(spin)
        spin.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().multipliedBy(centerOffSetRatio)
        }
        spin.isHidden = true
    }

    /// 更新UI的状态
    func showLoading(_ loading: Bool, bgImage: UIImage? = Resources.refreshLoadingBg) {
        // 当前状态是否一致 一致不做处理
        if isLoading == loading {
            return
        }
        isLoading = loading
        spin.isHidden = !loading
        if loading {
            imageInfo = (image(for: .normal), image(for: .highlighted), image(for: .selected))
            setImage(bgImage, for: .normal)
            setImage(nil, for: .highlighted)
            setImage(nil, for: .selected)
        } else {
            if imageInfo == nil {
                return
            }
            setImage(imageInfo?.normal, for: .normal)
            setImage(imageInfo?.highlighted, for: .highlighted)
            setImage(imageInfo?.selected, for: .selected)
        }
    }
}
