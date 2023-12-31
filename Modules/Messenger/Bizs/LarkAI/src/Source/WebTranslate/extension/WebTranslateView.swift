//
//  WebTranslateView.swift
//  LarkAI
//
//  Created by liushuwei on 2020/11/24.
//

import UIKit
import Foundation
import RxSwift
import LarkGuideUI
import LarkActionSheet
import Homeric
import LKCommonsTracker
import UniverseDesignToast
import LarkModel
import LKCommonsLogging
import LarkSDKInterface
import LarkMessengerInterface
import EENavigator
import RustPB
import LarkStorage
import LarkContainer

//网页翻译功能的View部件
final class WebTranslateView {
    private static let logger = Logger.log(WebTranslateView.self, category: "Module.AI")

    @KVConfig(key: KVKeys.AI.webAutoTranslateGuide, store: KVStores.AI.global())
    private var hasShowedWebAutoTranslateGuideView: Bool
    // 弹窗选择语言
    private lazy var selectLanguageCenter: SelectTargetLanguageTranslateCenter? = { [weak self] in
        guard let self = self, let translateLanguageSetting = self.viewModel.translateLanguageSetting else { return nil }
        return SelectTargetLanguageTranslateCenter(
            userResolver: userResolver,
            selectTargetLanguageTranslateCenterdelegate: self,
            translateLanguageSetting: translateLanguageSetting
        )
    }()
    //对ViewModel的引用
    fileprivate var viewModel: WebTranslateViewModel
    fileprivate weak var parentViewController: UIViewController?
    private var isDoneAddTranslateBar = false
    private var isHiddenTranslateBar = false
    private var isShowingWebTranslateGuide = false
    // 网页翻译底部bar
    lazy var translateBar: WebTranslateControlBar = {
        let bar = WebTranslateControlBar(delegate: self)
        bar.layer.shadowRadius = 2
        bar.layer.shadowOpacity = 0.04
        bar.layer.shadowColor = UIColor.ud.staticBlack.cgColor
        bar.layer.shadowOffset = CGSize(width: 0, height: -2)
        return bar
    }()
    private var safeBottom: CGFloat {
        self.parentViewController?.view.window?.safeAreaInsets.bottom ?? 0
    }
    private var disposeBag = DisposeBag()

    let userResolver: UserResolver
    init(userResolver: UserResolver, viewModel: WebTranslateViewModel) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.parentViewController = viewModel.webviewApi
        self.setup()
    }

    //监听viewModel的控制事件
    private func setup() {
        observeTranslateBarVisibilityControl()
        observeWebTranslateInfo()
        observeOpenWebSetting()
        observeOpenChooseLanguage()
    }

    //监听翻译工具条的展示、隐藏控制
    private func observeTranslateBarVisibilityControl() {
        self.viewModel.translateBarStateChangeSubject
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isShow in
                guard let self = self else { return }
                guard self.viewModel.translateBarEnable else { return }
                if isShow {
                    self.displayTranslateBar()
                } else {
                    self.hideTranslateBar()
                }
            }).disposed(by: self.disposeBag)
    }

    //监听翻译状态的变更
    private func observeWebTranslateInfo() {
        self.viewModel.currentTranslateInfoSubject
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] translateInfo in
                guard let self = self else { return }
                self.translateBar.updateUIByWebTranslateConfig(translateInfo)
            }).disposed(by: self.disposeBag)
    }

    //监听打开设置弹窗命令
    private func observeOpenWebSetting() {
        self.viewModel.openWebTranslateSettingSubject
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] setting in
                self?.openWebSetting(setting.translateLanguageSetting, setting.notTranslateLanguages,
                                     setting.currentTranslateInfo)
            }).disposed(by: self.disposeBag)
    }

    //监听打开语言选择弹窗命令
    private func observeOpenChooseLanguage() {
        self.viewModel.showChooseLanguageSubject
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] info in
                self?.showChooseLanguageDialog(curTranslateInfo: info)
            }).disposed(by: self.disposeBag)
    }

    private func hideTranslateBar() {
        guard let parentVC = parentViewController else { return }
        guard isDoneAddTranslateBar,
              isHiddenTranslateBar == false,
              isShowingWebTranslateGuide == false else {
            return
        }
        isHiddenTranslateBar = true
        UIView.animate(withDuration: 0.5) {
            self.translateBar.snp.updateConstraints { (make) in
                make.top.equalTo(parentVC.view.snp.bottom)
            }
            self.translateBar.superview?.layoutIfNeeded()
        }
	}

    private func displayTranslateBar() {
        guard let parentVC = parentViewController else { return }
        if isDoneAddTranslateBar == false {
            parentVC.view.addSubview(translateBar)
            self.isDoneAddTranslateBar = true
            translateBar.snp.makeConstraints { (make) in
                make.top.equalTo(parentVC.view.snp.bottom).offset(-(48 + self.safeBottom))
                make.left.right.equalToSuperview()
                make.height.equalTo(48 + self.safeBottom)
            }
            translateBar.superview?.layoutIfNeeded()
            tryOpenWebTranslateGuide()
            return
        }
        guard isHiddenTranslateBar == true, isShowingWebTranslateGuide == false else { return }
        isHiddenTranslateBar = false
        UIView.animate(withDuration: 0.5) {
            self.translateBar.snp.updateConstraints { (make) in
                make.top.equalTo(parentVC.view.snp.bottom).offset(-(48 + self.safeBottom))
            }
            self.translateBar.superview?.layoutIfNeeded()
        }
    }

    private func tryOpenWebTranslateGuide() {
        let canAddAutoWebTranslateGuide = self.viewModel.translateLanguageSetting?.webXmlSwitch == false
        guard let parentVC = parentViewController else { return }
        // only when user first trigger manual translate here can display guide
        if canAddAutoWebTranslateGuide, hasShowedWebAutoTranslateGuideView == false, isShowingWebTranslateGuide == false {
            isShowingWebTranslateGuide = true
            let bottomConfig = BottomConfig(leftBtnInfo: ButtonInfo(title: BundleI18n.LarkAI.Lark_Chat_MissTurnOnAutoTranslation),
                                            rightBtnInfo: ButtonInfo(title: BundleI18n.LarkAI.Lark_Legacy_Open))
            let item = BubbleItemConfig(
                guideAnchor: TargetAnchor(targetSourceType: .targetView(self.translateBar.settingButton), offset: 4,
                                          arrowDirection: .down, targetRectType: .circle),
                textConfig: TextInfoConfig(detail: BundleI18n.LarkAI.Lark_Chat_OpenWebAutoTranslate),
                bottomConfig: bottomConfig)
            let singleBubbleConfig = SingleBubbleConfig(delegate: self, bubbleConfig: item, maskConfig: MaskConfig(shadowAlpha: 0.35))
            let bubbleType = BubbleType.single(singleBubbleConfig)
            GuideUITool.displayBubble(hostProvider: parentVC,
                                      bubbleType: bubbleType,
                                      dismissHandler: { [weak self] in
                                        self?.isShowingWebTranslateGuide = false
                                      })
            self.hasShowedWebAutoTranslateGuideView = true
        }
    }

    private func showChooseLanguageDialog(curTranslateInfo: WebTranslateProcessInfo) {
        guard let fromVC = parentViewController else {
            assertionFailure("parentVC is nil")
            return
        }
        let topmostFrom = WindowTopMostFrom(vc: fromVC)
        self.selectLanguageCenter?.showSelectDrawer(translateContext: .web(context: curTranslateInfo), from: topmostFrom)
    }

    //打开网页翻译设置
    private func openWebSetting(_ translateLanguageSetting: TranslateLanguageSetting,
                                _ notTranslateLanguages: [String],
                                _ currentTranslateInfo: WebTranslateProcessInfo) {
        guard let fromVC = parentViewController else {
            assertionFailure("parentVC is nil")
            return
        }
        let topmostFrom = WindowTopMostFrom(vc: fromVC)
        let actionSheet = ActionSheet(bottomOffset: -12)
        // add choice more target language item
        self.addChoiceMoreTargetLanguageItem(actionSheet: actionSheet,
                                             translateLanguageSetting: translateLanguageSetting,
                                             notTranslateLanguages: notTranslateLanguages,
                                             currentTranslateInfo: currentTranslateInfo)
        // add web auto transalte switch item
        self.addWebAutoTranslateItem(actionSheet: actionSheet,
                                     translateLanguageSetting: translateLanguageSetting,
                                     notTranslateLanguages: notTranslateLanguages,
                                     currentTranslateInfo: currentTranslateInfo)
        if translateLanguageSetting.webXmlSwitch {
            // add never translate this language itemTranslateSettingBody
            self.addNeverTranslateThisLanguageItem(actionSheet: actionSheet,
                                                   translateLanguageSetting: translateLanguageSetting,
                                                   notTranslateLanguages: notTranslateLanguages,
                                                   currentTranslateInfo: currentTranslateInfo)
            // add never translate this site item
            self.addNeverTranslateThisSiteItem(actionSheet: actionSheet,
                                               translateLanguageSetting: translateLanguageSetting,
                                               notTranslateLanguages: notTranslateLanguages,
                                               currentTranslateInfo: currentTranslateInfo)
        }
        // add showing more translate setting item
        actionSheet.addItemView(createItem(BundleI18n.LarkAI.Lark_Chat_MoreTranslateSetting), action: { [weak self] in
            self?.userResolver.navigator.push(body: TranslateSettingBody(), context: ["position": "web_setting"], from: topmostFrom)
        })
        self.parentViewController?.present(actionSheet, animated: true, completion: {})
    }

    // 创建网页翻译设置actionSheet的item
    private func createItem(_ text: String, font: UIFont = UIFont.systemFont(ofSize: 17), isSelected: Bool = false) -> WebTranslateActionSheetItem {
        let view = WebTranslateActionSheetItem(frame: .zero, text: text, font: font, isSelected: isSelected)
        return view
    }

    // add choice more target language item
    private func addChoiceMoreTargetLanguageItem(actionSheet: ActionSheet,
                                                 translateLanguageSetting: TranslateLanguageSetting,
                                                 notTranslateLanguages: [String],
                                                 currentTranslateInfo: WebTranslateProcessInfo) {
        actionSheet.addItemView(createItem(BundleI18n.LarkAI.Lark_Chat_ChooseTranslateLanguage), action: { [weak self] in
            guard let self = self else { return }
            self.showChooseLanguageDialog(curTranslateInfo: currentTranslateInfo)
        })
    }

    // set web auto transalte switch item
    private func addWebAutoTranslateItem(actionSheet: ActionSheet,
                                         translateLanguageSetting: TranslateLanguageSetting,
                                         notTranslateLanguages: [String],
                                         currentTranslateInfo: WebTranslateProcessInfo) {
        let isSelectedAutoTransalteSwitch = translateLanguageSetting.webXmlSwitch
        let autoTranslateItem = createItem(BundleI18n.LarkAI.Lark_Chat_WebAutoTranslate, isSelected: isSelectedAutoTransalteSwitch)
        let scope = translateLanguageSetting.translateScope
        let toastDesc = isSelectedAutoTransalteSwitch ?
            BundleI18n.LarkAI.Lark_Chat_SetUntranslateWebSuccess :
            BundleI18n.LarkAI.Lark_Chat_OpenWebAutoTranslateSuccess
        actionSheet.addItemView(autoTranslateItem, action: { [weak self] in
            guard let self = self else { return }
            let newScope = scope + (isSelectedAutoTransalteSwitch ? -RustPB.Im_V1_TranslateScopeMask.webXml.rawValue : RustPB.Im_V1_TranslateScopeMask.webXml.rawValue)
            //self.translateLanguageSetting?.translateScope = newScope
            self.viewModel.updateAutoTranslateScope(newScope: newScope, desc: toastDesc)
        })
    }

    // add never translate this language item
    private func addNeverTranslateThisLanguageItem(actionSheet: ActionSheet,
                                                   translateLanguageSetting: TranslateLanguageSetting,
                                                   notTranslateLanguages: [String],
                                                   currentTranslateInfo: WebTranslateProcessInfo) {
        let originName = currentTranslateInfo.originLangName
        let originCode = currentTranslateInfo.originLangCode
        let isNeverTranslateThisLanuage = translateLanguageSetting.webXmlSwitch && notTranslateLanguages.contains(originCode)
        let item = createItem(BundleI18n.LarkAI.Lark_Chat_ChooseUntranslateLanguage(originName), isSelected: isNeverTranslateThisLanuage)
        actionSheet.addItemView(item, isAddLine: false, action: { [weak self, weak item] in
            guard let self = self, let item = item else { return }
            let toSelect = !item.isSelected
            self.viewModel.neverTranslateThisLangTapped(originLangCode: originCode, toSelect: toSelect) { [weak self] isSelect in
                if isSelect {
                    self?.viewModel.sendManualTranslateEvent(["type": "revert"])
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {  [weak self] in
                        self?.onTapClose()
                    }
                }
            }
        })
    }

    // add never translate this site item
    private func addNeverTranslateThisSiteItem(actionSheet: ActionSheet,
                                               translateLanguageSetting: TranslateLanguageSetting,
                                               notTranslateLanguages: [String],
                                               currentTranslateInfo: WebTranslateProcessInfo) {
        let urlHost = self.viewModel.currentURL()
        let isSelectedUnTranslateThisSite = translateLanguageSetting.webTranslationConfig.blackDomains.contains(urlHost)
        let untransalteWebItem = createItem(BundleI18n.LarkAI.Lark_Chat_SetUntranslateWeb, isSelected: isSelectedUnTranslateThisSite)
        actionSheet.addItemView(untransalteWebItem, isAddLine: false, action: { [weak self, weak untransalteWebItem] in
            guard let self = self, let item = untransalteWebItem else { return }
            let toSelect = !item.isSelected
            self.viewModel.neverTranslateThisSiteTapped(urlHost: urlHost, toSelect: toSelect) { [weak self] isSelect in
                if isSelect {
                    self?.viewModel.sendManualTranslateEvent(["type": "revert"])
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {  [weak self] in
                        self?.onTapClose()
                    }
                }
            }
        })
    }
}

// 网页翻译工具条的交互事件代理
extension WebTranslateView: TranslateBarDelegate {
    func onTapOpenSetting() {
        self.viewModel.webSettingTapped()
    }

    func onTapManualTranslate(_ translateInfo: WebTranslateProcessInfo) {
        let info: [String: Any] = ["type": "updateTargetLang",
                                   "originLang": ["name": translateInfo.originLangName,
                                                  "code": translateInfo.originLangCode
                                   ],
                                   "targetLang": ["name": translateInfo.targetLangName,
                                                  "code": translateInfo.targetLangCode
                                   ]]
        self.viewModel.sendManualTranslateEvent(info)
    }

    func onTapShowOrigin() {
        self.viewModel.sendManualTranslateEvent(["type": "revert"])
    }

    func onTapClose() {
        self.hideTranslateBar()
        self.viewModel.setEnableDisplayTranslateBar(false)
    }
}

// 网页翻译引导的交互事件代理
extension WebTranslateView: GuideSingleBubbleDelegate {
    public func didClickLeftButton(bubbleView: GuideBubbleView) {
        if let parentVC = self.parentViewController {
            GuideUITool.closeGuideIfNeeded(hostProvider: parentVC)
        }
        self.isShowingWebTranslateGuide = false
        Tracker.post(TeaEvent(Homeric.CLOSE_WEB_AUTO_TRANSLATE_GUIDE))
    }

    public func didClickRightButton(bubbleView: GuideBubbleView) {
        if let parentVC = self.parentViewController {
            GuideUITool.closeGuideIfNeeded(hostProvider: parentVC)
        }
        self.isShowingWebTranslateGuide = false
        Tracker.post(TeaEvent(Homeric.WEB_AUTO_TRANSLATE_SETTING, params: ["action": "open",
                                                                           "position": "guide"
        ]))
        self.viewModel.openAutoTranslateTapped()
    }
}
extension WebTranslateView: SelectTargetLanguageTranslateCenterDelegate {

    func finishSelect(translateContext: TranslateContext, targetLanguage: String) {
        if case let .web(curTranslateInfo) = translateContext, let language = self.viewModel.translateLanguageSetting?.supportedLanguages[targetLanguage] {
            let eventInfo: [String: Any] = ["type": "updateTargetLang",
                                            "originLang": [
                                                "name": curTranslateInfo.originLangName,
                                                "code": curTranslateInfo.originLangCode],
                                            "targetLang": [
                                                "name": language,
                                                "code": targetLanguage]]
            Tracker.post(TeaEvent(Homeric.SET_WEB_TRANSLATE_LANGUGE))
            self.viewModel.sendManualTranslateEvent(eventInfo)
        }
    }
}
