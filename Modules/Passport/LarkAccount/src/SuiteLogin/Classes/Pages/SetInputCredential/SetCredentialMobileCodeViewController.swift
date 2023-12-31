//
//  SetCredentialMobileCodeViewController.swift
//  LarkAccount
//
//  Created by bytedance on 2021/9/7.
//

import LarkUIKit
import LarkLocalizations

struct SetCredentialMobileCodeViewControllerLayout {
    let headerHeight = 56
    let cellHeight = 50
    let space = 8
    let bottomSpace = 34
    let popoverWidth = 375
    let popoverInsetTop = 15
}

public final class SetCredentialMobileCodeViewController: UIViewController {
    fileprivate var tableView: UITableView = UITableView(frame: CGRect.zero, style: .grouped)
        
    private var confirmBlock: ((MobileCode) -> Void)?
    
    private var dataSource: [MobileCode] = []

    private var headerView: UIView = UIView()
    
    private let CL = SetCredentialMobileCodeViewControllerLayout()

    public init(
        countryList: [MobileCode],
        confirmBlock: ((MobileCode) -> Void)?
    ) {
    
        self.dataSource = countryList
        self.confirmBlock = confirmBlock
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.modalPresentationStyle == .popover {
            preferredContentSize = CGSize(width: CGFloat(CL.popoverWidth), height: contentHeight(count: dataSource.count))
        }
        
        self.view.backgroundColor = UIColor.ud.N100
        
        headerView.backgroundColor = UIColor.ud.N00
        self.view.addSubview(headerView)
        var headerInsetTop = 0
        if self.modalPresentationStyle == .popover {
            headerInsetTop = CL.popoverInsetTop
        }
        headerView.snp.makeConstraints { (make) in
            make.top.equalTo(headerInsetTop)
            make.left.right.equalToSuperview()
            make.height.equalTo(CL.headerHeight)
        }

        let titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.text = BundleI18n.suiteLogin.Lark_Login_TitleOfCountryCode
        headerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }

        let closeImageView = UIImageView(image: Resources.navigation_close_light.ud.withTintColor(UIColor.ud.iconN1))
        headerView.addSubview(closeImageView)
        closeImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(24)
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.height.width.equalTo(24)
        }
        closeImageView.lu.addTapGestureRecognizer(action: #selector(dismissVC), target: self, touchNumber: 1)


        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(headerView.snp.bottom).offset(CL.space)
            make.left.right.bottom.equalToSuperview()
        }

        tableView.backgroundColor = UIColor.ud.N00
        tableView.sectionIndexBackgroundColor = UIColor.clear
        tableView.sectionIndexColor = UIColor.ud.N500
        tableView.separatorStyle = .none
        tableView.rowHeight = CGFloat(CL.cellHeight)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false
        tableView.keyboardDismissMode = .onDrag
        let identifier = String(describing: SetCredentialMobileCodeCell.self)
        tableView.register(SetCredentialMobileCodeCell.self, forCellReuseIdentifier: identifier)
    }

    @objc
    private func dismissVC() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func contentHeight(count: Int) -> CGFloat {
        let CL = SetCredentialMobileCodeViewControllerLayout()
        var base = CL.headerHeight + CL.space + count * CL.cellHeight
        if self.modalPresentationStyle == .popover {
            base += CL.popoverInsetTop
        }else {
            base += CL.bottomSpace
        }
        return CGFloat(base)
    }
}

extension SetCredentialMobileCodeViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)
        let mobileCode: MobileCode = dataSource[indexPath.row]
        self.confirmBlock?(mobileCode)
        self.dismissVC()
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = SetCredentialMobileCodeCell()
        let data = dataSource[indexPath.row]
        cell.setCell(name: data.name, code: data.code)
        return cell
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return nil
    }

    public func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index + 1
    }
}

