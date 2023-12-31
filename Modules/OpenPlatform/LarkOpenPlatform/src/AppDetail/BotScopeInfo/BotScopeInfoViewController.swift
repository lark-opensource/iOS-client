//
//  BotScopeInfoViewController.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/4/26.
//

import Foundation
import LarkUIKit
import SnapKit
import UniverseDesignIcon
import Swinject
import RxSwift

public final class BotScopeInfoViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 32
        return tableView
    }()
    
    private lazy var titleNaviBar: TitleNaviBar = {
        let titleNaviBar = TitleNaviBar(titleString: BundleI18n.GroupBot.Lark_Bot_BotPermissionsTtl)
        titleNaviBar.backgroundColor = UIColor.ud.bgBody
        return titleNaviBar
    }()
    
    private lazy var emptyView: BotScopeEmptyView = BotScopeEmptyView()
    
    private let disposeBag = DisposeBag()
    private var scopeInfoList: [ScopeInfo]?
    
    public init(scopeInfoList: [ScopeInfo]) {
        self.scopeInfoList = scopeInfoList
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        isNavigationBarHidden = true
        self.view.addSubview(titleNaviBar)
        self.view.backgroundColor = UIColor.ud.bgBody
        
        titleNaviBar.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview()
        }
        let backButton = UIButton(type: .custom)
        let image = UDIcon.leftOutlined.ud.withTintColor(UIColor.ud.iconN1)
        backButton.setImage(image, for: .normal)
        backButton.rx.tap.asDriver().drive(onNext: { [weak self] in
            guard let `self` = self else { return }
            self.navigationController?.popViewController(animated: true)
        }).disposed(by: disposeBag)
        titleNaviBar.contentview.addSubview(backButton)
        backButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(17)
            make.height.width.equalTo(24)
        }
        guard let scopeInfoList =  self.scopeInfoList, scopeInfoList.count > 0 else {
            self.view.addSubview(emptyView)
            emptyView.snp.makeConstraints { make in
                make.left.right.centerX.centerY.equalToSuperview()
            }
            return
        }
        self.view.addSubview(tableView)
        tableView.register(BotScopeInfoCell.self, forCellReuseIdentifier: NSStringFromClass(BotScopeInfoCell.self))
        tableView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(titleNaviBar.snp.bottom)
        }
    }
    
    // MARK: - UITableViewDataSource
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(BotScopeInfoCell.self), for: indexPath) as? BotScopeInfoCell else {
            return UITableViewCell(frame: .zero)
        }
        guard let scopeInfo = scopeInfoList?[indexPath.row] else {
            return UITableViewCell(frame: .zero)
        }
        cell.updateInfo(scopeInfo: scopeInfo)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scopeInfoList?.count ?? 0
    }
}
