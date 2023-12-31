//
//  SIPDialAggViewController.swift
//  ByteView
//
//  Created by admin on 2022/5/27.
//

import UIKit
import ByteViewUI
import UniverseDesignColor
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker
import LarkSegmentedView
import SnapKit
import RxSwift
import RxCocoa

class SIPDialAggViewController: VMViewController<SIPDialViewModel> {

    enum ListType: String {
        case dialIn
        case dialOut

        var defaultTitle: String {
            switch self {
            case .dialIn:
                return I18n.View_M_DialIn
            case .dialOut:
                return I18n.View_M_DialOut
            }
        }
    }

    let segmentedTypes: [ListType] = [.dialIn, .dialOut]
    lazy var subviewControllers: [JXSegmentedListContainerViewListDelegate] = {
        let dialInVC = SIPDialInViewController(viewModel: self.viewModel)
        let inviteVM = SIPInviteViewModel(meeting: self.viewModel.meeting)
        let dialOutVC = SIPInviteViewController(viewModel: inviteVM)
        self.dialInVC = dialInVC
        self.dialOutVC = dialOutVC
        return [dialInVC, dialOutVC]
    }()

    weak var dialInVC: SIPDialInViewController?
    weak var dialOutVC: SIPInviteViewController?

    lazy var controllersDatasource: [JXSegmentedListContainerViewListDelegate] = {
        return self.subviewControllers
    }()

    lazy var segmentedDataSource: JXSegmentedTitleDataSource = {
       let datasource = JXSegmentedTitleDataSource()
        datasource.widthForTitleClosure = { [weak self] _ -> CGFloat in
            guard let self = self else { return 0 }
            let viewWidth = (self.navigationController?.view.bounds.size.width ?? self.view.bounds.size.width)
            let itemWidth = viewWidth / CGFloat(self.controllersDatasource.count)
            return itemWidth
        }
        datasource.isTitleColorGradientEnabled = false
        datasource.titleNormalFont = UIFont.systemFont(ofSize: 14)
        datasource.titleSelectedFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        datasource.titleNormalColor = UIColor.ud.textTitle
        datasource.titleSelectedColor = UIColor.ud.primaryContentDefault
        datasource.titles = segmentedTypes.map { $0.defaultTitle }
        // 去除item之间的间距
        datasource.itemWidthIncrement = 0
        datasource.itemSpacing = 0
        return datasource
    }()

    lazy var segmentedView: JXSegmentedView = {
        let segmentedView = JXSegmentedView()
        segmentedView.dataSource = segmentedDataSource

        let indicator = JXSegmentedIndicatorLineView()
        indicator.indicatorHeight = 2
        indicator.indicatorColor = UIColor.ud.primaryContentDefault

        segmentedView.backgroundColor = UIColor.ud.bgFloatBase
        segmentedView.indicators = [indicator]
        segmentedView.isContentScrollViewClickTransitionAnimationEnabled = false
        // 去除整体内容的左右边距
        segmentedView.contentEdgeInsetLeft = 0
        segmentedView.contentEdgeInsetRight = 0

        segmentedView.listContainer = listContainerView
        segmentedView.delegate = self
        return segmentedView
    }()

    lazy var listContainerView: JXSegmentedListContainerView = {
        return JXSegmentedListContainerView(dataSource: self)
    }()

    var isFirstAppear: Bool = true
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = I18n.View_G_InviteBySIP
        setNavigationBarBgColor(.ud.bgFloatBase)

        layoutSegmentedView()
    }

    func layoutSegmentedView() {
        // 用于添加offset && 遮挡segmentedView上方的阴影
        let placeHolderView = UIView()
        placeHolderView.backgroundColor = UIColor.ud.bgFloatBase
        view.addSubview(placeHolderView)
        placeHolderView.snp.makeConstraints { (maker) in
            maker.height.equalTo(2)
            maker.top.left.right.equalToSuperview()
        }

        view.insertSubview(segmentedView, belowSubview: placeHolderView)
        segmentedView.snp.makeConstraints { (make) in
            make.top.equalTo(placeHolderView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(40)
        }
        view.addSubview(listContainerView)
        listContainerView.addBorder(edges: .top, color: .ud.lineDividerDefault, thickness: 0.5)
        listContainerView.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.top.equalTo(segmentedView.snp.bottom)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstAppear {
            // iOS 13后ipad formsheet样式导航栏的高度为56,系统存在导航栏高度更新不及时的问题
            if #available(iOS 13.0, *), Display.pad {
                navigationController?.navigationBar.setNeedsLayout()
            }
            isFirstAppear = false
        }
        segmentedView.reloadData()
        segmentedView.layoutIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        MeetingTracksV2.trackInviteAggClickClose(
            location: "tab_sip",
            fromCard: false
        )
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.segmentedView.reloadData()
    }
}

extension SIPDialAggViewController: JXSegmentedListContainerViewDataSource {
    func numberOfLists(in listContainerView: JXSegmentedListContainerView) -> Int {
        return segmentedTypes.count
    }

    func listContainerView(_ listContainerView: JXSegmentedListContainerView, initListAt index: Int) -> JXSegmentedListContainerViewListDelegate {
        return controllersDatasource[index]
    }
}

extension SIPDialAggViewController: JXSegmentedViewDelegate {

    func segmentedView(_ segmentedView: JXSegmentedView, didSelectedItemAt index: Int) {
        guard segmentedTypes.count > index else {
            return
        }
        switch segmentedTypes[index] {
        case .dialIn:
            dialInVC?.view.setNeedsLayout()
            MeetingTracks.trackInviteSIPInClick()
        case .dialOut:
            dialOutVC?.view.setNeedsLayout()
            MeetingTracks.trackInviteSIPOutClick()
        }

    }
}
