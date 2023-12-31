//
//  HomeActivityController.swift
//  SKSpace
//
//  Created by yinyuan on 2023/4/18.
//

import UIKit
import LarkUIKit
import SKCommon
import UniverseDesignColor
import SKFoundation
import SKResource
import EENavigator
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignEmpty
import LarkContainer

class HomeActivityController: BaseUIViewController {
    
    private let context: BaseHomeContext
    
    private lazy var emptyView: UDEmptyView = {
        let config = UDEmptyConfig(type: .custom(EmptyBundleResources.image(named: "emptyPositiveActivityAction1")))
        let empty = UDEmptyView(config: config)
        empty.isHidden = true
        return empty
    }()
    
    private lazy var activityView: ActivityTableView = {
        let view = ActivityTableView(context: self.context)
        return view
    }()
    
    private lazy var titleView: UIView = {
        let titleLabel = UILabel()
        titleLabel.text = BundleI18n.SKResource.Bitable_Workspace_Activities_Tab
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = UDColor.textTitle
        
        let infoView = UIButton()
        infoView.setImage(UDIcon.infoOutlined.withRenderingMode(.alwaysTemplate), for: [.normal])
        infoView.tintColor = UDColor.iconN3
        infoView.contentMode = .scaleAspectFit
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 44))
        view.addSubview(titleLabel)
        view.addSubview(infoView)
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20 + 6)
            make.height.equalTo(28)
            make.centerY.equalToSuperview()
            make.right.equalTo(infoView.snp.left).offset(-6)
            make.top.bottom.equalToSuperview()
        }
        
        infoView.hitTestEdgeInsets = .init(horizontal: -4, vertical: -4)
        infoView.isUserInteractionEnabled = true
        infoView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        infoView.addTarget(self, action: #selector(infoViewClick), for: .touchUpInside)
        
        return view
    }()
    
    let userResolver: UserResolver
    init(userResolver: UserResolver, context: BaseHomeContext) {
        self.userResolver = userResolver
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func infoViewClick() {
        UDToast.showTips(with: BundleI18n.SKResource.Bitable_Workspace_Activities_Tooltip, on: self.view)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UDColor.bgBody
        
        view.addSubview(emptyView)
        view.addSubview(activityView)
        
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        activityView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.title = BundleI18n.SKResource.Bitable_Workspace_Activities_Tab
        
        if UserScopeNoChangeFG.YY.bitableTabActivityTipsEnable {
            // 设置自定义视图为导航栏的 titleView
            navigationItem.titleView = titleView
        }
        
        DocsTracker.reportBitableHomePageEvent(enumEvent: .baseHomepageActivityView, parameters: [
            "current_sub_view": "activity_all"
        ], context: context)
    }
    
    func update(data: [HomePageData], activityEmptyConfig: ActivityEmptyConfig?, delegate: ActivityCellDelegate? = nil, selectedItem: HomePageData? = nil) {
        activityView.update(data: data, delegate: delegate, selectedItem: selectedItem)
        
        if !UserScopeNoChangeFG.YY.bitableActivityNewDisable {
            emptyView.isHidden = !data.isEmpty
            activityView.isHidden = data.isEmpty
            
            if !emptyView.isHidden {
                var config = UDEmptyConfig(type: .custom(EmptyBundleResources.image(named: "emptyPositiveActivityAction1")))
                config.title = .init(titleText: activityEmptyConfig?.title ?? BundleI18n.SKResource.Bitable_Workspace_Mobile_NoRecentActivity_Title)
                config.description = .init(descriptionText: activityEmptyConfig?.desc ?? BundleI18n.SKResource.Bitable_Workspace_Mobile_NoRecentActivity_Desc)
                if let buttonUrl = activityEmptyConfig?.buttonUrl, let button = activityEmptyConfig?.button, let url = URL(string: buttonUrl) {
                    config.primaryButtonConfig = (button, { [weak self] (_) in
                        guard let self = self else {
                            DocsLogger.error("self is nil")
                            return
                        }
                        DocsLogger.info("tap empty button")
                        self.userResolver.navigator.push(url, from: self)
                    })
                }
                emptyView.update(config: config)
            }
        }
    }
    
}
extension HomeActivityController: ActivityCellDelegate {
    func profileClick(data: HomePageData?) {
        if let userID = data?.noticeInfo?.fromUser?.userID {
            let profileService = ShowUserProfileService(userId: userID, fromVC: self)
            HostAppBridge.shared.call(profileService)
        }
    }
}
