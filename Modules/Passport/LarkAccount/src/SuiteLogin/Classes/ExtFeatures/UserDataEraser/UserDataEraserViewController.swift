//
//  UserDataEraserViewController.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/7/4.
//

import Foundation
import UniverseDesignProgressView
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignColor
import SnapKit
import LarkUIKit

protocol UserDataEraserDelegate: AnyObject {

    func dataEraseSuccess()

    func dataEraseFailed(with error: Error)
}

class UserDataEraserViewController: PassportBaseViewController {

    lazy var processView: UDProgressView = {
        UDProgressView()
    }()

    private let viewModel: UserDataEraserViewModel

    open weak var delegate: UserDataEraserDelegate?

    init(viewModel: UserDataEraserViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        //构建UI
        makeSubViews()
        //开始擦除数据
        viewModel.eraseUserData {[weak self] process in
            self?.processView.setProgress(CGFloat(process), animated: true)
        } completionHandler: { [weak self] result in
            switch result {
            case .success(_):
                self?.delegate?.dataEraseSuccess()
            case .failure(let error):
                self?.delegate?.dataEraseFailed(with: error)
            }
        }
    }

    private func makeSubViews() {

        let logoView = UIImageView(frame: .zero)
        logoView.backgroundColor = UIColor.clear
        logoView.image = BundleResources.AppResourceLogo.logo
        logoView.contentMode = .scaleAspectFill
        logoView.clipsToBounds = true

        let descLabel = UILabel()
        descLabel.font = UDFont.body2
        descLabel.textColor = UDColor.textCaption
        descLabel.text = I18N.Lark_ClearLocalCacheAtLogOut_ClearingKeepAppOpenPH
        descLabel.textAlignment = .center

        let topSpace = UIView()
        let bottomSpace = UIView()
        topSpace.isHidden = true
        bottomSpace.isHidden = true

        view.addSubview(topSpace)
        view.addSubview(logoView)
        view.addSubview(processView)
        view.addSubview(descLabel)
        view.addSubview(bottomSpace)

        //layout
        topSpace.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(bottomSpace)
        }
        logoView.snp.makeConstraints { make in
            make.top.equalTo(topSpace.snp.bottom)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(Layout.logoSize)
        }

        processView.snp.makeConstraints { make in
            make.top.equalTo(logoView.snp.bottom).offset(Layout.processViewTopMargin)
            make.centerX.equalToSuperview()
            make.height.equalTo(Layout.processViewHeight)
            if Display.pad {
                make.width.equalTo(Layout.processViewWidthForIpad)
            } else {
                make.left.equalToSuperview().offset(Layout.itemPadding)
                make.right.equalToSuperview().offset(-Layout.itemPadding)
            }
        }

        descLabel.snp.makeConstraints { make in
            make.top.equalTo(processView.snp.bottom).offset(Layout.subTitleLabelTopMargin)
            if Display.pad {
                make.width.equalTo(Layout.subTitleLabelWidthForIpad)
                make.centerX.equalToSuperview()
            } else {
                make.left.equalToSuperview().offset(Layout.itemPadding)
                make.right.equalToSuperview().offset(-Layout.itemPadding)
            }
        }

        bottomSpace.snp.makeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom)
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(topSpace)
        }
    }

}

fileprivate struct Layout {
    static let logoSize = 80
    static let processViewTopMargin = 32
    static let processViewWidthForIpad = 280
    static let processViewHeight = 8
    static let itemPadding = 48
    static let subTitleLabelWidthForIpad = 320
    static let subTitleLabelTopMargin = 12
}
