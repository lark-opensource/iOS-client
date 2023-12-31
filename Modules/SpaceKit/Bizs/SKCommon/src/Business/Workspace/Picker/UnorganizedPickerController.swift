//
//  UnorganizedPickerController.swift
//  SKCommon
//
//  Created by majie.7 on 2023/6/29.
//

import Foundation
import SKUIKit
import UniverseDesignEmpty
import UniverseDesignColor
import EENavigator
import SKResource
import SpaceInterface
import SKInfra
import LarkContainer
import SKFoundation

public class UnorganizedPickerController: BaseViewController {
    
    private lazy var emptyBackgroudView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var emptyView: UDEmpty = {
        let config = UDEmptyConfig(title: nil,
                                   description: .init(descriptionText: BundleI18n.SKResource.LarkCCM_NewCM_MoveToUnsortedFolder_Tooltip,
                                                      font: UIFont.systemFont(ofSize: 14)),
                                   type: .custom(EmptyBundleResources.image(named: "imEmptyNeutralDrag")))
        let view = UDEmpty(config: config)
        return view
    }()
    
    private lazy var searchBar: DocsSearchBar = {
        let bar = DocsSearchBar()
        bar.tapBlock = { [weak self] _ in self?.didClickSearchBar() }
        return bar
    }()
    
    private lazy var btnBackView: UIView = {
        let v = UIView()
        return v
    }()
    
    private lazy var actionButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setTitle(config.actionName, for: .normal)
        button.addTarget(self, action: #selector(didClickActionButton), for: .touchUpInside)
        button.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        button.backgroundColor = UDColor.primaryContentDefault
        button.layer.cornerRadius = 6
        button.docs.addStandardLift()
        return button
    }()
    
    private let config: WorkspacePickerConfig
    
    public init(config: WorkspacePickerConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        navigationBar.title = BundleI18n.SKResource.LarkCCM_NewCM_Unsorted_NavigationMenu
        
        view.addSubview(searchBar)
        view.addSubview(btnBackView)
        view.addSubview(emptyBackgroudView)
        emptyBackgroudView.addSubview(emptyView)
        btnBackView.addSubview(actionButton)
        
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(6)
            make.height.equalTo(32)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        btnBackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(80)
        }
        
        emptyBackgroudView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(6)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(btnBackView.snp.top)
        }
        
        emptyView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        actionButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.height.equalTo(44.0)
        }
    }
    
    
    
    private func didClickSearchBar() {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        guard let factory = try? userResolver.resolve(assert: WorkspaceSearchFactory.self) else {
            DocsLogger.error("can not get WorkspaceSearchFactory")
            return
        }

        let vc = factory.createWikiAndFolderSearchController(config: config)
        Navigator.shared.push(vc, from: self)
    }
    
    @objc
    private func didClickActionButton() {
        config.completion(.folder(location: .init(folderToken: "",
                                                  folderType: .v2Common,
                                                  isExternal: false,
                                                  canCreateSubNode: true,
                                                  targetModule: .space,
                                                  targetFolderType: .folder)
                                  ), self)
    }
}
