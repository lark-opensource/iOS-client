//
//  CertRetryViewController.swift
//  ByteView
//
//  Created by fakegourmet on 2020/8/24.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignIcon

class CertRetryViewController: CertBaseViewController {

    private struct Layout {
        static let imageWidth: CGFloat = 48
        static let imageTop: CGFloat = 181
        static let mainMsgTop: CGFloat = 14
        static let itemSpace: CGFloat = BaseLayout.itemSpace
    }

    override init(viewModel: CertBaseViewModel) {
        super.init(viewModel: viewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var imageView: UIImageView = {
        let icon = UDIcon.getIconByKey(.warningFilled, iconColor: .red, size: CGSize(width: Layout.imageWidth, height: Layout.imageWidth))
        return UIImageView(image: icon)
    }()

    lazy var mainMsgLabel: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.text = I18n.View_G_AuthenticationFailed
        lbl.font = .systemFont(ofSize: 16, weight: .regular)
        lbl.textColor = UIColor.ud.textTitle
        lbl.textAlignment = .center
        return lbl
    }()

    lazy var detailMsgLabel: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.font = .systemFont(ofSize: 14, weight: .regular)
        lbl.textColor = UIColor.ud.textCaption
        lbl.textAlignment = .center
        lbl.text = I18n.View_G_AuthenticationResultsNoMatch
        return lbl
    }()

    lazy var closeBtn: UIButton = {
        let button = UIButton(type: .custom)
        let image = UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.iconN1, size: CGSize(width: 24, height: 24))
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(didClickClose), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        nextButton.setTitle(I18n.View_G_AuthenticationRetry, for: .normal)
        nextButton.isEnabled = true
        setBackBtnHidden(true)

        view.addSubview(closeBtn)
        closeBtn.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-BaseLayout.itemSpace)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(BaseLayout.backButtonTopSpace)
            make.size.equalTo(CGSize(width: BaseLayout.backHeight, height: BaseLayout.backHeight))
        }

        moveBoddyView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(Layout.imageWidth)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(Layout.imageTop)
        }

        moveBoddyView.addSubview(mainMsgLabel)
        mainMsgLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(Layout.mainMsgTop)
            make.left.right.equalToSuperview().inset(Layout.itemSpace)
        }

        moveBoddyView.addSubview(detailMsgLabel)
        detailMsgLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(mainMsgLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(Layout.itemSpace)
        }

        nextButton.addTarget(self, action: #selector(didClickNext), for: .touchUpInside)
    }

    @objc private func didClickNext() {
        LiveCertTracks.trackLivenessFailPage(retry: true)
        guard let index = self.navigationController?.viewControllers.firstIndex(of: self),
              let toVc = self.navigationController?.viewControllers[index - 2] else {
            return
        }
        self.navigationController?.popToViewController(toVc, animated: true)
    }

    @objc override func didClickClose() {
        LiveCertTracks.trackLivenessFailPage(retry: false)
        self.dismiss(animated: true, completion: nil)
    }
}
