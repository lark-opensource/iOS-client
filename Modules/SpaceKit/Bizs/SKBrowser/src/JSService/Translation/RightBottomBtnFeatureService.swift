//
//  RightBottomBtnFeatureService.swift
//  SpaceKit
//
//  Created by LiXiaolin on 2019/6/11.
//  
import EENavigator
import SKCommon
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignColor
import UIKit
import LarkContainer

class RightBottomBtnFeatureService: BaseJSService {
    struct TranslateBtnInfo {
        var id: String = ""
        var title: String?  /// 文字按钮，大概率不会用到
        var disabled: Bool?
        var imageID: String
        var badgeStyle: String
        var badgeNum: Int
        var callback: (() -> Void)?
    }
    var alertButtonArr = [String]()
    var alertButtonType = [String]()
    var callbacks: String = ""
}

extension RightBottomBtnFeatureService: DocsJSServiceHandler {
    static let switchOrignal = "SWITCH_LANG_ORIGINAL"
    static let switchToTranslate = "SWITCH_LANG_TRANSLATE"
    var handleServices: [DocsJSService] {
        return [.translateBottomBtnVisible,
        .translateChooseLanguage,
        .setLangMenus]
    }
    var hostViewController: UIViewController {
        guard let host = self.navigator?.currentBrowserVC else {
            spaceAssertionFailure("cannot get hostViewController")
            return UIViewController()
        }
        return host
    }

    // swiftlint:disable cyclomatic_complexity
    func handle(params: [String: Any], serviceName: String) {
        let service = DocsJSService(serviceName)
        switch service {
        case .translateBottomBtnVisible :
            guard let visible = params["visible"] as? Bool else {
                DocsLogger.info("translateBottomBtnVisible失败了")
                return
            }
            if visible {
                ui?.displayConfig.showTranslateBtn()
            } else { ui?.displayConfig.hideTranslateBtn() }
        case .translateChooseLanguage :
            guard let languages = params["languages"] as? [String] else { return }
            guard let displayLanguages = params["display_languages"] as? [String] else { return }
            guard let callback = params["callback"] as? String else { return }
            callbacks = callback
            let displayIndex = params["display_language_index"] as? Int
            let isInCenter = params["isInCenter"] as? Bool
            self.makeLanguageChangeVC(languages: languages, displayLanguages: displayLanguages, displayIndex: displayIndex, isInCenter: isInCenter)
        case .setLangMenus :
            guard let infos = params["items"] as? [[String: Any]] else { return }
            guard let callback = params["callback"] as? String else { return }
            guard let alertButtonTypeArr = params["languages"] as? [String] else { return }
            guard let alertButtonTextArr = params["display_languages"] as? [String] else { return }
            guard let displayLanguageIndex = params["display_language_index"] as? Int else { return }

            alertButtonArr = alertButtonTextArr
            alertButtonType = alertButtonTypeArr
            callbacks = callback
            var menuInfos: [TranslateBtnInfo] = []
            infos.forEach { (info) in
                guard let id = info["id"] as? String else { return }
                let title = info["title"] as? String
                let disabled = info["disabled"] as? Bool
                let imageID = "\(id.lowercased())"
                var badgeStyle = info["badgeStyle"] as? String ?? "none"
                let badgeNum = info["badgeNum"] as? Int ?? 0
                if badgeNum == 0 {
                    badgeStyle = "none"
                }
                //let script = callback + "({id:'\(id)'})"
                let params = ["id": id]
                let info = TranslateBtnInfo(
                    id: id,
                    title: title,
                    disabled: disabled,
                    imageID: imageID,
                    badgeStyle: badgeStyle,
                    badgeNum: badgeNum,
                    callback: { [weak self] in
                        self?.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: params, completion: nil)
                    }
                )
                let isTranslateItem = info.id == RightBottomBtnFeatureService.switchOrignal
                    || info.id == RightBottomBtnFeatureService.switchToTranslate
                if isTranslateItem {
                    menuInfos.append(info)
                }
            }

            if menuInfos.count > 0 {
                ui?.displayConfig.rightBottomButtonItems = self.makeBottomButtons(
                    target: self,
                    infos: menuInfos,
                    btnTitles: alertButtonArr,
                    btnTypes: alertButtonType,
                    selectLanguageIndex: displayLanguageIndex
                )
            }
        default:
            DocsLogger.info("RightBottomBtnFeatureService enter default")
        }
    }
}

extension RightBottomBtnFeatureService {
    private func makeBottomButtons(target: AnyObject,
                                   infos: [TranslateBtnInfo],
                                   btnTitles: [String],
                                   btnTypes: [String],
                                   selectLanguageIndex: Int) -> [UIButton] {
        // 当存在自动翻译时，需要更新最近翻译记录
        if selectLanguageIndex >= 0,
            selectLanguageIndex < btnTitles.count,
            selectLanguageIndex < btnTypes.count,
            infos.first?.id != RightBottomBtnFeatureService.switchToTranslate {
            storeSelectLanguage(language: btnTypes[selectLanguageIndex], displayLanguage: btnTitles[selectLanguageIndex])
        }
        var items = [UIButton]()
        let bottomView: BottomTranslateButton
        let recentSelectLanguage = self.obtainRecentSelectLanguage()
        let browserVC = navigator?.currentBrowserVC as? BrowserViewController
        let defaultUR = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        bottomView = BottomTranslateButton(languages: btnTypes,
                                           displayLanguages: btnTitles,
                                           displayIndex: selectLanguageIndex,
                                           recentSelectLanguages: recentSelectLanguage,
                                           hostViewController: hostViewController,
                                           userResolver: model?.userResolver ?? defaultUR,
                                           isVersion: browserVC?.editor.docsInfo?.isVersion)
        bottomView.delegate = self

        infos.forEach { (info) in
            bottomView.viewIdentifier = info.id
            items.append(bottomView)
        }
        return items
    }

    private func makeLanguageChangeVC(languages: [String], displayLanguages: [String], displayIndex: Int?, isInCenter: Bool?) {
        guard let docsInfo = model?.browserInfo.docsInfo else {
            DocsLogger.error("docsInfo in nil")
            return
        }
        let browserVC = navigator?.currentBrowserVC as? BrowserViewController
        let recentSelectLanguage = self.obtainRecentSelectLanguage()
        let languageCVC = SelectLanguageController(languages: languages,
                                                   displayLanguages: displayLanguages,
                                                   displayIndex: displayIndex,
                                                   recentSelectLanguages: recentSelectLanguage,
                                                   isFromVersion: browserVC?.editor.docsInfo?.isVersion)
        languageCVC.delegate = self
        if docsInfo.inherentType == .docX {
            languageCVC.supportOrentations = browserVC?.supportedInterfaceOrientations ?? .portrait
        }
        if SKDisplay.phone {
            languageCVC.modalPresentationStyle = .overFullScreen
            browserVC?.present(languageCVC, animated: true)
        } else {
            // 前端通过 isInCenter 参数告诉 native 翻译语言选择面板是居中还是靠右展示
            if UserScopeNoChangeFG.TYP.translateBottom, let isInCenter = isInCenter, isInCenter {
                browserVC?.translateShowPopover(panel: languageCVC)
            } else {
                browserVC?.showPopover(panel: languageCVC, at: -1)
            }
        }
    }
}

extension RightBottomBtnFeatureService: SelectLanuageControllerDelegate {
    func didSelectDiffLanguage(language: String, displayLanguage: String) {
        let params = ["language": language]
        self.storeSelectLanguage(language: language, displayLanguage: displayLanguage)
        self.model?.jsEngine.callFunction(DocsJSCallBack(self.callbacks), params: params, completion: nil)
    }
}

extension RightBottomBtnFeatureService: BottomTranslateButtonDelegate {
    func bottomDidSelectDiffLanguage(language: String, displayLanguage: String) {
        let params = ["id": RightBottomBtnFeatureService.switchToTranslate,
                      "target_lang": language
                        ]
        self.storeSelectLanguage(language: language, displayLanguage: displayLanguage)
        self.model?.jsEngine.callFunction(DocsJSCallBack(callbacks), params: params, completion: nil)
    }

    func clickSeeOrignal() {
        let params = ["id": RightBottomBtnFeatureService.switchOrignal]
        self.model?.jsEngine.callFunction(DocsJSCallBack(callbacks), params: params, completion: nil)
    }

    func autoDismissSelf() {
        ui?.displayConfig.hideTranslateBtn()
    }
}

extension RightBottomBtnFeatureService {
    private func sqlTranslationHistroryPath() -> SKFilePath {
        let rootPath = SKFilePath.userSandboxWithLibrary(User.current.info?.userID ?? "unknown").appendingRelativePath("translationHistrory")
        if !rootPath.exists {
            do {
                try rootPath.createDirectory(withIntermediateDirectories: true)
            } catch let error {
                DocsLogger.error("db create file error", extraInfo: nil, error: error, component: nil)
            }
        }
        return rootPath
    }

    private func storeSelectLanguage(language: String, displayLanguage: String) {
        //获取本地数据
        var recentSelectLanguage = obtainRecentSelectLanguage()

        //包装数据
        let params = ["language": language, "displayLanguage": displayLanguage]

        //处理数据
        if recentSelectLanguage.contains(params) {
            recentSelectLanguage.lf_remove(object: params)
        }
        recentSelectLanguage.insert(params, at: 0)
        if recentSelectLanguage.count > 3 {
            recentSelectLanguage.removeLast()
        }
        
        var data: Data?
        data = try? NSKeyedArchiver.archivedData(withRootObject: recentSelectLanguage, requiringSecureCoding: true)

        let filePath = sqlTranslationHistroryPath().appendingRelativePath("translationHistrory")
        do {
            try data?.write(to: filePath)
        } catch {
            DocsLogger.info("save TranslationHistrory to file fail, \(error)", component: LogComponents.newCache)
        }

    }

    private func obtainRecentSelectLanguage() -> [[String: String]] {
        let path = sqlTranslationHistroryPath().appendingRelativePath("translationHistrory")
        if path.exists, let translationHistrory = NSKeyedUnarchiver.unarchiveObject(withFile: path.pathString) as? [[String: String]] {
            return translationHistrory
        }
        return []
    }
}
