//
//  WebTranslateControlBar.swift
//  LarkWebView
//
//  Created by JackZhao on 2020/8/20.
//

import Foundation
import UIKit
import LarkActivityIndicatorView
import LarkSDKInterface
import RxSwift
import LKCommonsLogging
import Homeric
import LKCommonsTracker

// 网页翻译状态
public enum WebTranslateStatus: String {
    case `init`
    case origin
    case loading
    case target
    case failed
    case unknown
}

// 网页翻译过程中的上下文信息
public struct WebTranslateProcessInfo {
    var status: WebTranslateStatus
    var originLangName: String
    var originLangCode: String
    var targetLangName: String
    var targetLangCode: String
    var supportedLanguages: [String: String]

    public init(status: WebTranslateStatus = .unknown,
                supportedLanguages: [String: String] = [:],
                originLangName: String = "",
                originLangCode: String = "",
                targetLangName: String = "",
                targetLangCode: String = "") {
        self.status = status
        self.supportedLanguages = supportedLanguages
        self.originLangCode = originLangCode
        self.targetLangCode = targetLangCode
        self.targetLangName = targetLangName
        self.originLangName = originLangName
    }
}

protocol TranslateBarDelegate: AnyObject {
    func onTapOpenSetting()
    func onTapManualTranslate(_ translateInfo: WebTranslateProcessInfo)
    func onTapShowOrigin()
    func onTapClose()
}

final class WebTranslateControlBar: UIView {
    weak var fromVC: UIViewController?

    private let disposeBag = DisposeBag()

    static private let logger = Logger.log(WebTranslateControlBar.self)

    private weak var translateBarDelegate: TranslateBarDelegate?

    private var currentInfo = WebTranslateProcessInfo()

    private let normalAttributes: [NSAttributedString.Key: Any] =
        [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .medium),
         NSAttributedString.Key.foregroundColor: UIColor.ud.textCaption]

    private let selectedAttributes: [NSAttributedString.Key: Any] =
        [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .medium),
        NSAttributedString.Key.foregroundColor: UIColor.ud.colorfulBlue]

    var containerView = UIView()

    var translateIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Resources.web_icon_translate
        return imageView
    }()

    lazy var originButton: UIButton = {
        let button = UIButton()
        let normalAttrTitle = NSAttributedString(string: BundleI18n.LarkAI.Lark_Chat_Original,
                                                 attributes: self.normalAttributes)
        let selectedAttrTitle = NSAttributedString(string: BundleI18n.LarkAI.Lark_Chat_Original,
                                                   attributes: self.selectedAttributes)
        button.setAttributedTitle(normalAttrTitle, for: .normal)
        button.setAttributedTitle(selectedAttrTitle, for: .selected)
        button.adjustsImageWhenHighlighted = false
        button.addTarget(self, action: #selector(tapDisplayOrigin(_:)), for: .touchUpInside)
        return button
    }()

    lazy var targetLanguageButton: UIButton = {
        let button = UIButton()
        button.adjustsImageWhenHighlighted = false
        button.addTarget(self, action: #selector(tapDisplayTarget(_:)), for: .touchUpInside)
        return button
    }()

    // 转圈控件
    var indicator: ActivityIndicatorView = {
        return ActivityIndicatorView(color: UIColor.ud.colorfulBlue)
    }()

    lazy var settingButton: UIButton = {
        let button = UIButton()
        button.adjustsImageWhenHighlighted = false
        button.setImage(Resources.web_icon_setting.ud.withTintColor(UIColor.ud.iconN2,
                                                                    renderingMode: .automatic), for: .normal)
        button.addTarget(self, action: #selector(tapSetting), for: .touchUpInside)
        button.hitTestEdgeInsets = .init(top: 5, left: 5, bottom: 5, right: 5)
        return button
    }()

    lazy private var exitButton: UIButton = {
        let button = UIButton()
        button.adjustsImageWhenHighlighted = false
        button.setImage(Resources.web_icon_close.ud.withTintColor(UIColor.ud.iconN2,
                                                                  renderingMode: .automatic), for: .normal)
        button.addTarget(self, action: #selector(tapExit), for: .touchUpInside)
        button.hitTestEdgeInsets = .init(top: 5, left: 5, bottom: 5, right: 5)
        return button
    }()

    init(delegate: TranslateBarDelegate) {
        super.init(frame: .zero)
        self.translateBarDelegate = delegate
        self.backgroundColor = UIColor.ud.bgFloat
		initView()
    }

    func initView() {
        self.addSubview(containerView)
        containerView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
        }

        containerView.addSubview(translateIcon)
        translateIcon.snp.makeConstraints { (make) in
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
            make.left.equalTo(20)
        }

        containerView.addSubview(originButton)
        originButton.snp.makeConstraints { (make) in
            make.left.equalTo(translateIcon.snp.right).offset(12)
            make.centerY.equalToSuperview()
        }

        containerView.addSubview(exitButton)
        exitButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(24)
            make.right.equalTo(-11)
            make.centerY.equalToSuperview()
        }

        containerView.addSubview(settingButton)
        settingButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(24)
            make.right.equalTo(exitButton.snp.left).offset(-20)
            make.centerY.equalToSuperview()
        }

        containerView.addSubview(targetLanguageButton)
        targetLanguageButton.snp.makeConstraints { (make) in
            make.left.equalTo(originButton.snp.right).offset(30)
            make.right.lessThanOrEqualTo(settingButton.snp.left)
            make.centerY.equalToSuperview()
        }

        containerView.addSubview(indicator)
        indicator.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.centerX.equalTo(targetLanguageButton)
            make.width.height.equalTo(15)
        }
    }

    func updateUIByWebTranslateConfig(_ info: WebTranslateProcessInfo) {
        switch info.status {
        case .origin:
            // 处理revert的情况，即目标语言和网站源语言相同
            if !originButton.isSelected {
                originButton.isSelected = true
            }
            if targetLanguageButton.isSelected {
                targetLanguageButton.isSelected = false
            }
        case .loading:
            // 转圈和目标语言按钮显示互斥
            // 开始进行网站翻译时会走到这里
            if indicator.isHidden {
                indicator.isHidden = false
            }
            if !indicator.isAnimating {
                indicator.startAnimating()
            }
            if !targetLanguageButton.isHidden {
                targetLanguageButton.isHidden = true
            }
        case .target:
            // 原文和目标语言按钮选择态互斥
            // 网页翻译完成会走到这里（除过目标语言和网站源语言相同）
            if !indicator.isHidden {
                indicator.isHidden = true
            }
            if indicator.isAnimating {
                indicator.stopAnimating()
            }
            if targetLanguageButton.isHidden {
                targetLanguageButton.isHidden = false
            }
            if !targetLanguageButton.isSelected {
                targetLanguageButton.isSelected = true
            }
            if originButton.isSelected {
                originButton.isSelected = false
            }
            let normalAttrTitle = NSAttributedString(string: info.targetLangName,
                                                     attributes: normalAttributes)
            targetLanguageButton.setAttributedTitle(normalAttrTitle, for: .normal)
            let selectedAttrTitle = NSAttributedString(string: info.targetLangName,
                                                       attributes: selectedAttributes)
            targetLanguageButton.setAttributedTitle(selectedAttrTitle, for: .selected)
        default:
            break
        }
		// origin的时候，targetLang和originLang是相同的，因此不更新数据
		if info.status != .origin {
			currentInfo = info
		}
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func tapExit() {
        let time = self.targetLanguageButton.isSelected ? "translate" : "untranslate"
        Tracker.post(TeaEvent(Homeric.CLOSE_WEB_TRANSLATE_GUIDE, params: ["time": time]))
        translateBarDelegate?.onTapClose()
    }

    @objc
    func tapDisplayOrigin(_ button: UIButton) {
        guard button.isSelected == false else { return }
        button.isSelected = true
        // 原文和目标语言按钮选中态互斥
        if self.targetLanguageButton.isSelected {
            self.targetLanguageButton.isSelected = false
        }
        translateBarDelegate?.onTapShowOrigin()
    }

    @objc
    func tapDisplayTarget(_ button: UIButton) {
        guard button.isSelected == false else { return }
        button.isSelected = true
        // 原文和目标语言按钮选中态互斥
        if self.originButton.isSelected {
            self.originButton.isSelected = false
        }
        translateBarDelegate?.onTapManualTranslate(currentInfo)
    }

    @objc
    func tapSetting() {
        translateBarDelegate?.onTapOpenSetting()
    }
}
