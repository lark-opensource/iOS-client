//
//  ZoomMeetingPhoneListViewController.swift
//  Calendar
//
//  Created by pluto on 2022-10-20.
//

import UIKit
import Foundation
import LarkContainer
import LKCommonsLogging
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignToast
import RxSwift
import FigmaKit
import LarkUIKit
import LarkEMM

final class ZoomMeetingPhoneListViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {

    private let logger = Logger.log(ZoomMeetingPhoneListViewController.self, category: "calendar.ZoomMeetingPhoneListViewController")
    private let viewModel: ZoomMeetingPhoneListViewModel

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.register(ZoomMeetingPhoneListCell.self, forCellReuseIdentifier: "ZoomMeetingPhoneListCell")
        tableView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        tableView.insetsContentViewsToSafeArea = false
        tableView.indicatorStyle = .black
        tableView.backgroundColor = UIColor.ud.bgBody
        return tableView
    }()

    private lazy var navigationBar: ZoomMeetingPhoneListNavigationBar = {
        let bar = ZoomMeetingPhoneListNavigationBar()
        bar.backgroundColor = .clear
        bar.configNavigationBar(title: I18n.Calendar_Zoom_DialInTitle, tapCallBack: {[weak self] in
            self?.dismiss(animated: true)
        })
        return bar
    }()

    private lazy var phoneHeaderView: ZoomMeetingPhoneListHeaderView = {
        let view = ZoomMeetingPhoneListHeaderView()
        view.backgroundColor = .clear
        view.sizeToFit()
        return view
    }()

    private lazy var loadingView: ZoomCommonPlaceholderView = {
        let view = ZoomCommonPlaceholderView()
        view.layoutNaviOffsetStyle()
        view.backgroundColor = UIColor.ud.bgBody
        view.isHidden = false
        return view
    }()

    init (viewModel: ZoomMeetingPhoneListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        tableView.delegate = self
        tableView.dataSource = self
        viewModel.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        title = I18n.Calendar_Zoom_DialInTitle
        addCloseItem()
        setupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    private func refreshUIData() {
        tableView.reloadData()
    }

    private func setupView() {
        view.addSubview(phoneHeaderView)
        phoneHeaderView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(12)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(phoneHeaderView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if Display.pad {
            copyInfo(dialInNumbers: viewModel.zoomPhoneNumModels[safeIndex: indexPath.row]?.dialInNumbers ?? [])
        } else {
            tapCall(dialInNumbers: viewModel.zoomPhoneNumModels[indexPath.row].dialInNumbers)
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ZoomMeetingPhoneListCell", for: indexPath) as? ZoomMeetingPhoneListCell else {
            return UITableViewCell()
        }
        if let item = viewModel.zoomPhoneNumModels[safeIndex: indexPath.row] {
            cell.configure(item)
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 46 + CGFloat(viewModel.zoomPhoneNumModels[safeIndex: indexPath.row]?.dialInNumbers.count ?? 1) * 20.0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.zoomPhoneNumModels.count
    }

    func copyInfo(dialInNumbers: [String]) {
        SCPasteboard.generalPasteboard(shouldImmunity: true).string = dialInNumbers.map { "\($0)#" }.joined(separator: "\n")
        UDToast.showTips(with: I18n.View_M_PhoneNumberAndMeetingIdCopied, on: self.view)
    }

    func tapCall(dialInNumbers: [String]) {
        guard let dialInNumber = dialInNumbers.first else {
            return
        }
        let phoneNumber = dialInNumber.replacingOccurrences(of: " ", with: "")
        // 拨打电话
        var callStr: String = ""
        if #available(iOS 15.4, *) {
            callStr = "\(phoneNumber)"
        } else {
            callStr = "\(phoneNumber)#"
        }

        guard let number = callStr.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
                let url = URL(string: "telprompt://\(number)") else { return }
        UIApplication.shared.open(url)
    }
}

extension ZoomMeetingPhoneListViewController: ZoomMeetingPhoneListViewModelDelegate {

    func reloadPhoneList(meetingID: String, password: String) {
        phoneHeaderView.configHeaderInfo(meetingID: meetingID, password: password)
        refreshUIData()
        loadingView.isHidden = true
    }
}
