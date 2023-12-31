//
//  WebSearchExtensionItem.swift
//  WebBrowser
//
//  Created by baojianjun on 2023/10/25.
//

import Foundation
import WebKit
import LarkWebViewContainer
import LarkKeyCommandKit
import LKCommonsLogging
import LarkSetting
import LarkContainer
import RxSwift
import RxCocoa
import ECOProbe

// MARK: - Type

public enum WebSearch {
    
    typealias IndexType = (Int, Int)
    typealias IndexResult = Result<IndexType, CustomError>
    typealias JSCallBack = (IndexResult) -> Void
    typealias ObservableIndexResult = Observable<IndexResult>
    
    enum CustomError: Error {
        case jsError(Error?)
        case noJSDelegate
        case noSelf
        
        var errString: String {
            switch self {
            case .jsError(let detail):
                detail?.localizedDescription ?? "[null]"
            case .noJSDelegate:
                "noJSDelegate"
            case .noSelf:
                "noSelf"
            }
        }
    }
    
    enum MonitorKey: String {
        case applicationID = "application_id"
        case openAction = "open_action"
        case searchID = "search_id"
        case click = "click"
        case resultCnt = "result_cnt"
    }
    
    public enum OpenActionType: String {
        case mouse
        case shortcut
    }
    
    enum ClickType: String {
        case search
        case search_result
        case next_item
        case previous_item
    }
}

// MARK: -

final public class WebSearchExtensionItem: WebBrowserExtensionItemProtocol {
    
    private static let logger = Logger.webBrowserLog(WebSearchExtensionItem.self, category: "WebSearchExtensionItem")
   
    private var script: String?
    
    /// 屏蔽快捷键的Host黑名单，setting配置
    private let keyCommandShieldHostBlackList: [String]
    
    /// iPad台前调度, 从物理键盘切换到软键盘, 输入框高度跟随的修复setting配置
    private let keyboardFixOnStageManager: Bool
    
    weak var browser: WebBrowser?
    /// 套件统一浏览器容器生命周期实例
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = WebSearchLifeCycleImpl(item: self)
    
    public var itemName: String? = "WebSearch"
    
    public init?(browser: WebBrowser) {
        guard browser.configuration.webBizType == .larkWeb else {
            return nil
        }
        
        let fgEnabled = FeatureGatingManager.realTimeManager.featureGatingValue(with: "openplatform.webbrowser.search_enabled")
        guard fgEnabled else {
            Self.logger.info("fg disabled")
            return nil
        }
        
        let searchDependency = try? browser.resolver?.resolve(assert: WebBrowserSearchDependency.self)
        if searchDependency == nil { Self.logger.error("resolve WebBrowserSearchDependency nil") }
        let script = searchDependency?.highlightSearchScript() ?? ""
        guard !script.isEmpty else {
            Self.logger.info("js script is empty")
            return nil
        }
        self.script = script
        
        do {
            let config = try SettingManager.shared.setting(with: .make(userKeyLiteral: "opWebSearchConfig"))
            keyCommandShieldHostBlackList = config["command_host_blacklist"] as? [String] ?? []
            keyboardFixOnStageManager = config["keyboard_fix_on_stage_manager"] as? Bool ?? false
        } catch {
            keyCommandShieldHostBlackList = []
            keyboardFixOnStageManager = false
        }
        
        self.browser = browser
    }
    
    fileprivate lazy var searchViewModel = {
        let vm = WebSearchBarViewModel()
        vm.stateListener = self
        vm.jsDelegate = self
        return vm
    }()
    
    fileprivate var searchBar: WebSearchBar?
    
    // 统一入口
    public func enterSearch(_ openAction: WebSearch.OpenActionType) {
        searchViewModel.enterSearchMode(openAction)
        _ = searchBar?.becomeFirstResponder()
    }
}

// MARK: - JS Native Bridge
extension WebSearchExtensionItem: WebSearchJSDelegate {
    
    private func jsEvalFunction(name: String, params: [String: Any?]? = nil, completion: ((Any?, Error?) -> Void)? = nil) {
        do {
            var paramString = "{}"
            if let params {
                let paramData = try JSONSerialization.data(withJSONObject: params)
                paramString = String(data: paramData, encoding: .utf8) ?? "{}"
            }
            let script = "window.__op_web_highlight_search__.\(name)(\(paramString))"
            browser?.webview.evaluateJavaScript(script) { result, error in
                if let wkError = error as? WKError {
                    Self.logger.error("js \(name) eval WKError: \(wkError.localizedDescription), code: \(wkError.code), jsexception: \(wkError.userInfo["WKJavaScriptExceptionMessage"] ?? "")")
                } else if let error {
                    Self.logger.error("js \(name) eval error: \(error.localizedDescription)")
                }
                
                completion?(result, error)
            }
        } catch {
            Self.logger.error("js \(name) parse error: \(error.localizedDescription)")
            completion?(nil, error)
        }
    }
    
    func injectJSScript() {
        guard let script else { return }
        
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        browser?.webview.configuration.userContentController.addUserScript(userScript)
    }
    
    func jsEnterSearch(keyword: String?, index: Int?) {
        guard let keyword, let index else {
            jsEvalFunction(name: "enterSearch")
            return
        }
        
        jsEvalFunction(name: "enterSearch", params: ["keyword": keyword, "index": index])
    }
    
    func jsExitSearch() {
        jsEvalFunction(name: "exitSearch")
    }
    
    func jsConfirmSearch(keyword: String?, callback: @escaping WebSearch.JSCallBack) {
        jsEvalFunction(name: "confirmSearch", params: ["keyword": keyword]) { result, error in
            guard let result = result as? [String: Any] else {
                return callback(.failure(.jsError(error)))
            }
            let response = (result["index"] as? Int ?? 0, result["count"] as? Int ?? 0)
            callback(.success(response))
        }
    }
    
    func jsPre(callback: @escaping WebSearch.JSCallBack) {
        jsPre(keyword: self.searchBar?.currentKeyword, callback: callback)
    }
    
    private func jsPre(keyword: String?, callback: @escaping WebSearch.JSCallBack) {
        jsEvalFunction(name: "pre", params: ["keyword": keyword]) { result, error in
            guard let result = result as? [String: Any] else {
                return callback(.failure(.jsError(error)))
            }
            let response = (result["index"] as? Int ?? 0, result["count"] as? Int ?? 0)
            callback(.success(response))
        }
    }
    
    func jsNext(callback: @escaping WebSearch.JSCallBack) {
        jsNext(keyword: self.searchBar?.currentKeyword, callback: callback)
    }
    
    private func jsNext(keyword: String?, callback: @escaping WebSearch.JSCallBack) {
        jsEvalFunction(name: "next", params: ["keyword": keyword]) { result, error in
            guard let result = result as? [String: Any] else {
                return callback(.failure(.jsError(error)))
            }
            let response = (result["index"] as? Int ?? 0, result["count"] as? Int ?? 0)
            callback(.success(response))
        }
    }
}

// MARK: WebSearchBarStateListener

extension WebSearchExtensionItem: WebSearchBarStateListener {
    
    func stateDidChange(_ newValue: SearchState, oldValue: SearchState) {
        switch newValue {
        case .none:
            // 内部退出搜索流程的标识位置
            jsExitSearch()
            searchBar?.removeFromSuperview()
            searchBar = nil
        case .searching(let openAction):
            enterSearchMode(openAction)
        }
    }
    
    func monitorSearchClick(_ click: WebSearch.ClickType, resultCnt: Int?) {
        guard let traceId = searchBar?.traceId else {
            return
        }
        let monitor = getMonitor(name: "openplatform_web_container_search_click", traceId: traceId)
            .addCategoryValue(WebSearch.MonitorKey.click.rawValue, click.rawValue)
        
        if let resultCnt {
            monitor.addCategoryValue(WebSearch.MonitorKey.resultCnt.rawValue, "\(resultCnt)")
        }
        monitor.flush()
    }
    
    private func enterSearchMode(_ openAction: WebSearch.OpenActionType) {
        guard let browser else {
            Self.logger.error("enterSearchMode but cannot find browser")
            return
        }
        
        let initialBar = getSearchBar()
        browser.view.addSubview(initialBar)
        initialBar.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(initialBar.visibleContainer) // 和内部可视容器顶部对齐, 高度由它撑开
        }
        
        let firstShow = initialBar.becomeFirstResponder()
        if !firstShow {
            Self.logger.error("enterSearchMode but searchBar cannot becomeFirstResponder")
        }
        
        if let keyword = searchViewModel.cacheKeyword, !keyword.isEmpty {
            let index = searchViewModel.cacheIndex ?? (0, 0)
            jsEnterSearch(keyword: keyword, index: index.0)
            // 更新keyword和初始状态
            initialBar.resume(keyword: keyword, index: index)
        } else {
            jsEnterSearch(keyword: nil, index: nil)
        }
        
        bind(with: initialBar)
        
        getMonitor(name: "openplatform_web_container_search_view", traceId: initialBar.traceId)
            .addCategoryValue(WebSearch.MonitorKey.openAction.rawValue, openAction.rawValue)
            .flush()
    }
    
    private func getSearchBar() -> WebSearchBar {
        if self.searchBar != nil {
            Self.logger.error("there should no searBar")
            self.searchBar?.removeFromSuperview()
            self.searchBar = nil
        }
        let bar = WebSearchBar(frame: .zero)
        bar.keyboardFixFromHardwareToVirtualOnStageManager = keyboardFixOnStageManager
        self.searchBar = bar
        return bar
    }
    
    private func bind(with searchBar: WebSearchBar) {
        searchViewModel.bind(
            upArrowSignal: searchBar.upArrowSignal,
            pressShiftEnterSignal: searchBar.pressShiftEnterSignal,
            downArrowSignal: searchBar.downArrowSignal,
            pressEnterSignal: searchBar.pressEnterSignal,
            finishSignal: searchBar.finishSignal,
            pressEscapeSignal: searchBar.pressEscapeSignal,
            searchObservable: searchBar.searchObservable,
            indexSubject: searchBar.indexSubject,
            disposeBag: searchBar.disposeBag)
        
        searchBar.indexSubject
            .asSignal(onErrorJustReturn: (0, 0))
            .emit { [weak self] index in
                self?.searchBar?.update(index: index)
            }.disposed(by: searchBar.disposeBag)
    }
    
    private func monitorSearchEnter(
        _ openAction: WebSearch.OpenActionType,
        _ traceId: String
    ) {
    }
    
    private func getMonitor(name: String, traceId: String) -> OPMonitor {
        let applicationID = browser?.currrentWebpageAppID()
        return OPMonitor(name)
            .addCategoryValue(WebSearch.MonitorKey.applicationID.rawValue, applicationID ?? "none")
            .addCategoryValue(WebSearch.MonitorKey.searchID.rawValue, traceId)
            .addCategoryValue("target", "none")
            .setPlatform(.tea)
    }
}

// MARK: - WebBrowserLifeCycleProtocol

public final class WebSearchLifeCycleImpl: WebBrowserLifeCycleProtocol {
    
    private weak var extensionItem: WebSearchExtensionItem?
    
    init(item: WebSearchExtensionItem) {
        extensionItem = item
    }
    
    public func viewDidLoad(browser: WebBrowser) {
        extensionItem?.injectJSScript()
    }
    
    public func viewDidLayoutSubviews() {
        guard let searchBar = extensionItem?.searchBar,
              let browser = extensionItem?.browser,
              searchBar.superview == browser.view else {
            return
        }
        // 始终把搜索框放在最前面
        if browser.view.subviews.last != searchBar {
            browser.view.bringSubviewToFront(searchBar)
        }
    }
}

// MARK: KeyBinding

extension WebSearchExtensionItem {
    func externalKeyCommand() -> [KeyBindingWraper] {
        if !keyCommandShieldHostBlackList.isEmpty,
           let host = browser?.browserURL?.host,
           keyCommandShieldHostBlackList.contains(host) {
            return []
        }
        
        return [
            KeyCommandBaseInfo(
                input: "f",
                modifierFlags: [.command],
                discoverabilityTitle: BundleI18n.WebBrowser.LittleApp_MoreFeat_FindOnPageBttn)
            .binding { [weak self] in
                self?.enterSearch(.shortcut)
            }.wraper,
        ]
    }
}



//private let defaultHighlightSearchScript = """
//class OPWebBrowserHighlightSearch {
//  constructor({ domContainer = "body", blackClassName = [] }) {
//    this.initializeVar({ domContainer, blackClassName });
//  }
//  initializeVar({ domContainer, blackClassName }) {
//    // 首次搜索
//    this.firstSearchDone = false;
//    // 搜索区域
//    this.domContainer = domContainer || "body";
//    this.dom = null;
//    // 搜索关键词
//    this.keyword = null;
//    // 黑名单
//    this.blackClassName = blackClassName ?? [];
//    // 命中关键词所在的DOM和整个文本，便于后续跨标签匹配
//    this.searchDom = {
//      text: "",
//      data: {},
//    };
//    // 命中总数
//    this.count = 0;
//    // 命中dom
//    this.domList = [];
//    // 当前命中的索引
//    this.searchIndex = -1;
//    this.markID = 0;
//    // 横向滚动条
//    this.overflowXDom = [];
//    // 纵向滚动条
//    this.overflowYDom = [];
//  }
//  // 是否属于真实可渲染的节点
//  isRealNode(node) {
//    return (
//      node.nodeType === 1 &&
//      getComputedStyle(node).display != "none" &&
//      node.tagName !== "svg"
//    );
//  }
//  // 校验class是否存在黑名单内
//  checkClassName(el, blackClassName) {
//    return (
//      el.classList &&
//      !blackClassName.filter((item) => {
//        try {
//          let has = el.className.indexOf(item) > -1;
//          return has;
//        } catch (error) {
//          return false;
//        }
//      }).length
//    );
//  }
//  // 查询keyword子串出现在dom所属位置
//  searchSubStr(str, subStr) {
//    const parsedStr = str.toLowerCase();
//    let arr = [];
//    let index = parsedStr.indexOf(subStr);
//    while (index > -1) {
//      arr.push(index);
//      index = parsedStr.indexOf(subStr, index + 1);
//    }
//    return arr;
//  }
//  // 处理异常的文本节点
//  formatTextNode(el) {
//    const parentNode = el.parentNode;
//    const afterNode =
//      parentNode.childNodes[
//        Array.apply(null, parentNode.childNodes).indexOf(el) - 1
//      ];
//    const targetNode = parentNode.removeChild(el);
//    let span = document.createElement("span");
//    span.appendChild(targetNode);
//    if (afterNode) {
//      parentNode.appendChild(span);
//      afterNode.after(span);
//    } else {
//      parentNode.prepend(span);
//    }
//    return targetNode;
//  }
//  regExpescape(str) {
//    return str.replace(/[-\\/\\^$*+?.()|[\\]{}]/g, "\\$&");
//  }
//  // 清除所有高亮节点染色
//  cancelHighlight() {
//    const that = this;
//    this.domList.forEach((dom) => {
//      that.cancelHilightForDOM(dom);
//    });
//  }
//  // 取消高亮染色
//  cancelHilightForDOM(dom) {
//    dom.forEach((item) => {
//      item.style.backgroundColor = "";
//    });
//  }
//  // 高亮染色
//  hilightDOM(dom) {
//    dom.forEach((item) => {
//      item.style.backgroundColor = "orange";
//    });
//  }
//  // 跳转到目标dom
//  scrollToIndex(index) {
//    if (index < 0 || index >= this.domList.length) return;
//
//    const that = this;
//    this.domList[index].forEach((list) => {
//      list.scrollIntoView({ block: "center", behavior: "smooth" });
//      that.hilightDOM([list]);
//    });
//  }
//
//  // 取消高亮
//  resetMarkDOM(el) {
//    const highlightSpans = el.querySelectorAll("mark.op-web-highlight-search");
//    highlightSpans.forEach((el) => {
//      // 找到所有.highlight并遍历
//      if (!el.parentNode) return;
//      if (el.parentNode.op_web_search_style_cache) {
//        el.parentNode.style = el.parentNode.op_web_search_style_cache;
//        delete el.parentNode.op_web_search_style_cache;
//      }
//      const template = el.parentNode.querySelector(
//        "template[op-web-highlight-search]"
//      );
//      if (!template) return;
//      // 找到父节点中的template，将自己内容替换为template内容
//      el.parentNode.innerHTML = el.parentNode.querySelector(
//        "template[op-web-highlight-search]"
//      ).innerHTML;
//    });
//  }
//  // 获取dom分组
//  getDomList() {
//    const markList = document.querySelectorAll("mark.op-web-highlight-search");
//    let list = {};
//    markList.forEach((item) => {
//      const id = item.getAttribute("mark-id");
//      if (!list[id]) list[id] = [];
//      list[id].push(item);
//    });
//    return Object.values(list);
//  }
//  // DOM染色
//  markDom(el, value, isSame) {
//    if (!el.parentNode || !value) return;
//    //如果父级下有多个子节点的话，说明该文本不是单独标签包含，需要处理下
//    if (el.parentNode.childNodes.length > 1) {
//      el = this.formatTextNode(el);
//    } else if (getComputedStyle(el.parentNode)?.display === "inline-flex") {
//      el.parentNode.op_web_search_style_cache = getComputedStyle(el.parentNode);
//      el.parentNode.style.display = "inline";
//    }
//    const reg = new RegExp(this.regExpescape(value), "ig");
//    const highlightList = el.data.match(reg); // 得出文本节点匹配到的字符串数组
//    if (!highlightList) return;
//    const splitTextList = el.data.split(reg); // 分割多次匹配
//    const that = this;
//    // 遍历分割的匹配数组，将匹配出的字符串加上.highlight并依次插入DOM, 同时给为匹配的template用于后续恢复
//    el.parentNode.innerHTML = splitTextList.reduce((html, splitText, i) => {
//      const text =
//        html +
//        splitText +
//        (i < splitTextList.length - 1
//          ? `<mark class="op-web-highlight-search" mark-id="${that.markID}">${highlightList[i]}</mark>`
//          : `<template op-web-highlight-search>${el.data}</template>`);
//      if (isSame) that.markID++;
//      return text;
//    }, "");
//  }
//  formatDom(el, value) {
//    const that = this;
//    const childList = el.childNodes;
//    if (!childList.length || !value.length) return; // 无子节点或无查询值，则不进行下列操作
//    childList.forEach((el) => {
//      // 遍历其内子节点
//      if (el.nodeType === 1 || el.nodeType === 3) {
//        // 页面内存在滚动节点的话，需要记录
//        if (this.isRealNode(el)) {
//          if (el.scrollHeight > el.clientHeight) {
//            // 纵向滚动条
//            that.overflowYDom.push(el);
//          }
//          if (el.scrollWidth > el.clientWidth) {
//            // 横向滚动条
//            that.overflowXDom.push(el);
//          }
//        }
//        if (
//          that.isRealNode(el) && // 如果是元素节点
//          that.checkClassName(el, that.blackClassName) &&
//          !/(script|style|template)/i.test(el.tagName)
//        ) {
//          // 并且元素标签不是script或style或template等特殊元素
//          that.formatDom(el, value); // 那么就继续遍历(递归)该元素节点
//        } else if (el.nodeType === 3) {
//          const text = el.data.toLowerCase();
//          if (text.indexOf(value) > -1) {
//            const start = that.searchDom.text.length;
//            const parentText =
//              el.parentNode.innerText || el.parentNode.textContent;
//            that.searchDom.text = that.searchDom.text + parentText;
//            that.searchDom.data[`${start}-${that.searchDom.text.length - 1}`] =
//              el;
//          }
//        }
//      }
//    });
//  }
//
//  parseKeyword(text) {
//    if (text == undefined) return text;
//    return text.trim().toLowerCase();
//  }
//
//  // 重置搜索数据
//  reset(clearIndex = false) {
//    if (clearIndex) {
//      this.searchIndex = -1;
//    }
//    this.count = 0;
//    const dom = document.querySelector(this.domContainer);
//    this.resetMarkDOM(dom);
//    this.domList = [];
//    this.searchDom = {
//      text: "",
//      data: {},
//    };
//    this.markID = 0;
//    this.overflowXDom = [];
//    this.overflowYDom = [];
//  }
//
//  mainSearch(parsedkeyword) {
//    if (parsedkeyword == undefined) return;
//    this.reset(this.keyword !== parsedkeyword);
//    this.keyword = parsedkeyword;
//
//    if (this.keyword.length === 0) {
//      return {
//        index: 0,
//        count: 0,
//      };
//    }
//
//    const dom = document.querySelector(this.domContainer);
//    this.dom = dom;
//
//    // 深度优先处理待搜索的dom
//    this.formatDom(dom, this.keyword);
//
//    // 处理跨标签搜索
//    const poi = this.searchSubStr(this.searchDom.text, this.keyword);
//
//    for (let i = 0; i < poi.length; i++) {
//      const start = poi[i];
//      const end = poi[i] + this.keyword.length - 1;
//      const key = Object.keys(this.searchDom.data);
//      const target = [];
//      for (let j = 0; j < key.length; j++) {
//        const itemPoi = key[j].split("-");
//        // 超过边界直接过滤
//        if (itemPoi[1] < start || itemPoi[0] > end) continue;
//        // 单一标签内
//        if (itemPoi[0] <= start && itemPoi[1] >= end) {
//          target.push(this.searchDom.data[key[j]]);
//          break;
//        }
//        target.push(this.searchDom.data[key[j]]);
//      }
//      if (target.length < 2) {
//        // 只命中一个节点，没有跨标签
//        const el = target[0];
//        this.markDom(el, this.keyword, true);
//      } else {
//        // 合并多个标签的文本，计算起始文本位置和终止文本位置
//        let text = "";
//        let keywordLength = this.keyword.length;
//        target.forEach((item) => {
//          text += item.parentNode.innerText;
//        });
//        let start = text.indexOf(this.keyword);
//        // 开始染色,只需要处理头和尾标签的特殊染色位置，其余的全量染色
//        for (let k = 0; k < target.length; k++) {
//          let text = "";
//          if (k === 0) {
//            // 头部
//            text = target[k].parentNode.innerText.slice(start);
//            keywordLength = keywordLength - text.length;
//            this.markDom(target[k], text, false);
//          } else if (k === target.length - 1) {
//            // 尾部
//            text = target[k].parentNode.innerText.slice(0, keywordLength);
//            this.markDom(target[k], text, false);
//          } else {
//            keywordLength =
//              keywordLength - target[k].parentNode.innerText.length;
//            this.markDom(target[k], target[k].parentNode.innerText, false);
//          }
//        }
//      }
//    }
//
//    this.domList = this.getDomList();
//    this.count = this.domList.length;
//
//    if (!this.firstSearchDone) {
//      this.firstSearchDone = true;
//    }
//    if (this.count === 0) {
//      return {
//        index: 0,
//        count: 0,
//      };
//    }
//  }
//
//  search({ keyword, index = this.searchIndex, resume = false }) {
//    if (this.domContainer == undefined || keyword == undefined) {
//      return {
//        index: 0,
//        count: 0,
//      };
//    }
//
//    this.searchIndex = index;
//
//    const parsedkeyword = this.parseKeyword(keyword);
//    if (!resume && this.keyword === parsedkeyword) {
//      return {
//        index: this.searchIndex + 1,
//        count: this.count,
//      };
//    }
//
//    this.mainSearch(parsedkeyword);
//
//    if (resume) {
//      return {
//        index: 0,
//        count: this.count,
//      };
//    } else {
//      if (this.searchIndex < 0) {
//        this.next({ keyword: parsedkeyword });
//      } else {
//        this.scrollToIndex(this.searchIndex);
//      }
//      return {
//        index: this.searchIndex + 1,
//        count: this.count,
//      };
//    }
//  }
//
//  enterSearch({ keyword, index }) {
//    if (keyword == undefined || index == undefined || !this.firstSearchDone) {
//      return;
//    }
//
//    this.search({ keyword, index: index - 1, resume: true });
//  }
//  exitSearch() {
//    this.reset();
//  }
//
//  confirmSearch({ keyword }) {
//    return this.search({ keyword });
//  }
//
//  // 下一个
//  next({ keyword = this.keyword }) {
//    const parsedkeyword = this.parseKeyword(keyword);
//    if (parsedkeyword !== this.keyword) {
//      this.mainSearch(parsedkeyword);
//    }
//
//    if (this.count === 0) {
//      return {
//        index: 0,
//        count: 0,
//      };
//    }
//
//    ++this.searchIndex;
//    if (this.searchIndex < 0 || this.searchIndex >= this.count) {
//      this.searchIndex = 0;
//      this.cancelHilightForDOM(this.domList[this.domList.length - 1]);
//    }
//    this.cancelHighlight();
//    this.scrollToIndex(this.searchIndex);
//    return {
//      index: this.searchIndex + 1,
//      count: this.count,
//    };
//  }
//  // 上一个
//  pre({ keyword = this.keyword }) {
//    const parsedkeyword = this.parseKeyword(keyword);
//    if (parsedkeyword !== this.keyword) {
//      this.mainSearch(parsedkeyword);
//    }
//
//    if (this.count === 0) {
//      return {
//        index: 0,
//        count: 0,
//      };
//    }
//
//    --this.searchIndex;
//    if (this.searchIndex < 0 || this.searchIndex >= this.count) {
//      this.searchIndex = this.domList.length - 1;
//      this.cancelHilightForDOM(this.domList[0]);
//    }
//    this.cancelHighlight();
//    this.scrollToIndex(this.searchIndex);
//    return {
//      index: this.searchIndex + 1,
//      count: this.count,
//    };
//  }
//  reloadPage({ domContainer = "body", blackClassName = [] }) {
//    this.initializeVar({ domContainer, blackClassName });
//  }
//}
//if (!window.__op_web_highlight_search__) {
//  window.__op_web_highlight_search__ = new OPWebBrowserHighlightSearch({});
//}
//"""
