//
//  MinutesStatisticsViewController.swift
//  Minutes
//
//  Created by sihuahao on 2021/6/30.
//

import UIKit
import SnapKit
import LarkUIKit
import EENavigator
import MinutesFoundation
import MinutesNetwork
import UniverseDesignToast
import LarkContainer

protocol  CellInfo {
    var withIdentifier: String { get }
}

protocol MinutesStatisticsCell: UITableViewCell {
    func setData(cellInfo: CellInfo)
}

struct OriginCellInfo: CellInfo {
    let withIdentifier: String = MinutesOriginInfoCell.description()
    var titleLabelText: String
    var hasUrl: Bool
    var leftImageName: String
    var rightLabelText: String
}

struct StatisticsCellInfo: CellInfo {
    let withIdentifier: String = MinutesStatisticsInfoCell.description()
    var titleLabelText: String
    var hasStatistics: Bool?
    var leftlabelNum: Int?
    var rightLabelNum: Int?
    var leftBottomLabelText: String
    var rightBottomLabelText: String
    var isSingle: Bool = false
}

public final class MinutesStatisticsViewController: UIViewController {

    var navigationBarIsHidden: Bool?

    private var tracker: MinutesTracker

    private var cellsInfo: [CellInfo]

    private var moreDetailsInfo: MoreDetailsInfo?

    private let viewModel: MinutesStatisticsViewModel

    lazy var tableView: UITableView = {
        let tableView: UITableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.bounces = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.dragInteractionEnabled = false
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false

        tableView.register(MinutesOriginInfoCell.self, forCellReuseIdentifier: MinutesOriginInfoCell.description())
        tableView.register(MinutesStatisticsInfoCell.self, forCellReuseIdentifier: MinutesStatisticsInfoCell.description())
        return tableView
    }()

    private lazy var minutesStatisticsTitleView: MinutesStatisticsTitleView = {
        var minutesStatisticsTitleView = MinutesStatisticsTitleView()
        minutesStatisticsTitleView.delegate = self
        return minutesStatisticsTitleView
    }()

    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGestureRecognizer.delegate = self
        return tapGestureRecognizer
    }()

    let userResolver: UserResolver
    init(resolver: UserResolver, minutes: Minutes) {
        self.tracker = MinutesTracker(minutes: minutes)
        self.userResolver = resolver
        self.viewModel = MinutesStatisticsViewModel(minutes: minutes)
        self.cellsInfo = viewModel.configCellInfo(moreDetailsInfo: moreDetailsInfo)
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var shouldAutorotate: Bool {
        return false
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addGestureRecognizer(tapGestureRecognizer)
        view.addSubview(minutesStatisticsTitleView)
        view.addSubview(tableView)

        minutesStatisticsTitleView.layer.cornerRadius = 6
        minutesStatisticsTitleView.snp.makeConstraints { maker in
            maker.bottom.equalToSuperview()
            maker.left.right.equalToSuperview()
            maker.height.equalTo(515)
        }

        tableView.snp.makeConstraints { maker in
            maker.top.equalTo(minutesStatisticsTitleView.snp.top).offset(73)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(466)
        }

        tapGestureRecognizer.cancelsTouchesInView = false
        tracker.tracker(name: .detailMoreInfoView, params: [:])
        setDetailsInfoData()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    private func configFailureCell() {
        for row in 0 ..< tableView.numberOfRows(inSection: 0) {
            if let cell = self.tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? MinutesStatisticsInfoCell {
                cell.setFailureCellStyle()
            }
        }
    }

    private func setDetailsInfoData() {
        viewModel.requestMoreDetailsInformation(catchError: true, successHandler: { [weak self] moreDetailsInfo in
            guard let wSelf = self else { return }
            MinutesLogger.detail.info("setting Requested moreDetailsInfo data")
            wSelf.cellsInfo = wSelf.viewModel.configCellInfo(moreDetailsInfo: moreDetailsInfo)
            wSelf.tableView.reloadData()
        }, failureHandler: { [weak self] in
            guard let wSelf = self else { return }
            wSelf.configFailureCell()
            MinutesLogger.detail.info("failed get data,current state is \(UIApplication.shared.applicationState)")
        })
    }
}

extension MinutesStatisticsViewController: UIGestureRecognizerDelegate {
    @objc
    private func handleTapGesture(_ sender: UITapGestureRecognizer) {
        if !minutesStatisticsTitleView.frame.contains(sender.location(in: self.view)) {
            self.dismiss(animated: true, completion: nil)
            MinutesLogger.detail.info(" Dismiss Area Tapped, dismissing")
        }
    }
}

extension MinutesStatisticsViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellsInfo.count
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch  cellsInfo[indexPath.row].withIdentifier {
        case MinutesOriginInfoCell.description():
            return 94
        case MinutesStatisticsInfoCell.description():
            return 110
        default:
            return 0
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            if let ownerInfo = viewModel.minutes.info.basicInfo?.ownerInfo {
                let from = userResolver.navigator.mainSceneTopMost
                MinutesProfile.personProfile(chatterId: ownerInfo.userId, from: from, resolver: userResolver)
                MinutesLogger.detail.info("Tapped owner ,turning into profile")
            }
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = cellsInfo[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: item.withIdentifier, for: indexPath) as? MinutesStatisticsCell {
            cell.setData(cellInfo: item)
            if let cell = cell as? MinutesStatisticsInfoCell {
                cell.tapAction = { [weak self] in
                    let alert = UIAlertController(title: BundleI18n.Minutes.MMWeb_G_StatsCountedFrom202011C_Tooltip, message: nil, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString(BundleI18n.Minutes.MMWeb_G_StatsCountedFrom202011_GotIt_Button, comment: "Default action"), style: .default, handler: { _ in
                    }))
                    
                    self?.userResolver.navigator.mainSceneTopMost?.present(alert, animated: true, completion: nil)
                    MinutesLogger.detail.info("Tapped hot area")
                }
            }
            return cell
        } else {
            return UITableViewCell()
        }
    }
}

public final class MinutesStatisticsNavigationController: LkNavigationController, UIViewControllerTransitioningDelegate {

    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func presentationController(forPresented presented: UIViewController,
                                       presenting: UIViewController?,
                                       source: UIViewController) -> UIPresentationController? {
        return MinutesMorePresentationController(presentedViewController: presented, presenting: presenting)
    }
}

extension MinutesStatisticsViewController: MinutesCloseMoreInfoPanelDelegate {
    func closePanel() {
        self.dismiss(animated: true, completion: nil)
    }
}
