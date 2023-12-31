//
//  SpaceListModeSwitchView.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/3.
//

import UIKit
import UniverseDesignColor
import UniverseDesignIcon

class SpaceListDisplayModeView: UIControl {

    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.bordersOutlined.withRenderingMode(.alwaysTemplate)
        view.contentMode = .scaleAspectFit
        view.tintColor = UDColor.iconN2
        return view
    }()
    typealias DisplayMode = SpaceListDisplayMode
    private(set) var mode: DisplayMode = .list

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(18)
        }
        docs.addHighlight(with: UIEdgeInsets(top: -6, left: -8, bottom: -6, right: -8),
                          radius: 8)
    }

    func update(mode: DisplayMode) {
        // 这里要反过来，当前是 list，icon 要显示为 grid
        switch mode {
        case .list:
            imageView.image = UDIcon.bordersOutlined.withRenderingMode(.alwaysTemplate)
        case .grid:
            imageView.image = UDIcon.disorderListOutlined.withRenderingMode(.alwaysTemplate)
        }
        self.mode = mode
    }
}
