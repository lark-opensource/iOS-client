//
//  TemplatesPreviewViewController.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/6/18.
//  


import SKFoundation
import SKUIKit
import RxSwift
import Lottie
import UniverseDesignColor
import EENavigator
import UniverseDesignToast
import SKResource
import SpaceInterface

public protocol TemplatePreviewBrowser: UIViewController {
    func templatePreviewBrowserLoad(url: URL)
    func templatePreviewDidClickDone()
    func shouldTemplatePreviewBrowserOpen(url: URL) -> Bool
    var isFromTemplatePreview: Bool { get set }
    var templatesPreviewNavigationBarDelegate: TemplatePreviewNavigationBarProtocol? { get set }
}

public protocol TemplatePreviewNavigationBarProtocol: AnyObject {
    func hideTemplatesPreviewNavigationBar(_ hide: Bool)
    func shouldChangeCompleteButton(visible: Bool)
}

public class TemplatesPreviewViewController: BaseViewController {
    typealias BrowserInfo = (browser: TemplatePreviewBrowser, docsType: DocsType)
    
    /// 这个参数的存在过于久远，写着行代码的人已经找不到了。目前推断是通过向上偏移 44 来隐藏 newBrowser 内的导航栏。
    private static let topOffsetHeightForHideInnerNaviagtionBar: CGFloat = -44
    
    var docsInfo: DocsInfo?

    // 记录原始返回键
    var tempLeadingBarButtonItems: [SKBarButtonItem] = []

    // 记录导航栏是否正在展示done按钮
    var isDoneButtonVisible = false
    
    private var isForceFullScreen: Bool = false

    open override var canShowDoneItem: Bool { // 只有当显示场景为iPhone时，完成按钮显示在左侧，才需要与返回按钮的显示进行兼容
        return isDoneButtonVisible && SKDisplay.phone
    }

    var usingWebviewTitle = false

    var bottomOffset: CGFloat = 0.0 {
        didSet {
            guard let browser = browserInfo?.browser else {
                return
            }
            updateLayout()
        }
    }
        
    var browserInfo: BrowserInfo?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = BundleI18n.SKResource.CreationMobile_Operation_Preview
    }

    @objc
    public override func onDoneBarButtonClick() {
        browserInfo?.browser.templatePreviewDidClickDone()
    }

    func selectTemplate(_ template: TemplateModel) {
        self.openTemplate(template)
        TemplateCenterTracker.clickTemplatePreview(from: .collection)
    }
    
    func queryParamsAppendToURL() -> [String: String] {
        return ["from": "template_preview"]
    }
    
    func openTemplate(_ template: TemplateModel, isNewForm: Bool = false) {
        var url = DocsUrlUtil.url(type: template.docsType, token: template.objToken)
        let params = queryParamsAppendToURL()
        for (key, value) in params where url.queryParameters[key] == nil {
            url = url.append(name: key, value: value)
        }
        if isNewForm {
            url = url.append(name: "larkForm", value: "1")
            url = url.append(name: "isTemplatePreview", value: "true")
        }
        createBrowser(url: url, docsType: template.docsType)
//        guard let (browserVC, docsType) = browserInfo else {
//            createBrowser(url: url, docsType: template.docsType)
//            return
//        }
//        guard let (browserVC, docsType) = browserInfo, docsType != template.docsType else {
//            createBrowser(url: url, docsType: template.docsType)
//            return
//        }
//        browserVC.templatePreviewBrowserLoad(url: url)
    }
    
    private func createBrowser(url: URL, docsType: DocsType) {
        let (browser, _) = SKRouter.shared.open(with: url, params: [WorkspaceCrossRouter.skipRouterKey: true])
        guard let newBrowser = browser as? TemplatePreviewBrowser else { return }
        newBrowser.isFromTemplatePreview = true
        if let oldBrowser = browserInfo?.browser {
            oldBrowser.willMove(toParent: nil)
            oldBrowser.view.snp.removeConstraints()
            oldBrowser.view.removeFromSuperview()
            oldBrowser.removeFromParent()
        }
        addChild(newBrowser)
        view.insertSubview(newBrowser.view, at: 0)
        newBrowser.view.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(view)
            make.top.equalTo(navigationBar.snp.bottom).offset(TemplatesPreviewViewController.topOffsetHeightForHideInnerNaviagtionBar)
            make.bottom.equalToSuperview().offset(-bottomOffset)
        }
        newBrowser.didMove(toParent: self)
        browserInfo = (newBrowser, docsType)
        
        newBrowser.templatesPreviewNavigationBarDelegate = self
        
        if docsType == .bitable {
            forceFullScreen()
        } else {
            cancelForceFullScreen()
        }
    }
    public func forceFullScreen() {
        isForceFullScreen = true
        navigationBar.alpha = 0 // 文档容器下可能会有N个导航栏叠在一起
        statusBar.snp.remakeConstraints { it in
            it.top.leading.trailing.equalToSuperview()
            it.height.equalTo(0)
        }
        statusBar.isHidden = true
        updateLayout()
    }
    public func cancelForceFullScreen() {
        if browserInfo?.docsType == .bitable {
            // 新版必须 fullScreen
            return
        }
        isForceFullScreen = false
        navigationBar.alpha = 1 // 文档容器下可能会有N个导航栏叠在一起
        statusBar.snp.remakeConstraints { it in
            it.top.leading.trailing.equalToSuperview()
        }
        statusBar.isHidden = false
        updateLayout()
    }
    
    private func updateLayout() {
        guard browserInfo?.browser.view.superview != nil else {
            return
        }
        let navigationBarHidden = self.navigationBar.isHidden
        let isForceFullScreen = self.isForceFullScreen
        browserInfo?.browser.view.snp.remakeConstraints({ make in
            make.leading.trailing.equalTo(view)
            if isForceFullScreen {
                make.top.equalToSuperview()
            } else if navigationBarHidden {
                make.top.equalTo(navigationBar.snp.bottom)
            } else {
                make.top.equalTo(navigationBar.snp.bottom).offset(TemplatesPreviewViewController.topOffsetHeightForHideInnerNaviagtionBar)
            }
            make.bottom.equalToSuperview().offset(-bottomOffset)
        })
    }
}

extension TemplatesPreviewViewController: TemplatePreviewNavigationBarProtocol {

    public func shouldChangeCompleteButton(visible: Bool) {
        isDoneButtonVisible = visible
        if SKDisplay.pad {
            var itemComponents: [SKBarButtonItem] = navigationBar.temporaryTrailingBarButtonItems
            if visible, !itemComponents.contains(doneButtonItem) {
                itemComponents.insert(doneButtonItem, at: 0)
            } else if !visible, itemComponents.contains(doneButtonItem) {
                itemComponents = itemComponents.filter { $0 != doneButtonItem }
            }
            navigationBar.temporaryTrailingBarButtonItems = itemComponents
        } else {
            if visible {
                if tempLeadingBarButtonItems.isEmpty {
                    tempLeadingBarButtonItems = navigationBar.leadingBarButtonItems
                }
                navigationBar.leadingBarButtonItems = [doneButtonItem]
            } else {
                if !tempLeadingBarButtonItems.isEmpty {
                    navigationBar.leadingBarButtonItems = tempLeadingBarButtonItems
                }
            }
        }
    }
    
    public func hideTemplatesPreviewNavigationBar(_ hide: Bool) {
        self.navigationBar.isHidden = hide
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        updateLayout()
    }
}
