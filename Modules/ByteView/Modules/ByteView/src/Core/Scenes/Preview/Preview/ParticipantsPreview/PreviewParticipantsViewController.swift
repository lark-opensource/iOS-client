//
//  PreviewParticipantsViewController.swift
//  ByteView
//
//  Created by yangyao on 2020/11/19.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.

import UIKit
import SnapKit
import Action
import RxSwift
import RxCocoa
import ByteViewCommon
import ByteViewUI

class PreviewParticipantsViewController: VMViewController<PreviewParticipantsViewModel> {
    private let disposeBag = DisposeBag()

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if VCScene.rootTraitCollection?.horizontalSizeClass == .compact {
            // 退出时恢复window背景色
            customBackgroundView.removeFromSuperview()
        }
    }

    lazy var customBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.staticBlack.withAlphaComponent(0.35)
        return view
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarBgColor(UIColor.ud.bgFloat)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if VCScene.rootTraitCollection?.horizontalSizeClass == .compact,
           let currentWindow = self.view.window,
           let rootVC = currentWindow.rootViewController,
           let rootVCWindowView = currentWindow.subviews.first(where: { rootVC.view.isDescendant(of: $0) }) {
            currentWindow.insertSubview(customBackgroundView, belowSubview: rootVCWindowView)
            customBackgroundView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
        }
    }

    override func setupViews() {
        let titleLabel = UILabel()
        self.navigationItem.titleView = titleLabel
        viewModel.numberHints
            .drive(onNext: { (num) in
                titleLabel.attributedText = NSAttributedString(string: num, config: .h3)
                titleLabel.sizeToFit()
            })
            .disposed(by: rx.disposeBag)
        setupTableview()
    }

    override func bindViewModel() {
        super.bindViewModel()
        if viewModel.didSelectCellCallback == nil {
            viewModel.didSelectCellCallback = { [weak self] participant, _ in
                guard let self = self else { return }
                self.viewModel.gotoUserProfile(participant.userId, from: self)
            }
        }
        viewModel.participantsRelay
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] pariticpants in
                guard let self = self else { return }
                if pariticpants.isEmpty {
                    self.setupBusinessLoading()
                } else {
                    self.hideBusinessLoading()
                }
            }).bind(to: tableView.rx.items(cellIdentifier: String(describing: PreviewParticipantCell.self), cellType: PreviewParticipantCell.self)) { [weak self] _, item, cell in
                guard let self = self else { return }
                cell.isRelationTagEnabled = self.viewModel.isRelationTagEnabled
                cell.previewedParticipant = item
                cell.delegate = self
                if let model = self.viewModel {
                    cell.selectionStyle = (model.didSelectCellCallback != nil) ? .default : .none
                    cell.updateRelationOrExternalTag()
                    cell.resetLayout(isPopover: model.isPopover)
                }
            }
            .disposed(by: disposeBag)

        tableView.rx.modelSelected(PreviewParticipantWrapper.self)
            .subscribe(onNext: { [weak self] wrapper in
                if let self = self {
                    self.viewModel.didSelectCellCallback?(wrapper.participant, self)
                }
            })
            .disposed(by: disposeBag)

        viewModel.rxLoadMoreState
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] loadMoreState in
                Self.logger.info("rxLoadMoreState:\(loadMoreState)")
                self?.doUpdateLoadMoreState(loadMoreState)
            })
            .disposed(by: disposeBag)
    }

    private var fullTitleView: FullTitleView?

    private lazy var tableView: BaseTableView = {
        let tableView = BaseTableView(frame: .zero, style: .plain)
        tableView.showsVerticalScrollIndicator = viewModel.isPopover
        tableView.rowHeight = (viewModel.isPopover ? 64 : 66)
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.ud.bgFloat
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        let headerHeight: CGFloat = Display.pad ? 4 : 8
        if viewModel.isPopover {
            tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: headerHeight, height: headerHeight))
            tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: headerHeight, height: headerHeight))
        }
        tableView.register(PreviewParticipantCell.self, forCellReuseIdentifier: String(describing: PreviewParticipantCell.self))
        return tableView
    }()

    private func setupTableview() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)
    }

    private lazy var businessLoadingView: BusinessLoadingView = {
        var view = BusinessLoadingView()
        view.backgroundColor = UIColor.ud.N00
        return view
    }()

    func dismissSelf() {
        if viewModel.isPopover {
            self.view.alpha = 0
            self.dismiss(animated: false)
        } else {
            self.navigationController?.popViewController(animated: false)
        }
    }

    var loadMoreAnimator: RefreshAnimator {
        return RefreshAnimator(frame: .zero)
    }

    lazy var errorFooterView: UIView = {
        let view = UIView(frame: .zero)
        let tap = UITapGestureRecognizer(target: self, action: #selector(loadMore))
        view.addGestureRecognizer(tap)
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.attributedText = NSAttributedString(string: I18n.View_G_UnableToLoadRetryButton, config: .tinyAssist)
        label.textAlignment = .center
        view.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-VCScene.safeAreaInsets.bottom)
        }
        return view
    }()

    @objc private func loadMore() {
        viewModel.loadMore()
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        fullTitleView?.hide(animated: false)
    }

    private func showFullTitle(_ text: String, on view: UIView? = nil) {
        fullTitleView = FullTitleView(title: text)
        if VCScene.rootTraitCollection?.isRegular == true, let view = view {
            fullTitleView?.show(on: view, from: self, animated: false)
        } else {
            fullTitleView?.showFullScreen(animated: false, from: self)
        }
    }
}

extension PreviewParticipantsViewController: PreviewParticipantCellDelegate {
    func didTapNameLabel(label: UILabel) {
        guard let text = label.text else { return }
        showFullTitle(text, on: label)
    }
}

extension PreviewParticipantsViewController {
    private func doUpdateLoadMoreState(_ loadMoreState: ListLoadMoreState) {
        Self.logger.info("doUpdateLoadMoreState:\(loadMoreState)")
        switch loadMoreState {
        case .none:
            hideErrorFooterView()
            tableView.es.removeRefreshFooter()
        case .noMore:
            hideErrorFooterView()
            tableView.es.stopLoadingMore()
            tableView.es.noticeNoMoreData()
        case .loading:
            if viewModel.participantsRelay.value.isEmpty {
                businessLoadingView.showLoading()
            } else {
                hideErrorFooterView()
                setupFooterIfNeeded()
                tableView.footer?.startRefreshing()
            }
        case .hasMore:
            hideErrorFooterView()
            setupFooterIfNeeded()
            tableView.es.stopLoadingMore()
            tableView.es.resetNoMoreData()
        case .error:
            if viewModel.participantsRelay.value.isEmpty {
                businessLoadingView.showFailed { [weak self] in
                    self?.loadMore()
                }
            } else {
                showErrorFooterView()
                setupFooterIfNeeded()
                tableView.es.resetNoMoreData()
                tableView.es.stopLoadingMore()
            }
        }
    }

    private func setupFooterIfNeeded() {
        guard tableView.footer == nil else {
            tableView.footer?.isHidden = false
            return
        }
        tableView.es.addBVInfiniteScrolling(animator: loadMoreAnimator, handler: { [weak self] in
            guard let self = self else { return }
            let state = self.viewModel.rxLoadMoreState.value
            if state == .error || state == .hasMore {
                self.viewModel.loadMore()
            }
        })
    }

    private func showErrorFooterView() {
        errorFooterView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 48 + VCScene.safeAreaInsets.bottom)
        tableView.tableFooterView = errorFooterView
    }

    private func hideErrorFooterView() {
        tableView.tableFooterView = nil
    }

    private func hideBusinessLoading() {
        businessLoadingView.removeFromSuperview()
    }

    private func setupBusinessLoading() {
        if businessLoadingView.superview == nil {
            view.addSubview(businessLoadingView)
            businessLoadingView.snp.makeConstraints { (maker) in
                maker.left.right.bottom.equalToSuperview()
                maker.top.equalTo(-(UIApplication.shared.statusBarFrame.height + (navigationController?.navigationBar.intrinsicContentSize.height ?? 0)))
            }
        }
        view.bringSubviewToFront(businessLoadingView)
    }
}
