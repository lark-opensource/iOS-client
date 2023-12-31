//
//  FontSettingViewController.swift
//  TangramUIComponentDev
//
//  Created by 袁平 on 2021/7/1.
//

import Foundation
import UIKit
import UniverseDesignColor
import LarkZoomable

class FontSettingViewController: UIViewController {
    var zoom: Zoom = Zoom.currentZoom

    lazy var zoomSlider: ZoomSlider = {
        let slider = ZoomSlider()
        slider.zoom = self.zoom
        slider.onZoomChanged = { zoom in
            self.zoom = zoom
            self.zoomLabel.font = LarkFont.getTitle4(for: zoom)
        }
        return slider
    }()

    lazy var normalLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.text = "标准"
        label.font = LarkFont.getTitle4(for: .normal)
        return label
    }()

    lazy var zoomLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.text = "A"
        label.font = LarkFont.getTitle4(for: self.zoom)
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        title = "Font Setting"

        view.addSubview(zoomSlider)
        zoomSlider.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(27)
            make.trailing.equalToSuperview().offset(-27)
            make.centerY.equalToSuperview()
        }

        view.addSubview(normalLabel)
        normalLabel.sizeToFit()
        let offset = (view.bounds.width - 27 * 2) / CGFloat(Zoom.allCases.count - 1) + 35 - normalLabel.bounds.width / 2
        normalLabel.snp.makeConstraints { make in
            make.bottom.equalTo(zoomSlider.snp.top).offset(-8)
            make.leading.equalToSuperview().offset(offset)
        }

        view.addSubview(zoomLabel)
        zoomLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(normalLabel.snp.bottom).offset(-100)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Zoom.setZoom(zoom)
    }
}
