//
//  ReportViewController.swift
//  Moment
//
//  Created by zc09v on 2021/2/26.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignButton
import EditTextView
import LarkContainer
import RxSwift
import LKCommonsLogging
import UniverseDesignToast
import LarkInteraction

final class ReportViewController: BaseUIViewController, EditTextViewTextDelegate, UserResolverWrapper {
    let userResolver: UserResolver
    @ScopedInjectedLazy private var postAPI: PostApiService?
    static let logger = Logger.log(ReportViewController.self, category: "Module.Moments.ReportViewController")

    private let inputTextView = LarkEditTextView()
    private let countLabel: UILabel = UILabel(frame: .zero)
    private let textMaxLength: Int = 200
    private var viewDidAppeaded: Bool = false
    private lazy var reportButton: UDButton = {
        let normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                      backgroundColor: UIColor.ud.primaryContentDefault,
                                                      textColor: UIColor.ud.primaryOnPrimaryFill)
        let loadingColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.ud.primaryContentLoading,
                                                       textColor: UIColor.ud.primaryOnPrimaryFill)
        let disableColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.ud.fillDisable,
                                                       textColor: UIColor.ud.primaryOnPrimaryFill)
        let config = UDButtonUIConifg(normalColor: normalColor,
                                      disableColor: disableColor,
                                      loadingColor: loadingColor,
                                      loadingIconColor: UIColor.ud.primaryOnPrimaryFill,
                                      type: .big,
                                      radiusStyle: .square)
        let button = UDButton(config)
        button.addPointer(.lift)
        return button
    }()
    private let disposeBag = DisposeBag()

    private let type: ReportType
    init(userResolver: UserResolver, type: ReportType) {
        self.userResolver = userResolver
        self.type = type
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.Moment.Lark_Community_Report
        self.view.backgroundColor = UIColor.ud.bgBase
        self.setupView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !viewDidAppeaded {
            viewDidAppeaded = true
            inputTextView.becomeFirstResponder()
        }
    }
    func setupView() {
        let font = UIFont.systemFont(ofSize: 16)
        let defaultTypingAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.textTitle
        ]
        let inputTextViewBgView = UIView()
        inputTextViewBgView.backgroundColor = UIColor.ud.bgBody
        self.view.addSubview(inputTextViewBgView)
        inputTextViewBgView.addSubview(inputTextView)
        let maxHeight: CGFloat = 172
        inputTextViewBgView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(16)
            make.left.right.equalToSuperview()
            make.height.equalTo(maxHeight)
        }
        inputTextView.textDelegate = self
        inputTextView.defaultTypingAttributes = defaultTypingAttributes
        inputTextView.font = font
        inputTextView.textAlignment = .left
        inputTextView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        inputTextView.placeholder = BundleI18n.Moment.Lark_Community_DescribeProblem
        inputTextView.placeholderTextColor = UIColor.ud.textPlaceholder
        inputTextView.maxHeight = maxHeight
        inputTextView.backgroundColor = UIColor.clear
        inputTextView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.lessThanOrEqualTo(maxHeight)
        }

        let countLabelContainer = UIView(frame: .zero)
        countLabelContainer.backgroundColor = UIColor.ud.bgBody
        self.view.addSubview(countLabelContainer)
        countLabelContainer.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(inputTextViewBgView.snp.bottom)
            make.height.equalTo(28)
        }
        countLabel.font = .systemFont(ofSize: 12)
        countLabelContainer.addSubview(countLabel)
        countLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(2)
        }
        let attr = NSAttributedString(string: "\(0)/\(textMaxLength)",
                                      attributes: [.foregroundColor: UIColor.ud.textPlaceholder])
        countLabel.attributedText = attr

        let tipLabel = UILabel(frame: .zero)
        tipLabel.text = BundleI18n.Moment.Lark_Community_ReportInfoWillGoToCommunityAdminCustomized(MomentTab.tabTitle())
        tipLabel.numberOfLines = 0
        tipLabel.font = UIFont.systemFont(ofSize: 14)
        tipLabel.textColor = UIColor.ud.textPlaceholder
        tipLabel.backgroundColor = UIColor.clear
        self.view.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { (make) in
            make.top.equalTo(countLabelContainer.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        reportButton.setTitle(BundleI18n.Moment.Lark_Community_Submit, for: .normal)
        reportButton.addTarget(self, action: #selector(doReport), for: .touchUpInside)
        reportButton.isEnabled = false
        self.view.addSubview(reportButton)
        reportButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(tipLabel.snp.bottom).offset(32)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(48)
        }
    }

    func textChange(text: String, textView: LarkEditTextView) {
        let numCount = text.count
        if numCount > textMaxLength {
            let attr = NSMutableAttributedString(string: "\(numCount)",
                                                 attributes: [.foregroundColor: UIColor.ud.functionDangerContentDefault])
            attr.append(NSAttributedString(string: "/\(textMaxLength)",
                                           attributes: [.foregroundColor: UIColor.ud.textPlaceholder]))
            countLabel.attributedText = attr
        } else {
            let attr = NSAttributedString(string: "\(numCount)/\(textMaxLength)",
                                          attributes: [.foregroundColor: UIColor.ud.textPlaceholder])
            countLabel.attributedText = attr
        }
        reportButton.isEnabled = numCount > 0
    }

    @objc
    func doReport() {
        if self.inputTextView.text.count > textMaxLength {
            UDToast.showTips(with: BundleI18n.Moment.Lark_Community_LimitReport200Words, on: self.view)
            return
        }
        self.reportButton.showLoading()
        self.postAPI?.report(type: self.type, reason: self.inputTextView.text)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] (_) in
                guard let self = self else { return }
                UDToast.showTips(with: BundleI18n.Moment.Lark_Community_ReportSuccessful, on: self.view.window ?? self.view, delay: 1.5)
                self.reportButton.hideLoading()
                self.dismissSelf()
            } onError: { [weak self] (error) in
                guard let self = self else { return }
                Self.logger.error("moment trace report fail \(self.type.id)", error: error)
                UDToast.showTips(with: BundleI18n.Moment.Lark_Community_ReportFailed, on: self.view)
                self.reportButton.hideLoading()
            }.disposed(by: self.disposeBag)
    }
    /// 点击空白 收起键盘
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    func dismissSelf() {
        if hasBackPage {
            navigationController?.popViewController(animated: true)
        } else if presentingViewController != nil {
            dismiss(animated: true, completion: nil)
        }
    }
}
