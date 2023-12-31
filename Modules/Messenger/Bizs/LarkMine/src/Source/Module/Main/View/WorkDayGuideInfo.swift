//
//  WorkDayGuideInfo.swift
//  Action
//
//  Created by czp-dev on 2018/10/30.
//

import Foundation
import UIKit
import LarkGuide

final class WorkDayGuideInfo: LineGuideItemInfo {
    static let key: String = "all_on_leave_status"
    var key: String {
        return WorkDayGuideInfo.key
    }
    var guideView: UIView
    var guideViewSize: CGSize
    var iconInfo: (UIView, CGSize)
    var dismissCallBack: (() -> Void)?
    private let isChinese = (BundleI18n.currentLanguage == .zh_CN)

    init(workDayIcon: UIImage, dismissCallBack: (() -> Void)?) {
        self.dismissCallBack = dismissCallBack
        let imageView = UIImageView(image: Resources.work_day)
        imageView.isUserInteractionEnabled = true
        imageView.layer.shadowColor = UIColor.ud.staticBlack.cgColor
        imageView.layer.shadowRadius = 4.5
        imageView.layer.shadowOpacity = 0.09
        imageView.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.guideView = imageView

        let width = UIScreen.main.bounds.width - 2 * 16
        let ratio: CGFloat = width / 345
        let height = (isChinese ? 122 : 162) * ratio
        self.guideViewSize = CGSize(width: width, height: height)

        let icon = UIImageView(image: workDayIcon)
        icon.backgroundColor = UIColor.ud.N00
        icon.layer.cornerRadius = 1
        icon.layer.masksToBounds = true
        icon.contentMode = .scaleAspectFit
        self.iconInfo = (icon, workDayIcon.size)

        let dismissBtn = UIButton(type: .custom)
        dismissBtn.addTarget(self, action: #selector(clickDismissBtn), for: .touchUpInside)
        self.guideView.addSubview(dismissBtn)
        dismissBtn.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-15 * ratio)
            make.left.equalToSuperview().offset(126 * ratio)
            make.right.equalToSuperview().offset(-126 * ratio)
        }
    }

    @objc
    private func clickDismissBtn() {
        self.dismissCallBack?()
    }
}
