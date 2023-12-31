//
//  TemplateDocsCreateViewController.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/6/9.
//  


import SKFoundation
import SKUIKit
import SKResource
import Lottie
import UniverseDesignColor
import UniverseDesignToast
import SpaceInterface
import SKInfra
import LarkTab
import LarkContainer
import LarkQuickLaunchInterface

public final class TemplateDocsCreateViewController: BaseViewController {
    private let templateToken: String?
    private let templateId: String?
    private let docsType: DocsType?
    private let clickFrom: String?
    private var networkRequest: DocsRequest<TemplateCreateDocsResult>?
    private weak var docTab: TabContainable?
    @InjectedSafeLazy private var temporaryTabService: TemporaryTabService
    private lazy var defaultLoadingView: DocsLoadingViewProtocol = {
        DocsContainer.shared.resolve(DocsLoadingViewProtocol.self)!
    }()
    public init(templateToken: String?, templateId: String?, docsType: DocsType?, clickFrom: String?) {
        self.templateToken = templateToken
        self.templateId = templateId
        self.docsType = docsType
        self.clickFrom = clickFrom
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(defaultLoadingView.displayContent)
        defaultLoadingView.displayContent.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        createDocs()
    }
    
    private func createDocs() {
        defaultLoadingView.startAnimation()
        if let id = templateId {
            self.networkRequest = DocsRequestCenter.createBy(templateId: id, in: "", from: self, completion: { [weak self] result, error in
                guard let self = self else { return }
                self.defaultLoadingView.stopAnimation()
                self.defaultLoadingView.displayContent.isHidden = true
                guard let objToken = result?.objToken, let objType = result?.objType else {
                    if let error = error {
                        DocsLogger.error("根据模版创建文档失败", error: error)
                        let message: String
                        if let docsError = error as? DocsNetworkError {
                            message = docsError.code.templateErrorMsg()
                        } else {
                            message = BundleI18n.SKResource.Doc_List_TemplateGeneralErrorToast
                        }
                        QuotaAlertPresentor.shared.showQuotaAlertIfNeed(
                            type: .createByTemplate,
                            defaultToast: message,
                            error: error,
                            from: self,
                            token: ""
                        )
                    }
                    return
                }
                self.openDocsBy(objToken: objToken, type: DocsType(rawValue: objType), templateToken: result?.templateToken)
            })
        } else if let token = templateToken, let docsType = docsType {
            let params = ["token": token]
            self.networkRequest = DocsRequestCenter.createByTemplate(type: docsType, in: nil, parameters: params, from: self, completion: { [weak self] result, error in
                guard let self = self else { return }
                self.defaultLoadingView.stopAnimation()
                self.defaultLoadingView.displayContent.isHidden = true
                guard let objToken = result?.objToken, let objType = result?.objType else {
                    if let error = error {
                        DocsLogger.error("根据模版创建文档失败", error: error)
                        let message: String
                        if let docsError = error as? DocsNetworkError {
                            message = docsError.code.templateErrorMsg()
                        } else {
                            message = BundleI18n.SKResource.Doc_List_TemplateGeneralErrorToast
                        }
                        QuotaAlertPresentor.shared.showQuotaAlertIfNeed(
                            type: .createByTemplate,
                            defaultToast: message,
                            error: error,
                            from: self,
                            token: token
                        )
                    }
                    return
                }
                self.openDocsBy(objToken: objToken, type: DocsType(rawValue: objType), templateToken: token)
            })
        }
        
    }
    private func openDocsBy(objToken: String, type: DocsType, templateToken: String?) {
        let url = DocsUrlUtil.url(type: type, token: objToken)
        let (vc, _) = SKRouter.shared.open(with: url)
        if let browser = vc {
            self.addChild(browser)
            self.view.addSubview(browser.view)
            browser.view.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            browser.didMove(toParent: self)
            docTab = browser as? TabContainable
            temporaryTabService.updateTab(self)
        }
        
        var extra: [String: Any] = [:]
        if let clickFrom = self.clickFrom {
            extra["template_createfromsource"] = clickFrom
        }
        if let templateToken = templateToken {
            extra["token"] = templateToken
            extra[DocsTracker.Params.nonSensitiveToken] = true
        }
        if let templateId = templateId {
            extra["template_id"] = templateId
        }
        SKCreateTracker.reportCreateNewObj(type: type,
                                           token: objToken,
                                           source: nil,
                                           templateCenterSource: nil,
                                           error: nil,
                                           moduleInfo: nil,
                                           templateInfos: nil,
                                           extra: extra)
    }
}

extension TemplateDocsCreateViewController: TabContainable {
    
    public var tabID: String {
        "\(templateToken ?? "")_\(templateId ?? "")_\(clickFrom ?? "")"
    }
    
    public var tabBizID: String {
        ""
    }
    
    public var tabBizType: CustomBizType {
        return .CCM
    }
    
    public var tabIcon: LarkTab.CustomTabIcon {
        if let icon = docTab?.tabIcon {
            return icon
        } else {
            let type = docsType ?? .docX
            return .iconName(type.squareColorfulIconKey)
        }
    }
    
    public var tabTitle: String {
        docTab?.tabTitle ?? DocsType.docX.i18Name
    }
    
    public var tabURL: String {
        docTab?.tabURL ?? ""
    }
    
    public var tabAnalyticsTypeName: String {
        "template"
    }

    public var forceRefresh: Bool {
        if docTab != nil {
            //文档创建完后，不保活，退出标签页后该控制器会被销毁，再次点击标签会使用tabURL里的文档链接走文档路由
            return true
        } else {
            //文档创建成功前，保活，避免退出后创建失败
            return false
        }
    }
    
}
