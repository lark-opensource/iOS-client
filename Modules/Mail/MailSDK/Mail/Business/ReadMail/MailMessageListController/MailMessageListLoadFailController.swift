//
//  MailMessageListLoadFailController.swift
//  MailSDK
//
//  Created by Ender on 2022/9/15.
//

import LarkUIKit
import UniverseDesignIcon

class MailMessageListLoadFailController: MailBaseViewController {
    enum ErrorType {
        case empty
        case netError
        case accountError
    }

    private var errorType: ErrorType
    private let errorIcon = UIImageView()
    private let errorMessage = UILabel()
    private let accountContext: MailAccountContext

    init(errorType: ErrorType, accountContext: MailAccountContext) {
        self.errorType = errorType
        self.accountContext = accountContext
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    private lazy var loadFailView: UIView = {
        let container = UIView()
        switch errorType {
        case .empty:
            errorIcon.image = Resources.mail_load_fail_icon
            errorMessage.text = BundleI18n.MailSDK.Mail_ReadMailBot_UnableToView_Empty
        case .netError:
            errorIcon.image = Resources.feed_error_icon
            errorMessage.text = BundleI18n.MailSDK.Mail_ReadMailBot_UnableToViewUnstableNetwork_Empty
        case .accountError:
            errorIcon.image = Resources.mail_load_fail_icon
            errorMessage.text = BundleI18n.MailSDK.Mail_ReadMailBot_ReceivingAccountError_empty
        }
        errorMessage.font = UIFont.systemFont(ofSize: 14)
        errorMessage.textColor = UIColor.ud.textPlaceholder
        errorMessage.textAlignment = .center
        errorMessage.numberOfLines = 0

        [errorIcon, errorMessage].forEach { container.addSubview($0) }
        errorIcon.snp.makeConstraints { (make) in
            make.top.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.height.width.equalTo(100)
        }
        errorMessage.snp.makeConstraints { (make) in
            make.top.equalTo(errorIcon.snp.bottom).offset(12)
            make.bottom.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
        return container
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBase
        isNavigationBarHidden = true
        let messageNavBar = MailMessageNavBar(type: .NormalNavBarType)
        if hasBackPage {
            let backBtn = TitleNaviBarItem(image: UDIcon.leftOutlined.withRenderingMode(.alwaysTemplate),
                                           action: { [weak self] (btn) in
                self?.backItemTapped()
            })
            messageNavBar.setLeftItems([backBtn])
        } else {
            let closeBtn = TitleNaviBarItem(image: UDIcon.closeOutlined.withRenderingMode(.alwaysTemplate),
                                            action: { [weak self] (btn) in
                self?.closeBtnTapped()
            })
            messageNavBar.setLeftItems([closeBtn])
        }
        view.addSubview(messageNavBar)
        messageNavBar.snp.makeConstraints { (make) in
            make.top.width.equalToSuperview()
        }
        view.addSubview(loadFailView)
        loadFailView.snp.makeConstraints { (make) in
            let centerYoffset = -(Display.realNavBarHeight() + Display.bottomSafeAreaHeight) / 2
            make.centerY.equalToSuperview().offset(centerYoffset)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().offset(-32)
        }
    }
}
