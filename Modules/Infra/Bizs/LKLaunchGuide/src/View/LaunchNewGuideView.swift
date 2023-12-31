//
//  LaunchNewGuideView.swift
//  LKLaunchGuide
//
//  Created by Yuri on 2023/8/21.
//

import UIKit
import SnapKit
import LottieLark
import UniverseDesignColor
import UniverseDesignFont
import LarkLocalizations

/// Layout 的间距等常量
private enum Layout {

    static let buttonHeight: CGFloat = 112
    static let groupMaxWidth: CGFloat = 400
    static let buttonSpacing: CGFloat = 16
    static var buttonFont: UIFont { .systemFont(ofSize: 17) }

    static let hMargin: CGFloat = 24
    static let vMargin: CGFloat = 16
    static let pvMargin: CGFloat = 24

    static let titleSpacing: CGFloat = 20
    static var titleFont: UIFont { .systemFont(ofSize: 30, weight: .semibold) }
    static var detailFont: UIFont { .systemFont(ofSize: 16) }
    static let titleKern: CGFloat = 4
    static let subTitleLineSpacing: CGFloat = 4

    static let titleImageSpacing: CGFloat = 16
}

final class LaunchNewGuideView: UIView {
    typealias I18N = BundleI18n.LKLaunchGuide

    public var showSignButton: Bool = false {
        didSet {
            self.signupButton.isHidden = !showSignButton
            if isLark { self.signupButton.isHidden = true }
        }
    }
    private var titleViews: [UIView] = []
    private var currentIndex: Int = 1
    private var autoScrollMode: Bool = true

    let contentView = UIView()
    private lazy var topContainer: UIView = UIView()
    private lazy var bottomContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBase
        return view
    }()

    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    /// 按钮容器
    private lazy var buttonGroupView: UIView = UIView()

    private lazy var loginButton: UIButton = {
        let button = makeButton()
        button.setTitle(I18N.Lark_Passport_Newsignup_LoginButton, for: .normal)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.backgroundColor = UIColor.ud.primaryContentDefault
        button.layer.cornerRadius = 6
        return button
    }()

    private lazy var signupButton: UIButton = {
        let button = makeButton()
        button.setTitle(I18N.Lark_Passport_Newsignup_SignUpTeamButton(LanguageManager.bundleDisplayName), for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = Layout.buttonFont.withWeight(.semibold)
        button.backgroundColor = UIColor.ud.bgBody
        button.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.bgBody), for: .normal)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.udtokenBtnTextBgPriHover), for: .highlighted)
        return button
    }()

    private func makeButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.font = Layout.buttonFont
        button.addTarget(self, action: #selector(btnClick), for: .touchUpInside)
        return button
    }

    lazy var imageContainer: UIView = {
        let view = UIView()
        return view
    }()

    lazy var lmAnimationView: LottieAnimationView = {
        return makeAnimationView(name: "guide_lm")
    }()

    lazy var dmAnimationView: LottieAnimationView = {
        return makeAnimationView(name: "guide_dm")
    }()

    private func makeAnimationView(name: String) -> LottieAnimationView {
        let path = BundleConfig.LKLaunchGuideBundle.path(forResource: name, ofType: "lottie", inDirectory: "Lottie") ?? ""
        let vi = LottieAnimationView(configuration: .init(renderingEngine: .mainThread))
        DotLottieFile.loadedFrom(filepath: path) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    vi.loadAnimation(from: success)
                    vi.loopMode = .loop
                    vi.play()
                case .failure(_):
                    break
                }
            }
        }
        vi.isHidden = true
        return vi
    }

    private var lastPage: Int = 1
    private var isPageChanged: Bool = false

    var signupAction: (() -> Void)?
    var loginAction: (() -> Void)?

    var isLark: Bool
    var isDark: Bool
    init(frame: CGRect, isLark: Bool = false, isDark: Bool = false) {
        self.isLark = isLark
        self.isDark = isDark
        super.init(frame: frame)
        self.backgroundImageView.backgroundColor = UIColor.ud.bgBody
        self.backgroundImageView.isHidden = isDark
        setupSubviews()
        setupConstraints()
        self.signupButton.isHidden = !self.showSignButton
        if isLark { self.signupButton.isHidden = true }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        viewShouldRemove()
    }

    @objc
    private func btnClick(sender: UIButton) {
        if sender == signupButton {
            self.signupAction?()
        }
        if sender == loginButton {
            self.loginAction?()
        }
    }

    private func generateAttributeString(string: String, lineHeight: CGFloat, font: UIFont) -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineHeight - font.lineHeight
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byTruncatingTail
        let attributedString = NSMutableAttributedString(string: string)
        attributedString.addAttributes([.paragraphStyle: paragraphStyle, .font: font],
                                       range: NSRange(location: 0, length: string.count))
        return attributedString
    }

    public func viewShouldRemove() {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - setup view
extension LaunchNewGuideView {

    private func setupSubviews() {
        if isLark {
            loginButton.setTitle(I18N.Lark_Global_Registration_StarterPage_GetStarted_Button, for: .normal)
        }
        addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        addSubview(topContainer)
        topContainer.addSubview(contentView)
        addSubview(buttonGroupView)
        buttonGroupView.addSubview(loginButton)
        buttonGroupView.addSubview(signupButton)

        contentView.snp.makeConstraints {
            $0.width.equalTo(400)
            $0.centerX.equalToSuperview()
            $0.top.equalTo(safeAreaLayoutGuide.snp.top)
            $0.bottom.equalTo(buttonGroupView.snp.top)
        }

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-36)
        }

        let container = UIView()
        let imageView = UIImageView()
        imageView.image = Resources.LKLaunchGuide.guide_background
        container.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        container.addSubview(dmAnimationView)
        dmAnimationView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-4)
            $0.size.equalTo(CGSize(width: 167, height: 167))
        }
        container.addSubview(lmAnimationView)
        lmAnimationView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-4)
            $0.size.equalTo(CGSize(width: 167, height: 167))
        }
        container.layoutIfNeeded()
        lmAnimationView.layoutIfNeeded()
        dmAnimationView.layoutIfNeeded()
        if isDark {
            backgroundImageView.isHidden = true
            backgroundColor = UIColor.ud.bgBody
            lmAnimationView.isHidden = true
            dmAnimationView.isHidden = false
            dmAnimationView.play()
        } else {
            backgroundImageView.isHidden = false
            backgroundColor = .clear
            dmAnimationView.isHidden = true
            lmAnimationView.isHidden = false
            lmAnimationView.play()
        }


        stackView.addArrangedSubview(container)
        stackView.setCustomSpacing(24, after: container)
        container.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 280, height: 249))
        }

        let title = isLark ? I18N.Lark_Marketing_Lark_MainSlogan_2023() : I18N.Lark_Marketing_Feishu_MainSlogan_2023()
        let desc = isLark ? I18N.Lark_Marketing_Lark_SubSlogan_2023() : I18N.Lark_Marketing_Feishu_SubSlogan_2023()
        let titleFont = UIFont.systemFont(ofSize: 24, weight: .semibold)
        let descFont = UIFont.systemFont(ofSize: 16)
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 2
        titleLabel.attributedText = generateAttributeString(string: title, lineHeight: 32, font: titleFont)
        stackView.addArrangedSubview(titleLabel)
        stackView.setCustomSpacing(24, after: titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.trailing.equalToSuperview().inset(24)
        }

        if !desc.isEmpty, desc != " " { // 飞书文案目前为空
            let descLabel = UILabel()
            descLabel.numberOfLines = 3
            descLabel.attributedText = generateAttributeString(string: desc, lineHeight: 24, font: descFont)
            stackView.addArrangedSubview(descLabel)
            descLabel.snp.makeConstraints {
                $0.leading.equalToSuperview().offset(24)
                $0.trailing.equalToSuperview().inset(24)
            }
        }
    }

    private func setupConstraints() {
        topContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(buttonGroupView.snp.top)
        }
        buttonGroupView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.lessThanOrEqualToSuperview().offset(Layout.hMargin)
            make.trailing.lessThanOrEqualToSuperview().offset(-Layout.hMargin)
            make.width.lessThanOrEqualTo(Layout.groupMaxWidth).priority(.medium)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-20)
            make.height.equalTo(Layout.buttonHeight)
        }
        signupButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(48)
            make.bottom.equalToSuperview()
        }
        loginButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(48)
            make.bottom.equalTo(signupButton.snp.top).offset(-Layout.buttonSpacing)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if UIDevice.current.userInterfaceIdiom == .pad {
            let width = min(self.bounds.width, 400)
            contentView.snp.updateConstraints {
                $0.width.equalTo(width)
            }
        } else {
            contentView.snp.updateConstraints {
                $0.width.equalTo(bounds.width)
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard #available(iOS 13.0, *),
              traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
            // 如果当前设置主题一致，则不需要切换资源
            return
        }
        if self.traitCollection.userInterfaceStyle == .dark {
            backgroundImageView.isHidden = true
            self.backgroundColor = UIColor.ud.bgBody
            lmAnimationView.isHidden = true
            dmAnimationView.isHidden = false
            dmAnimationView.play()
        } else {
            backgroundImageView.isHidden = false
            self.backgroundColor = UIColor.clear
            dmAnimationView.isHidden = true
            lmAnimationView.isHidden = false
            lmAnimationView.play()
        }
    }
}
