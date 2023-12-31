//
//  PhoneListViewController.swift
//  ByteView
//
//  Created by 费振环 on 2020/8/10.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import SnapKit
import ByteViewUI

final class PhoneListViewController: VMViewController<PhoneListViewModel>, UITableViewDataSource, UITableViewDelegate {
    static let cellReuseIdentifier = "PhoneListCell"

    private lazy var tableView = BaseTableView()
    private lazy var meetingNumberLabel = UILabel()

    private var dialInInfoModels: [DialInInfoModel] = []

    override func setupViews() {
        view.backgroundColor = UIColor.ud.bgBody
        title = I18n.View_M_DialIn
        meetingNumberLabel.textColor = UIColor.ud.textTitle

        let topInfoLabel = UILabel()
        topInfoLabel.attributedText = .init(string: I18n.View_M_DialInInfo, config: .bodyAssist)
        topInfoLabel.textColor = UIColor.ud.textPlaceholder
        topInfoLabel.numberOfLines = 0
        topInfoLabel.lineBreakMode = .byWordWrapping

        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.lineDividerDefault

        let topView = UIView()
        topView.addSubview(topInfoLabel)
        topView.addSubview(meetingNumberLabel)
        topView.addSubview(lineView)
        view.addSubview(topView)

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(PhoneListCell.self, forCellReuseIdentifier: Self.cellReuseIdentifier)
        tableView.insetsContentViewsToSafeArea = false
        tableView.indicatorStyle = .black
        tableView.delegate = self
        tableView.dataSource = self
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(sender:)))
        tableView.addGestureRecognizer(longPressRecognizer)
        view.addSubview(tableView)

        topView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.right.equalTo(view.safeAreaLayoutGuide).offset(-16)
        }

        tableView.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
            make.top.equalTo(topView.snp.bottom)
        }

        topInfoLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12.5)
            make.left.right.equalToSuperview()
        }
        meetingNumberLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(topInfoLabel.snp.bottom).offset(12.0)
        }
        lineView.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.top.equalTo(meetingNumberLabel.snp.bottom).offset(12.0)
            make.left.right.equalTo(view)
            make.bottom.equalToSuperview().offset(0.5)
        }
    }

    override func bindViewModel() {
        let displayedMeetingNumber = "\(I18n.View_M_MeetingIdColon)\(viewModel.meetingNumber)"
        meetingNumberLabel.attributedText = .init(string: displayedMeetingNumber, config: .body)
        dialInInfoModels = viewModel.dialInInfoModels
        tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    @objc func longPressed(sender: UILongPressGestureRecognizer) {
        if Display.phone, sender.state == .began {
            let touchPoint = sender.location(in: self.tableView)
            if  let indexPath = tableView.indexPathForRow(at: touchPoint) {
                viewModel.copyInfo(dialInNumbers: dialInInfoModels[indexPath.row].dialInNumbers)
            }
        }
    }

    func tapDial(dialInNumbers: [String]) {
        guard let dialInNumber = dialInNumbers.first else {
            return
        }
        self.viewModel.tapCall(dialInNumber: dialInNumber)
    }

    // MARK: - Orientations
    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dialInInfoModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellReuseIdentifier, for: indexPath)
        if let cell = cell as? PhoneListCell {
            cell.configure(dialInInfoModels[indexPath.row], meetingNumber: viewModel.meetingNumber)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if Display.pad {
            viewModel.copyInfo(dialInNumbers: dialInInfoModels[indexPath.row].dialInNumbers)
        } else {
            tapDial(dialInNumbers: dialInInfoModels[indexPath.row].dialInNumbers)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 46.0 + CGFloat(dialInInfoModels[indexPath.row].dialInNumbers.count) * 22.0
    }
}
