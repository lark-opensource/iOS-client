//
//  UserInfoListViewController.swift
//  SKCommon
//
//  Created by GuoXinyi on 2023/1/15.
//

import UIKit
import SnapKit
import SKResource
import RxCocoa
import RxSwift
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignEmpty
import UniverseDesignIcon
import SKUIKit

public final class UserInfoListViewController: BaseViewController {
    
    public var supportOrientations: UIInterfaceOrientationMask = .portrait
    
    private let data: [UserInfoData.UserData]
    
    private let toProfileAction: ((UserInfoData.UserData) -> Void)?
    
    private let tableView: UITableView = {
        let vi = UITableView(frame: .zero, style: .plain)
        vi.register(UserInfoCell.self, forCellReuseIdentifier: UserInfoCell.defaultReuseId)
        vi.backgroundColor = UDColor.bgBody
        vi.separatorStyle = .none
        vi.alwaysBounceVertical = true
        return vi
    }()
    
    private let emptyView: UDEmptyView = {
        let config = UDEmptyConfig(type: .noData)
        return UDEmptyView(config: config)
    }()
    
    private(set) lazy var closeButton = UIButton().construct { it in
        it.setImage(UDIcon.closeSmallOutlined, withColorsForStates: [
            (UDColor.iconN1, .normal),
            (UDColor.iconN3, .highlighted),
            (UDColor.iconDisabled, .disabled)
        ])
        it.hitTestEdgeInsets = UIEdgeInsets(edges: -10)
    }
    
    public init(data: [UserInfoData.UserData], toProfileAction: ((UserInfoData.UserData) -> Void)?) {
        self.data = data
        self.toProfileAction = toProfileAction
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        addCloseBarItemIfNeed()
        subviewsInit()
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }
    
    private func addCloseBarItemIfNeed() {
        if self.navigationController?.modalPresentationStyle == .formSheet {
            navigationBar.addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.leading.equalTo(view.safeAreaLayoutGuide.snp.leading).inset(16)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(24)
            }
            closeButton.addTarget(self, action: #selector(didClickedCloseBarItem), for: .touchUpInside)
        }
    }
    
    @objc
    func didClickedCloseBarItem() {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func subviewsInit() {
        view.backgroundColor = UDColor.bgBody
        view.insertSubview(tableView, belowSubview: navigationBar)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom)
        }
        if data.count == 0 {
            view.addSubview(emptyView)
            emptyView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension UserInfoListViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserInfoCell.defaultReuseId, for: indexPath)
        if let vCell = cell as? UserInfoCell {
            vCell.update(data[indexPath.row])
            vCell.showSpLine(indexPath.row != 0)
            vCell.avatarAction = { [weak self] user in
                self?.toProfileAction?(user)
            }
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        72
    }
}
