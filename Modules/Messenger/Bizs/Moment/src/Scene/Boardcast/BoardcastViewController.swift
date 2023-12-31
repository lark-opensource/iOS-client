//
//  BoardcastViewController.swift
//  Moment
//
//  Created by zc09v on 2021/3/9.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignToast
import EENavigator
import LarkCore
import LarkContainer
import RxSwift
import LarkAlertController
import UniverseDesignColor

private final class SetBoardcastInfo {
    let postId: String
    var title: String
    var endTime: Date

    init(postId: String, title: String, endTime: Date) {
        self.title = title
        self.endTime = endTime
        self.postId = postId
    }

    init(postId: String) {
        self.postId = postId
        self.title = ""
        let calendar = NSCalendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        if let todayStart = calendar.date(from: components) {
            self.endTime = calendar.date(byAdding: .day, value: 4, to: todayStart) ?? Date()
        } else {
            self.endTime = Date()
        }
    }
}

final class ReplaceBoardcastInfo {
    let boardcast: RawData.Broadcast
    var selected: Bool
    init(boardcast: RawData.Broadcast, selected: Bool) {
        self.boardcast = boardcast
        self.selected = selected
    }
}

enum BoardcastOperationType {
    case create([RawData.Broadcast])  //新建
    case edit(RawData.Broadcast)    //编辑
}

final class BoardcastViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, SetBoardcastWithInputCellDelegate, UserResolverWrapper {
    let userResolver: UserResolver
    private let operationType: BoardcastOperationType
    private var boardcastInfo: SetBoardcastInfo

    enum FunctionType {
        case setTitle
        case setEndTime
        case replaceBoardcast
    }
    private var dataSource: [FunctionType] = []
    private var replceBoardcastInfos: [ReplaceBoardcastInfo] = []
    private var inputBecomeFirstResponder: (() -> Void)?
    private var inputResignFirstResponder: (() -> Void)?
    @ScopedInjectedLazy private var postAPI: PostApiService?
    private let disposeBag = DisposeBag()

    private let originTitle: String

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SetBoardcastWithTextCell.self, forCellReuseIdentifier: SetBoardcastWithTextCell.indentify)
        tableView.register(SetBoardcastWithInputCell.self, forCellReuseIdentifier: SetBoardcastWithInputCell.indentify)
        tableView.tableFooterView = UIView()
        return tableView
    }()

    init(userResolver: UserResolver, postId: String, operationType: BoardcastOperationType) {
        self.userResolver = userResolver
        self.operationType = operationType
        dataSource = [.setTitle, .setEndTime]
        switch operationType {
        case .create(let boardcasts):
            if boardcasts.count >= 3 {
                dataSource.append(.replaceBoardcast)
                replceBoardcastInfos = boardcasts.map { (boardcast) -> ReplaceBoardcastInfo in
                    return ReplaceBoardcastInfo(boardcast: boardcast, selected: false)
                }
            }
            self.boardcastInfo = SetBoardcastInfo(postId: postId)
        case .edit(let boardcast):
            self.boardcastInfo = SetBoardcastInfo(postId: postId,
                                                  title: boardcast.title,
                                                  endTime: Date(timeIntervalSince1970: TimeInterval(boardcast.endTimeSec)))
        }
        self.originTitle = self.boardcastInfo.title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func closeBtnTapped() {
        if self.boardcastInfo.title != self.originTitle {
            let alertController = LarkAlertController()
            alertController.setContent(text: BundleI18n.Moment.Lark_Community_ExitChangesNoSaveNote)
            alertController.addCancelButton()
            alertController.addPrimaryButton(text: BundleI18n.Moment.Lark_Community_ExitButton, dismissCompletion: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            })
            userResolver.navigator.present(alertController, from: self, animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.inputBecomeFirstResponder?()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addCloseItem()
        switch operationType {
        case .create(let boardcasts):
            if boardcasts.count >= 3 {
                self.title = BundleI18n.Moment.Lark_Moments_ReplaceTrendingPost_Title
            } else {
                self.title = BundleI18n.Moment.Lark_Moments_PinToTrending_Title
            }
        case .edit(let boardcast):
            self.title = BundleI18n.Moment.Lark_Moments_DisplayInTrending_Title
        }
        let confirmButton = UIButton(type: .system)
        confirmButton.setTitle(BundleI18n.Moment.Lark_Community_Confirm, for: .normal)
        confirmButton.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        confirmButton.setTitleColor(UIColor.ud.B300.ud.withOver(UIColor.ud.N00.withAlphaComponent(0.5)),
                                 for: .disabled)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        confirmButton.addTarget(self, action: #selector(confirmClick), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: confirmButton)
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        self.view.addSubview(self.tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    @objc
    func confirmClick() {
        if self.boardcastInfo.endTime <= Date() {
            UDToast.showTips(with: BundleI18n.Moment.Lark_Moments_EndingTimePassedReselect_Toast, on: self.view)
            return
        }
        var newBoardcast = RawData.Broadcast()
        newBoardcast.title = self.boardcastInfo.title
        newBoardcast.endTimeSec = Int64(self.boardcastInfo.endTime.timeIntervalSince1970)
        newBoardcast.postID = self.boardcastInfo.postId
        let apiObservable: Observable<Void>?
        switch operationType {
        case .create:
            apiObservable = self.postAPI?.setboardcast(boardcast: newBoardcast, relpacePostId: selectedReplaceBoardcast()?.boardcast.postID)
        case .edit:
            apiObservable = self.postAPI?.setboardcast(boardcast: newBoardcast, relpacePostId: nil)
        }
        let hud = UDToast.showLoading(on: self.view)
        apiObservable?
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                hud.remove()
                UDToast.showSuccess(with: BundleI18n.Moment.Lark_Moments_AddedToTrendingRefresh_Toast, on: self.view)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [weak self] in
                    self?.dismiss(animated: true, completion: nil)
                })
            }, onError: { [weak self] (_) in
                guard let self = self else { return }
                hud.remove()
                UDToast.showFailure(with: BundleI18n.Moment.Lark_Moments_UnableToAddToTrendingTryAgain_Toast, on: self.view)
            }).disposed(by: self.disposeBag)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let functionType = dataSource[indexPath.row]
        switch functionType {
        case .setTitle:
            if let cell = tableView.dequeueReusableCell(withIdentifier: SetBoardcastWithInputCell.indentify) as? SetBoardcastWithInputCell {
                cell.set(title: BundleI18n.Moment.Lark_Moments_TitleInTrending_Subtitle, content: self.boardcastInfo.title)
                cell.delegate = self
                self.inputBecomeFirstResponder = cell.inputBecomeFirstResponder
                self.inputResignFirstResponder = cell.inputResignFirstResponder
                return cell
            }
        case .setEndTime:
            if let cell = tableView.dequeueReusableCell(withIdentifier: SetBoardcastWithTextCell.indentify) as? SetBoardcastWithTextCell {
                cell.set(title: BundleI18n.Moment.Lark_Moments_EndingTimeInTrending_Subtitle, content: self.boardcastInfo.endTime.format(with: "YYYY-MM-dd HH:mm"), contentTextColor: UIColor.ud.N900)
                return cell
            }
        case .replaceBoardcast:
            if let cell = tableView.dequeueReusableCell(withIdentifier: SetBoardcastWithTextCell.indentify) as? SetBoardcastWithTextCell {
                if let selectedPlaceBoardcast = selectedReplaceBoardcast() {
                    cell.set(title: BundleI18n.Moment.Lark_Moments_PostToBeReplaced_Subtiitle, content: selectedPlaceBoardcast.boardcast.title, contentTextColor: UIColor.ud.N900)
                } else {
                    cell.set(title: BundleI18n.Moment.Lark_Moments_PostToBeReplaced_Subtiitle, content: BundleI18n.Moment.Lark_Community_Select, contentTextColor: UIColor.ud.N500)
                }
                return cell
            }
        }
        return UITableViewCell(frame: .zero)
    }

    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let functionType = dataSource[indexPath.row]
        switch functionType {
        case .setTitle:
            break
        case .setEndTime:
            let vc = DatePickerForBoardcastViewControllerFactory.create(delegate: self, defaultDate: self.boardcastInfo.endTime)
            if Display.pad {
                self.inputResignFirstResponder?()
                vc.popoverPresentationController?.backgroundColor = .ud.N00
                MomentsIpadPopoverAdapter.popoverVC(vc,
                                                    fromVC: self,
                                                    sourceView: tableView.cellForRow(at: indexPath) ?? tableView,
                                                    preferredContentSize: vc.preferredContentSize,
                                                    permittedArrowDirections: .up)
            } else {
                userResolver.navigator.present(vc, from: self, animated: false)
            }
        case .replaceBoardcast:
            let vc = BoardcastReplceSelectViewControllerFactory.create(delegate: self, replceBoardcastInfos: replceBoardcastInfos)
            if Display.pad {
                self.inputResignFirstResponder?()
                vc.popoverPresentationController?.backgroundColor = .ud.N00
                let sourceView = tableView.cellForRow(at: indexPath)
                MomentsIpadPopoverAdapter.popoverVC(vc,
                                                    fromVC: self,
                                                    sourceView: tableView.cellForRow(at: indexPath) ?? tableView,
                                                    preferredContentSize: vc.preferredContentSize,
                                                    permittedArrowDirections: .up)
            } else {
                userResolver.navigator.present(vc, from: self, animated: false)
            }
        }
    }
    // swiftlint:enable did_select_row_protection

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 82
    }

    func textReachLimit(maxLength: Int) {
        UDToast.showTips(with: BundleI18n.Moment.Lark_Community_EnterNoMoreThanCharacters("\(maxLength)"), on: self.view)
    }

    func current(text: String) {
        self.boardcastInfo.title = text
        self.navigationItem.rightBarButtonItem?.isEnabled = self.confirmEnable()
    }

    func confirmEnable() -> Bool {
        let textEmpty = self.boardcastInfo.title.isEmpty
        let hasReplaced = replceBoardcastInfos.isEmpty || replceBoardcastInfos.contains(where: { $0.selected })
        return !textEmpty && hasReplaced
    }

    private func selectedReplaceBoardcast() -> ReplaceBoardcastInfo? {
        return self.replceBoardcastInfos.first(where: { $0.selected })
    }
}

extension BoardcastViewController: BoardcastReplceSelectViewControllerDelegate {
    func selected(boardcastId: String) {
        for boardcastInfo in replceBoardcastInfos {
            boardcastInfo.selected = boardcastInfo.boardcast.postID == boardcastId
        }
        self.tableView.reloadData()
        self.navigationItem.rightBarButtonItem?.isEnabled = self.confirmEnable()
    }
}

extension BoardcastViewController: DatePickerForBoardcastViewControllerDelegate {
    func selected(date: Date) {
        self.boardcastInfo.endTime = date
        self.tableView.reloadData()
        self.navigationItem.rightBarButtonItem?.isEnabled = self.confirmEnable()
    }
}
