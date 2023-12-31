//
//  AutoTranslateGuideController.swift
//  LarkChat
//
//  Created by 李勇 on 2019/7/18.
//

import UIKit
import Lottie
import RxSwift
import LarkUIKit
import Foundation
import UniverseDesignToast
import EENavigator
import LarkActionSheet
import LarkLocalizations
import LarkContainer

/// 自动翻译引导
final class AutoTranslateGuideController: BaseUIViewController, UserResolverWrapper {
    let userResolver: UserResolver
    private let disposeBag = DisposeBag()
    private let viewModel: AutoTranslateGuideViewModel
    private let contentWrapperView = UIView()
    private let languageLabel = UILabel()

    init(userResolver: UserResolver, viewModel: AutoTranslateGuideViewModel) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear

        /// 中间内容宽度、高度
        self.contentWrapperView.backgroundColor = UIColor.ud.bgFloat
        self.contentWrapperView.layer.borderWidth = 1
        self.contentWrapperView.layer.borderColor = UIColor.ud.lineDividerDefault.cgColor
        self.contentWrapperView.layer.cornerRadius = 6
        self.contentWrapperView.layer.shadowRadius = 12
        self.contentWrapperView.layer.shadowOpacity = 1
        self.contentWrapperView.layer.shadowOffset = .zero
        self.contentWrapperView.layer.shadowColor = UIColor.ud.shadowPriMd.withAlphaComponent(0.16).cgColor
        self.view.addSubview(self.contentWrapperView)

        /// 自动翻译title
        let titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.text = BundleI18n.LarkChat.Lark_Legacy_AutoTranslation
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.ud.textTitle
        self.contentWrapperView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.height.equalTo(24)
            make.left.equalToSuperview().offset(18)
            make.right.equalToSuperview().offset(-18)
            make.top.equalToSuperview().offset(20)
        }

        /// lottie动画 需要根据当前屏幕宽高进行等比缩放
        let originWidth: CGFloat = 598.0
        let originHeight: CGFloat = 206.0
        let animationView = LOTAnimationView(filePath: self.translateAnimationPath())
        self.contentWrapperView.addSubview(animationView)
        animationView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(18)
            make.right.equalToSuperview().offset(-18)
            make.height.equalTo(animationView.snp.width).multipliedBy(originHeight / originWidth)
            make.top.equalTo(titleLabel.snp.bottom).offset(18)
        }
        animationView.loopAnimation = true
        animationView.play()

        /// 分割线
        let topLine = UIView()
        topLine.backgroundColor = UIColor.ud.lineDividerDefault
        self.contentWrapperView.addSubview(topLine)
        topLine.snp.makeConstraints { (make) in
            make.top.equalTo(animationView.snp.bottom).offset(24)
            make.left.equalToSuperview().offset(18)
            make.right.equalToSuperview().offset(-18)
            make.height.equalTo(0.5)
        }

        /// 描述
        let detailLabel = UILabel()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = .left
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.ud.textCaption
        ]
        detailLabel.attributedText = NSAttributedString(
            string: BundleI18n.LarkChat.Lark_Chat_AutoTranslationGuide,
            attributes: attributes
        )
        detailLabel.numberOfLines = 0
        self.contentWrapperView.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(18)
            make.right.equalToSuperview().offset(-18)
            make.top.equalTo(topLine.snp.bottom).offset(18.5)
        }

        /// 当前语言提示
        let languageTripLabel = UILabel()
        languageTripLabel.font = UIFont.systemFont(ofSize: 14)
        languageTripLabel.textColor = UIColor.ud.textCaption
        languageTripLabel.text = BundleI18n.LarkChat.Lark_Chat_AutoTranslationGuideTips
        languageTripLabel.numberOfLines = 0
        self.contentWrapperView.addSubview(languageTripLabel)
        languageTripLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(18)
            make.right.equalToSuperview().offset(-18)
            make.top.equalTo(detailLabel.snp.bottom).offset(18)
        }

        /// 当前语言
        let languageButton = UIButton(type: .custom)
        languageButton.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.bgBody), for: .normal)
        languageButton.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.bgFloat), for: .highlighted)
        languageButton.layer.borderColor = UIColor.ud.lineDividerDefault.cgColor
        languageButton.layer.masksToBounds = true
        languageButton.layer.borderWidth = 1
        languageButton.layer.cornerRadius = 4
        languageButton.addTarget(self, action: #selector(selectTargetLanguage(sender:)), for: .touchUpInside)
        self.contentWrapperView.addSubview(languageButton)
        languageButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(18)
            make.right.equalToSuperview().offset(-18)
            make.height.equalTo(36)
            make.top.equalTo(languageTripLabel.snp.bottom).offset(8)
        }
        do {
            self.languageLabel.font = UIFont.systemFont(ofSize: 14)
            self.languageLabel.textColor = UIColor.ud.textCaption
            self.languageLabel.text = self.viewModel.languageValue(language: self.viewModel.selectdTargetLanguage)
            languageButton.addSubview(self.languageLabel)
            self.languageLabel.snp.makeConstraints { (make) in
                make.left.equalTo(12)
                make.centerY.equalToSuperview()
            }
            let iconView = UIImageView()
            iconView.image = Resources.guide_select_language_icon
            iconView.transform = CGAffineTransform(rotationAngle: .pi / 2)
            languageButton.addSubview(iconView)
            iconView.snp.makeConstraints { (make) in
                make.right.equalTo(-8)
                make.centerY.equalToSuperview()
            }
        }

        /// 分割线
        let bottomLine = UIView()
        bottomLine.backgroundColor = UIColor.ud.lineDividerDefault
        self.contentWrapperView.addSubview(bottomLine)
        bottomLine.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(18)
            make.right.equalToSuperview().offset(-18)
            make.height.equalTo(0.5)
            make.top.equalTo(languageButton.snp.bottom).offset(16)
        }

        /// 暂不开启
        let leftButton = UIButton(type: .system)
        leftButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        leftButton.setTitleColor(UIColor.ud.N900, for: .normal)
        leftButton.setTitle(BundleI18n.LarkChat.Lark_Chat_MissTurnOnAutoTranslation, for: .normal)
        leftButton.rx.tap.asDriver().drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.dismiss(animated: false, completion: nil)
        }).disposed(by: self.disposeBag)
        self.contentWrapperView.addSubview(leftButton)
        leftButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalTo(bottomLine.snp.bottom).offset(0.5)
            make.height.equalTo(51.5)
            make.bottom.equalToSuperview()
        }
        /// 开启自动翻译
        let rightButton = UIButton(type: .system)
        rightButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        rightButton.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        rightButton.setTitle(BundleI18n.LarkChat.Lark_Chat_TurnOnAutoTranslation, for: .normal)
        rightButton.rx.tap.asDriver().drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.viewModel.changeTargetLanguageAndOpenAutoTranslateGlobaSwitch()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (_) in
                    UDToast.showSuccess(with: BundleI18n.LarkChat.Lark_Chat_OpenAutoTranslationSuccess, on: self.view)
                    self.dismiss(animated: false, completion: nil)
                }, onError: { error in
                    UDToast.showFailure(with: BundleI18n.LarkChat.Lark_Setting_PrivacySetupFailed, on: self.view, error: error)
                    self.dismiss(animated: false, completion: nil)
                }).disposed(by: self.disposeBag)
        }).disposed(by: self.disposeBag)
        self.contentWrapperView.addSubview(rightButton)
        rightButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.top.equalTo(bottomLine.snp.bottom).offset(0.5)
            make.height.equalTo(51.5)
            make.left.equalTo(leftButton.snp.right)
            make.width.equalTo(leftButton)
            make.bottom.equalToSuperview()
        }
        /// 底部竖线
        let bottomCenterLine = UIView()
        bottomCenterLine.backgroundColor = UIColor.ud.N300
        self.contentWrapperView.addSubview(bottomCenterLine)
        bottomCenterLine.snp.makeConstraints { (make) in
            make.width.equalTo(0.5)
            make.height.equalTo(51.5)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(rightButton)
        }
        /// 需要做一个缩放动画，先缩小视图
        self.contentWrapperView.transform = CGAffineTransform.identity.scaledBy(x: 0.1, y: 0.1)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateContentWrapperView(newCollection: traitCollection)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /// 因为当前vc在present时是没有动画的，所以需要等待一会儿才可以做自己的动画，不然动画会被吞掉
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.35) {
                self.contentWrapperView.transform = CGAffineTransform.identity.scaledBy(x: 1, y: 1)
            }
        }
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        updateContentWrapperView(newCollection: newCollection)
    }

    private func updateContentWrapperView(newCollection: UITraitCollection) {
        if newCollection.horizontalSizeClass == .compact {
            contentWrapperView.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(36)
                make.right.equalToSuperview().offset(-36)
                make.center.equalToSuperview()
            }
        } else {
            // 模态窗大小为540
            contentWrapperView.snp.remakeConstraints { (make) in
                make.width.equalTo(540)
                make.center.equalToSuperview()
            }
        }
    }

    /// 选择其他语言
    @objc
    private func selectTargetLanguage(sender: UIControl) {
        let actionSheet = ActionSheet()
        self.viewModel.allNeedShowSupportedLanguages.forEach { (languageKey) in
            let currIsSelectdLanguage = languageKey == self.viewModel.selectdTargetLanguage
            actionSheet.addItem(
                title: self.viewModel.languageValue(language: languageKey),
                textColor: UIColor.ud.N900,
                icon: currIsSelectdLanguage ? Resources.select_target_language_icon : nil,
                action: { [weak self] in
                    guard let `self` = self else { return }
                    self.viewModel.selectdTargetLanguage = languageKey
                    self.languageLabel.text = self.viewModel.languageValue(language: languageKey)
                }
            )
        }
        actionSheet.addCancelItem(title: BundleI18n.LarkChat.Lark_Legacy_Cancel)
        navigator.present(actionSheet, from: self)
    }

    /// 根据当前语言，获取动画文件路径
    private func translateAnimationPath() -> String {
        let path: String
        switch LanguageManager.currentLanguage {
        case .zh_CN:
            path = "translate_animation_zh"
        default:
            path = "translate_animation_en"
        }
        let jsonPath = BundleConfig.LarkChatBundle.path(
            forResource: "fanyi",
            ofType: "json",
            inDirectory: "Lottie/\(path)"
        )
        return jsonPath ?? ""
    }
}
