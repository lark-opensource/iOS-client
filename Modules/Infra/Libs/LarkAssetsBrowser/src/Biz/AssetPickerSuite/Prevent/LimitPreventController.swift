//
//  LimitPreventController.swift
//  LarkAssetsBrowser
//
//  Created by xiongmin on 2021/4/25.
//

import Foundation
import UIKit
import LarkUIKit
import LarkFoundation
import UniverseDesignColor

final class LimitPreventController: UIViewController {

    var continueClosure: (() -> Void)?
    var goSettingClosure: (() -> Void)?
    var closeClosure: (() -> Void)?

    private var style: PreventStyle

    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(Resources.close_icon, for: .normal)
        button.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        return button
    }()

    private lazy var goSettingButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.ud.colorfulBlue
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 4
        button.setTitle(BundleI18n.LarkAssetsBrowser.Lark_IM_NoAlbumAccessEnableInSettings_Button, for: .normal)
        button.setTitleColor(UIColor.ud.N00, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.addTarget(self, action: #selector(goSetting), for: .touchUpInside)
        return button
    }()

    private lazy var continueButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.LarkAssetsBrowser.Lark_Chat_KeepAllowingSelectedPhotos, for: .normal)
        button.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.addTarget(self, action: #selector(continueAction), for: .touchUpInside)
        return button
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel.lu.labelWith(fontSize: 24,
                                         textColor: UIColor.ud.N00,
                                         text: BundleI18n.LarkAssetsBrowser.Lark_Chat_UnableAccessAllPhotosTitle)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private lazy var contentLabel: UILabel = {
        let label = UILabel.lu.labelWith(fontSize: 16,
                                         textColor: UIColor.ud.N00,
                                         text: BundleI18n.LarkAssetsBrowser.Lark_Chat_UnableAccessAllPhotosDesc())
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    init(with style: PreventStyle) {
        self.style = style
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("must call init(with style: PreventStyle)")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            self.overrideUserInterfaceStyle = .light
        }
        let safeInset = self.view.window?.safeAreaInsets ?? .zero
        view.backgroundColor = UIColor.ud.N900
        view.addSubview(closeButton)
        view.addSubview(titleLabel)
        view.addSubview(contentLabel)
        view.addSubview(goSettingButton)
        view.addSubview(continueButton)
        closeButton.snp.makeConstraints { (make) in
            make.size.equalTo(44)
            make.left.equalToSuperview().offset(9)
            make.top.equalToSuperview().offset(safeInset.top + 44)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(closeButton.snp.bottom).offset(111)
            make.left.equalToSuperview().offset(18)
            make.right.equalToSuperview().offset(-18)
        }
        contentLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(25)
            make.right.equalToSuperview().offset(-18)
            make.left.equalToSuperview().offset(18)
        }
        let width = (continueButton.titleLabel?.text as NSString?)?.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]).width ?? 100
        continueButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-82 - safeInset.bottom)
            make.width.equalTo(width + 20)
            make.height.equalTo(20)
        }
        goSettingButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-142 - safeInset.bottom)
            make.left.equalToSuperview().offset(68)
            make.right.equalToSuperview().offset(-68)
            make.height.equalTo(40)
        }
        continueButton.isHidden = style == .denied
        updateContentCopywriteIfNeeded()
    }

    @objc
    private func closeAction() {
        dismiss(animated: true, completion: closeClosure)
    }

    @objc
    private func goSetting() {
        dismiss(animated: true, completion: goSettingClosure)
    }

    @objc
    private func continueAction() {
        dismiss(animated: true, completion: continueClosure)
    }

    private func updateContentCopywriteIfNeeded() {
        if Utils.hasTriggeredIOS17PhotoPermissionBug(), !PhotoAuthorityFixer.isIOS17PermissionBugFixed {
            goSettingButton.setTitle(BundleI18n.LarkAssetsBrowser.Lark_IM_CantEditPhotoAccessDownloadAgain_GoToSettings_iOS_Button, for: .normal)
            titleLabel.text = BundleI18n.LarkAssetsBrowser.Lark_Chat_UnableAccessAllPhotosTitle
            contentLabel.text = BundleI18n.LarkAssetsBrowser.Lark_IM_CantEditPhotoAccessDownloadAgain_iOS_Text()
        }
    }
}
