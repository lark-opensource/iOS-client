//
//  MinutesHomeSortAlertController.swift
//  Minutes
//
//  Created by chenlehui on 2021/9/7.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignColor
import LarkUIKit
import MinutesFoundation
import MinutesNetwork
import UniverseDesignIcon

class MinutesHomeSortAlertController: UIViewController {

    let presentationManager: SlidePresentationManager = {
        let p = SlidePresentationManager()
        p.style = .actionSheet(.bottom)
        return p
    }()

    lazy var maskLayer: CALayer = {
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height), byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 12, height: 12))
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        return layer
    }()
    
    var regularHeight: CGFloat {
        return CGFloat(36 + viewModel.cellsInfo.count * 52)
    }

    var height: CGFloat {
        return CGFloat(52 + viewModel.cellsInfo.count * 52)
    }
    
    private lazy var sepLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.ud.lineDividerDefault
        return v
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        l.textColor = UIColor.ud.textTitle
        l.textAlignment = .center
        l.text = BundleI18n.Minutes.MMWeb_G_SortBy
        return l
    }()

    private lazy var closeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UDIcon.getIconByKey(.closeSmallOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 24, height: 24)), for: .normal)
        btn.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        return btn
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = UIColor.ud.bgFloat
        tv.separatorColor = UIColor.ud.bgFloat
        tv.rowHeight = 52
        tv.estimatedRowHeight = 52
        tv.isScrollEnabled = false
        tv.dataSource = self
        tv.delegate = self
        return tv
    }()

    private var filterInfo: FilterInfo

    private var minutesSpaceType: MinutesSpaceType

    private var viewModel: MinutesHomeFilterViewModel

    var completionBlock: ((FilterInfo) -> Void)?

    private let tracker = BusinessTracker()

    init(filterInfo: FilterInfo) {
        minutesSpaceType = filterInfo.spaceType
        self.filterInfo = filterInfo
        viewModel = MinutesHomeFilterViewModel(filterInfo: filterInfo)
        viewModel.configCellInfo()
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = presentationManager
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgFloat
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        if modalPresentationStyle == .popover {
            tableView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
                make.height.equalTo(viewModel.cellsInfo.count * 52)
            }
            titleLabel.snp.makeConstraints { make in
                make.left.equalTo(16)
                make.bottom.equalTo(tableView.snp.top)
            }
            titleLabel.textAlignment = .left
        } else {
            view.layer.mask = maskLayer
            titleLabel.snp.makeConstraints { make in
                make.top.equalTo(14)
                make.centerX.equalToSuperview()
                make.height.equalTo(24)
            }
            view.addSubview(sepLine)
            sepLine.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(0.5)
                make.top.equalTo(48)
            }
            view.addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.width.height.equalTo(44)
                make.left.equalTo(6)
                make.centerY.equalTo(titleLabel)
            }
            tableView.snp.makeConstraints { make in
                make.top.equalTo(52)
                make.left.right.equalToSuperview()
                make.bottom.equalTo(view.safeAreaLayoutGuide)
            }
        }
        trackerFilterIconClick()
    }

    @objc private func closeAction() {
        dismiss(animated: true, completion: nil)
    }

    private func isDefaultStatus() -> Bool {
        for item in viewModel.cellsInfo where item.isConditionSelected {
            switch minutesSpaceType {
            case .home:
                if item.ownerType != MinutesOwnerType.byAnyone || item.schedulerType != nil {
                    return false
                }
            case .my:
                return item.rankType == MinutesRankType.createTime && !item.isArrowUp
            case .share:
                return item.rankType == MinutesRankType.shareTime && !item.isArrowUp
            case .trash :
                return !item.isArrowUp
            default:
                return true
            }
        }
        return true
    }

    private func trackerFilterIconClick() {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams["click"] = "items_filter_button"
        trackParams["target"] = "vc_minutes_list_view"
        trackParams["page_name"] = minutesSpaceType.pageName
        tracker.tracker(name: .listClick, params: trackParams)
    }

    private func trackerFilterRankConfirmClick() {
        var trackParams: [AnyHashable: Any] = [:]
        if viewModel.filterInfo.spaceType == .trash {
            trackParams["click"] = viewModel.filterInfo.rankType == .schedulerExecuteTime ? "auto_delete_time_order" : "remaining_time_order"
        } else {
            trackParams["click"] = viewModel.filterInfo.rankType == .schedulerExecuteTime ? "auto_delete_time_order" : "items_filter"
        }
        trackParams["target"] = "vc_minutes_list_view"
        trackParams["page_name"] = minutesSpaceType.pageName
        trackParams["show"] = viewModel.filterInfo.rankType.trackerKey
        if viewModel.filterInfo.rankType == .schedulerExecuteTime || viewModel.filterInfo.spaceType == .trash {
            trackParams["order_type"] = viewModel.filterInfo.asc ? "asc" : "desc"
        } else {
            trackParams["order_type"] = viewModel.filterInfo.asc ? "earliest_to_latest" : "latest_to_earliest"
        }
        tracker.tracker(name: .listClick, params: trackParams)
    }
}

extension MinutesHomeSortAlertController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.cellsInfo.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = viewModel.cellsInfo[indexPath.row]
        return tableView.mins.dequeueReusableCell(with: Cell.self) { cell in
            cell.config(item: item)
        }
    }
}

extension MinutesHomeSortAlertController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let filterConditions = viewModel.cellsInfo
        if filterConditions[indexPath.row].isConditionSelected {
            viewModel.cellsInfo[indexPath.row].isArrowUp = !filterConditions[indexPath.row].isArrowUp
            tableView.reloadData()
        } else {
            for i in 0..<filterConditions.count {
                if i == indexPath.row {
                    viewModel.cellsInfo[i].isConditionSelected = true
                    viewModel.cellsInfo[i].hasArrow = true
                } else {
                    viewModel.cellsInfo[i].isConditionSelected = false
                    viewModel.cellsInfo[i].hasArrow = false
                }
            }
            tableView.reloadData()
        }
        viewModel.setConfirmInfo()
        viewModel.filterInfo.isFilterIconActived = !isDefaultStatus()
        completionBlock?(viewModel.filterInfo)
        trackerFilterRankConfirmClick()
        closeAction()
    }
}

extension MinutesHomeSortAlertController {

    class Cell: UITableViewCell {

        private lazy var titleLabel: UILabel = {
            let l = UILabel()
            l.font = UIFont.systemFont(ofSize: 17)
            l.textColor = UIColor.ud.textTitle
            return l
        }()

        lazy var icon: UIImageView = {
            let iv = UIImageView()
            iv.image = UDIcon.getIconByKey(.spaceUpOutlined, iconColor: UIColor.ud.textCaption, size: CGSize(width: 16, height: 16))
            return iv
        }()

        var arrowUp: Bool = true {
            didSet {
                if arrowUp {
                    icon.transform = CGAffineTransform.init(scaleX: 1.0, y: 1.0)
                } else {
                    icon.transform = CGAffineTransform.init(scaleX: 1.0, y: -1.0)
                }
            }
        }

        private var hasArrow: Bool = false {
            didSet {
                if hasArrow {
                    icon.isHidden = false
                } else {
                    icon.isHidden = true
                }
            }
        }

        private var isConditionSelected: Bool = false {
            didSet {
                if isConditionSelected {
                    titleLabel.textColor = UIColor.ud.primaryContentDefault
                    icon.image = UDIcon.getIconByKey(.spaceUpOutlined, iconColor: UIColor.ud.primaryContentDefault, size: CGSize(width: 16, height: 16))
                } else {
                    titleLabel.textColor = UIColor.ud.textCaption
                    icon.image = UDIcon.getIconByKey(.spaceUpOutlined, iconColor: UIColor.ud.textCaption, size: CGSize(width: 16, height: 16))
                }
            }
        }

        private var isCellEnabled: Bool = true {
            didSet {
                if isCellEnabled {
                    self.isUserInteractionEnabled = true
                } else {
                    self.isUserInteractionEnabled = false
                    self.backgroundColor = UIColor.ud.bgFloatOverlay
                    titleLabel.textColor = UIColor.ud.textDisabled
                }
            }
        }

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            contentView.backgroundColor = UIColor.ud.bgFloat
            contentView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.left.equalTo(16)
                make.centerY.equalToSuperview()
            }
            contentView.addSubview(icon)
            icon.snp.makeConstraints { make in
                make.left.equalTo(titleLabel.snp.right).offset(8)
                make.centerY.equalTo(titleLabel)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func config(item: FilterCondition) {
            titleLabel.text = item.rankType.title
            arrowUp = item.isArrowUp
            hasArrow = item.hasArrow
            isConditionSelected = item.isConditionSelected
            isCellEnabled = item.isEnabled
        }
    }
}
