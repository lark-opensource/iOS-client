//
//  MinutesCollectionViewController.swift
//  ByteViewTab
//
//  Created by 陈乐辉 on 2023/5/8.
//

import Foundation
import ByteViewUI
import ByteViewCommon
import RxSwift
import UIKit
import UniverseDesignColor
import ByteViewNetwork
import UniverseDesignIcon
import FigmaKit
import ByteViewTracker

final class MinutesCollectionViewController: VMViewController<MinutesCollcetionViewModel>, UITableViewDataSource, UITableViewDelegate {

    lazy var naviBar: MeetingCollectionNavigationBar = {
        let nav = MeetingCollectionNavigationBar()
        nav.backButton.addTarget(self, action: #selector(doBack), for: .touchUpInside)
        return nav
    }()

    var backgroundView = UIView()
    lazy var backgroundImageView: UIImageView = {
        let backgroundImageView = UIImageView()
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.image = BundleResources.ByteViewTab.Collection.collectionCalendarBg
        return backgroundImageView
    }()

    lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.backgroundColor = .clear
        tv.tableHeaderView = headerView
        tv.tableFooterView = UIView()
        tv.register(MeetingFileTableViewCell.self, forCellReuseIdentifier: "MeetingFileTableViewCell")
        tv.register(MinutesCollectionSectionHeader.self, forHeaderFooterViewReuseIdentifier: "SectionHeader")
        tv.register(MinutesCollectionSectionFooter.self, forHeaderFooterViewReuseIdentifier: "SectionFooter")
        tv.dataSource = self
        tv.delegate = self
        tv.rowHeight = 76
        tv.separatorStyle = .none
        return tv
    }()

    lazy var headerView: MinutesCollectionHeaderView = {
        let header = MinutesCollectionHeaderView()
        return header
    }()

    lazy var tableViewBackgroundView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.ud.bgBody
        return v
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func setupViews() {
        super.setupViews()
        isNavigationBarHidden = true
        view.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        view.addSubview(backgroundImageView)
        view.addSubview(tableViewBackgroundView)
        view.addSubview(tableView)
        view.addSubview(naviBar)
        updateLayout()
        updateBackgroundColor()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _ in
            self?.configHeaderView()
            self?.updateBackgroundColor()
            self?.updateLayout()
            self?.tableView.reloadData()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configHeaderView()
        updateBackgroundColor()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override func bindViewModel() {
        super.bindViewModel()
        viewModel.delegate = self
        viewModel.generateItems()
    }

    func updateLayout() {
        if traitCollection.isRegular {
            backgroundImageView.snp.remakeConstraints {
                $0.top.right.equalToSuperview()
                $0.width.equalTo(650.0)
                $0.height.equalTo(380.0)
            }
            naviBar.snp.remakeConstraints {
                $0.left.top.right.equalToSuperview()
                $0.height.equalTo(84.0)
            }
            tableView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.left.equalTo(48)
                make.right.equalTo(-48)
            }
        } else {
            backgroundImageView.snp.remakeConstraints {
                $0.top.equalToSuperview()
                $0.right.equalToSuperview().offset(62.0)
                $0.width.equalTo(438.0)
                $0.height.equalTo(256.0)
            }
            naviBar.snp.remakeConstraints {
                $0.left.top.right.equalToSuperview()
                $0.height.equalTo(88.0)
            }
            tableView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }

    func updateBackgroundColor() {
        backgroundImageView.alpha = 1.0
        let direction: GradientDirection = traitCollection.isRegular ? .topToBottom : .rightToLeft
        var colorSet: [UIColor] = [UDColor.rgb(0xDAE3ED), UDColor.rgb(0xF7F8FB)]
        if #available(iOS 12.0, *), traitCollection.userInterfaceStyle == .dark {
            backgroundImageView.alpha = 0.05
            colorSet = [UDColor.rgb(0x293747), UDColor.rgb(0x232932)]
        }
        backgroundView.backgroundColor = UIColor.fromGradientWithDirection(direction, frame: view.frame, colors: colorSet)
        backgroundView.setNeedsLayout()
        tableViewBackgroundView.isHidden = traitCollection.isRegular
    }

    func updateTableViewBackgroundViewHeight(_ offset: CGFloat = 0) {
        if traitCollection.isRegular { return }
        let hy = headerView.bounds.height
        let y = hy - offset + 76
        let h = view.bounds.height - y
        tableViewBackgroundView.frame = CGRect(x: 0, y: y, width: view.bounds.width, height: h)
    }

    func configHeaderView() {
        headerView.config(with: viewModel.title, subtitle: viewModel.subtitle)
        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: headerView.calculateHeight())
        tableView.reloadData()
        updateTableViewBackgroundViewHeight()
    }

   func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        viewModel?.router?.pushOrPresentURL(url, from: self)
    }

    func forwardMinutes(_ urlString: String) {
        viewModel?.router?.forwardMessage(urlString, from: self)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "MeetingFileTableViewCell", for: indexPath) as? MeetingFileTableViewCell {
            let item = viewModel.items[indexPath.row]
            let meetingID = viewModel.meetingID
            cell.configCollectionMinutes(with: item, viewModel: viewModel)
            cell.forwardAction = { [weak self] in
                if let urlString = item.url {
                    self?.forwardMinutes(urlString)
                    VCTracker.post(name: .vc_discussion_cluster_click, params: [.click: "mm_share", "conference_id": meetingID, "target": "vc_minutes_detail_view", "object_id": "\(item.objectID)"])
                }
            }
            cell.tapAction = { [weak self] in
                if let urlString = item.url {
                    self?.openURL(urlString)
                    VCTracker.post(name: .vc_discussion_cluster_click, params: [.click: "mm", "conference_id": meetingID, "target": "vc_minutes_detail_view", "object_id": "\(item.objectID)"])
                }
            }
            if traitCollection.isRegular {
                cell.separatorLine.isHidden = indexPath.row == viewModel.items.count - 1
            } else {
                cell.separatorLine.isHidden = true
            }
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SectionHeader") as? MinutesCollectionSectionHeader {
            header.setIsRegular(isRegular: traitCollection.isRegular)
            return header
        }
        return nil
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SectionFooter") as? MinutesCollectionSectionFooter {
            header.setIsRegular(isRegular: traitCollection.isRegular)
            return header
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return traitCollection.isRegular ? 20 : 8
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return traitCollection.isRegular ? 20 : 8
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let length = abs(headerView.subtitleLabel.frame.origin.y - naviBar.bounds.height)
        let offset = min(scrollView.contentOffset.y, length)
        let alpha = offset / length
        naviBar.updateBgAlpha(alpha)
        updateTableViewBackgroundViewHeight(scrollView.contentOffset.y)
    }
}

extension MinutesCollectionViewController: MinutesCollcetionViewModelDelegate {
    func minutesCollcetionDidUpdate() {
        configHeaderView()
        naviBar.setTitle(viewModel.title)
    }
}
