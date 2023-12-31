//
//  OPSDKFeatureGating.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/27.
//

import Foundation
import LarkFeatureGating
import LarkSetting
import RxSwift
import LKCommonsLogging
import LarkBoxSetting
import ECOInfra

import LarkContainer
import LarkQuickLaunchInterface
import LarkDowngrade

// 灰度设计文档: https://bytedance.feishu.cn/docs/doccn1uxdySkmMJ52a6Sz50zose
// openplatform.gadget.newcontainer: 全局关闭所有灰度
// gadget.container.enable. ：开启某个小程序灰度，需要再拼接standard/embed + appid
// gadget.container.disable. 关闭某个小程序灰度，需要再拼接standard/embed + appid
// gadget.container.enable.batch：批量开启灰度

@objcMembers public final class OPSDKFeatureGating: NSObject {
    
    // 缓存值，避免动态修改造成前后读取不一致
    private static var cacheConfig: [String: Bool] = [:]
    //日志新增
    static let logger = Logger.oplog(OPSDKFeatureGating.self, category: "OPSDK")
    private static var debugConfig: [String: Bool]?
    private static let disposeBag = DisposeBag()
    private static func getValueWithCache(for key: String) -> Bool {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        #if DEBUG
        if let debugConfig = debugConfig, let value = debugConfig[key] {
            return value
        }
        #endif
        if let value = cacheConfig[key] {
            return value
        }
        let value = LarkFeatureGating.shared.getFeatureBoolValue(for: key)
        cacheConfig[key] = value
        return value
    }
    //缓存一下 isBoxOff 的值，避免频繁调用（默认为true，后续从observe更新值）
    private static var _isBoxOff: Bool = BoxSetting.isBoxOff()
    //是否开启离线包能力，默认为false。保证进程那状态统一，有缓存
    // 使用realTimeManager解决首次安装APP时打开主导航离线应用报错的问题
    public static func isWebappOfflineEnable() -> Bool {
        return FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webapp.offline.enable"))
    }
    
    ///  是否禁用queuemap的修复逻辑（默认enable生效）
    public static func disablePrehandleQueueMapFix() -> Bool {
        return getValueWithCache(for: "openplatform.gadget.disbale.prehandle.queuemap.fix")
    }

    /// 使用默认全量的FG配置(支持止血)
    public static func getFullReleaseFeatureBoolValue(for key: String) -> Bool {
        if shouldDisableFullRelease(for: key) {
            return LarkFeatureGating.shared.getFeatureBoolValue(for: key)
        }
        // 默认全量
        return true
    }
    
    /// 禁止全量发布FG的开关（用于紧急止血，如果没有问题就可以跟随端上代码全量一起删掉了）
    private static func shouldDisableFullRelease(for key: String) -> Bool {
        if LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.gadget.container.full_release.disable.\(key)") {
            return true
        }
        return LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.gadget.container.full_release.disable")
    }
    
    public static func isBubbleEventTurnOn() -> Bool {
        return getValueWithCache(for: "gadget.container.enable.bubble")
    }
    
    public static func isBuildInPackageProcessEnable() -> Bool {
        //审核 或 ODR开启时，启动解压流程默认开启。但可以通过打开 openplatform.gadget.preset.disable，一键关闭这个通道
        return (self.isBoxOff() || self.isEnableApplePie())&&(!getValueWithCache(for: "openplatform.gadget.preset.disable"))
    }
       
   public static func isBoxOff() -> Bool {
       logger.info("OPSDKFeatureGating->isBoxOff:\(_isBoxOff)")
       //保证代码只执行一次
       DispatchQueue.once(identifier: "isBoxOff", block: {
           BoxSetting.shared.boxOffChangeObservable.subscribe(onNext: { isBoxOffValue in
               logger.info("OPSDKFeatureGating->_isBoxOff changed:\(isBoxOffValue)")
               Self._isBoxOff = isBoxOffValue
           }).disposed(by: Self.disposeBag)
       })
       return _isBoxOff
   }
    
    /// 如果应用ID在ODR名单内，并且线上开启 ODR能力。=
    /// 此时只能使用ODR名单内的应用，禁止目标进行止血操作或过期判断（以免 meta request forbidden）
    /// - Parameter uniqueID: 检查的应用ID
    /// - Returns: 是否可以进行止血或者过期操作
    public static func canSilenceUpdateOrExpire(_ uniqueID: OPAppUniqueID) -> Bool {
        return !(self.isEnableApplePie() && self.isTargetInBuildinList(uniqueID))
    }
    
    //isBoxOff为true，或者在不预置列表内，则不删除
    public static func shouldKeepDataWith(_ uniqueID: OPAppUniqueID?) -> Bool {
        return self.isBoxOff() || self.isTargetInBuildinList(uniqueID)
    }
    
    //ODR能力强制开启时，资源列表内的数据不允许通过meta请求后落库（否则可能会出现包和meta版本不匹配的情况）
    public static func enableMetaSaveCheckIfNecessary(_ uniqueID: OPAppUniqueID?) -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.pkm.pie.save.check.enable")) && self.isTargetInBuildinList(uniqueID)
    }
    
    //如果应用在预置列表内，则返回true
    //如果当前不是线上版本（或禁用ODR能力时）直接返回 false
    private static func isTargetInBuildinList(_ uniqueID: OPAppUniqueID?) -> Bool {
        if let uniqueID = uniqueID,
           (uniqueID.versionType != .current || !self.isEnableApplePie()) {
            //如果不是线上版本（扫码预览或者调试），均跳过 ODR 名单检查。避免调试包命中ODR逻辑
            logger.warn("\(uniqueID.fullString) version type is:\(uniqueID.versionType), skipped")
            return false
        }
        var targetHit = false
        let buildInMetaListMap: [OPAppType: String] = [.gadget: "appMetaList", .block: "blockMetaList"]
        if let uniqueID = uniqueID,
           let timorBundleUrl = Bundle.main.url(forResource: "TimorAssetBundle", withExtension: "bundle"),
           let mainBundle = Bundle(url: timorBundleUrl),
           let buindinBundleForJSON = mainBundle.path(forResource: "BuildinResources.bundle", ofType: ""),
           let metaListFileName = buildInMetaListMap[uniqueID.appType] {
            // lint:disable:next lark_storage_check
            if  let buildMetaJsonData = try? Data(contentsOf: URL(fileURLWithPath: buindinBundleForJSON.appending("/\(metaListFileName).json"))),
                let jsonString = String(bytes: buildMetaJsonData, encoding: .utf8) {
                //判断是否在内置的数据里，包含目标identifier
                targetHit = jsonString.contains(uniqueID.identifier)
            } else {
                logger.error("isTargetInBuildinList check error: json invalid")
            }
        } else {
            logger.error("isTargetInBuildinList check error: bundle invalid")
        }
        logger.info("isTargetInBuildinList return with hit status:\(targetHit)")
        return targetHit
    }
    //默认开启，只有当 openplatform.pkm.disable.apple.pie 设置时，才会关闭
    public static func isEnableApplePie() -> Bool {
        //收敛FG，如果 boxOff 为true，就开启 ODR 功能【默认】
        //但是该逻辑允许回撤（下发 openplatform.pkm.disable.boxoff.union FG），还是执行老逻辑
        if LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.pkm.disable.boxoff.union") {
            return !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.pkm.disable.apple.pie"))
        } else {
            return isBoxOff()
        }
    }
    
    private static func fetchCachedFGInUserDefaultWithKey(_ key: String) -> Bool {
        //key的值和当前租户形态无关，这里不用区分userID
        let keyUsedInUserDefaults = "OPSDK.UserDefaultKey.\(key)"
        let result = LSUserDefault.standard.getBool(forKey: keyUsedInUserDefaults)
        logger.info("try to fetchCachedFGInUserDefaultWithKey with result:\(result)")
        //同一个FG，保证代码只执行一次
        DispatchQueue.once(identifier: key, block: {
            //订阅FG是否更新了，如果更新了就需要刷新 userDefault
            FeatureGatingManager.shared.fgObservable.subscribe(onNext: {
                let latestValue = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: key))
                logger.info("try to store with result:\(result) and latestValue:\(latestValue) if they're different")
                if latestValue != result {
                    LSUserDefault.standard.set(latestValue, forKey: keyUsedInUserDefaults)
                }
            }).disposed(by: Self.disposeBag)
        })
        return result
    }

    /// Only For Debug
    public static func setupDebugConfig(_ config: [String: Bool]) {
        debugConfig = config
    }
    
    /// 是否修复小程序 Toolbar 的位置偏移问题
    public static func shouldFixToolBarPosition(_ uniqueID: OPAppUniqueID?) -> Bool {
        if let uniqueID = uniqueID {
            //如果配置appId且需要降级，则回滚 4.2 autolayout 的修复方案到原 layoutSubviews 的布局逻辑
            let downgrade =
            //命中 disable 的FG，则进行降级
            getValueWithCache(for: "openplatform.gadget.toolbar.position.fix.disable.\(uniqueID.appID)") ||
            //允许批量降级
            getValueWithCache(for: "openplatform.gadget.toolbar.position.fix.disable.batch")
            //有限判断降级逻辑
            if downgrade {
                return false
            }
        }
        return true
    }
    
    /// 修复小程序Toolbar在iOS11-12下，布局异常的问题
    public static func shouldFixToolBarLayoutError() -> Bool {
        return LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.gadget.toolbar.layout.fix")
    }
    
    /// 是否开启JSSDK内置流程优化逻辑
    public static func enableWaitJSSDKLoaded() -> Bool {
        return LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.gadget.enable_wait_jssdk_loaded")
    }
    /// 是否禁用 AppPage 默认的 DarkMode
    public static func shouldDisableAppPageDefaultDarkMode() -> Bool {
        return LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.gadget.app_page.dark_mode.disable")
    }
    
    /// 新容器预备移除一部分无用的代码，默认开启
    public static func isGadgetContainerRemoveCode(_ uniqueID: OPAppUniqueID?) -> Bool {
        return getFullReleaseFeatureBoolValue(for: "openplatform.gadget.newcontainer.remove_code")
    }

    //是否打开小程序 BDPMonitorEvent 在独立线程中上报 flush 的开关
    public static func enableMonitorFlushInQueue() -> Bool {
        //https://meego.feishu.cn/larksuite/issue/detail/4499907#detail
        //修正线上因提前调用FG时机导致的crash问题。临时注释关闭，待修正后开启FG
        return false
//        return getValueWithCache(for: "openplatform.gadget.monitor.flush.queue.enable")
    }
    
    public static func enableMsgCardJSSDKUpdate() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "lynxcard.client.render.enable"))
    }

    /// 开启返回/关闭小程序的二次弹框提醒
    public static func enableLeaveComfirm() -> Bool {
        return LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.enable.level.confirm.cancel.event")
    }

    /// 是否支持解析小程序中orientation字段FG(是否支持横屏)
    public static func enablePageOrientation() -> Bool {
        return getValueWithCache(for: "openplatform.gadget.enable_page_orientation")
    }

    /// 是否控制小程序侧滑退出小程序手势(用于小程序横竖屏功能)
    public static func controlLandscapePopGesture() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.control_landscape_popgesture"))
    }

    /// 通过手势侧滑退出小程序后, 是否需要调整上一个小程序的界面方向(小程序横竖屏功能)
    public static func fixGadgetOrientationByPreviewsGadgetGestureExit() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.autorotate_handle_pop_gesture"))
    }

    /// 通过飞书版本来判断最低兼容版本
    public static func gadgetCheckMinLarkVersion() -> Bool {
        return getValueWithCache(for: "openplatform.gadget.check_min_lark_version.enable")
    }
    
    /// pageViewcontroller init 方法中是否设置self.view 的 theme color
    public static func disableSetThemeColorInInit() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.disable_set_theme_color_ininit"))
    }
    
    /// 是否允许在小程序侧滑关闭后取消所有加载任务
    public static func enableToCancelAllReadDataCompletionBlks() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.enable_all_read_data_completion"))
    }

    /// 是否将settings中的'miniprogram_copyable_config' 配置信息挂载到webview的EMANativeConfig中
    public static func enableGadgetInjectCopyableConfig() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "open.platform.gadget.copyable.enable"))
    }

    /// 小程序首页redirectTo 非 tabbar 页面，判断左上角是否展示 home icon
    /// 默认值NO，如果只有一个VC就展示Home icon，多个不展示；FG 设置为YES后，就不展示home icon
    public static func disableShowGoHomeRedirectTo() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.disable_show_go_home_redirectto"))
    }
    
    /// 是否开启多Tab默认非选中第一个Tab的优化逻辑，默认不开启
    public static func enableOptimizeSelectNotFirstTab() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.optimize_select_not_firsttab"))
    }

    /// 是否禁用iOS16系统, 小程序的自动旋转功能
    public static func disableIOS16Orientation() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadge.disable_ios16_orientation"))
    }
    
    /// 是否打开 applyUpdate API 的优化开关
    public static func enableApplyUpdateImprove() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.api.applyupdate.improve.enable"))
    }
    
    /// 修复包重新下载时出现的loadScript错误
    public static func fixLoadScriptFailWhenRetryDownloadPackage() -> Bool {
        return getValueWithCache(for: "openplatform.gadget.package.fix_load_script_retry_download")
    }
    
    /// 是否开启存储升级
    public static func enableDBUpgrade() -> Bool {
        return getValueWithCache(for: "openplatform.gadget.meta_use_db.enable")
    }

    /// 小程序包管理中是否允许对db(BDPPkgInfoTableV3)这个表表中的ext字段进行读写
    public static func packageExtReadWriteEnable() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.package_db_ext.enable"))
    }
    
    ///  是否开启预安装多线程保护
    public static func enableInjectorsProtection() -> Bool {
        return getValueWithCache(for: "openplatform.gadget.enable.prehandle.injectors.protection")
    }

    /// 用户点击'清理缓存'按钮后, 是否触发小程序包清理逻辑
    public static func gadgetPackageUserCleanEnable() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.package.user_clean.enable"))
    }

    /// lark清理缓存逻辑触发后, 是否触发小程序包清理逻辑
    public static func gadgetPackageClientCleanEnable() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.package.client_clean.enable"))
    }

    /// 设置小程序页面方向API是否生效开关
    public static func gadgetSetPageOrientationEnable() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.set_page_orientation.enable"))
    }

    /// 设置小程序是否使用UIApplication statusBarOrientation来表示设备方向
    public static func gadgetUseStatusBarOrientation() -> Bool {
        return getValueWithCache(for: "openplatform.gadget.use_status_bar_orientation.enable")
    }

    /// 关闭预加载信息上报
    public static func disablePreloadMonitorInfo() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.preload.monitor.disable"))
    }

    /// 打开webview 后台切换到前台预加载逻辑
    public static func enableWebViewPreloadFromActivebg() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.preload.render.from.activebg"))
    }

    /// 打开js runtime 后台切换到前台预加载逻辑
    public static func enableJsRuntimePreloadFromActivebg() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.preload.jsruntime.from.activebg"))
    }
    
    /// 是否修复input收起时，pageFrame恢复至弹起时的originY值，而不是0.该FG是disable类型开关，默认不下发
    public static func enableInputPageFrameOriginYFix() -> Bool {
        return !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.input.pageframe.originy.fix.disable"))
    }
    
    /// 是否开启启动删包逻辑，默认关闭
    public static func enablePackageCleanWhenLaunching() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.pkg.clean.when.launching"))
    }

    /// 是否开启小程序启动时, 数据记录
    public static func enableGadgetLaunchInfoRecord() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.record.usage"))
    }

    /// 关闭预加载使用率优化相关功能：禁止预加载 和 预加载埋点上报功能； 默认返回NO，预加载使用率优化功能开启
    public static func disablePreloadUsePercent() -> Bool {
        if LarkUniversalDowngradeService.shared.needDowngrade(key: "OPSDKFeatureGatingTask", strategies: [.lowDevice()]) {
            return true
        } else {
            return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.disable.preload.use.percent"))
        }
    }
    /// 关闭预处理的多线程问题修复逻辑
    public static func disablePrehandleConcurrnetFix() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.disable.prehandle.concurrent.fix"))
    }

    /// 预处理使用单测改造后的代码
    public static func prehandleUnitTestCodeEnable() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.prehandle_unit_test.enable"))
    }
    
    /// 是否移除异步更新时的版本检查逻辑（防止灰度编译场景时造成有包变无包的情况）
    public static func enableMetaSaveVersionCheckRemove() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.meta_save.versioncheck.remove"))
    }

    /// 关闭小程序提前缓存下个页面逻辑，如果BDPAppPageFactory 中不存在预加载AppPage, 触发预加载并由BDPAppPageFactory 持有；存在的话啥也不做
    public static func disablePrecacheNextAppPage() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.disable.precache.next.apppage"))
    }
    
    ///  半屏小程序打开自身的全屏小程序时，在自动流程中终止
    public static func enableStopLaunchingSelfWhilePresentingInXScreen() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.enable.xscreen_stop_launching_self"))
    }
    
    ///  是否开启循环引用修复
    public static func enablePackageFileHandleLeakFix() -> Bool {
        //防止高频读取造成性能裂化，内存里缓存第一次读取的值
        return getValueWithCache(for: "openplatform.gadget.enable.filehandle.leak.fix")
    }
    
    ///  是否开启BDPPkgHeaderParser 的线程保护
    public static func enableHeaderParserProtection() -> Bool {
        //防止高频读取造成性能裂化，内存里缓存第一次读取的值
        return getValueWithCache(for: "openplatform.gadget.enable.header.parse.protection")
    }

    ///  是否使用PKM加载meta和pkg
    public static func pkmLoadMetaAndPkgEnable() -> Bool {
        return getValueWithCache(for: "openplatform.package.pkm.enable") && enableDBUpgrade()
    }
    
    ///  小程序iPad进Super app临时区单独开关
    public static func gadgetOpenInTemporaryEnable() -> Bool {
        return !getValueWithCache(for: "openplatform.gadget.temporary.open.disable")
    }
    
    ///  小程序iPad工作台使用临时区打开开关
    public static func workplaceGadgetOpenInTemporaryEnable() -> Bool {
        return getValueWithCache(for: "openplatform.gadget.workplace.temporary.enable")
    }
    
    ///  小程序iPad路由支持参数showTemporary
    public static func gadgetRouteShowTemporaryDisable() -> Bool {
        return getValueWithCache(for: "openplatform.gadget.handle.showtemporary.disable")
    }
    
    /// 是否开启关于页Loader流程使用PKM加载
    public static func pkmLoadAboutPageEnable() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.package.pkm.about.enable")) && pkmLoadMetaAndPkgEnable()
    }

    /// 小程序包增量更新功能是否开启
    public static func packageIncremetalUpdateEnable() -> Bool {
        return getValueWithCache(for: "openplatform.package.incremental.update.enable") && enableDBUpgrade()
    }
    
    /// 主导航小程序禁用applyUpdate API (这边主要是提前返回错误信息)
    public static func tabGadgetDisableApplyUpdate() -> Bool {
        return getValueWithCache(for: "openplatform.gadget.fix.add.embed.app.api.error.code")
    }
    /// 包管理相关API是否统一改造FG
    public static func packageAPIUnifiedEnable() -> Bool {
        return getValueWithCache(for: "openplatform.package.api.unifined.enable")
    }

    public static func enableCompensateTraitCollectionDidChange() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.enable.compensate_traitcollection_change"))
    }
    //是否针对包管理 getAppMeta 开启域名切换逻辑
    public static func enableGetAppMetaDomainShift() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.pkm.domain.shift.enable"))
    }
    
    public static func downgradeResolveBizDepenedence() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.downgrade.resolve.business.dependence"))
    }
    
    /// 关闭triggerForCheckForUpdate这个API触发时会删除本地meta的操作
    public static func disableDeleteMetaWhenTriggerCheckForUpdate() -> Bool {
        return getValueWithCache(for: "openplatform.gadget.delete_meta_when_trigger_update.disable")
    }
    
    /// 合并相同包下载任务存在多线程问题fix
    public static func fixPackageDownloadTaskMergeIncorrect() -> Bool {
        return getValueWithCache(for: "openplatform.package.fix_package_download_merge_incorrect.enable")
    }
    
    /// 是否提前 EENetwork注册（开启getAppMeta rust 网络库）
    public static func enableRustInGetAppMeta() -> Bool {
        return getValueWithCache(for: "openplatform.gadget.rust.getappmeta.enable")
    }
    
    /// 小程序是否使用统一存储API
    public static func enableUnifiedStorage() -> Bool {
        return getValueWithCache(for: "openplatform.gadget.unified.storage.enable")
    }
    
    /// 是否禁用 WebApp 的 metacache
    public static func disableMetaCacheInWebApp() -> Bool {
        return getValueWithCache(for: "openplatform.webapp.metacache.disable")
    }
    
    /// meta请求是否为合并情况埋点上报
    public static func enableReportmetaRequestMergeMonitor() -> Bool {
        return getValueWithCache(for: "openplatform.meta.request.merge.monitor.enable")
    }
    
    /// BDPPkgHeaderParser解析文件名crash bugfix
    public static func fixPkgHeaderParseFileNameCrash() -> Bool {
        return getValueWithCache(for: "openplatform.package.fix_parse_file_name_crash.enable")
    }
    
    /// MetaFetcher是否开启循环依赖bugfix
   public static func enableMetaFetcherLeakFix() -> Bool {
        return getValueWithCache(for: "openplatform.pkm.enable.metafetcher.leak.fix")
    }
    
    ///是否开启本地已存在包对分包的支持
   public static func enablePackageExistCheckSubpackageSupport() -> Bool {
        return getValueWithCache(for: "openplatform.pkm.enable.subpackage.check.support")
    }
    
    /// 是否优化飞书启动7s 延迟更新任务，优化后调整到登录后执行更新逻辑
    public static func enableOptimizeUpdateRelativeData() -> Bool {
        return getValueWithCache(for: "openplatform.gadget.optimize.update.relativedata")
    }

    /// 关闭BDPURLProtocol 中的日志
    public static func disableProtocolLog() -> Bool {
        return getValueWithCache(for: "openplatform.gadget.protocol.log.disable")
    }

    /// 是否在 request 里继续保留多余的 session 信息
    /// 注意这里是一个取反的值，FG不配置的时候方法 return true，配置了return false
    public static func enableKeepRedundantSessionInRequest() -> Bool {
        let shouldRemoveLarkSession = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.network.remove_larksession_from_req_body"))
        return !shouldRemoveLarkSession
    }
    
    // 屏蔽BDPJSBridgeRegister注册的开关, 默认值是false, 表示优化打开.
    public static func bdpJSBridgeRegisterOptDisable() -> Bool {
        getValueWithCache(for: EEFeatureGatingKeyBDPPiperRegisterOptDisable)
    }
    
    public static func apiNetworkV1DispatchFromPMDisable() -> Bool {
        getValueWithCache(for: EEFeatureGatingKeyAPINetworkV1PMDisable)
    }
    
    public static func apiDynamicDispatchFromPMEnable() -> Bool {
        getValueWithCache(for: "openplatform.api.dynamic.dispatch.pm.enable")
    }
    
    /// 是否将 URLSession 切换成 RustHTTPSession
    /// https://bytedance.sg.feishu.cn/docx/E2MWd0c64ogbvIxtSLvl4Ty6gqf
    public static func enableMetaFetcherViaRustHttpAPI() -> Bool {
        return getValueWithCache(for: "openplatform.gadget.metafetcher.rusthttp.enable")
    }
    
    public static func enableTabGadgetUpdate() -> Bool {
        return getValueWithCache(for: "openplatform.gadget.tab.container.update.supported")
    }
    
    /// 是否允许BDPTabBarPageController进行pop和push操作，命中FG并且tabbar显示进行pop、push操作；不命中FG强制pop、push;
    /// 参考：BDPTabBarPageController 中的viewDidAppear 中origin_pop 和origin_push调用
    /// - Returns: true/ false
    public static func enableTabPopPushIfNeed() -> Bool {
        return getValueWithCache(for: "openplatform.gadget.tabvc.poppush.ifneed")
    }

    /// 是否开启预安装性能优化开关
    public static func enablePrehandleOptimizing() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.prehandle.performance.optimization.enable"))
    }
}

fileprivate extension DispatchQueue {
    private static var _onceTracker = [String]()
    //保证方法之执行一次，实现类似 dispatch_once的功能
    class func once(identifier: String, block: ()->Void) {
        objc_sync_enter(self); defer { objc_sync_exit(self) }
        if _onceTracker.contains(identifier) {
            return
        }
        _onceTracker.append(identifier)
        block()
    }
}

@objc public class OPTemporaryContainerService: NSObject {
    var temporaryTabService: TemporaryTabService { Container.shared.resolve(TemporaryTabService.self)! } // swiftlint:disable:this all
    
    @objc public static func isGadgetTemporaryEnabled() -> Bool {
        return OPSDKFeatureGating.gadgetOpenInTemporaryEnable() && OPTemporaryContainerService().temporaryTabService.isTemporaryEnabled
    }
    
    public static func getTemporaryService() -> TemporaryTabService {
        return OPTemporaryContainerService().temporaryTabService
    }
    
    @objc public static func isTemporay(container:UIViewController) -> Bool {
        return container.isTemporaryChild
    }
}
