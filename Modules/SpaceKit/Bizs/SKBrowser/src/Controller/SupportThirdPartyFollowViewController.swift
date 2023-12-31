//
//  SupportThirdPartyFollowViewController.swift
//  SpaceKit
//
//  Created by 吴珂 on 2020/4/12.
//  


import Foundation
import SKCommon
import SpaceInterface

class SupportThirdPartyFollowViewController: BaseViewController {
    lazy var browserView: SupportThirdPartyFollowBrowserView = {
        return  SupportThirdPartyFollowBrowserView(frame: .zero)
    }()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(browserView)
        
        browserView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarHidden(true, animated: false)
    }
    
    func injectJavascript(_ script: String) {
        browserView.injectUserscript(script)
    }
    
    func openUrl(_ url: String) {
        browserView.openUrl(url)
    }
    
    func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {
        browserView.callFunction(function, params: params, completion: completion)
    }
}

extension SupportThirdPartyFollowViewController: FollowableViewController {

    var isEditingStatus: Bool {
        return browserView.webView.isFirstResponder
    }

    var followTitle: String {
        return ""
    }
    
    var followScrollView: UIScrollView? {
        return browserView.webView.scrollView
    }
    
    func onSetup(followAPIDelegate: SpaceFollowAPIDelegate) {
        browserView.spaceFollowAPIDelegate = followAPIDelegate
    }
    
    func refreshFollow() {
//        browserView.reload()   //改由RN刷新了
    }

    func injectJS(_ script: String) {
        var injectScript = script
        if let token = browserView.spaceFollowAPIDelegate?.token {
            injectScript = "try{window.vcData = {token: '\(token)'};}catch(e){};\(script)" //googledoc手动注入token
        }
        injectJavascript(injectScript)
    }
    
}
