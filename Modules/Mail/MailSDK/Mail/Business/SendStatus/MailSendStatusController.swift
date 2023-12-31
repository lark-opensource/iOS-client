//
//  MailSendStatusController.swift
//  MailSDK
//
//  Created by tanghaojin on 2021/8/17.
//

import Foundation
import RxSwift
import UniverseDesignButton

class MailSendStatusController: MailBaseViewController, UITableViewDelegate, UITableViewDataSource {
    let headerViewHeight: CGFloat = 44
    var loadingStartTime: DispatchTime = .now()
    var viewModel: MailSendStatusViewModel
    private var disposeBag = DisposeBag()
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(MailSendStatusCell.self, forCellReuseIdentifier: MailSendStatusCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView.init(frame: CGRect.zero)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.rowHeight = MailSendStatusCell.cellHeight
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.estimatedRowHeight = 0.0
        tableView.estimatedSectionFooterHeight = 0.0
        tableView.estimatedSectionHeaderHeight = 0.0
        return tableView
    }()

    lazy var headerViewText: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.ud.textTitle
        return label
    }()
    lazy var headerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: headerViewHeight))
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(headerViewText)
        view.addSubview(refreshBtn)
        headerViewText.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalTo(view.snp.centerY)
        }
        refreshBtn.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-12)
            make.centerY.equalTo(view.snp.centerY)
        }
        return view
    }()
    lazy var refreshBtn: UDButton = {
        let btnType: UDButtonUIConifg.CustomButtonType = (CGSize(width: 0, height: 28), 4, UIFont.systemFont(ofSize: 14), .zero)
        var btnConfig = UDButtonUIConifg.textBlue
        btnConfig.type = .custom(type: btnType)
        let btn = UDButton(btnConfig)
        btn.setTitle(BundleI18n.MailSDK.Mail_Send_Refresh, for: .normal)
        btn.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.loadingStartTime = .now()
            self?.refreshBtn.showLoading()
            self?.viewModel.refreshDetailMessages(errorHandler: {
                self?.refreshBtn.hideLoading()
            })
        }).disposed(by: disposeBag)
        return btn
    }()
    
    private let accountContext: MailAccountContext

    init(accountContext: MailAccountContext, messageId: String, threadId: String, labelId: String) {
        self.accountContext = accountContext
        self.viewModel = MailSendStatusViewModel(messageId: messageId, threadId: threadId, labelId: labelId)
        super.init(nibName: nil, bundle: nil)
        self.viewModel.bindDataSourceToVC = { [weak self] in
            guard let `self` = self else { return }
            self.rebindDataSource()
        }
        self.viewModel.bindHeaderText = { [weak self] (processText) in
            guard let `self` = self else { return }
            self.bindHeaderText(processText)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.N300
        self.view.addSubview(headerView)
        headerView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(0.5)
            make.left.right.equalToSuperview()
            make.height.equalTo(headerViewHeight)
        }
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(headerView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        self.title = BundleI18n.MailSDK.Mail_Send_SendingStatus
        self.viewModel.refreshDetailMessages()
        self.showLoading()
    }
    


    func rebindDataSource() {
        self.hideLoading()
        // loading 至少显示 1.2s 防止闪烁
        let loadingTime: Double = 1.2
        DispatchQueue.main.asyncAfter(deadline: self.loadingStartTime + loadingTime) {
            self.refreshBtn.hideLoading()
        }
        self.tableView.reloadData()
    }

    func bindHeaderText(_ processText: String) {
        let originText = BundleI18n.MailSDK.Mail_Send_SentDone(processText)
        let progressRange = originText.range(of: processText)
        var converRange: NSRange?
        if let progress = progressRange {
            converRange = NSRange(progress, in: originText)
        }
        let attText = NSMutableAttributedString(string: originText,
                                                attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .regular),
                                                             .foregroundColor: UIColor.ud.textTitle])
        if let range = converRange {
            attText.addAttributes([.foregroundColor: UIColor.ud.textPlaceholder],
                                  range: range)
        }
        self.headerViewText.attributedText = attText
    }

    // MARK: - tableView delegate & dataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MailSendStatusCell.identifier, for: indexPath as IndexPath)
        if cell is MailSendStatusCell, let dataSource = self.viewModel.dataSource {
            cell.isUserInteractionEnabled = false
            if indexPath.row < dataSource.count {
                let model = dataSource[indexPath.row]
                (cell as? MailSendStatusCell)?.updateDetailModel(model: model)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.dataSource?.count ?? 0
    }
}
