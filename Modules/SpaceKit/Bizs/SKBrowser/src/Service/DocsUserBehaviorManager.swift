//
//  DocsUserBehaviorManager.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/2/6.
//
// 文档用户行为预测,管控模板预加载
// https://bytedance.sg.feishu.cn/docx/HLVBdOoHWo4PyOxPLXRliZfUgmc


import SKFoundation
import SKCommon
import ThreadSafeDataStructure
import SpaceInterface
import LKCommonsTracker
import SKInfra

final public class DocsUserBehaviorManager {
    private let configKey = "DocsUserBehaviorConfig"
    private let defaultDisableTemplatePreloadCount = 30
    private let defaultDisableWebviewPreloadCount = 60
    private let defaultRecordLength = 100
    
    
    private(set) var docsTypeUsages =  ThreadSafeDictionary<Int, DocsTypeUsage>()
    public static let shared = DocsUserBehaviorManager()
    let queue = DispatchQueue(label: "DocsUserBehaviorQueue")
    
    //最大预加载type数量
    var maxPreloadTypeCount: Int {
        SettingConfig.docsForecastConfig?.maxPreloadTypeCount ?? 5
    }
    
    private var supportTypes: [Int] {
        //[.doc, .docX, .sheet, .bitable, .wiki, .mindnote, .slides]
        SettingConfig.docsForecastConfig?.supportPreloadTypes ?? [2, 22, 3, 8, 16, 11, 30]
    }
    
    private var disableTemplatePreloadCount: Int {
        SettingConfig.docsForecastConfig?.disableTemplatePreloadCount ?? defaultDisableTemplatePreloadCount
    }
    
    private var disableWebViewPreloadCount: Int {
        SettingConfig.docsForecastConfig?.disableWebviewPreloadCount ?? defaultDisableWebviewPreloadCount
    }
    
    private var maxRecordLength: Int {
        SettingConfig.docsForecastConfig?.recordLength ?? defaultRecordLength
    }
    
    public init() {
        NotificationCenter.default.addObserver(self, selector: #selector(userDidLogout), name: Notification.Name.Docs.userDidLogout, object: nil)
    }
    
    func userDidLogin() {
        guard DocsUserBehaviorManager.isEnable() else {
            return
        }
        DocsLogger.info("loadData DocsUserBehaviorConfig onLogin", component: LogComponents.UserBehavior)
        queue.async {
            self.loadDataAsync()
        }
    }
    
    private func loadDataAsync() {
        guard let userId = User.current.basicInfo?.userID else {
            resetConfig()
            spaceAssertionFailure("no userid" + LogComponents.UserBehavior)
            saveData()
            return
        }
        guard let data = CCMKeyValue.userDefault(userId).data(forKey: configKey) else {
            resetConfig()
            DocsLogger.error("no behavior data onLogin", component: LogComponents.UserBehavior)
            saveData()
            return
        }
        guard var dict = try? JSONDecoder().decode([Int: DocsTypeUsage].self, from: data) else {
            resetConfig()
            spaceAssertionFailure("decode DocsUserBehaviorConfig failed" + LogComponents.UserBehavior)
            saveData()
            return
        }
        
        docsTypeUsages.removeAll()
        let countForTemplate = disableTemplatePreloadCount
        let countForWebview = disableWebViewPreloadCount
        let recordLength = maxRecordLength
        DocsLogger.info("load DocsUserBehaviorConfig onLogin:\(dict.keys), countForTemplate:\(countForTemplate), countForWebview:\(countForWebview), recordLength:\(recordLength)", component: LogComponents.UserBehavior)
        
        for type in supportTypes {
            //登入时新增一条记录
            if let usage = dict[type] {
                usage.appendNewRecord()
            } else {
                let usage = DocsTypeUsage()
                usage.appendNewRecord()
                dict[type] = usage
            }
        }
        
        for (type, usage) in dict {
            usage.cutdownIfNeed(maxSize: maxRecordLength)
            self.docsTypeUsages.updateValue(usage, forKey: type)
        }
        DocsLogger.info("load DocsUserBehaviorConfig \(dict)", component: LogComponents.UserBehavior)
        saveData()
    }
    
    /// 注入单测数据
    func injectTestData(_ data: [Int: [Int]]) {
        guard DocsSDK.isBeingTest else {
            return
        }
        docsTypeUsages.removeAll()
        for item in data {
            docsTypeUsages.updateValue(DocsTypeUsage(lastOpenTime: 0, recentOpenCount: item.value), forKey: item.key)
        }
    }

    @objc
    private func userDidLogout() {
        queue.async {
            self.docsTypeUsages.removeAll()
        }
    }
    
    private func resetConfig() {
        docsTypeUsages.removeAll()
        for type in supportTypes {
            let usage = DocsTypeUsage()
            usage.appendNewRecord()
            self.docsTypeUsages.updateValue(usage, forKey: type)
        }
    }
    
    private func saveData() {
        guard let userId = User.current.basicInfo?.userID else {
            spaceAssertionFailure()
            return
        }
        let dict = self.docsTypeUsages.all()
        guard let data = try? JSONEncoder().encode(dict) else {
            spaceAssertionFailure("encode docsTypeUsages error," + LogComponents.UserBehavior)
            return
        }
        CCMKeyValue.userDefault(userId).set(data, forKey: self.configKey)
    }
    
    private func shouldPreloadInDefault(type: DocsType) -> Bool {
        //根据原来的setting判断是否需要预加载
        let shouldPreload = SettingConfig.preloadJsmoduleSequeceConfig?.contains(type.name) ?? false
        return shouldPreload
    }
    
    /// 记录用户打开文档行为
    public func openDocs(docsInfo: DocsInfo) {
        queue.async {
            if let usage = self.docsTypeUsages.value(ofKey: docsInfo.type.rawValue) {
                usage.increaseOpenCount()
            } else {
                let usage = DocsTypeUsage()
                usage.increaseOpenCount()
                self.docsTypeUsages.updateValue(usage, forKey: docsInfo.type.rawValue)
            }
            DocsLogger.info("openDocs usages for \(docsInfo.type.name)", component: LogComponents.UserBehavior)
            if docsInfo.type == .wiki {
                //wiki需要更新inherentType类型
                if let realTypeUsage = self.docsTypeUsages.value(ofKey: docsInfo.inherentType.rawValue) {
                    realTypeUsage.increaseOpenCount()
                } else {
                    let realTypeUsage = DocsTypeUsage()
                    realTypeUsage.increaseOpenCount()
                    self.docsTypeUsages.updateValue(realTypeUsage, forKey: docsInfo.inherentType.rawValue)
                }
                DocsLogger.info("openDocs usages for \(docsInfo.inherentType.name)", component: LogComponents.UserBehavior)
            }
            self.saveData()
        }
    }
    
    /// 根据用户行为获取需求预加载的文档类型（按使用频率排序）
    /// - Returns:
    ///  1. [DocsType]数组，数组为空则表示不需要预加载任何类型
    ///  2. nil，表示不开启用户行为管控策略，外部自行决定需要加载的类型
    public func getPreloadTypes() -> [String]? {
        let checkCount = disableTemplatePreloadCount
        guard checkCount > 0 else {
            DocsLogger.info("getPreloadTypes do nothing", component: LogComponents.UserBehavior)
            return nil
        }
        
        var usageDict = [Int: Int]()
        let allData = docsTypeUsages.all()
        guard !allData.isEmpty else {
            DocsLogger.info("getPreloadTypes data is empty", component: LogComponents.UserBehavior)
            return nil
        }
        
        //计算最近N次启动的打开总次数
        allData.forEach { (key: Int, usage: DocsTypeUsage) in
            let openCount = usage.recentOpenCount.suffix(checkCount).reduce(0, +)
            if openCount > 0 {
                usageDict[key] = openCount
            } else {
                if usage.recentOpenCount.count < checkCount, self.shouldPreloadInDefault(type: DocsType(rawValue: key)) {
                    //记录样本数据不够时，如果docsType在默认配置中，也可以加进来排序
                    usageDict[key] = 0
                }
            }
        }
        
        //按使用次数排序进行预加载
        let defaultTypes = SettingConfig.preloadJsmoduleSequeceConfig ?? []
        let sortTypes = usageDict.sorted {
            if $0.value == $1.value {
                //如果使用次数相同，则按默认配置中的顺序
                let type0 = DocsType(rawValue: $0.key)
                let type1 = DocsType(rawValue: $1.key)
                let index0 = defaultTypes.firstIndex(of: type0.name) ?? Int.max
                let index1 = defaultTypes.firstIndex(of: type1.name) ?? Int.max
                return index0 < index1 //索引小的在前
            }
            return $0.value > $1.value
        }.prefix(maxPreloadTypeCount).map { $0.key }
        let types = sortTypes.compactMap {
            let docType = DocsType(rawValue: $0)
            if docType.isOpenByWebview {
                return docType.name
            }
            return nil
        }
        DocsLogger.info("getPreloadTypes: \(types), checkCount:\(checkCount)", component: LogComponents.UserBehavior)
        return types
    }
    
    
    /// 根据用户行为判断该文档类型是否需要预加载模板
    public func shouldPreloadTemplate(type: DocsType) -> Bool {
        let checkCount = disableTemplatePreloadCount
        guard checkCount > 0 else {
            DocsLogger.info("shouldPreloadTemplate do nothing", component: LogComponents.UserBehavior)
            return true
        }
        guard let usage = self.docsTypeUsages.value(ofKey: type.rawValue) else {
            //没有记录根据默认配置
            return shouldPreloadInDefault(type: type)
        }
        if usage.recentOpenCount.count < checkCount {
            //如果没有记录够次数，则按照旧逻辑，根据默认配置判断
            return shouldPreloadInDefault(type: type)
        }
        //判断最近N次启动是否有使用
        let hasOpenInRecent = usage.recentOpenCount.suffix(checkCount).contains{ $0 > 0 }
        return hasOpenInRecent
    }
    
    
    /// 根据用户行为判断是否需要预加载Webview
    public func shouldPreloadWebView() -> Bool {
        let checkCount = disableWebViewPreloadCount
        guard checkCount > 0 else {
            DocsLogger.info("shouldPreloadWebView do nothing", component: LogComponents.UserBehavior)
            return true
        }
        let hasOpenInRecent = docsTypeUsages.all().contains { (key: Int, usage: DocsTypeUsage) in
            if usage.recentOpenCount.count < checkCount {
                //如果没有记录够次数，则按照旧逻辑，可以预加载
                return true
            }
            //判断最近N次启动是否打开过文档
            let hasOpenInRecent = usage.recentOpenCount.suffix(checkCount).contains{ $0 > 0}
            return hasOpenInRecent
        }
        return hasOpenInRecent
    }
    
    /// 是否有拦截模板预加载
    public func hasInterruptPreload(types: [String]) -> Bool {
        guard let defaultTypes = SettingConfig.preloadJsmoduleSequeceConfig else {
            return false
        }
        //1. 预加载的类型比默认预加载类型少，说明减少了某些类型预加载，有收益
        if types.count < defaultTypes.count {
            return true
        }
        //2. 默认类型中没有，但也触发了预加载，也有收益
        var hasInterrupt = false
        types.forEach {
            if !defaultTypes.contains($0) {
                hasInterrupt = true
            }
        }
        return hasInterrupt
    }
    
    public static func isEnable() -> Bool {
        if UserScopeNoChangeFG.LJY.enableDocsUserBehavior {
#if DEBUG
            return true
#else
            if let abEnable = Tracker.experimentValue(key: "docs_forecast_enable", shouldExposure: true) as? Int,
               abEnable == 1 {
                return true
            }
#endif
        }
        return false
    }
}

extension LogComponents {
    public static let UserBehavior = "==Behavior== "
}
