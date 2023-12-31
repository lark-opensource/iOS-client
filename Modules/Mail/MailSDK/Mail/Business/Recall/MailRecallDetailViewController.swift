//
//  MailRecallDetailViewController.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2020/5/12.
//

import UIKit
import LarkUIKit
import RxSwift

final class MailRecallDetailViewController: MailBaseViewController, UITableViewDelegate {

    private let messageId: String
    private let detailTableView = UITableView(frame: .zero, style: .grouped)

    private let bag = DisposeBag()
    private let viewModel: MailRecallDetailViewModel
    private let accountContext: MailAccountContext

    private lazy var loadFailView: MailLoadErrorView = {
        let loadFailView = MailLoadErrorView(frame: .zero, retryHandler: { [weak self] in
            self?.onErrorRetry()
        })
        view.addSubview(loadFailView)
        loadFailView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        return loadFailView
    }()

    init(messageId: String, accountContext: MailAccountContext) {
        self.messageId = messageId
        self.accountContext = accountContext
        self.viewModel = MailRecallDetailViewModel(messageId: messageId)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindToViewModel()
    }
    


    private func setupViews() {
        view.backgroundColor = UIColor.ud.bgBodyOverlay
        view.addSubview(detailTableView)

        detailTableView.register(MailRecallDetailTableViewCell.self,
                                 forCellReuseIdentifier: MailRecallDetailTableViewCell.identifier)
        detailTableView.separatorStyle = .none
        detailTableView.allowsSelection = false
        detailTableView.estimatedRowHeight = 66
        detailTableView.backgroundColor = UIColor.ud.bgBody
        detailTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 0.01))
        detailTableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 3, left: 0, bottom: 0, right: 0))
        }
    }

    private func bindToViewModel() {
        title = viewModel.title

        viewModel.cellVMs
            .asObservable()
            .bind(to: detailTableView.rx.items(cellIdentifier: MailRecallDetailTableViewCell.identifier, cellType: MailRecallDetailTableViewCell.self)) { (_, vm, cell) in
                cell.setup(with: vm)
            }.disposed(by: bag)

        viewModel.showLoading
            .drive(onNext: { [weak self] (showLoading) in
                if showLoading {
                    self?.toggleErrorView(show: false)
                    self?.showLoading()
                } else {
                    self?.hideLoading()
                }
                }, onCompleted: nil, onDisposed: nil)
            .disposed(by: bag)

        viewModel.showError
            .drive(onNext: { [weak self] (showError) in
                self?.toggleErrorView(show: showError)
                }, onCompleted: nil, onDisposed: nil)
            .disposed(by: bag)

        detailTableView.rx.setDelegate(self).disposed(by: bag)
    }

    private func toggleErrorView(show: Bool) {
        if show {
            hideLoading()
            loadFailView.alpha = 1
            InteractiveErrorRecorder.recordError(event: .recall_detail_error_page,
                                                 errorCode: .rust_error,
                                                 tipsType: .error_page)
        } else {
            UIView.animate(withDuration: timeIntvl.uiAnimateNormal, animations: {
                self.loadFailView.alpha = 0.0
            })
        }
    }

    @objc
    func onErrorRetry() {
        viewModel.fetch()
    }

    // MARK: - UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        let label = UILabel()
        label.text = viewModel.bannerText
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 14)
        header.addSubview(label)
        let constraintRect = CGSize(width: tableView.bounds.width - 32, height: .greatestFiniteMagnitude)
        let boundingRect = (label.text as NSString?)?.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin,
                                                                   attributes: [.font: label.font ?? UIFont.systemFont(ofSize: 14)], context: nil) ?? .zero
        label.frame = CGRect(x: 16, y: 15, width: tableView.bounds.width - 32, height: boundingRect.height)
        header.backgroundColor = UIColor.ud.bgBody
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let constraintRect = CGSize(width: tableView.bounds.width - 32, height: .greatestFiniteMagnitude)
        let boundingRect = (viewModel.bannerText as NSString).boundingRect(with: constraintRect, options: .usesLineFragmentOrigin,
                                                                           attributes: [.font: UIFont.systemFont(ofSize: 14)], context: nil)
        return boundingRect.height + 15
    }
}
