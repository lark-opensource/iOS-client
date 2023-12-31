//
//  LivenessCertViewController.swift
//  ByteView
//
//  Created by fakegourmet on 2020/8/24.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewUI
import UniverseDesignColor
import UniverseDesignToast

final class LivenessCertViewController: CertBaseViewController {

    let vm: LivenessCertViewModel

    init(viewModel: LivenessCertViewModel) {
        self.vm = viewModel
        super.init(viewModel: viewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var imageView: UIImageView = {
        let result = UIImageView(image: BundleResources.Cert.FaceVerification)
        return result
    }()

    lazy var mainMsgLabel: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.text = I18n.View_G_FacialRecognitionInfo
        lbl.font = .systemFont(ofSize: 16, weight: .regular)
        lbl.textColor = UIColor.ud.textTitle
        lbl.textAlignment = .center
        return lbl
    }()

    lazy var detailMsgLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 14, weight: .regular)
        lbl.textColor = UIColor.ud.textPlaceholder
        lbl.textAlignment = .center
        lbl.attributedText = detailMsgString()
        return lbl
    }()

    lazy var verifyFaceButton: NextButton = {
        let btn = NextButton(title: I18n.View_G_StartFacialRecognition)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.nextButton.isHidden = true

        moveBoddyView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(130)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(150)
        }

        moveBoddyView.addSubview(mainMsgLabel)
        mainMsgLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(Layout.itemSpace)
        }

        moveBoddyView.addSubview(detailMsgLabel)
        detailMsgLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(mainMsgLabel.snp.bottom).offset(Layout.itemSpace)
            make.left.right.equalToSuperview().inset(Layout.itemSpace)
        }

        moveBoddyView.addSubview(self.verifyFaceButton)
        verifyFaceButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(Layout.itemSpace)
            make.top.equalTo(detailMsgLabel.snp.bottom).offset(Layout.verifyFaceButtonTop)
            make.height.equalTo(NextButton.Layout.nextButtonHeight)
        }

        verifyFaceButton.addTarget(self, action: #selector(didClickVerifyFace), for: .touchUpInside)
        LiveCertTracks.trackLivenessPage(nextStep: nil)
    }

    private func detailMsgString() -> NSAttributedString {
        let base = I18n.View_G_FacialRecognitionSelf(vm.name)
        let value = vm.name
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14.0, weight: .regular),
            .foregroundColor: UIColor.ud.textCaption
        ]
        let resultAttributedString = NSMutableAttributedString(string: base, attributes: baseAttributes)

        let range = NSString(string: base).range(of: value)
        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14.0, weight: .bold),
            .foregroundColor: UIColor.ud.textTitle
        ]
        resultAttributedString.addAttributes(boldAttributes, range: range)
        return resultAttributedString
    }

    private func doLivenessCheck() {
        self.showLoading()
        self.vm.doLivenessCheck { [weak self] result in
            switch result {
            case .success:
                self?.stopLoading()
                self?.quit(completion: {
                    guard let self = self else { return }
                    UDToast.showSuccess(with: I18n.View_G_AuthenticationSuccess, on: self.view)
                    self.vm.handleCallBack(.success(Void()))
                })
            case .failure(let error):
                self?.stopLoading()
                self?.handle(error)
                if let e = error as? CertError {
                    self?.vm.handleCallBack(.failure(e))
                }
            }
        }
    }

    private func quit(completion: (() -> Void)? = nil) {
        // nolint-next-line: magic number
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: { [weak self] in
            self?.dismiss(animated: true, completion: completion)
        })
    }

    override func handle(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if case let CertError.unknown(_, msg) = error {
                ByteViewDialog.Builder()
                    .title(I18n.View_VM_NotificationDefault)
                    .message(msg)
                    .rightTitle(I18n.View_G_OkButton)
                    .show()
            } else if case CertError.livenessFailed(_) = error {
                let vc = CertRetryViewController(viewModel: self.vm)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    override func clickBack() {
        LiveCertTracks.trackLivenessPage(nextStep: false)
    }

    @objc private func didClickVerifyFace() {
        LiveCertTracks.trackLivenessPage(nextStep: true)
        self.doLivenessCheck()
    }

    private struct Layout {
        static let itemSpace: CGFloat = 16
        static let seperateLabelPadding: CGFloat = 8.0
        static let verifyFaceButtonTop: CGFloat = 32.0
        static let lineHight: CGFloat = 0.5
    }
}
