//
//  OtherAuthMethodViewController.swift
//  LarkAccount
//
//  Created by zhaoKejie on 2023/8/13.
//

import Foundation
import LarkUIKit
import LKCommonsLogging
import UniverseDesignIcon
import RxSwift

class OtherVerifyMethodViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let logger = Logger.plog(OtherVerifyMethodViewController.self, category: "OtherVerifyMethodViewController")

    private let disposeBag = DisposeBag()

    var titleText: String

    lazy var tableView: UITableView = {

        let tb = UITableView(frame: .zero, style: .plain)
        tb.lu.register(cellSelf: AuthTypeCell.self)
        tb.backgroundColor = .clear
        tb.separatorStyle = .none
        tb.dataSource = self
        tb.delegate = self
        tb.showsHorizontalScrollIndicator = false
        tb.showsVerticalScrollIndicator = false
        tb.estimatedSectionHeaderHeight = 0.01
        tb.estimatedSectionFooterHeight = 0.01
        tb.sectionHeaderHeight = UITableView.automaticDimension
        // 自动计算行高
        tb.rowHeight = UITableView.automaticDimension
        // 设置预估行高
        tb.estimatedRowHeight = 102

        return tb
    }()

    private let navigationBar = UINavigationBar()

    var dataSource: [AuthTypeCellData]

    var callbackSelect: (ActionIconType) -> Void

    init(title: String, verifyList: [Menu], callback: @escaping (ActionIconType) -> Void) {
        self.titleText = title
        callbackSelect = callback
        dataSource = Self.generateAuthTypeList(verifyList, selectCallback: callback)
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.ud.bgLogin
        let closeButtonImage = UDIcon.getIconByKey(.closeBoldOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN1)
        let closeButton = UIBarButtonItem(image: closeButtonImage,
                                          style: .plain, target: self, action: #selector(closeButtonTapped))
        closeButton.tintColor = UIColor.ud.iconN1
        // 创建一个导航栏项，并将关闭按钮添加到左边
        let navigationItem = UINavigationItem(title: self.titleText)
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundImage = UIImage.ud.fromPureColor(UIColor.ud.bgBody)
            navigationItem.standardAppearance = appearance
            navigationItem.scrollEdgeAppearance = appearance
        } else {
            navigationBar.backgroundColor = UIColor.ud.bgBody
        }
        navigationItem.leftBarButtonItem = closeButton

        // 将导航栏项设置给自定义的导航栏
        navigationBar.items = [navigationItem]

        // 将自定义导航栏添加到视图控制器的视图层次结构中
        view.addSubview(navigationBar)
        navigationBar.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        self.view.addSubview(tableView)
        tableView.contentInset = .init(top: 16, left: 0, bottom: 0, right: 0)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }

        view.bringSubviewToFront(navigationBar)
    }

    @objc func closeButtonTapped() {
        dismiss(animated: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func generateAuthTypeList(_ authTypeList: [Menu], selectCallback: @escaping (ActionIconType) -> Void) -> [AuthTypeCellData] {
        let result = authTypeList.map { item -> AuthTypeCellData in
            var image = UIImage()
            let iconUrl: String? = nil
            switch item.actionType {

            case .verifyEmail:
                image = BundleResources.UDIconResources.mailOutlined
            case .verifyMobile:
                image = BundleResources.UDIconResources.cellphoneOutlined
            case .verifyPwd:
                image = BundleResources.UDIconResources.lockOutlined
            case .verifySpareCode:
                image = BundleResources.UDIconResources.safePassOutlined
            case .verifyOTP:
                image = BundleResources.UDIconResources.otpOutLined
            case .verifyAppleID:
                image = Resource.V3.appleId.ud.withTintColor(UIColor.ud.iconN1)
            case .verifyGoogle:
                image = Resource.V3.googleAccount
            case .verifyBIdp:
                image = Resource.V3.icon_sso_outlined_24
            case .verifyFIDO:
                image = BundleResources.UDIconResources.fidoOutlined
            default:
                image = Resource.V3.idpAccount.ud.withTintColor(UIColor.ud.iconN1)
            }
            return AuthTypeCellData(icon: image,
                                    iconUrl: iconUrl,
                                    title: item.text,
                                    subtitle: item.desc,
                                    action: {
                                        selectCallback(item.actionType ?? .unknown)
                                        return .just(())
                                    })

        }
        return result
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let c = tableView.cellForRow(at: indexPath)
        if let cell = c as? AuthTypeCell {
            let cellData = self.dataSource[indexPath.row]
            cellData.action().subscribe {[weak self] _ in
                self?.logger.info("select \(cellData.title) verify and callback")
                self?.dismiss(animated: true)
            }.disposed(by: disposeBag)
        }
    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? AuthTypeCell
        cell?.updateSelection(true)
    }

    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? AuthTypeCell
        cell?.updateSelection(false)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < dataSource.count {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: AuthTypeCell.lu.reuseIdentifier,
                                                           for: indexPath) as? AuthTypeCell else {
                return UITableViewCell()
            }

            cell.data = self.dataSource[indexPath.row]
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        CGFLOAT_MIN
    }

    struct Layout {
        static let navigationBarHeight = 48
        static let cellHeight: CGFloat = 102
    }

}
