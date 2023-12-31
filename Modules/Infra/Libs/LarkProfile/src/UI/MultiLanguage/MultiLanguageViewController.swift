//
//  MultiLanguageViewController.swift
//  LarkMine
//
//  Created by ByteDance on 2023/9/27.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import UniverseDesignTheme
import Homeric
import LKCommonsTracker
import FigmaKit
import LarkContainer
import LarkSDKInterface
import UniverseDesignToast
import SnapKit
import LarkOpenSetting

private let settingKey = "PROFILE_NAME_DISPLAY_TYPE"

final class MultiLanguageViewController: BaseUIViewController, UserResolverWrapper {
    let userResolver: UserResolver

    @ScopedInjectedLazy var service: UserUniversalSettingService?
    private let disposeBag = DisposeBag()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.LarkProfile.Lark_Settings_NameDisplayOnProfilePage_Title
        setupUI()

        defaultNameView.tapRelay
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.updateConfig(optionView: self?.defaultNameView, config: 0)
        }).disposed(by: disposeBag)

        defaultAndEnglishNameView.tapRelay
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.updateConfig(optionView: self?.defaultAndEnglishNameView, config: 1)
        }).disposed(by: disposeBag)

        defaultNameView.isSelected = (service?.getIntUniversalUserSetting(key: settingKey) ?? 0) == 0
        defaultAndEnglishNameView.isSelected = !defaultNameView.isSelected
    }

    private func updateConfig(optionView: MultiLanguageOptionView?, config: Int64) {
        self.service?.setUniversalUserConfig(values: [settingKey: .intValue(config)])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.defaultNameView.isSelected = self.defaultNameView == optionView
                self.defaultAndEnglishNameView.isSelected = !self.defaultNameView.isSelected

                SettingLoggerService.logger(.custom("MultiLanguage")).info("api/set/req: config: \(config); res: ok")
                UDToast.showSuccess(with: BundleI18n.LarkProfile.Lark_Settings_NameDisplay_SettingSaved_Toast, on: self.view, delay: 0.5)
            }, onError: { [weak self] error in
                guard let self else { return }

                SettingLoggerService.logger(.custom("MultiLanguage")).error("api/set/req: config: \(config); res: error: \(error)")
                UDToast.showSuccess(with: BundleI18n.LarkProfile.Lark_Settings_NameDisplay_SettingUnsaved_Toast, on: self.view, delay: 0.5)
            }).disposed(by: disposeBag)
    }

    private func setupUI() {
        view.addSubview(contentView)
        contentView.addSubview(defaultNameView)
        contentView.addSubview(defaultAndEnglishNameView)

        let defaultAndEnglishNameViewBottomMargin = -21
        let contentViewLeftMargin = 16
        let contentViewTopMargin = 12

        defaultNameView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
        }

        defaultAndEnglishNameView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(defaultNameView.snp.bottom)
            make.bottom.equalToSuperview().offset(defaultAndEnglishNameViewBottomMargin)
        }

        contentView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(contentViewLeftMargin)
            make.right.equalToSuperview().offset(-contentViewLeftMargin)
            make.top.equalToSuperview().offset(contentViewTopMargin)
        }
    }

    private lazy var contentView: UIView = {
        let cornerRadius: CGFloat = 8

        let view = UIStackView()
        view.layer.cornerRadius = cornerRadius
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    private lazy var defaultNameView: MultiLanguageOptionView = {
        let view = MultiLanguageOptionView(frame: .zero)
        view.title = BundleI18n.LarkProfile.Lark_Settings_NameDisplayOnProfilePage_DefaultOnly_Option
        view.userName = BundleI18n.LarkProfile.Lark_Settings_NameDisplayOnProfilePage_DefaultOnly_Example
        return view
    }()

    private lazy var defaultAndEnglishNameView: MultiLanguageOptionView = {
        let view = MultiLanguageOptionView(frame: .zero)
        view.title = BundleI18n.LarkProfile.Lark_Settings_NameDisplayOnProfilePage_DefaultAndEnglish_Option
        view.userName = BundleI18n.LarkProfile.Lark_Settings_NameDisplayOnProfilePage_DefaultAndEnglish_Example
        return view
    }()
}
