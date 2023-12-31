//
//  ReactionDetailTableController.swift
//  LarkChat
//
//  Created by kongkaikai on 2018/12/11.
//

import Foundation
import UIKit
import RxSwift
import LarkPageController
import LarkUIKit

final class ReactionDetailTableController: PageInnerTableViewController {
    private var disposeBag = DisposeBag()
    var viewModel: ReactionDetailTableViewModel? {
        didSet { addViewModelReloadObserver() }
    }

    private var emptyCoverView = UIView()
    private var loadingView = LoadingPlaceholderView()
    private lazy var loadingFail: LoadFaildRetryView = {
        let view = LoadFaildRetryView()
        view.isHidden = true
        emptyCoverView.addSubview(view)
        view.snp.makeConstraints({ (maker) in
            maker.edges.equalToSuperview()
        })
        view.retryAction = { [weak self] in
            self?.tryToReloadData()
        }
        view.accessibilityIdentifier = "reaction.detail.page.failed.retry"
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .none
        tableView.register(
            ReactionDetailTableViewCell.self,
            forCellReuseIdentifier: NSStringFromClass(ReactionDetailTableViewCell.self)
        )
        customInitLoading()

        self.tableView.accessibilityIdentifier = "reation.detail.page.table"
    }

    private func customInitLoading() {
        emptyCoverView.backgroundColor = UIColor.ud.N00
        view.addSubview(emptyCoverView)
        emptyCoverView.accessibilityIdentifier = "reaction.detail.page.emptyCoverView"

        emptyCoverView.snp.makeConstraints { (maker) in
            maker.left.top.width.height.equalToSuperview()
        }

        emptyCoverView.addSubview(loadingView)
        loadingView.snp.makeConstraints({ (maker) in
            maker.edges.equalToSuperview()
        })
        loadingView.accessibilityIdentifier = "reaction.detail.page.loadingView"

        // chatters.chatters 有值则不显示Loading
        if viewModel?.chatters.isEmpty != false {
            emptyCoverView.isHidden = false
            loadingView.animationView.play()
        }
    }

    deinit {
        loadingView.animationView.stop()
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.chatters.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: NSStringFromClass(ReactionDetailTableViewCell.self),
            for: indexPath
        )

        if let detailCell = cell as? ReactionDetailTableViewCell,
            let chatter = viewModel?.chatter(at: indexPath.row) {

            detailCell.avatarImageFetcher = { [weak self] (chatter: Chatter, callback: @escaping (UIImage) -> Void) in
                guard let viewModel = self?.viewModel else { return }
                viewModel.delegate?.reactionDetailTableFetchChatterAvatar(
                    message: viewModel.message,
                    chatter: chatter,
                    callback: callback
                )
            }

            detailCell.chatter = chatter
        }
        cell.accessibilityIdentifier = "reaction.detail.page.cell.\(indexPath.row)"
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)

        viewModel?.showPersonCard(at: indexPath.row)
    }

    override func reloadData() {
        super.reloadData()

        self.disposeBag = DisposeBag()

        // 重新添加 reloadData 事件监听
        self.addViewModelReloadObserver()

        self.showLoading()
        self.viewModel?.reload()
    }

    private func addViewModelReloadObserver() {
        viewModel?.reloadData
            .drive(onNext: { [weak self] _ in
                self?.configFooter()
                self?.tableView.reloadData()
                self?.setCoverViewStatus()
            })
            .disposed(by: disposeBag)

        viewModel?.startLoading
            .drive(onNext: { [weak self] _ in
                self?.setCoverViewStatus()
            })
            .disposed(by: disposeBag)
    }
}

// MARK: error & empty()
extension ReactionDetailTableController {
    fileprivate func setCoverViewStatus() {

        guard viewModel?.error != nil || viewModel?.chatters.isEmpty == true else {
            loadingView.animationView.stop()
            emptyCoverView.isHidden = true
            return
        }

        emptyCoverView.isHidden = false
        if viewModel?.error != nil {
            loadingView.animationView.stop()
            loadingFail.isHidden = false
            loadingView.isHidden = true
        } else {
            showLoading()
        }
    }

    fileprivate func tryToReloadData() {
        viewModel?.startLoadChatters()
        showLoading()
    }

    /// 显示加载中
    fileprivate func showLoading() {
        loadingFail.isHidden = true
        loadingView.isHidden = false
        if !loadingView.animationView.isAnimationPlaying {
            loadingView.animationView.play()
        }
    }

    fileprivate func configFooter() {
        if let viewModel = viewModel {
            tableView.tableFooterView = viewModel.delegate?.reactionCustomFooter(message: viewModel.message,
                                                                                 reaction: viewModel.reaction,
                                                                                 chatters: viewModel.chatters)
        }
    }
}
