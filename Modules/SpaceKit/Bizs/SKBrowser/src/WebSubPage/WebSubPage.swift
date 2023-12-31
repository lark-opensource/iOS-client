import WebKit
import SKCommon
import SKFoundation
import SKUIKit
import SnapKit
import EENavigator
import UniverseDesignColor
import LarkWebViewContainer
import LarkUIKit

class WebSubPageWeakHolder {
    private(set) weak var subPage: WebSubPage?
    
    init(_ subPage: WebSubPage) {
        self.subPage = subPage
    }
}

protocol WebSubPage: AnyObject {
    var webView: WKWebView { get }
    func webViewDidClose(_ webView: WKWebView)
}

class WebSubPageViewController: DraggableViewController, WKUIDelegate, UIViewControllerTransitioningDelegate, WebSubPage {
    
    let subPageModel: SubPageModel
    
    let configuration: WKWebViewConfiguration
    
    // swiftlint:disable ImplicitlyUnwrappedOptionalRule
    lazy var webView = WebBrowserView.makeDefaultWebView(
        webViewConfiguration: configuration,
        bizType: LarkWebViewBizType("webSubPage"),
        disableClearBridgeContext: true
    ) as WKWebView
    
    private var titleObservation: NSKeyValueObservation?
    
    lazy var titleView = SKDraggableTitleView().construct({
        
        $0.backgroundColor = UDColor.bgFloatBase
        $0.leftButton.addTarget(self, action: #selector(leftButtonClick), for: .touchUpInside)
        
        $0.layer.cornerRadius = 12
        $0.layer.maskedCorners = .top
        $0.layer.masksToBounds = true
        
        if subPageModel.canDrag {
            $0.leftButton.isHidden = true
            
            $0.addGestureRecognizer(panGestureRecognizer)
        } else {
            $0.topLine.isHidden = true
        }
        
        if let initTitle = subPageModel.pageStyle.navigationbarInfo?.initTitle {
            $0.titleLabel.text = initTitle
        }
    })
    
    lazy var topLine: UIView = {
        let view = UIView()
        
        let line = UIView()
        line.backgroundColor = UDColor.lineBorderCard
        line.layer.cornerRadius = 2
        line.docs.addStandardLift()
        
        view.addSubview(line)
        line.snp.makeConstraints { make in
            make.bottom.centerX.equalToSuperview()
            make.height.equalTo(4)
            make.width.equalTo(40)
        }
        
        view.addGestureRecognizer(panGestureRecognizer)
        
        return view
    }()
    
    init(
        subPageModel: SubPageModel,
        configuration: WKWebViewConfiguration
    ) {
        self.subPageModel = subPageModel
        self.configuration = configuration
        
        super.init(nibName: nil, bundle: nil)
        if SKDisplay.pad {
            modalPresentationStyle = .formSheet
        } else {
            modalPresentationStyle = .overCurrentContext
            transitioningDelegate = self
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.scrollView.backgroundColor = UDColor.bgFloatBase
        
        if !subPageModel.canDrag {
            disableDrag = true
        }
        
        addGestureRecognizer()
        
        webView.uiDelegate = self
        
        if subPageModel.canDrag, let dragModel = subPageModel.pageStyle.dragParams {
            if let maxHeight = dragModel.maxHeight, let minHeight = dragModel.minHeight {
                contentViewMaxY = view.frame.height - view.frame.height * minHeight
                contentViewMinY = view.frame.height - view.frame.height * maxHeight
            }
        }
        
        contentView = UIView().construct({
            $0.backgroundColor = UIColor.ud.bgBody
            $0.layer.cornerRadius = 12
            $0.layer.maskedCorners = .top
            $0.layer.masksToBounds = true
            $0.layer.ud.setShadowColor(UDColor.shadowDefaultLg)
            $0.layer.shadowOpacity = 1
            $0.layer.shadowRadius = 24
            $0.layer.shadowOffset = CGSize(width: 0, height: -6)
        })
        
        view.addSubview(contentView)
        
        if subPageModel.showNavigationBar {
            contentView.addSubview(titleView)
            contentView.addSubview(webView)
        } else {
            contentView.addSubview(webView)
        }
        
        contentView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            if SKDisplay.pad {
                make.top.equalToSuperview()
            } else {
                if subPageModel.canDrag {
                    make.top.equalTo(contentViewMinY)
                } else {
                    if let pageHeight = subPageModel.pageStyle.pageHeight {
                        make.height.equalTo(view.frame.height * pageHeight)
                    } else {
                        make.top.equalTo(contentViewMinY)
                    }
                }
            }
            make.bottom.equalToSuperview()
        }
        
        if subPageModel.showNavigationBar {
            titleView.snp.makeConstraints { (make) in
                make.left.top.right.equalToSuperview()
                make.height.equalTo(60)
            }
        }
        
        webView.snp.makeConstraints { make in
            if subPageModel.showNavigationBar {
                make.top.equalTo(titleView.snp.bottom)
            } else {
                make.top.equalToSuperview()
            }
            
            make.bottom.left.right.equalToSuperview()
        }
        
        if subPageModel.showNavigationBar {
            titleObservation = webView
                .observe(
                    \.title,
                     options: [.old, .new],
                     changeHandler: { [weak self] (_, change) in
                         guard let `self` = self else { return }
                         var title = ""
                         if let newTitlt = change.newValue, let t = newTitlt {
                             title = t
                         }
                         self.titleView.titleLabel.text = title
                     }
                )
        }
        
        if subPageModel.canDrag, !subPageModel.showNavigationBar {
            contentView.addSubview(topLine)
            topLine.snp.makeConstraints { (make) in
                make.top.equalToSuperview().inset(6)
                make.centerX.equalToSuperview()
                make.height.equalTo(8)
                make.left.right.equalToSuperview()
            }
        }
    }
    
    @objc func leftButtonClick() {
        dismiss(animated: true, completion: nil)
    }
    
    override func dragDismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        dismiss(animated: true, completion: nil)
    }
    
    private func addGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapDimiss))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc
    private func onTapDimiss() {
        dismiss(animated: true, completion: nil)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DimmingPresentAnimation(animateDuration: 0.15, layerAnimationOnly: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DimmingDismissAnimation(animateDuration: 0.15, layerAnimationOnly: true)
    }
}

class WebPageViewController: BaseUIViewController, WKUIDelegate, WebSubPage {
    
    let subPageModel: SubPageModel
    
    let configuration: WKWebViewConfiguration
    
    // swiftlint:disable ImplicitlyUnwrappedOptionalRule
    lazy var webView = WebBrowserView.makeDefaultWebView(
        webViewConfiguration: configuration,
        bizType: LarkWebViewBizType("webSubPage"),
        disableClearBridgeContext: true
    ) as WKWebView
    
    private var titleObservation: NSKeyValueObservation?
    
    override var navigationBarStyle: NavigationBarStyle {
//        if let backgroundColor = subPageModel.pageStyle.navigationbarInfo?.backgroundColor {
//           return .custom(UIColor.docs.rgb(backgroundColor))
//        }
//        return .default
        return .custom(UDColor.bgBase)
    }
    
    init(
        subPageModel: SubPageModel,
        configuration: WKWebViewConfiguration
    ) {
        self.subPageModel = subPageModel
        self.configuration = configuration
        
        super.init(nibName: nil, bundle: nil)
        if SKDisplay.pad {
            modalPresentationStyle = .formSheet
        } else {
            modalPresentationStyle = .overCurrentContext
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        if let backgroundColor = subPageModel.pageStyle.backgroundColor {
//            webView.scrollView.backgroundColor = UIColor.docs.rgb(backgroundColor)
//        }
        
        webView.scrollView.backgroundColor = UDColor.bgBase
        
        if subPageModel.pageStyle.bounces == true {
            webView.scrollView.bounces = true
        }
        
        self.title = subPageModel.pageStyle.navigationbarInfo?.initTitle
        
        webView.uiDelegate = self
        
        view.addSubview(webView)
        
        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        if subPageModel.showNavigationBar {
            titleObservation = webView
                .observe(
                    \.title,
                     options: [.old, .new],
                     changeHandler: { [weak self] (_, change) in
                         guard let `self` = self else { return }
                         var title = ""
                         if let newTitlt = change.newValue, let t = newTitlt {
                             title = t
                         }
                         self.title = title
                     }
                )
        }
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        DocsLogger.info("webViewDidClose")
        close()
    }
    
    private func close() {
        if Display.pad {
            self.navigationController?.dismiss(animated: true)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func backItemTapped() {
        DocsLogger.info("backItemTapped")
        webView.evaluateJavaScript("window.lark.biz.webSubPage.onBackPress()") { (result, error) in
            guard error == nil else {
                DocsLogger.error("evaluate js failed", error: error)
                self.close()
                return
            }
            guard let res = result as? [String: Any] else {
                DocsLogger.error("result invalid")
                self.close()
                return
            }
            let resultHandled = "handled"   // 已被前端处理
            if let result = res["result"] as? String, result == resultHandled {
                // 被前端处理
                DocsLogger.info("backItemTapped handled by web")
                return
            }
            DocsLogger.info("backItemTapped close res:\(res)")
            self.close()
        }
    }
    
}
