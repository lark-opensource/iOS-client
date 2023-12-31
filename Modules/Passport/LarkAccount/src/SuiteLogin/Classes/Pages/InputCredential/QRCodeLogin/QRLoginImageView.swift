//
//  QRLoginImageView.swift
//  LarkAccount
//
//  Created by Miaoqi Wang on 2021/1/19.
//

import Foundation
import QRCode
import RxSwift

class QRCodeLoginImageView: UIView {

    private lazy var okIcon: UIImageView = UIImageView(image: BundleResources.LarkAccount.V3.qrlogin_scanned)
    private let avatarView: UIImageView = UIImageView()
    private let qrCodeView: UIImageView = UIImageView()

    private let refreshBtn: DarkBackBtnView = DarkBackBtnView()
    private let disposeBag: DisposeBag = DisposeBag()
    private var content: String

    init(content: String, refreshAction: @escaping () -> Void) {
        self.content = content
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        self.layer.cornerRadius = Common.Layer.loginQRCodeRadius
        self.clipsToBounds = true

        addSubview(qrCodeView)
        qrCodeView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(Layout.qrCodeSize)
        }

        addSubview(avatarView)
        avatarView.layer.cornerRadius = Layout.avatarSize / 2
        avatarView.clipsToBounds = true
        avatarView.isHidden = true
        avatarView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: Layout.avatarSize, height: Layout.avatarSize))
        }

        addSubview(okIcon)
        okIcon.isHidden = true
        okIcon.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: Layout.okIconSize, height: Layout.okIconSize))
            make.trailing.equalTo(avatarView.snp.trailing).offset(Layout.okIconEdge)
            make.bottom.equalTo(avatarView.snp.bottom).offset(Layout.okIconEdge)
        }

        addSubview(refreshBtn)
        refreshBtn.rx.controlEvent(.touchUpInside)
            .subscribe { (_) in
                refreshAction()
            }.disposed(by: disposeBag)

        refreshBtn.isHidden = true
        refreshBtn.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        self.qrCodeView.image = QRCodeTool.createQRImg(str: content, size: Layout.qrCodeSize)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(content: String, avatarUrl: String?) {
        self.content = content
        self.qrCodeView.image = QRCodeTool.createQRImg(str: content, size: Layout.qrCodeSize)
        if let urlString = avatarUrl, let url = URL(string: urlString) {
            self.avatarView.isHidden = false
            self.okIcon.isHidden = false
            self.avatarView.kf.setImage(with: url)
            self.qrCodeView.alpha = 0.2
        } else {
            self.avatarView.image = nil
            self.qrCodeView.alpha = 1.0
            self.okIcon.isHidden = true
            self.avatarView.isHidden = true
        }
    }

    func revalid() {
        self.refreshBtn.isHidden = true
    }

    func invalid() {
        update(content: content, avatarUrl: nil)
        self.refreshBtn.isHidden = false
    }
}

extension QRCodeLoginImageView {
    enum Layout {
        static let size: CGFloat = 200
        static let qrCodeSize: CGFloat = 184
        static let avatarSize: CGFloat = 68
        static let okIconSize: CGFloat = 24
        static let okIconEdge: CGFloat = 2
    }
}

class DarkBackBtnView: UIControl {
    private lazy var label: UILabel = {
        let lb = UILabel()
        lb.text = I18N.Lark_Login_RefreshQRCode
        lb.textAlignment = .center
        lb.textColor = UIColor.ud.primaryOnPrimaryFill
        lb.font = UIFont.boldSystemFont(ofSize: 14)
        return lb
    }()

    private let imageView: UIImageView = UIImageView(image: BundleResources.UDIconResources.refreshOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill))

    override init(frame: CGRect) {
        super.init(frame: frame)

        let backView = UIView()
        backView.isUserInteractionEnabled = false
        backView.backgroundColor = UIColor.ud.rgb("#000000")
        backView.alpha = 0.5
        backView.layer.cornerRadius = Common.Layer.loginQRCodeRadius
        backView.clipsToBounds = true
        addSubview(backView)
        addSubview(label)
        addSubview(imageView)

        backView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        imageView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 45, height: 45))
        }

        label.snp.makeConstraints { (make) in
            make.top.equalTo(self.snp.centerY).offset(20)
            make.top.equalTo(imageView.snp.bottom).offset(CL.itemSpace)
            make.centerX.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
