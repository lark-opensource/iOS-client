//
//  AudioLanguageLabel.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/8/27.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import EENavigator
import LarkLocalizations
import LarkActionSheet
import LarkAlertController
import RxSwift
import LarkContainer
import LarkNavigator
import UniverseDesignColor // UDColor
import UniverseDesignIcon // UDIcon

final class AudioLanguageLabel: UIView, UserResolverWrapper {
    private var disposeBag = DisposeBag()
    private var languageLabel = UILabel()
    private var languageTapView = UIView()
    private var tipLabel = UILabel()
    private let arrowImageView: UIImageView = {
        let image = Resources.conversation_arrow.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.tintColor = UIColor.ud.textTitle
        return imageView
    }()

    private var type: AudioTracker.RecognizeType

    var recognitionLanguage: Lang {
        return RecognizeLanguageManager.shared.recognitionLanguage
    }

    let userResolver: UserResolver

    init(userResolver: UserResolver, type: AudioTracker.RecognizeType) {
        self.userResolver = userResolver
        self.type = type
        super.init(frame: .zero)
        self.setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        self.addSubview(languageTapView)
        languageTapView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        languageTapView.lu.addTapGestureRecognizer(
            action: #selector(AudioLanguageLabel.handleLanguageTap),
            target: self
        )

        self.languageLabel.font = UIFont.systemFont(ofSize: 16)
        self.languageLabel.textAlignment = .center
        self.languageLabel.textColor = UIColor.ud.textTitle
        self.languageLabel.text = self.languageText()
        languageTapView.addSubview(self.languageLabel)
        self.languageLabel.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(10)
            maker.top.equalTo(9)
        }

        languageTapView.addSubview(arrowImageView)
        self.arrowImageView.transform = CGAffineTransform(rotationAngle: .pi / 2)
        self.arrowImageView.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalTo(self.languageLabel)
            make.left.equalTo(self.languageLabel.snp.right).offset(5)
        }

        self.tipLabel.font = UIFont.systemFont(ofSize: 14)
        self.tipLabel.textAlignment = .center
        self.tipLabel.textColor = UIColor.ud.textPlaceholder
        languageTapView.addSubview(self.tipLabel)
        self.tipLabel.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.languageLabel.snp.bottom).offset(4)
            maker.bottom.equalToSuperview().offset(-10)
        }

        RecognizeLanguageManager.shared
            .languageSubject
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.languageLabel.text = self.languageText()
            }).disposed(by: self.disposeBag)
    }

    func setTipString(_ tip: String) {
        self.tipLabel.text = tip
    }

    func updateLabelAndIcon(labelFont: CGFloat, labelColor: UIColor) {
        languageLabel.font = UIFont.systemFont(ofSize: labelFont)
        languageLabel.textColor = labelColor
        arrowImageView.image = UDIcon.downBoldOutlined.ud.withTintColor(UIColor.ud.iconN2)
        self.arrowImageView.transform = CGAffineTransform(rotationAngle: 0)
        languageLabel.snp.remakeConstraints { make in
            make.left.top.bottom.equalToSuperview()
        }
        arrowImageView.snp.remakeConstraints { make in
            make.right.centerY.equalToSuperview()
            make.width.height.equalTo(12)
            make.left.equalTo(self.languageLabel.snp.right).offset(4)
        }
    }

    private func languageText() -> String {
        return RecognizeLanguageManager.shared.recognitionLanguageI18n
    }

    @objc
    private func handleLanguageTap() {
        guard let window = self.window else {
            assertionFailure("Lost From Window")
            return
        }
        self.presentActionPanel(from: window)
    }

    private func presentActionPanel(from: NavigatorFrom) {
        let vc = LanguagePickerViewController(userResolver: userResolver,
                                              currentTargetLanguage: RecognizeLanguageManager.shared.recognitionLanguage,
                                              supportLangs: AudioKeyboardDataService.shared.supportLangs,
                                              supportLangsi18nMap: AudioKeyboardDataService.shared.supportLangsi18nMap,
                                              recognizeType: self.type)
        let panel = LanguagePickerActionPanel(navigator: userResolver.navigator, languagePickerVC: vc, supportLangs: AudioKeyboardDataService.shared.supportLangs)
        userResolver.navigator.present(panel, from: from)
    }
}
