//
//  WAContainerViewController.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/14.
//

import Foundation
import WebKit
import LarkWebViewContainer
import LarkUIKit
import LKCommonsLogging
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignLoading
import UniverseDesignEmpty
import SKUIKit
import SKResource
import LarkContainer

public class WAContainerViewController: BaseUIViewController {
    static let logger = Logger.log(WAContainerViewController.self, category: WALogger.TAG)
    
    // -------- View --------
    let contentView: WAContainerView
    lazy var titleNaviBar: WATitleNaviBar = WATitleNaviBar()
    var hasSetCustomTitleBar: Bool = false
    
    private(set) lazy var emptyView: WAEmptyView = {
        let view = WAEmptyView()
        view.isHidden = true
        return view
    }()

    
    // -------- Data --------
    let urlString: String
    var viewModel: WAContainerViewModel {
        contentView.viewModel
    }
    // -------- Container -----------
    let userResolver: UserResolver
    
    public required init(urlString: String, config: WebAppConfig, userResolver: UserResolver) {
        self.urlString = urlString
        self.contentView = ContainerCreator.createContainerView(config: config,
                                                                userResolver: userResolver,
                                                                frame: .zero)
        self.userResolver = userResolver
        
        super.init(nibName: nil, bundle: nil)
        Self.logger.info("webappvc create", tag: LogTag.open.rawValue)
        self.contentView.attachToVC(self)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        Self.logger.info("webappvc deinit,\(urlString)", tag: LogTag.open.rawValue)
        self.contentView.dettachFromVC()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        if let loadeStatus = viewModel.loader?.loadStatus, loadeStatus.isLoading {
            self.onLoadStatusChange(old: .start, new: loadeStatus)
        }
        viewModel.load(urlString: self.urlString)
    }
    
    func setup() {
        defer { view.bringSubviewToFront(self.titleNaviBar) }
        setupTitleBar()
        self.view.addSubview(self.contentView)
        self.contentView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(titleNaviBar.snp.bottom)
        }
        
        self.view.addSubview(self.emptyView)
        self.emptyView.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }
    }
    
    func setupTitleBar() {
        self.isNavigationBarHidden = true
        view.addSubview(titleNaviBar)
        titleNaviBar.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview()
        }
        titleNaviBar.setup()
        titleNaviBar.navigationBar.leadingBarButtonItems = [SKBarButtonItem(image: UDIcon.leftOutlined, style: .plain, target: self, action: #selector(onBackItemClick))]
    }
    
    @objc
    func onBackItemClick() {
        back()
    }
}

extension WAContainerViewController {
    func back() {
        if let navigationController = self.navigationController {
            let didPop: Bool
            let popedvc = navigationController.popViewController(animated: true)
            didPop = (popedvc != nil)
            
            if didPop == false, self.presentingViewController != nil {
                dismiss(animated: true, completion: nil)
            }
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}

