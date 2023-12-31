//
//  BTFieldGroupingAnimateViewController.swift
//  SKBitable
//
//  Created by zoujie on 2022/3/15.
//  


import Foundation
import SKCommon
import SKResource
import SKBrowser
import LarkUIKit
import SKUIKit
import SKFoundation
import UniverseDesignColor
import UniverseDesignIcon
import EENavigator
import UIKit

enum BTFieldGroupingViewType: Int {
    case GROUP_RESULT_VIEW = 1
    case TYPE_SET_VIEW = 2
    case TOTAL_STATISTICS_VIEW = 3
}

extension BTGroupStatPanelType {
    var title: String {
        switch self {
        case .group:
            return BundleI18n.SKResource.Bitable_Field_StatsByGroup
        case .total:
            return BundleI18n.SKResource.Bitable_Mobile_CardMode_RecordSummary_Button
        }
    }
}

protocol BTFieldGroupingAnimateViewControllerDelegate: AnyObject {
    func didOpenFieldGroupingView(groupingStatisticsModel: BTGroupingStatisticsModel)
}

final class BTFieldGroupingAnimateViewController: BTDraggableViewController {
    private var isFirstOpen = true
    private var groupingStatisticsModel: BTGroupingStatisticsModel
    private weak var hostVC: UIViewController?
    weak var delegate: BTFieldGroupingAnimateViewControllerDelegate?
    weak var dataService: BTDataService?
    private var groupViewVC: BTFieldGroupingViewController?
    private var reportCommonParams: [String: Any]
    var openPanelAction: BTGroupingActionTask?

    private lazy var viewCapturePreventer: ViewCapturePreventable = {
        let preventer = ViewCapturePreventer()
        preventer.notifyContainer = []
        return preventer
    }()
    
    let baseContext: BaseContext
    private let basePermissionHelper: BasePermissionHelper
    
    init(groupingStatisticsModel: BTGroupingStatisticsModel,
         reportCommonParams: [String: Any],
         openPanelAction: BTGroupingActionTask,
         hostVC: UIViewController?,
         baseContext: BaseContext,
         dataService: BTDataService?) {
        self.hostVC = hostVC
        self.openPanelAction = openPanelAction
        self.reportCommonParams = reportCommonParams
        self.groupingStatisticsModel = groupingStatisticsModel
        self.baseContext = baseContext
        self.dataService = dataService
        self.openPanelAction = openPanelAction
        self.basePermissionHelper = BasePermissionHelper(baseContext: baseContext)
        super.init(title: groupingStatisticsModel.panelType.title, shouldShowDragBar: true)

        self.groupViewVC = BTFieldGroupingViewController(groupingStatisticsModel: groupingStatisticsModel,
                                                         openPanelAction: openPanelAction,
                                                         reportCommonParams: reportCommonParams,
                                                         hostVC: hostVC,
                                                         delegate: self,
                                                         dataService: dataService)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var minViewHeight: CGFloat {
        SKDisplay.windowBounds(self.view).height * 0.45
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        basePermissionHelper.startObserve(observer: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstOpen {
            delegate?.didOpenFieldGroupingView(groupingStatisticsModel: groupingStatisticsModel)
        }
        isFirstOpen = false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return [.allButUpsideDown]
    }

    override func setupUI() {
        initViewHeight = minViewHeight
        super.setupUI()
        guard let groupViewVC = self.groupViewVC else { return }
        self.addChild(groupViewVC)
        
        let container: UIView
        if ViewCapturePreventer.isFeatureEnable {
            container = viewCapturePreventer.contentView
            contentView.addSubview(container)
            container.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        } else {
            container = contentView
        }
        container.addSubview(groupViewVC.view)
        
        groupViewVC.didMove(toParent: self)

        groupViewVC.view.snp.makeConstraints { make in
            make.edges.equalTo(contentView.safeAreaLayoutGuide)
        }

        self.navigationController?.navigationBar.isHidden = true
        containerView.backgroundColor = UDColor.bgFloatBase
        groupViewVC.view.backgroundColor = .clear
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard !isFirstOpen, #available(iOS 13.0, *) else { return }
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        guard UIApplication.shared.applicationState != .background else { return }
        DocsLogger.info("userInterfaceStyle changed close page")
        self.dismiss(animated: true)
    }

    func updateData(groupingStatisticsModel: BTGroupingStatisticsModel) {
        guard let groupViewVC = self.groupViewVC else { return }
        self.groupingStatisticsModel = groupingStatisticsModel
        groupViewVC.updateGroupData(data: groupingStatisticsModel)
    }

    func updateGroupObtainData(groupingStatisticsObtainData: BTGroupingStatisticsObtainGroupData) {
        guard let groupViewVC = self.groupViewVC else { return }
        groupViewVC.sentEvent(event: "ccm-send-obtainData", params: groupingStatisticsObtainData.toJSON())
    }
}

extension BTFieldGroupingAnimateViewController: BTFieldGroupingViewControllerDelegate {
    func didClickClosePage() {
        self.dismiss(animated: true)
    }
}

extension BTFieldGroupingAnimateViewController {
    func setCaptureAllowed(_ allow: Bool) {
        viewCapturePreventer.isCaptureAllowed = allow
    }
}

extension BTFieldGroupingAnimateViewController: BasePermissionObserver {
    func initOrUpdateCapturePermission(hasCapturePermission: Bool) {
        DocsLogger.info("[BasePermission] BTFieldGroupingAnimateViewController initOrUpdateCapturePermission \(hasCapturePermission)")
        setCaptureAllowed(hasCapturePermission)
    }
}

