//
//  SelectTranslateContainerViewController.swift
//  LarkAI
//
//  Created by ByteDance on 2022/8/15.
//
//

import Foundation
import LarkUIKit
import FigmaKit
import LarkContainer
import LarkSDKInterface
import UIKit
import LarkModel
import LarkMessengerInterface
import ServerPB
import RxSwift
import UniverseDesignToast
import LarkCore
import LarkSearchCore
import LarkReleaseConfig
import LarkEMM
import LarkSensitivityControl
import EENavigator
private enum UI {
    static let screenHeight: CGFloat = UIScreen.main.bounds.size.height
    static let screenWidth: CGFloat = UIScreen.main.bounds.size.width
    static let headerHeight: CGFloat = 60
    static let sendButtonHeight: CGFloat = 48
    static let sendButtonMargin: CGFloat = 16
    static let gradientViewWidth: CGFloat = 52
    static let contentPadding: CGFloat = 16
    static let changeLanguageBtnHeight: CGFloat = 52
    static let feedbackBtnHeight: CGFloat = 52
}

/// 为支持划词卡片上的可划选复制
final class ReplicableTextView: UITextView {

    var copyConfig: TranslateCopyConfig = TranslateCopyConfig() {
        didSet {
            self.pointId = copyConfig.pointId
        }
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setTextStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTextStyle() {
        isEditable = false
        isScrollEnabled = false
        backgroundColor = .ud.bgFloat
        /// 去除textView和文字之间的padding
        textContainerInset = UIEdgeInsets.zero
        textContainer.lineFragmentPadding = 0
        delegate = self
    }
    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.copy(_:)) {
            return super.canPerformAction(action, withSender: sender)
        }
        /// disable remaining items
        return false
    }
    override func copy(_ sender: Any?) {
        if self.pointId != nil || copyConfig.canCopy {
            //pointId不为空时，允许复制，由LarkEMM管控
            super.copy(sender)
        } else {
            guard let window = self.window, let text = copyConfig.denyCopyText, let view = WindowTopMostFrom(window: window).fromViewController?.view else { return }
            UDToast.showFailure(with: text, on: view)
        }
    }
}
extension ReplicableTextView: UITextViewDelegate {

    @available(iOS 13.0, *)
    func textView(_ textView: UITextView, editMenuForTextIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
        var additionalActions: [UIMenuElement] = []
        if let selectRange = Range(range, in: textView.text) {
            let selectText = String(textView.text[selectRange])
            let copyAction = UIAction(title: BundleI18n.LarkAI.Lark_ASLTranslation_SelectAndTranslate_CopySelectedWords_CopyButton) { [weak self] _ in
                guard let self else { return }
                if self.copyConfig.canCopy || self.pointId != nil {
                    let config = PasteboardConfig(token: Token("LARK-PSDA-select_translate_card_copy_content"), pointId: self.pointId)
                    SCPasteboard.general(config).string = selectText
                } else if let window = self.window, let text = self.copyConfig.denyCopyText, let view = WindowTopMostFrom(window: window).fromViewController?.view {
                    //业务方传入了denyCopyText，弹出复制失败提示
                    UDToast.showFailure(with: text, on: view)
                }
            }
            additionalActions.append(copyAction)
        }
        return UIMenu(children: additionalActions)
    }
}

final class SelectTranslateContainerViewController: BaseUIViewController, UserResolverWrapper {

    let selectText: String
    var translateText: String = ""
    /// 翻译类型，后端传值，取值为：sentence/word
    var translateType: String = ""
    /// 划选的文本长度，后端传值
    var translateLength: String = ""
    private var selectTranslateData: ServerPB_Translate_TranslateWebXMLResponse
    private var targetLanguage: String = ""
    private let copyConfig: TranslateCopyConfig
    private var params: [String: Any] = [:]
    private let disposeBag = DisposeBag()
    private var _presentationDelegage: Any?
    @available(iOS 15.0, *)
    var presentationDelegage: UISheetPresentationControllerDelegate? {
        get {
            return _presentationDelegage as? UISheetPresentationControllerDelegate
        }
        set {
            _presentationDelegage = newValue
        }
    }

    @ScopedInjectedLazy var userGeneralSettings: UserGeneralSettings?
    @ScopedInjectedLazy var translateFeedbackService: TranslateFeedbackService?
    private let selectTranslateAPI: SelectTranslateAPI
    private lazy var selectLanguageCenter: SelectTargetLanguageTranslateCenter? = {
        guard let userGeneralSettings else { return nil }
        return SelectTargetLanguageTranslateCenter(
            userResolver: userResolver,
            selectTargetLanguageTranslateCenterdelegate: self,
            translateLanguageSetting: userGeneralSettings.translateLanguageSetting
        )
    }()

    lazy var captureShieldUtil = CaptureShieldUtility()
    // UI部分，防截图container
    private lazy var containerView: UIView = {
        return captureShieldUtil.contentView
    }()
    // 整个卡片的滚动视图
    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.ud.bgFloatBase
        return view
    }()
    // 可滚动视图承载的卡片界面
    private let containerScrollView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.ud.bgFloatBase
        return view
    }()

    // 划词卡片/机器翻译卡片
    private var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private var contentViewController = UIViewController()
    // 翻译头部
    private lazy var headerView: SelectTranslateHeadView = {
        let headerView = SelectTranslateHeadView(delegate: self)
        headerView.backgroundColor = UIColor.ud.bgFloatBase
        return headerView
    }()

    // 复制译文按钮
    private lazy var copyTranslationView: UIView = {
        let view = UIView()
        let gesture = UITapGestureRecognizer(target: self, action: #selector(clickCopyTranslation))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addGestureRecognizer(gesture)
        view.backgroundColor = .ud.bgFloat
        view.roundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], radius: 8.0)
        return view
    }()
    private lazy var copyTranslationText: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = BundleI18n.LarkAI.Lark_ASLTranslation_SelectAndTranslate_CopyTranslation_Button
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()
    private lazy var copyTranslationLogo: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setImage(Resources.translate_card_copy, tintColor: UIColor.ud.iconN1)
        return imageView
    }()
    // 切换语种按钮
    private lazy var changeLanguageView: UIView = {
        let view = UIView()
        let gesture = UITapGestureRecognizer(target: self, action: #selector(clickChangeLanguage))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addGestureRecognizer(gesture)
        view.backgroundColor = .ud.bgFloat
        view.roundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], radius: 8.0)
        return view
    }()
    private lazy var changeLanguageText: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = BundleI18n.LarkAI.Lark_ASL_SelectTranslate_TranslationResult_SwitchLanguages
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()
    private lazy var changeLanuageLogo: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setImage(Resources.translate_card_changeLanguage, tintColor: UIColor.ud.iconN1)
        return imageView
    }()

    // 翻译反馈按钮
    private lazy var feedBackView: UIView = {
        let view = UIView()
        let gesture = UITapGestureRecognizer(target: self, action: #selector(clickTranslateFeedBack))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addGestureRecognizer(gesture)
        view.backgroundColor = .ud.bgFloat
        view.roundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], radius: 8.0)
        return view
    }()
    private lazy var feedBackText: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = BundleI18n.LarkAI.Lark_ASL_SelectTranslate_TranslationResult_TranslationFeedback
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()
    private lazy var feedBackLogo: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setImage(Resources.translate_card_feedback, tintColor: UIColor.ud.iconN1)
        return imageView
    }()

    let userResolver: UserResolver
    init(resolver: UserResolver, selectTranslateData: ServerPB_Translate_TranslateWebXMLResponse,
         selectText: String,
         copyConfig: TranslateCopyConfig?,
         trackParam: [String: Any]
    ) {
        self.userResolver = resolver
        self.selectText = selectText
        self.selectTranslateData = selectTranslateData
        self.copyConfig = copyConfig ?? TranslateCopyConfig()
        self.params = trackParam
        self.selectTranslateAPI = RustSelectTranslateAPI(resolver: resolver)
        super.init(nibName: nil, bundle: nil)
        self.targetLanguage = userGeneralSettings?.translateLanguageSetting.targetLanguage ?? ""
        updateTranslateString()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubViews()
        captureShieldUtil.setCaptureAllowed(copyConfig.canCopy)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    func updateTranslateString() {
        var translateTextString: String = ""
        if selectTranslateData.translateDictCardMap.isEmpty || ReleaseConfig.isLark {
            for content in selectTranslateData.trgContents {
                translateTextString.append(content)
            }
        } else {
            selectTranslateData.translateDictCardMap[selectText]?.definitions.forEach { (definition) in
                translateTextString.append(definition.pos)
                translateTextString.append(definition.definitionText)
                translateTextString.append("\n")
            }
        }
        self.translateText = translateTextString.isEmpty ? selectText : translateTextString
        self.translateType = selectTranslateData.trackInfos.first?.chosenContentType ?? ""
        self.translateLength = selectTranslateData.trackInfos.first?.wordCount ?? ""

    }

    @objc
    func clickTranslateFeedBack() {
        let feedBackParam: [String: Any] = [
            "objectID": params["objectID"],
            "cardSource": params["cardSource"]
        ]
        translateFeedbackService?.showTranslateFeedbackForSelectText(selectText: selectText,
                                                                    translateText: translateText,
                                                                    targetLanguage: targetLanguage,
                                                                    copyConfig: copyConfig,
                                                                    extraParam: feedBackParam,
                                                                    fromVC: self)
        let extraParam = ["target": "asl_crosslang_translation_card_sub_view", "function_type": "feedback"]
        SelectTranslateTracker.selectTranslateCardClick(resultType: "success",
                                                        clickType: "function",
                                                        wordID: params["wordID"],
                                                        messageID: params["messageID"],
                                                        chatID: params["chatID"],
                                                        fileID: params["fileID"],
                                                        fileType: params["fileType"],
                                                        srcLanguage: params["srcLanguage"],
                                                        tgtLanguage: params["tgtLanguage"],
                                                        cardSouce: params["cardSource"],
                                                        translateType: self.translateType,
                                                        translateLength: self.translateLength,
                                                        extraParam: extraParam)
    }

    @objc
    func clickChangeLanguage() {
        guard let selectLanguageCenter else { return }
        selectLanguageCenter.showSelectDrawer(translateContext: .text(context: selectText), from: self, backButtonStatus: .cancel, usePush: true)
        let extraParam = ["target": "none", "function_type": "switch_lang"]
        SelectTranslateTracker.selectTranslateCardClick(resultType: "success",
                                                        clickType: "function",
                                                        wordID: params["wordID"],
                                                        messageID: params["messageID"],
                                                        chatID: params["chatID"],
                                                        fileID: params["fileID"],
                                                        fileType: params["fileType"],
                                                        srcLanguage: params["srcLanguage"],
                                                        tgtLanguage: params["tgtLanguage"],
                                                        cardSouce: params["cardSource"],
                                                        translateType: self.translateType,
                                                        translateLength: self.translateLength,
                                                        extraParam: extraParam)
    }

    @objc
    func clickCopyTranslation() {
        guard copyConfig.pointId != nil || copyConfig.canCopy else {
            if let text = copyConfig.denyCopyText {
                UDToast.showFailure(with: text, on: self.view)
            }
            return
        }
        let config = PasteboardConfig(token: Token("LARK-PSDA-select_translate_card_copy_translation"), pointId: copyConfig.pointId)
        SCPasteboard.general(config).string = self.translateText
        if copyConfig.pointId == nil {
            UDToast.showSuccess(with: BundleI18n.LarkAI.Lark_ASLTranslation_SelectAndTranslate_CopyTranslation_CopiedToast, on: self.view)
        }
        let extraParam = ["target": "none"]
        SelectTranslateTracker.selectTranslateCardClick(resultType: "success",
                                                        clickType: "copy",
                                                        wordID: params["wordID"],
                                                        messageID: params["messageID"],
                                                        chatID: params["chatID"],
                                                        fileID: params["fileID"],
                                                        fileType: params["fileType"],
                                                        srcLanguage: params["srcLanguage"],
                                                        tgtLanguage: params["tgtLanguage"],
                                                        cardSouce: params["cardSource"],
                                                        translateType: self.translateType,
                                                        translateLength: self.translateLength,
                                                        extraParam: extraParam)
    }
}
extension SelectTranslateContainerViewController: SelectTranslateHeadViewDelegate {
    func cancelFeedback() {
        dismiss(animated: true, completion: nil)
    }
}

@available(iOS 15.0, *)
extension SelectTranslateContainerViewController: UISheetPresentationControllerDelegate {
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_: UISheetPresentationController) {
        SelectTranslateTracker.selectTranslateCardClick(resultType: "success",
                                                        clickType: "unfold_explanation",
                                                        wordID: params["wordID"],
                                                        messageID: params["messageID"],
                                                        chatID: params["chatID"],
                                                        fileID: params["fileID"],
                                                        fileType: params["fileType"],
                                                        srcLanguage: params["srcLanguage"],
                                                        tgtLanguage: params["tgtLanguage"],
                                                        cardSouce: params["cardSource"],
                                                        translateType: self.translateType,
                                                        translateLength: self.translateLength,
                                                        extraParam: ["target": "none"])
    }

}
extension SelectTranslateContainerViewController: SelectTargetLanguageTranslateCenterDelegate {
    func finishSelect(translateContext: TranslateContext, targetLanguage: String) {
        // 调用翻译的接口，刷新卡片
        selectTranslateAPI.selectTextTranslateInformation(selectText: selectText, trgLanguage: targetLanguage)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                self?.selectTranslateData = response
                self?.targetLanguage = targetLanguage
                self?.updateTranslateString()
                self?.contentView.removeFromSuperview()
                self?.updateUIAndData()
            }, onError: { [weak self] _ in
                guard let self = self, let window = self.view.window else { return }
                UDToast.showTips(with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError, on: window)
            }).disposed(by: disposeBag)
    }
    private func updateUIAndData() {
        contentViewController = transitionContent()
        contentView = contentViewController.view ?? UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        containerScrollView.addSubview(contentView)
        constraintContentView()
        self.view.setNeedsLayout()
    }
}

private extension SelectTranslateContainerViewController {
    /// 布局子试图
    private func setupSubViews() {
        view.backgroundColor = .ud.bgFloatBase
        view.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        containerView.addSubview(headerView)
        headerView.snp.makeConstraints { (make) in
            make.top.equalTo(containerView.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(UI.headerHeight)
        }
        view.addSubview(scrollView)
        scrollView.addSubview(containerScrollView)
        contentViewController = transitionContent()
        self.addChild(contentViewController)
//        contentViewController.didMove(toParent: self)

        contentView = contentViewController.view ?? UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        containerScrollView.addSubview(contentView)
        containerScrollView.addSubview(copyTranslationView)
        containerScrollView.addSubview(changeLanguageView)
        containerScrollView.addSubview(feedBackView)

        copyTranslationView.addSubview(copyTranslationText)
        copyTranslationView.addSubview(copyTranslationLogo)

        changeLanguageView.addSubview(changeLanguageText)
        changeLanguageView.addSubview(changeLanuageLogo)

        feedBackView.addSubview(feedBackText)
        feedBackView.addSubview(feedBackLogo)

        constraintScrollView()
        constraintContentView()
        constraintCopyTransBtn()
        constraintChangeLangBtn()
        constraintFeedbackBtn()
        feedBackView.isHidden = !AIFeatureGating.translateFeedback.isUserEnabled(userResolver: userResolver)
    }
    func constraintScrollView() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])

        NSLayoutConstraint.activate([
            containerScrollView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            containerScrollView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            containerScrollView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            containerScrollView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor)
        ])

        let contentViewCenterY = containerScrollView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
        contentViewCenterY.priority = .defaultLow

        let contentViewHeight = containerScrollView.heightAnchor.constraint(greaterThanOrEqualTo: containerView.heightAnchor)
        contentViewHeight.priority = .defaultLow

        NSLayoutConstraint.activate([
            containerScrollView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            contentViewCenterY,
            contentViewHeight
        ])
    }
    func constraintContentView() {
        let contentViewHeight = contentView.heightAnchor.constraint(equalToConstant: 0)
        contentViewHeight.priority = .defaultLow

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: containerScrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: containerScrollView.leadingAnchor,
                                                 constant: UI.contentPadding),
            contentView.trailingAnchor.constraint(equalTo: containerScrollView.trailingAnchor,
                                                  constant: -UI.contentPadding),
            contentView.bottomAnchor.constraint(equalTo: copyTranslationView.topAnchor,
                                                                        constant: -UI.contentPadding),
            contentViewHeight
        ])
    }

    func constraintCopyTransBtn() {
        NSLayoutConstraint.activate([
            copyTranslationView.bottomAnchor.constraint(equalTo: changeLanguageView.topAnchor,
                                                                        constant: -8),
            copyTranslationView.leadingAnchor.constraint(equalTo: containerScrollView.leadingAnchor,
                                                  constant: UI.contentPadding),
            copyTranslationView.trailingAnchor.constraint(equalTo: containerScrollView.trailingAnchor,
                                                   constant: -UI.contentPadding),
            copyTranslationView.heightAnchor.constraint(equalToConstant: UI.changeLanguageBtnHeight),

            copyTranslationText.leadingAnchor.constraint(equalTo: copyTranslationView.leadingAnchor, constant: UI.contentPadding),
            copyTranslationText.centerYAnchor.constraint(equalTo: copyTranslationView.centerYAnchor),
            copyTranslationLogo.trailingAnchor.constraint(equalTo: copyTranslationView.trailingAnchor, constant: -UI.contentPadding),
            copyTranslationLogo.centerYAnchor.constraint(equalTo: copyTranslationView.centerYAnchor)
        ])
    }

    func constraintChangeLangBtn() {
        NSLayoutConstraint.activate([
            changeLanguageView.bottomAnchor.constraint(equalTo: feedBackView.topAnchor,
                                                                        constant: -8),
            changeLanguageView.leadingAnchor.constraint(equalTo: containerScrollView.leadingAnchor,
                                                  constant: UI.contentPadding),
            changeLanguageView.trailingAnchor.constraint(equalTo: containerScrollView.trailingAnchor,
                                                   constant: -UI.contentPadding),
            changeLanguageView.heightAnchor.constraint(equalToConstant: UI.changeLanguageBtnHeight),

            changeLanguageText.leadingAnchor.constraint(equalTo: changeLanguageView.leadingAnchor, constant: UI.contentPadding),
            changeLanguageText.centerYAnchor.constraint(equalTo: changeLanguageView.centerYAnchor),
            changeLanuageLogo.trailingAnchor.constraint(equalTo: changeLanguageView.trailingAnchor, constant: -UI.contentPadding),
            changeLanuageLogo.centerYAnchor.constraint(equalTo: changeLanguageView.centerYAnchor)
        ])

    }

    func constraintFeedbackBtn() {
        let feedBackViewBottom = feedBackView.bottomAnchor.constraint(equalTo: containerScrollView.bottomAnchor,
                                                                      constant: -UI.contentPadding)
        feedBackViewBottom.priority = .defaultLow
        NSLayoutConstraint.activate([
            feedBackView.leadingAnchor.constraint(equalTo: containerScrollView.leadingAnchor,
                                                  constant: UI.contentPadding),
            feedBackView.trailingAnchor.constraint(equalTo: containerScrollView.trailingAnchor,
                                                   constant: -UI.contentPadding),
            feedBackViewBottom,
            feedBackView.heightAnchor.constraint(equalToConstant: UI.feedbackBtnHeight),
            feedBackText.leadingAnchor.constraint(equalTo: feedBackView.leadingAnchor, constant: UI.contentPadding),
            feedBackText.centerYAnchor.constraint(equalTo: feedBackView.centerYAnchor),
            feedBackLogo.trailingAnchor.constraint(equalTo: feedBackView.trailingAnchor, constant: -UI.contentPadding),
            feedBackLogo.centerYAnchor.constraint(equalTo: feedBackView.centerYAnchor)
        ])
    }

    func transitionContent() -> UIViewController {
        if selectTranslateData.translateDictCardMap.isEmpty || ReleaseConfig.isLark {
            return SelectMachineTranslateViewController(
                userResolver: userResolver,
                selectText: selectText,
                translateText: translateText,
                copyConfig: copyConfig
            )
        } else {
            guard let translateDictData = selectTranslateData.translateDictCardMap[selectText] else { return UIViewController() }
            let viewModel = SelectTranslateDictCardViewModel(
                translateDictData: translateDictData,
                trackParam: params,
                copyConfig: copyConfig
            )
            return SelectTranslateDictViewController(resolver: userResolver,
                                                     viewModel: viewModel,
                                                     targetLanguage: targetLanguage,
                                                     translateType: translateType,
                                                     translateLength: self.translateLength)
        }
    }
}
