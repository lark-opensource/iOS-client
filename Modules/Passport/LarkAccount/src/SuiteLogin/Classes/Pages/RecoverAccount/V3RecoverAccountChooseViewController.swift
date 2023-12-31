//
//  V3RecoverAccountChooseViewController.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/7/26.
//

import Foundation
import Homeric

class V3RecoverAccountChooseViewController: BaseViewController {
    private let vm: V3RecoverAccountChooseViewModel
    override func needBackImage() -> Bool { false }

    override var needSkipWhilePop: Bool { true }

    lazy var imageView: UIImageView = {
        let result = UIImageView(image: BundleResources.LarkIllustrationResources.specializedAdminCertification)
        return result
    }()

    lazy var mainMsgLabel: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.text = vm.title
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
        lbl.attributedText = AttributedStringUtil.attributedString(vm.subTitle, value: vm.name, placeholder: "{{user_name}}")
        return lbl
    }()

    lazy var verifyFaceButton: NextButton = {
        let btn = NextButton(title: vm.buttonTitle)
        return btn
    }()

    lazy var bottomLabel: UITextView = {
        let detailLabel = LinkClickableLabel.default(with: self)
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.textContainerInset = .zero
        detailLabel.textContainer.lineFragmentPadding = 0
        detailLabel.attributedText = self.vm.bottomTitle
        detailLabel.textAlignment = .center
        return detailLabel
    }()

    init(vm: V3RecoverAccountChooseViewModel) {
        self.vm = vm
        super.init(viewModel: vm)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.N00
        self.navigationController?.navigationBar.barTintColor = UIColor.ud.N00
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
            make.left.right.equalToSuperview().inset(Common.Layout.itemSpace)
        }

        moveBoddyView.addSubview(detailMsgLabel)
        detailMsgLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(mainMsgLabel.snp.bottom).offset(Common.Layout.itemSpace)
            make.left.right.equalToSuperview().inset(Common.Layout.itemSpace)
        }

        moveBoddyView.addSubview(self.verifyFaceButton)
        verifyFaceButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(Common.Layout.itemSpace)
            make.top.equalTo(detailMsgLabel.snp.bottom).offset(Layout.verifyFaceButtonTop)
            make.height.equalTo(NextButton.Layout.nextButtonHeight48)
        }
        self.verifyFaceButton.rx.tap.subscribe { [unowned self] (_) in
            SuiteLoginTracker.track(
                Homeric.PASSPORT_FACE_VERIFY_CLICK,
                params: ["click": "face_verify"]
            )
            self.showLoading()
            self.vm.onVerifyFaceButtonClicked().subscribe(onNext: { [weak self] in
                self?.stopLoading()
            }, onError: { [weak self] (err) in
                self?.handle(err)
            }).disposed(by: self.disposeBag)
        }.disposed(by: disposeBag)

        moveBoddyView.addSubview(self.bottomLabel)
        bottomLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(CL.itemSpace)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-32)
            make.centerX.equalToSuperview()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        SuiteLoginTracker.track(
            Homeric.PASSPORT_FACE_VERIFY_VIEW,
            params: [CommonConst.sourceType: self.vm.recoverAccountChooseInfo.sourceType ?? 0]
        )
    }
}

extension V3RecoverAccountChooseViewController {
    struct Layout {
        static let verifyFaceButtonTop: CGFloat = 32.0
        static let lineHight: CGFloat = 0.5
    }
}
