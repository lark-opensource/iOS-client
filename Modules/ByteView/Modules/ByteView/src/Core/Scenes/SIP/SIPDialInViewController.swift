//
//  SIPDialInViewController.swift
//  ByteView
//
//  Created by admin on 2022/5/27.
//

import UIKit
import ByteViewUI
import UniverseDesignColor
import ByteViewCommon
import ByteViewTracker
import LarkSegmentedView
import RxSwift

enum DialInCellType {
    case uri
    case ipAddr
    case meetingId

    var title: String {
        switch self {
        case .uri: return I18n.View_G_SIPAddress
        case .ipAddr: return I18n.View_G_IPAddress
        case .meetingId: return I18n.View_N_MeetingId
        }
    }
}

final class SIPDialInViewController: VMViewController<SIPDialViewModel>, UITableViewDataSource, UITableViewDelegate {

    private var menuFixer: MenuFixer?
    private let disposeBag = DisposeBag()
    private let tap = UITapGestureRecognizer()
    lazy var tableView: UITableView = {
        let tableView = BaseGroupedTableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        return tableView
    }()

    fileprivate lazy var dialInTypes: [DialInCellType] = [.uri, .ipAddr, .meetingId]
    fileprivate lazy var selectionViews: [SIPDialInSelectionView] = {
        dialInTypes.map {
            let view = SIPDialInSelectionView()
            view.title = $0.title
            if $0 == .ipAddr {
                view.addTapGesture(tap)
            }
            return view
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setNavigationBarBgColor(.ud.bgFloatBase)
        view.backgroundColor = .ud.bgFloatBase

        view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        tap.addTarget(self, action: #selector(handleIPAddrsClick))
        self.viewModel.sipInviteObservable
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self]_ in
                self?.tableView.reloadData()
            }
            .disposed(by: disposeBag)
        setupMenuFixer()
    }

    override func bindViewModel() {
        self.viewModel.fetchIPAddrs()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    private func setupMenuFixer() {
        menuFixer = MenuFixer(viewController: self)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "SIPDialInReuseIdentifier")
        cell.contentView.backgroundColor = .ud.bgFloat
        if indexPath.section == 0 {
            let selectionView = selectionViews[indexPath.row]
            cell.contentView.addSubview(selectionView)
            selectionView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.left.right.equalToSuperview().inset(16)
            }
            setupDialInCellData(type: .uri, view: selectionView)
        } else if indexPath.section == 1 {
            let selectionView = selectionViews[indexPath.row + 1]
            if indexPath.row == 0 {
                cell.addBorder(edges: .bottom, color: UIColor.ud.lineDividerDefault, thickness: 0.5)
            }

            cell.contentView.addSubview(selectionView)
            selectionView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.left.right.equalToSuperview().inset(16)
            }
            setupDialInCellData(type: dialInTypes[indexPath.row + 1], view: selectionView)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        let label = UILabel()
        label.text = section == 0 ? I18n.View_G_DialInFromSIP : I18n.View_G_DialInFromSystem
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(2)
            make.height.equalTo(20)
        }
        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        38
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        55
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        section == 1 ? 28 : 0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 && indexPath.row == 0 {
            self.handleIPAddrsClick()
        }
    }

    @objc func handleIPAddrsClick() {
        guard selectionViews.count >= 1  else {
            return
        }
        let selectionView = selectionViews[1]
        switch selectionView.stateType {
        case .error:
            self.viewModel.fetchIPAddrs()
            self.tableView.reloadData()
        case .arrow:
            gotoChooseIPAddrsVC()
        case .none, .loading:
            break
        }
    }

    func gotoChooseIPAddrsVC() {
        let vc = SIPChosenIPViewController(viewModel: self.viewModel)
        vc.chosenIPAddrChanged = { [weak self] in
            self?.tableView.reloadRows(at: [IndexPath.init(row: 0, section: 1)], with: .automatic)
        }
        viewModel.meeting.router.push(vc)
    }

    func setupDialInCellData(type: DialInCellType, view: SIPDialInSelectionView) {
        view.stateType = .none
        var text = ""
        let color = UIColor.ud.textTitle
        var config = VCFontConfig.body
        switch type {
        case .uri:
            text = viewModel.sipURI
        case .ipAddr:
            text = viewModel.ipAddrTitle
            view.stateType = viewModel.ipAddrStateType
            config = .h4
        case .meetingId:
            text = viewModel.formattedMeetingNumber
        }
        let s = NSMutableAttributedString(string: text, config: config)
        s.addAttribute(.foregroundColor, value: color, range: NSRange(0 ..< s.length))
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        s.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(0 ..< s.length))
        view.despAttributedText = s
    }
}

// MARK: - JXSegmentedListContainerViewListDelegate
extension SIPDialInViewController: JXSegmentedListContainerViewListDelegate {
    func listView() -> UIView {
        return view
    }
}
