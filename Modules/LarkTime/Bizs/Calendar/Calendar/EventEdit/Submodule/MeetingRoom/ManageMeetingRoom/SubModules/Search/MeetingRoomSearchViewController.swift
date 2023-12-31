//
//  MeetingRoomSearchViewController.swift
//  Calendar
//
//  Created by zhuheng on 2021/1/22.
//

import UIKit
import RxSwift
import RxCocoa
import LarkUIKit
import LarkActivityIndicatorView
import RoundedHUD
import UniverseDesignToast
import UniverseDesignDialog

protocol MeetingRoomSearchViewControllerDelegate: AnyObject {
    func didSelectMeetingRoom(
        _ meetingRoom: CalendarMeetingRoom,
        from viewController: MeetingRoomSearchViewController
    )
    func didSelectMeetingRoomDetail(
        _ resourceID: String,
        from viewController: MeetingRoomSearchViewController
    )
}

final class MeetingRoomSearchViewController: UIViewController {

    let viewModel: MeetingRoomSearchViewModel
    weak var delegate: MeetingRoomSearchViewControllerDelegate?

    private typealias UIStyle = EventEditUIStyle

    private lazy var tableView = initTableView()
    private lazy var statusView = initStatusView()
    private lazy var loadMoreView = LoadMoreView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 44))

    private let disposeBag = DisposeBag()

    private let cellReuseId = "Cell"
    init(viewModel: MeetingRoomSearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bindViewData()
        bindViewAction()
        viewModel.onAllCellDataUpdate = { [weak self] in
            self?.tableView.reloadData()
        }
    }

    private func setupView() {
        view.backgroundColor = UIStyle.Color.viewControllerBackground

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        view.addSubview(statusView)
        statusView.snp.makeConstraints {
            $0.edges.equalTo(tableView)
        }
    }

    private func bindViewData() {
        viewModel.rxViewState.bind { [weak self] viewState in
            guard let self = self else { return }
            switch viewState {
            case .loading:
                self.view.superview?.bringSubviewToFront(self.view)
                self.view.isHidden = false
                self.statusView.isHidden = false
                self.statusView.status = .loading
                self.tableView.isHidden = true
                self.tableView.contentOffset = .zero
                self.view.bringSubviewToFront(self.statusView)
            case .empty(let text, _):
                self.view.superview?.bringSubviewToFront(self.view)
                self.view.isHidden = false
                self.statusView.isHidden = false
                self.statusView.status = .empty(text)
                self.tableView.isHidden = true
                self.view.bringSubviewToFront(self.statusView)
            case .data(let hasMore, let isLoadingMore):
                self.view.superview?.bringSubviewToFront(self.view)
                self.view.isHidden = false
                self.statusView.isHidden = true
                self.tableView.isHidden = false
                if hasMore {
                    self.loadMoreView.isLoading = isLoadingMore
                    self.loadMoreView.clickHandler = { [weak self] in
                        self?.viewModel.loadMore()
                    }
                    self.tableView.tableFooterView = self.loadMoreView
                } else {
                    self.tableView.tableFooterView = UIView()
                }
                self.view.bringSubviewToFront(self.tableView)
            case .failed:
                self.view.superview?.bringSubviewToFront(self.view)
                self.view.isHidden = false
                self.statusView.isHidden = false
                self.statusView.status = .failed
                self.tableView.isHidden = true
                self.view.bringSubviewToFront(self.statusView)
            case .cancelSearch:
                self.view.isHidden = true
            }
        }.disposed(by: disposeBag)
    }

    private func bindViewAction() {
        viewModel.rxAlert
            .subscribeForUI(onNext: { [weak self] (title, content) in
                let dialog = UDDialog(config: UDDialogUIConfig())
                dialog.setTitle(text: title)
                dialog.setContent(text: content)
                dialog.addPrimaryButton(text: I18n.Calendar_Common_GotIt)
                self?.present(dialog, animated: true)
            }).disposed(by: disposeBag)
    }

}

extension MeetingRoomSearchViewController {
    func initTableView() -> UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIStyle.Color.viewControllerBackground
        tableView.separatorInset = .init(top: 0, left: UIStyle.Layout.contentLeftMargin, bottom: 0, right: 0)
        tableView.separatorColor = UIStyle.Color.horizontalSeperator
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .onDrag
        tableView.register(EventMeetingRoomCell.self, forCellReuseIdentifier: cellReuseId)
        return tableView
    }

    func initStatusView() -> LoadStatusView {
        let loadingView = LoadStatusView()
        loadingView.backgroundColor = UIColor.ud.bgBody
        return loadingView
    }
}

extension MeetingRoomSearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath)

        if let cell = cell as? EventMeetingRoomCell {
            cell.viewData = viewModel.cellData(at: indexPath.row)
            cell.setFirstLevelStyle()
            cell.onTapped = { [weak self] in
                guard let self = self else { return }
                guard let meetingRoom = self.viewModel.meetingRoom(at: indexPath.row) else {
                    assertionFailure()
                    return
                }
                if let data = cell.viewData,
                   !data.isAvailable,
                   let reason = data.unAvailableReason,
                   !reason.isEmpty {
                    UDToast.showTips(with: reason, on: self.view)
                    return
                }
                self.delegate?.didSelectMeetingRoom(meetingRoom, from: self)
            }
            cell.showInfoButton()
            cell.infoBtnOnTapped = { [weak self] in
                guard let self = self else { return }
                guard let meetingRoom = self.viewModel.meetingRoom(at: indexPath.row) else {
                    assertionFailure()
                    return
                }

                self.delegate?.didSelectMeetingRoomDetail(meetingRoom.getPBModel().attendeeCalendarID, from: self)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68
    }

}

extension MeetingRoomSearchViewController {

    /// 展示会议室搜索的 loading、empty、failed 状态
    final class LoadStatusView: UIView {

        enum Status {
            case loading
            case empty(String)
            case failed
        }

        private let activityView = LarkActivityIndicatorView.ActivityIndicatorView(color: UIColor.ud.primaryContentDefault)
        private let titleLabel = UILabel.cd.textLabel()

        var status: Status = .loading {
            didSet {
                switch status {
                case .loading:
                    activityView.isHidden = false
                    activityView.startAnimating()
                    titleLabel.snp.updateConstraints {
                        $0.left.equalToSuperview().offset(UIStyle.Layout.contentLeftMargin)
                    }
                    titleLabel.text = BundleI18n.Calendar.Calendar_Common_LoadingCommon
                case .empty(let text):
                    activityView.isHidden = true
                    activityView.stopAnimating()
                    titleLabel.snp.updateConstraints {
                        $0.left.equalToSuperview().offset(UIStyle.Layout.iconLeftMargin)
                    }
                    titleLabel.text = text
                case .failed:
                    activityView.isHidden = true
                    activityView.stopAnimating()
                    titleLabel.snp.updateConstraints {
                        $0.left.equalToSuperview().offset(UIStyle.Layout.iconLeftMargin)
                    }
                    titleLabel.text = BundleI18n.Calendar.Calendar_Common_FailedToLoad
                }
            }
        }

        override init(frame: CGRect) {
            super.init(frame: frame)

            addSubview(activityView)
            activityView.snp.makeConstraints {
                $0.left.equalToSuperview().offset(UIStyle.Layout.iconLeftMargin)
                $0.centerY.equalTo(self.snp.top).offset(32)
                $0.size.equalTo(UIStyle.Layout.iconSize)
            }

            addSubview(titleLabel)
            titleLabel.snp.makeConstraints {
                $0.left.equalToSuperview().offset(UIStyle.Layout.contentLeftMargin)
                $0.centerY.equalTo(activityView)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    final class LoadMoreView: UIControl {

        var clickHandler: (() -> Void)?

        var isLoading: Bool = false {
            didSet {
                if isLoading {
                    activityView.isHidden = false
                    activityView.startAnimating()
                    isUserInteractionEnabled = false
                } else {
                    activityView.isHidden = true
                    activityView.stopAnimating()
                    isUserInteractionEnabled = true
                }
            }
        }

        private let activityView = LarkActivityIndicatorView.ActivityIndicatorView(color: UIColor.ud.primaryContentDefault)
        private let titleLabel = UILabel()

        override init(frame: CGRect) {
            super.init(frame: frame)

            addSubview(activityView)
            activityView.snp.makeConstraints {
                $0.left.equalToSuperview().offset(UIStyle.Layout.iconLeftMargin)
                $0.centerY.equalToSuperview()
                $0.size.equalTo(UIStyle.Layout.iconSize)
            }

            titleLabel.font = UIFont.systemFont(ofSize: 16)
            titleLabel.textColor = UIColor.ud.primaryContentDefault
            titleLabel.text = BundleI18n.Calendar.Calendar_Common_LoadMoreMobile
            addSubview(titleLabel)
            titleLabel.snp.makeConstraints {
                $0.left.equalToSuperview().offset(UIStyle.Layout.contentLeftMargin)
                $0.centerY.equalTo(activityView)
            }

            addTarget(self, action: #selector(didClick), for: .touchUpInside)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc
        private func didClick() {
            clickHandler?()
        }
    }

}
