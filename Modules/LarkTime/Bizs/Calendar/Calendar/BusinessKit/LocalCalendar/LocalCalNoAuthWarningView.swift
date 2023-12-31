//
//  LocalCalNoAuthWarningView.swift
//  Calendar
//
//  Created by jiayi zou on 2018/9/19.
//  Copyright © 2018 EE. All rights reserved.
//

import UniverseDesignIcon
import UIKit
import LarkAlertController
import CalendarFoundation

final class LocalCalNoAuthWarningController {
    private var alertController: LarkAlertController

    init() {
        let warningView = LocalCalNoAuthWarningView(frame: CGRect.zero)
        alertController = LarkAlertController()
        alertController.setContent(view: warningView, padding: .zero)
        warningView.confirmButton.setTitle(BundleI18n.Calendar.Calendar_Setting_OpenPrivacySetting, for: .normal)
        warningView.closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        warningView.confirmButton.addTarget(self, action: #selector(handleConfirm), for: .touchUpInside)
    }

    func show(_ vc: UIViewController?) {
        vc?.present(alertController, animated: true)
    }

    @objc
    func handleClose() {
        alertController.dismiss(animated: true)
    }

    @objc
    func handleConfirm() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(
            url,
            options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]),
            completionHandler: nil
        )
        CalendarTracer.shareInstance.jumpToPrivacySetting()
    }
}

final class LocalCalNoAuthWarningView: UIView {
    fileprivate var closeButton = IconButton()
    fileprivate var confirmButton = UIButton()
    override init(frame: CGRect) {

        super.init(frame: frame)

        closeButton.setImage(UDIcon.getIconByKeyNoLimitSize(.closeSmallOutlined).scaleNaviSize().renderColor(with: .n1), for: .normal)
        closeButton.increaseClickableArea()
        addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(27)
            make.top.right.equalToSuperview().inset(6)
        }

        let imageView = UIImageView(image: UIImage.cd.image(named: "locker").withRenderingMode(.alwaysOriginal))
        self.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.width.equalTo(60)
            make.height.equalTo(67.5)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(36)
        }
        let mainLabel = UILabel()
        mainLabel.font = CalendarExtension.mediumFont(ofSize: 17)
        mainLabel.text = BundleI18n.Calendar.Calendar_Setting_NoEnoughAccess
        mainLabel.textAlignment = .center
        self.addSubview(mainLabel)
        mainLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(13)
            make.height.equalTo(24)
        }
        let subLabel = UILabel()
        subLabel.font = CalendarExtension.regularFont(ofSize: 14)
        subLabel.numberOfLines = 3
        subLabel.text = BundleI18n.Calendar.Calendar_Setting_GoToIphoneSetting()
        subLabel.textAlignment = .center
        subLabel.textColor = UIColor.ud.textPlaceholder
        self.addSubview(subLabel)
        subLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(mainLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(20)
        }

        let seperatorLine = UIView()
        seperatorLine.backgroundColor = UIColor.ud.lineDividerDefault
        self.addSubview(seperatorLine)
        seperatorLine.snp.makeConstraints { make in
            make.top.equalTo(subLabel.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        confirmButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        self.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(50)
            make.top.equalTo(seperatorLine.snp.bottom)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value) })
}
