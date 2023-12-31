//
//  WorkplacePreviewController.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/10/11.
//

import UIKit
import LarkUIKit
import SnapKit
import UniverseDesignNotice
import RxSwift
import EENavigator
import LKCommonsLogging
import LarkNavigation
import LarkContainer
import LarkNavigator

final class WorkplacePreviewController: BaseUIViewController, UserResolverWrapper {
    static let logger = Logger.log(WorkplacePreviewController.self)

    public var userResolver: LarkContainer.UserResolver

    /// state view 需要整理
    private lazy var _stateView: WPPageStateView = { buildStateView() }()
    var stateView: WPPageStateView {
        view.bringSubviewToFront(_stateView)
        return _stateView
    }

    lazy var noticeView: UDNotice = { buildNoticeView() }()
    lazy var naviBar: NaviBarProtocol = { buildNaviBar() }()
    let contentView = UIView(frame: .zero)
    var templateVC: WPHomeContainerVC?

    var contentSuperTopConstraint: Constraint?
    var contentTopConstraint: Constraint?
    var contentWidthConstraint: Constraint?
    var contentSuperWidthConstraint: Constraint?

    let userId: String
    let tenantId: String
    let navigator: UserNavigator
    let viewModel: WorkplacePreviewViewModel
    let navigationService: NavigationService
    let traceService: WPTraceService

    let disposeBag = DisposeBag()

    init(
        userResolver: UserResolver,
        userId: String,
        tenantId: String,
        navigator: UserNavigator,
        viewModel: WorkplacePreviewViewModel,
        navigationService: NavigationService,
        traceService: WPTraceService
    ) {
        self.userResolver = userResolver
        self.userId = userId
        self.tenantId = tenantId
        self.navigator = navigator
        self.viewModel = viewModel
        self.navigationService = navigationService
        self.traceService = traceService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindEvent()

        viewModel.reloadPreviewData()
    }

    override func closeBtnTapped() {
        Self.logger.info("did click close button")
        // ipad下，如果是唯一一个VC，则展示Default来关闭VC
        if Display.pad, navigationController?.viewControllers.first == self {
            navigator.showDetail(DefaultDetailController(), from: self)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
}
