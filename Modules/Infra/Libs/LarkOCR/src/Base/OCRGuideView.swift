//
//  OCRGuideView.swift
//  LarkOCR
//
//  Created by 李晨 on 2022/9/5.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignColor

final class OCRGuideView: UIView {

    let textLabel = UILabel()
    let iconView = UIImageView()
    let tap: UITapGestureRecognizer = UITapGestureRecognizer()

    init(image: UIImage, text: String) {
        super.init(frame: .zero)

        self.iconView.isUserInteractionEnabled = false
        self.iconView.contentMode = .scaleAspectFit
        self.addSubview(self.iconView)
        self.iconView.image = image
        self.iconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-20)
            make.width.height.equalTo(90)
        }

        self.addSubview(self.textLabel)
        self.textLabel.text = text
        self.textLabel.font = .systemFont(ofSize: 14)
        self.textLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        self.textLabel.textAlignment = .center
        self.textLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.iconView.snp.bottom).offset(18)
        }

        self.tap.addTarget(self, action: #selector(clickGuideView))
        self.addGestureRecognizer(self.tap)

        self.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.6)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func checkCanShowGuide(in view: UIView) -> Bool {
        let subviews = view.window?.subviews ?? []
        var canShow: Bool = true
        subviews.forEach { view in
            if view is OCRGuideView {
                canShow = false
            }
        }
        return canShow
    }

    func showIn(view: UIView) {
        guard let window = view.window else {
            return
        }
        window.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @objc
    func clickGuideView() {
        self.removeFromSuperview()
    }
}
