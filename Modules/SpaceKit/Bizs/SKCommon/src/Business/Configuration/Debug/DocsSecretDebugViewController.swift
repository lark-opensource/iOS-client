//
//  DocsSercetDebugViewController.swift
//  SpaceKit
//
//  Created by xurunkang on 2018/9/11.
//  swiftlint:disable cyclomatic_complexity type_body_length line_length file_length

import UIKit
import SSZipArchive
import TTVideoEngine
import SwiftyJSON
import SKFoundation
import SKUIKit
import UniverseDesignToast
import SKInfra
#if BETA || ALPHA || DEBUG
import ServerPB
import LarkAIInfra
import RxSwift
import RxCocoa
#endif

public final class DocsSercetDebugViewController: DocsDebugBaseViewController {
#if BETA || ALPHA || DEBUG
    private let showFeatureID = "featureID"
    private let renderCacheDelay = "renderCache 后的delay(ms)"
    private let showRNDebug = "RN Debug"
    private let setWatermarkPolicy = "全局水印展示策略"
    private let editorPoolMin = "不要保存用过多的webview（仅供测试）"
    private let isForTest  = "QA在用？"
    private let pullDriveVideoSDKLog = "拉取视频SDK日志"
    private let driveAutoTest = "Drive性能测试工具"
    private let startAutoOpenDocs = "自动化测试"
    private let autoOpenDocslist = "白名单"
    private let clearLocalDomainConfig = "删除本地的domainConfig"
    private let sendLog = "发送日志"
    private let testLocalFile = "Drive本地文件预览"
    private let testUnzipXzFile = "xz文件解压测试"
    private let configProxy = "configProxy"
    private let makePowerIssue = "制造一个功耗issue"
    private let markWebViewUnResponsive = "Make WebView UnResponsive"
    private var watermarkPolicyPickerView: UIPickerView!
    lazy private var watermarkPolicyPickViewDataSource: WatermarkPickDataSource = {
        let obj = WatermarkPickDataSource(from: self)
        obj.onSelectAction = { [weak self] in
            self?.refresh()
        }
        return obj
    }()
    private let logLevel = "日志等级"
    private var logLevelPicker: UIPickerView!
#endif
    
#if BETA || ALPHA || DEBUG
    var aiModule: LarkInlineAISDK?
    var aiAsrSDK: InlineAIAsrSDK?
    var aiAsrDisposeBag = DisposeBag()
#endif
    //swiftlint:disable function_body_length
    override public func configDebugDataSource() {
        debugDataSouce.removeAll()
        // 下面信息顺序是固定的，不能随意切换
        debugDataSouce.append((
            "用户信息",
            [
                DocsDebugCellItem(title: "离线资源包版本", type: .id, detail: DocsSDK.offlineResourceVersion() ?? ""),
                DocsDebugCellItem(title: "userID", type: .id, detail: User.current.info?.userID ?? ""),
                DocsDebugCellItem(title: "deviceID", type: .id, detail: CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.deviceID) ?? ""),
                DocsDebugCellItem(title: "SpaceKitVersion", type: .id, detail: SpaceKit.version),
                DocsDebugCellItem(title: "AppVersion", type: .id, detail: getAppVersion())

            ]
        ))

        let curResInfo = DocsSDK.getCurUsingPkgInfo()
        self.debugDataSouce.append((
            "精简和完整资源包",
            [
                DocsDebugCellItem(title: "使用指定离线资源包(重启后生效)",
                                  type: .switchButton(isOn: DocsDebugConstant.isCustomOfflineResourceEnable,
                                                      tag: DocsDebugConstant.SwitchButtonTag.enableCustomOfflineResourceEnable.rawValue)),
                DocsDebugCellItem(title: "当前是否在用精简包", type: .id, detail: "\(curResInfo.isSlim)"),
                DocsDebugCellItem(title: "当前使用的资源包版本", type: .id, detail: "\(curResInfo.version)"),
                DocsDebugCellItem(title: "当前使用包名称", type: .id, detail: "\(curResInfo.name)"),
                DocsDebugCellItem(title: "内嵌精简包版本", type: .id, detail: "\(curResInfo.simplePkgVersion)"),
                DocsDebugCellItem(title: "内嵌精简包对应的完整包版本", type: .id, detail: "\(curResInfo.fullPkgVersion)"),
                DocsDebugCellItem(title: "当前手动指定的资源包版本", type: .id, detail: "\(curResInfo.specialVersion)"),
                DocsDebugCellItem(title: DebugCellTitle.specialPkgInfo.rawValue, type: .id),
                DocsDebugCellItem(title: DebugCellTitle.grayscalePkgInfo.rawValue, type: .id),
                DocsDebugCellItem(title: DebugCellTitle.geckoPkgInfo.rawValue, type: .id),
                DocsDebugCellItem(title: "完整包是否ready", type: .id, detail: "\(curResInfo.fullPkgIsReady)"),
                DocsDebugCellItem(title: "灰度包是否ready", type: .id, detail: "\(curResInfo.isGrayscaleExist)"),
                DocsDebugCellItem(title: "灰度包版本", type: .id, detail: "\(curResInfo.grayscaleVersion)"),
                DocsDebugCellItem(title: DebugCellTitle.removeLocalFullPkgResource.rawValue, type: .id),
                DocsDebugCellItem(title: DebugCellTitle.removeLocalGrayscalePkgResource.rawValue, type: .id),
                DocsDebugCellItem(title: DebugCellTitle.forceUseSimplePkg.rawValue, type: .switchButton(isOn: DocsDebugConstant.isUseSimplePackage, tag: DocsDebugConstant.SwitchButtonTag.useSimpleFEPackage.rawValue))
            ]
        ))

    
#if BETA || ALPHA || DEBUG
        let appEnvItems = [
            DocsDebugCellItem(title: sendLog, type: .id, detail: nil),
            DocsDebugCellItem(title: "使用本地离线资源包",
                              type: .switchButton(isOn: DocsDebugConstant.isProtocolEnable,
                                                  tag: DocsDebugConstant.SwitchButtonTag.protocolEnable.rawValue)),
            DocsDebugCellItem(title: "代理到前端",
                              type: .switchButton(isOn: DocsDebugConstant.isAgentToFrontend,
                                                  tag: DocsDebugConstant.SwitchButtonTag.isSetAgentToFrontend.rawValue)),
            DocsDebugCellItem(title: "代理模式复用模版",
                              type: .switchButton(isOn: DocsDebugConstant.isAgentRepeatModule,
                                                  tag: DocsDebugConstant.SwitchButtonTag.isAgentRepeatModule.rawValue)),
            DocsDebugCellItem(title: "Gecko 资源拉取",
                              type: .switchButton(isOn: DocsDebugConstant.isGeckoApplyDisable,
                                                  tag: DocsDebugConstant.SwitchButtonTag.geckoEnable.rawValue)),
            DocsDebugCellItem(title: "统计数据上报加密",
                              type: .switchButton(isOn: DocsDebugConstant.isEnableStatisticsEncryption,
                                                  tag: DocsDebugConstant.SwitchButtonTag.enableStatisticsEnctyption.rawValue)),
            DocsDebugCellItem(title: "是否展示打开文档时信息", type: .switchButton(isOn: DocsDebugConstant.shouldShowFileOpenBasicInfo,
                                                                                              tag: DocsDebugConstant.SwitchButtonTag.showFileOpenBasicInfo.rawValue),
                              detail: "预加载次数等"),
//                DocsDebugCellItem(title: showServerConfigStr, type: .id),
            DocsDebugCellItem(title: setWatermarkPolicy, type: .id, detail: WatermarkPolicy.current.rawValue),
            DocsDebugCellItem(title: showFeatureID, type: .id, detail: OpenAPI.docs.featureID),
            DocsDebugCellItem(title: renderCacheDelay, type: .id, detail: OpenAPI.renderCachedHtmlDelayInMilliscond.description),
            DocsDebugCellItem(title: isForTest, type: .switchButton(isOn: OpenAPI.isForQATest, tag: DocsDebugConstant.SwitchButtonTag.isForQA.rawValue), detail: nil),
            DocsDebugCellItem(title: "使用远端RN包", type: .switchButton(isOn: DocsDebugConstant.useRemoteRNResource, tag: DocsDebugConstant.SwitchButtonTag.useRemoteRNResource.rawValue)),
            DocsDebugCellItem(title: "代理到RN(先启用远端)", type: .switchButton(isOn: DocsDebugConstant.remoteRNAddress, tag: DocsDebugConstant.SwitchButtonTag.remoteRNAddress.rawValue)),
            DocsDebugCellItem(title: showRNDebug, type: .id, detail: nil),
            DocsDebugCellItem(title: "评论卡片强制使用DebugSetting值", type: .switchButton(isOn: DocsDebugConstant.commentCardUserDebug, tag: DocsDebugConstant.SwitchButtonTag.commentCardUseDebugSetting.rawValue)),
            DocsDebugCellItem(title: "iPad评论卡片使用旧版", type: .switchButton(isOn: CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.ipadCommentUseOldDebug), tag: DocsDebugConstant.SwitchButtonTag.ipadCommentUserOld.rawValue)),
            DocsDebugCellItem(title: "评论卡片新版本（先打开强制使用）", type: .switchButton(isOn: DocsDebugConstant.commentCardDebugValue, tag: DocsDebugConstant.SwitchButtonTag.commentCardUserNew.rawValue)),
            DocsDebugCellItem(title: "图片上传走docRequest", type: .switchButton(isOn: CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.debugUploadImgByDocRequest), tag: DocsDebugConstant.SwitchButtonTag.uploadImgByDocRequest.rawValue)),
            DocsDebugCellItem(title: configProxy, type: .id, detail: nil),
            DocsDebugCellItem(title: makePowerIssue, type: .id, detail: nil),
            DocsDebugCellItem(title: "请求notRust", type: .switchButton(isOn: CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.disableRustRequest), tag: DocsDebugConstant.SwitchButtonTag.disableRustRequest.rawValue)),
            // 前端ETTest开关
            DocsDebugCellItem(title: "FrontEnd ETTest On", type: .switchButton(isOn: CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.enableEtTest), tag: DocsDebugConstant.SwitchButtonTag.enableEtTest.rawValue)),
            // 强制允许截屏录屏
            DocsDebugCellItem(title: "Force Allow Capture", type: .switchButton(isOn: DocsDebugConstant.screenCaptureForceAllowed, tag: DocsDebugConstant.SwitchButtonTag.allowScreenCaptureInDebug.rawValue)),
            DocsDebugCellItem(title: "查看评论日志", type: .switchButton(isOn: DocsDebugConstant.commentDebugValue, tag: DocsDebugConstant.SwitchButtonTag.commentDebugEnable.rawValue)),
            DocsDebugCellItem(title: "代理本地文件", type: .switchButton(isOn: DocsDebugConstant.localFileValue, tag: DocsDebugConstant.SwitchButtonTag.localFile.rawValue))
        ]
        self.debugDataSouce.append((
            "应用环境",
            appEnvItems
        ))

        debugDataSouce.append((
            "WebView调试",
            [
                DocsDebugCellItem(title: "禁用webview复用",
                                  type: .switchButton(isOn: OpenAPI.docs.disableEditorResue,
                                                      tag: DocsDebugConstant.SwitchButtonTag.disableEditorReuse.rawValue)),
                DocsDebugCellItem(title: "每次打开文档使用相同webview", type: .switchButton(isOn: OpenAPI.useSingleWebview, tag: DocsDebugConstant.SwitchButtonTag.useSingleWebview.rawValue), detail: ""),
                DocsDebugCellItem(title: markWebViewUnResponsive, type: .id, detail: nil),
                DocsDebugCellItem(title: "开启vConsole", type: .switchButton(isOn: DocsDebugConstant.isVconsoleEnable, tag: DocsDebugConstant.SwitchButtonTag.vconsoleEnable.rawValue), detail: ""),
                DocsDebugCellItem(title: "使用指定注入js url", type: .switchButton(isOn: DocsDebugConstant.isUseThirdPartyJavascriptEnable,
                                                                                         tag: DocsDebugConstant.SwitchButtonTag.enableCustomThirdPartyJavascriptEnable.rawValue)),
                DocsDebugCellItem(title: "不过滤文档BOM字符", type: .switchButton(isOn: OpenAPI.docs.disableFilterBOMChar,
                                                                                         tag: DocsDebugConstant.SwitchButtonTag.disableFilterBOMChar.rawValue)),
                DocsDebugCellItem(title: "开启ClientVar和SSR命中缓存提示", type: .switchButton(isOn: OpenAPI.docs.enableSSRCahceToastForTest,
                                                                                      tag: DocsDebugConstant.SwitchButtonTag.enableSSRCahceToast.rawValue)),
                DocsDebugCellItem(title: "SSRWebView保持常驻", type: .switchButton(isOn: OpenAPI.docs.enableKeepSSRWebViewTest,
                                                                                      tag: DocsDebugConstant.SwitchButtonTag.keepSSRWebViewAlive.rawValue)),
                
                DocsDebugCellItem(title: "killWebContentProcess", type: .id, detail: nil),
                DocsDebugCellItem(title: DebugCellTitle.killAllWebViewProcess.rawValue, type: .id, detail: nil),
                DocsDebugCellItem(title: DebugCellTitle.clearWKWebViewCache.rawValue, type: .id, detail: nil),
            ]
        ))
        
        let item: (String, [DocsDebugCellItem]) = (
            "Drive调试",
            [
                DocsDebugCellItem(title: pullDriveVideoSDKLog, type: .id),
                DocsDebugCellItem(title: "开启视频SDK日志", type: .switchButton(isOn: DocsDebugConstant.driveVideoSDKLogEnabled, tag: DocsDebugConstant.SwitchButtonTag.driveVideoSDKLogEnable.rawValue)),
                DocsDebugCellItem(title: "开启视频原地址播放", type: .switchButton(isOn: DocsDebugConstant.driveVideoPlayOriginEnable, tag: DocsDebugConstant.SwitchButtonTag.driveVideoPlayOriginEnable.rawValue)),
                DocsDebugCellItem(title: DebugCellTitle.cleanDriveCache.rawValue, type: .id),
                DocsDebugCellItem(title: driveAutoTest, type: .switchButton(isOn: false, tag: DocsDebugConstant.SwitchButtonTag.driveTest.rawValue)),
                DocsDebugCellItem(title: testLocalFile, type: .id),
                DocsDebugCellItem(title: testUnzipXzFile, type: .id)
            ]
        )
        
        debugDataSouce.append(item)

        debugDataSouce.append((
            "引导调试",
            [
                DocsDebugCellItem(title: "清空引导缓存，不将完成情况同步到远端",
                                  type: .switchButton(isOn: DocsDebugConstant.verifiesAllOnboardings,
                                                      tag: DocsDebugConstant.SwitchButtonTag.verifiesAllOnboardings.rawValue))
            ]
        ))

        debugDataSouce.append((
            "Wiki 调试",
            [
                DocsDebugCellItem(title: DebugCellTitle.cleanWikiDb.rawValue, type: .id)
            ]
        ))

        debugDataSouce.append((
            "AUTO TEST",
            [
                DocsDebugCellItem(title: startAutoOpenDocs, type: .id, detail: "关闭"),
                DocsDebugCellItem(title: autoOpenDocslist, type: .id, detail: "[docs, sheet, bitable]")
            ]
        ))

        var hasDomainConfig = false
        if let domainConfig = DomainConfig.globalConfig, !domainConfig.isEmpty {
            hasDomainConfig = true
        }
        debugDataSouce.append((
            "私有化调试",
            [
                DocsDebugCellItem(title: clearLocalDomainConfig, type: .id, detail: hasDomainConfig ? "本地有": "本地无")
            ]
        ))

        debugDataSouce.append((
            "native编辑器调试",
            [
                DocsDebugCellItem(title: "强制使用Debug设置", type: .switchButton(isOn: CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.nativeEditorUseDebugSetting), tag: DocsDebugConstant.SwitchButtonTag.nativeEditorUseDebugSetting.rawValue)),
                DocsDebugCellItem(title: "Docx使用nativeEditor", type: .switchButton(isOn: CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.docxUseNativeEditorInDebug), tag: DocsDebugConstant.SwitchButtonTag.docxUseNativeEditorInDebug.rawValue)),
                DocsDebugCellItem(title: DebugCellTitle.nativeEditorSheetJSServer.rawValue, type: .id),
                DocsDebugCellItem(title: DebugCellTitle.nativeEditorPreloadJSServer.rawValue, type: .id)
            ]
        ))

        debugDataSouce.append((
            "lynx调试",
            [
                DocsDebugCellItem(title: DebugCellTitle.lynxJSURL.rawValue, type: .id),
                DocsDebugCellItem(title: DebugCellTitle.lynxDevtoolOpen.rawValue, type: .id),
                DocsDebugCellItem(title: DebugCellTitle.lynxPkgCustom.rawValue, type: .switchButton(isOn: LynxCustomPkgManager.shared.shouldUseCustomPkg, tag: DocsDebugConstant.SwitchButtonTag.enableCustomLynxPkg.rawValue)),
                DocsDebugCellItem(title: DebugCellTitle.showLynxPkgInfo.rawValue, type: .id)
            ]
        ))
        
        debugDataSouce.append((
            "企业密钥调试",
            [
                DocsDebugCellItem(title: DebugCellTitle.cipherDelete.rawValue, type: .id)
            ]
        ))
#endif
        #if BETA || ALPHA || DEBUG
        debugDataSouce.append((
            "A浮窗调试🤖️",
            [
                DocsDebugCellItem(title: DebugCellTitle.openInlineAI.rawValue, type: .id),
                DocsDebugCellItem(title: DebugCellTitle.inlineAIResSetting.rawValue, type: .id)
            ]
        ))
        #endif

        debugDataSouce.append((
            "轻轻的我走了, 正如我轻轻的来",
            [
                DocsDebugCellItem(title: "返回", type: .back)
            ]
        ))
    }

    @objc
    override public func didClickSwitchButton(sender: UISwitch) {
        switch sender.tag {
        case DocsDebugConstant.SwitchButtonTag.enableCustomOfflineResourceEnable.rawValue:
            showCustomOfflineResourceAlert(sender)
        case DocsDebugConstant.SwitchButtonTag.useSimpleFEPackage.rawValue:
                    SpecialVersionResourceService.updateIsUseSimplePackage(on: sender.isOn, onView: view)
#if BETA || ALPHA || DEBUG
        case DocsDebugConstant.SwitchButtonTag.protocolEnable.rawValue :
            OpenAPI.offlineConfig.protocolEnable = sender.isOn
        case DocsDebugConstant.SwitchButtonTag.disableEditorReuse.rawValue:
            OpenAPI.docs.disableEditorResue = sender.isOn
        case DocsDebugConstant.SwitchButtonTag.geckoEnable.rawValue :
            OpenAPI.offlineConfig.geckoFetchEnable = sender.isOn
        case DocsDebugConstant.SwitchButtonTag.isSetAgentToFrontend.rawValue:
            OpenAPI.docs.isSetAgentToFrontend = sender.isOn
            if sender.isOn {
                showAgentToFrontendAlert()
            }
            if OpenAPI.docs.isSetAgentToFrontend {
                DocsTracker.shared.forbiddenTrackerReason.insert(.useProxyToAgent)
            } else {
                DocsTracker.shared.forbiddenTrackerReason.remove(.useProxyToAgent)
            }
        case DocsDebugConstant.SwitchButtonTag.isAgentRepeatModule.rawValue:
            OpenAPI.docs.isAgentRepeatModule = sender.isOn
        case DocsDebugConstant.SwitchButtonTag.enableCustomThirdPartyJavascriptEnable.rawValue:
                   showCustomJavascriptResourceAlert(sender)
        case DocsDebugConstant.SwitchButtonTag.showFileOpenBasicInfo.rawValue:
            OpenAPI.docs.shouldShowFileOpenBasicInfo = sender.isOn
        case DocsDebugConstant.SwitchButtonTag.useSingleWebview.rawValue:
            OpenAPI.useSingleWebview = sender.isOn
        case DocsDebugConstant.SwitchButtonTag.vconsoleEnable.rawValue:
            changeVConsole(isOn: sender.isOn)
        case DocsDebugConstant.SwitchButtonTag.isForQA.rawValue:
            OpenAPI.isForQATest = sender.isOn
        case DocsDebugConstant.SwitchButtonTag.driveVideoSDKLogEnable.rawValue:
            OpenAPI.docs.driveVideoLogEnable = sender.isOn
        case DocsDebugConstant.SwitchButtonTag.driveVideoPlayOriginEnable.rawValue:
            OpenAPI.docs.driveVideoPlayOriginEnable = sender.isOn
        case DocsDebugConstant.SwitchButtonTag.driveTest.rawValue:
            autoTestOpenDrive(isOn: sender.isOn)
        case DocsDebugConstant.SwitchButtonTag.verifiesAllOnboardings.rawValue:
            OpenAPI.docs.verifiesAllOnboardings = sender.isOn
        case DocsDebugConstant.SwitchButtonTag.driveTest.rawValue:
            autoTestOpenDrive(isOn: sender.isOn)
        case DocsDebugConstant.SwitchButtonTag.useRemoteRNResource.rawValue:
            OpenAPI.docs.remoteRN = sender.isOn
            OpenAPI.docs.rnDebugShakeFollowSetting()
            if sender.isOn == false {
                CCMKeyValue.globalUserDefault.set(nil, forKey: "RCTDevMenu")
            }
        case DocsDebugConstant.SwitchButtonTag.remoteRNAddress.rawValue:
            if sender.isOn {
                showRemoteRNAddressAlert()
            } else {
                OpenAPI.docs.RNHost = ""
                OpenAPI.docs.remoteRNAddress = false
            }
        case DocsDebugConstant.SwitchButtonTag.commentCardUseDebugSetting.rawValue:
            DocsLogger.info("commentCardUseDebugSetting=\(sender.isOn)")
            CCMKeyValue.globalUserDefault.set(sender.isOn, forKey: UserDefaultKeys.commentCardUseDebugSetting)
            UDToast.showFailure(with: "需要重启app才能生效", on: self.view.window ?? self.view)
        case DocsDebugConstant.SwitchButtonTag.commentCardUserNew.rawValue:
            UDToast.showFailure(with: "需要重启app才能生效", on: self.view.window ?? self.view)
            CCMKeyValue.globalUserDefault.set(sender.isOn, forKey: UserDefaultKeys.commentCardUIDebugValue)
        case DocsDebugConstant.SwitchButtonTag.ipadCommentUserOld.rawValue:
            UDToast.showFailure(with: "重启下app", on: self.view.window ?? self.view)
            CCMKeyValue.globalUserDefault.set(sender.isOn, forKey: UserDefaultKeys.ipadCommentUseOldDebug)
        case DocsDebugConstant.SwitchButtonTag.uploadImgByDocRequest.rawValue:
            CCMKeyValue.globalUserDefault.set(sender.isOn, forKey: UserDefaultKeys.debugUploadImgByDocRequest)
            UDToast.showFailure(with: "需要重启app才能生效", on: self.view.window ?? self.view)
        case DocsDebugConstant.SwitchButtonTag.disableRustRequest.rawValue:
            CCMKeyValue.globalUserDefault.set(sender.isOn, forKey: UserDefaultKeys.disableRustRequest)
        case DocsDebugConstant.SwitchButtonTag.enableEtTest.rawValue:
            CCMKeyValue.globalUserDefault.set(sender.isOn, forKey: UserDefaultKeys.enableEtTest)
        case DocsDebugConstant.SwitchButtonTag.allowScreenCaptureInDebug.rawValue:
            DocsDebugConstant.screenCaptureForceAllowed = sender.isOn
            NotificationCenter.`default`.post(name: ViewCapturePreventer.debugAllowStateDidChange,
                                              object: nil, userInfo: ["isAllow": sender.isOn])
        case DocsDebugConstant.SwitchButtonTag.disableFilterBOMChar.rawValue:
            OpenAPI.docs.disableFilterBOMChar = sender.isOn
        case DocsDebugConstant.SwitchButtonTag.nativeEditorUseDebugSetting.rawValue:
            CCMKeyValue.globalUserDefault.set(sender.isOn, forKey: UserDefaultKeys.nativeEditorUseDebugSetting)
        case DocsDebugConstant.SwitchButtonTag.docxUseNativeEditorInDebug.rawValue:
            CCMKeyValue.globalUserDefault.set(sender.isOn, forKey: UserDefaultKeys.docxUseNativeEditorInDebug)
        case DocsDebugConstant.SwitchButtonTag.enableCustomLynxPkg.rawValue:
            showCustomLynxPkgAlert(sender)
        case DocsDebugConstant.SwitchButtonTag.commentDebugEnable.rawValue:
            CCMKeyValue.globalUserDefault.set(sender.isOn, forKey: UserDefaultKeys.commentDebugValue)
            
        case DocsDebugConstant.SwitchButtonTag.localFile.rawValue:
            CCMKeyValue.globalUserDefault.set(sender.isOn, forKey: UserDefaultKeys.localFileValue)
            if sender.isOn {
                showRemoteFileAddressAlert()
            }
        case DocsDebugConstant.SwitchButtonTag.enableSSRCahceToast.rawValue:
            OpenAPI.docs.enableSSRCahceToastForTest = sender.isOn
        case DocsDebugConstant.SwitchButtonTag.keepSSRWebViewAlive.rawValue:
            OpenAPI.docs.enableKeepSSRWebViewTest = sender.isOn
#endif
        default:
            break
        }
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        if indexPath.section == 0 { // 用户信息
            didSelectUserInfo(indexPath: indexPath)
        } else if indexPath.section == 1 { // 应用环境

        } else if indexPath.section == debugDataSouce.count - 1 { // 退出按钮
            didSelectBack()
        }
        let cellItem = cellItemFor(indexPath)
        if cellItem.title == DebugCellTitle.removeLocalFullPkgResource.rawValue {
            removeFullPkgFiles()
        } else if cellItem.title == DebugCellTitle.removeLocalGrayscalePkgResource.rawValue {
            removeGrayscalePkgFiles()
        } else if cellItem.title == DebugCellTitle.specialPkgInfo.rawValue {
            showSpecialPkgInfo()
        } else if cellItem.title == DebugCellTitle.grayscalePkgInfo.rawValue {
            showGrayscalePkgInfo()
        } else if cellItem.title == DebugCellTitle.geckoPkgInfo.rawValue {
            showGeckoPkgInfo()
        }
#if BETA || ALPHA || DEBUG
        if cellItem.title == showFeatureID {
            let alervc = UIAlertController(title: showFeatureID, message: nil, preferredStyle: .alert)
            var textField: UITextField?
            alervc.addTextField { (tfd) in
                tfd.placeholder = OpenAPI.docs.featureID
                tfd.text = OpenAPI.docs.featureID
                textField = tfd
            }
            alervc.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                OpenAPI.docs.featureID = textField?.text
                self.refresh()
            }))
            self.present(alervc, animated: true, completion: nil)
        } else if cellItem.title == renderCacheDelay {
            let alervc = UIAlertController(title: renderCacheDelay, message: nil, preferredStyle: .alert)
            var textField: UITextField?
            alervc.addTextField { (tfd) in
                tfd.placeholder = OpenAPI.docs.featureID
                tfd.keyboardType = .numberPad
                textField = tfd
            }
            alervc.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                OpenAPI.renderCachedHtmlDelayInMilliscond = Int(textField?.text ?? "0") ?? 0
                self.refresh()
            }))
            self.present(alervc, animated: true, completion: nil)

        } else if cellItem.title == showRNDebug {
            if OpenAPI.docs.remoteRN == false {
                UDToast.showFailure(with: "请先打开\"使用远端RN包\"开关", on: self.view.window ?? self.view)
            } else {
                NotificationCenter.default.post(name: NSNotification.Name(RNManager.showDebugNotification), object: nil)
            }
        } else if cellItem.title == configProxy {
            GlobalSetting.configRustProxy(force: true)
        } else if cellItem.title == makePowerIssue {
            self.createPowerIssue()
        } else if cellItem.title == setWatermarkPolicy {
            watermarkPolicyPickerView = UIPickerView()
            watermarkPolicyPickerView.dataSource = watermarkPolicyPickViewDataSource
            watermarkPolicyPickerView.delegate = watermarkPolicyPickViewDataSource
            watermarkPolicyPickerView.backgroundColor = UIColor.ud.N00
            view.addSubview(watermarkPolicyPickerView)
            watermarkPolicyPickerView.snp.makeConstraints { (make) in
                make.leading.trailing.bottom.equalToSuperview()
                make.height.equalTo(200)
            }
        } else if cellItem.title == pullDriveVideoSDKLog {
            getDriveVideoSDKLog()
        } else if cellItem.title == startAutoOpenDocs {
            beginAutoOpenDocs()
        } else if cellItem.title == autoOpenDocslist {
            didSelectAutoOpenDocsTypeList(indexPath: indexPath)
        } else if cellItem.title == clearLocalDomainConfig {
            clearLocalDomainConfig()
            refresh()
        } else if cellItem.title == sendLog {
            let vc = DocsDebugLogSendVC()
            self.navigationController?.pushViewController(vc, animated: true)
        } else if cellItem.title == testUnzipXzFile {
            enterXzUnzipTest()
        } else if cellItem.title == testLocalFile {
            showDriveLocalFile()
        } else if cellItem.title == DebugCellTitle.cleanDriveCache.rawValue {
            showCleanDriveCacheAlert()
        } else if cellItem.title == DebugCellTitle.cleanWikiDb.rawValue {
            showCleanWikiDBAlert()
        } else if cellItem.title == DebugCellTitle.nativeEditorSheetJSServer.rawValue {
            showLynxSheetServerAlert()
        } else if cellItem.title == DebugCellTitle.nativeEditorPreloadJSServer.rawValue {
            showLynxPreloadServerAlert()
        } else if cellItem.title == DebugCellTitle.lynxJSURL.rawValue {
            showLynxSourceURLAlert()
        } else if cellItem.title == DebugCellTitle.cipherDelete.rawValue {
            deleteDocsCipher()
        } else if cellItem.title == DebugCellTitle.lynxDevtoolOpen.rawValue {
            showLynxDevToolAlert()
        } else if cellItem.title == markWebViewUnResponsive {
            makeWebViewUnresponsive()
        } else if cellItem.title == DebugCellTitle.showLynxPkgInfo.rawValue {
            showLynxPkgInfo()
        } else if cellItem.title == "killWebContentProcess" {
            NotificationCenter.default.post(name: NSNotification.Name.KillWebContentProcess, object: nil)
        } else if cellItem.title == DebugCellTitle.killAllWebViewProcess.rawValue {
            killAllWebViewProcess()
        } else if cellItem.title == DebugCellTitle.clearWKWebViewCache.rawValue {
            clearWKWebViewCache()
        }
#endif
#if BETA || ALPHA || DEBUG
        if cellItem.title == DebugCellTitle.openInlineAI.rawValue {
//            aiTest()
            aiTestV2()
        }
        else if cellItem.title == DebugCellTitle.inlineAIResSetting.rawValue {
            navigationController?.pushViewController(DocsAIDebugController(), animated: true)
        }
#endif
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
            cell.isUserInteractionEnabled = true
            cell.contentView.alpha = 1.0
    }

#if BETA || ALPHA || DEBUG
    private func refresh() {
        configDebugDataSource()
        debugTableView.reloadData()
    }
    
    private func getDriveVideoSDKLog() {
        let events = TTVideoEngineEventManager.shared().popAllEvents()
        var count = 0
        events.forEach({ (event) in
            if let log = event as? [String: Any] {
                DocsLogger.info("Drive Video SDK Event", extraInfo: log)
                count += 1
            } else {
                DocsLogger.info("unknown Drive Video SDK Event")
            }
        })

        let alervc = UIAlertController(title: "成功拉取到日志", message: "拉取到\(count)个事件，请在lark日志中查看", preferredStyle: .alert)
        alervc.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
        }))

        self.present(alervc, animated: true, completion: nil)
    }
    
    private func showDriveLocalFile() {
        let vc = DriveLocalFileTestController()
        let nvc = UINavigationController(rootViewController: vc)
        self.present(nvc, animated: true, completion: nil)
    }
    
    private func enterXzUnzipTest() {
        let nav = UINavigationController(rootViewController: LocalFileUnzipTestController())
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func changeVConsole(isOn: Bool) {
        DocsDebugConstant.isVconsoleEnable = isOn
        DocsContainer.shared.resolve(SKCommonDependency.self)!.changeVConsoleState(isOn)
    }
#endif
}
#if BETA || ALPHA || DEBUG
extension DocsSercetDebugViewController: UIPickerViewDataSource {
    static let levels = [-1, DocsLogLevel.debug.rawValue, DocsLogLevel.verbose.rawValue, DocsLogLevel.info.rawValue]
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return DocsSercetDebugViewController.levels.count
    }
}

extension DocsSercetDebugViewController: UIPickerViewDelegate {

    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30
    }
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let levelInt = DocsSercetDebugViewController.levels[row]
        let logLevel = DocsLogLevel(rawValue: levelInt)
        if logLevel == nil {
            return "默认"
        } else {
            return "\(logLevel!)"
        }
    }
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let level = DocsSercetDebugViewController.levels[row]
        if level == -1 {
            OpenAPI.forceLogLevel = nil
        } else {
            OpenAPI.forceLogLevel = level
        }
        pickerView.removeFromSuperview()
        refresh()
    }
}
#endif
