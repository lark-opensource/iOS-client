//
//  LarkProfileAliasViewController.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/10/20.
//

import Foundation
import Homeric
import LarkContainer
import LarkSDKInterface
import LarkUIKit
import LKCommonsTracker
import RxSwift
import RxCocoa
import UniverseDesignInput
import UIKit
import UniverseDesignToast

public final class LarkProfileAliasViewController: BaseUIViewController, UDTextFieldDelegate {
    public var userResolver: LarkContainer.UserResolver

    private let userID: String
    private let name: String
    private var alias: String = ""
    private var memoText: String = ""
    private var memoImage: UIImage?
    private let memoDescription: ProfileMemoDescription?
    private var dismissCallback: ((String, String, UIImage?) -> Void)?
    private var canSave = false {
        didSet {
            saveItem.isEnabled = canSave
            if let item = saveItem as? LKBarButtonItem {
                item.setBtnColor(color: canSave ? UIColor.ud.textLinkNormal : UIColor.ud.textDisabled)
            }
        }
    }
    private var didBeginEditing = false

    let disposeBag = DisposeBag()

    lazy var aliasTitleLabel: UILabel = {
        let aliasTitleLabel = UILabel()
        aliasTitleLabel.font = UIFont.systemFont(ofSize: 14)
        aliasTitleLabel.textColor = UIColor.ud.textCaption
        aliasTitleLabel.text = BundleI18n.LarkProfile.Lark_ProfileMemo_Alias_Subtitle
        aliasTitleLabel.setContentHuggingPriority(.required, for: .vertical)
        aliasTitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        return aliasTitleLabel
    }()

    lazy var descriptionTitleLabel: UILabel = {
        let descriptionTitleLabel = UILabel()
        descriptionTitleLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionTitleLabel.textColor = UIColor.ud.textCaption
        descriptionTitleLabel.text = BundleI18n.LarkProfile.Lark_ProfileMemo_Notes_Subtitle
        descriptionTitleLabel.setContentHuggingPriority(.required, for: .vertical)
        descriptionTitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        return descriptionTitleLabel
    }()

    lazy var aliasTextField: UDTextField = {
        let textField = UDTextField()
        textField.config.isShowBorder = true
        textField.config.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        textField.config.textMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        textField.placeholder = BundleI18n.LarkProfile.Lark_ProfileMemo_EnterAlias_Placeholder
        return textField
    }()

    lazy var descriptionView: LarkProfileDescriptionView = {
        LarkProfileDescriptionView(userID: self.userID, navigator: self.userResolver.navigator)
    }()

    public override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgBodyOverlay)
    }

    private(set) lazy var cancelItem: UIBarButtonItem = {
        let btnItem = LKBarButtonItem(title: BundleI18n.LarkProfile.Lark_ProfileMemo_NotesCancel_Button)
        btnItem.setBtnColor(color: UIColor.ud.textTitle)
        btnItem.button.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        return btnItem
    }()

    private(set) lazy var saveItem: UIBarButtonItem = {
        let btnItem = LKBarButtonItem(title: BundleI18n.LarkProfile.Lark_ProfileMemo_NotesSave_Button)
        btnItem.setProperty(font: UIFont.systemFont(ofSize: 16), alignment: .right)
        btnItem.setBtnColor(color: UIColor.ud.textDisabled)
        btnItem.isEnabled = false
        btnItem.button.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
        return btnItem
    }()

    public init(resolver: UserResolver,
                userID: String,
                name: String,
                alias: String = "",
                memoDescription: ProfileMemoDescription? = nil,
                memoText: String = "",
                memoImage: UIImage? = nil,
                dismissCallback: ((String, String, UIImage?) -> Void)? = nil) {
        self.userResolver = resolver
        self.userID = userID
        self.name = name
        self.alias = alias
        self.memoDescription = memoDescription
        self.memoText = memoText
        self.dismissCallback = dismissCallback
        self.memoImage = memoImage

        super.init(nibName: nil, bundle: nil)

        if alias.isEmpty {
            self.aliasTextField.text = name
            self.aliasTextField.config.textColor = UIColor.ud.textCaption
        } else {
            self.aliasTextField.text = alias
            self.aliasTextField.config.textColor = UIColor.ud.textTitle
        }

        var viewParams: [AnyHashable: Any] = [:]
        viewParams["contact_type"] = LarkProfileTracker.userMap[userID]?["contact_type"] ?? ""
        viewParams["to_user_id"] = userID
        viewParams["name_length"] = self.aliasTextField.text?.count ?? 0
        viewParams["description_length"] = self.descriptionView.getLength(forText: memoDescription?.memoText ?? "")
        viewParams["has_pic"] = (memoDescription?.memoPicture.key.isEmpty ?? true) ? "false" : "true"
        Tracker.post(TeaEvent(Homeric.PROFILE_ALIAS_SETTING_VIEW, params: viewParams, md5AllowList: ["to_user_id"]))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.title = BundleI18n.LarkProfile.Lark_ProfileMemo_AliasAndNotes_PageTitle
        self.navigationItem.leftBarButtonItem = cancelItem
        self.navigationItem.rightBarButtonItem = saveItem
        self.view?.backgroundColor = UIColor.ud.bgBodyOverlay

        layoutSubView()
        addTapGesture()
    }

    private func layoutSubView() {
        self.view.addSubview(aliasTitleLabel)
        self.view.addSubview(aliasTextField)
        self.view.addSubview(descriptionTitleLabel)
        self.view.addSubview(descriptionView)

        aliasTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(20)
        }

        aliasTextField.delegate = self
        aliasTextField.snp.makeConstraints { make in
            make.top.equalTo(aliasTitleLabel.snp.bottom).offset(4)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(48)
        }
        aliasTextField.input.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        descriptionTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(aliasTextField.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(20)
        }

        descriptionView.snp.makeConstraints { make in
            make.top.equalTo(descriptionTitleLabel.snp.bottom).offset(Cons.descriptionTopMargin)
            make.left.equalToSuperview().offset(Cons.descriptionHMargin)
            make.right.equalToSuperview().offset(-Cons.descriptionHMargin)
            make.bottom.lessThanOrEqualToSuperview().offset(-Cons.descriptionBottomMargin)
        }

        descriptionView.fromVC = self
        descriptionView.textViewDidChange = { [weak self] (_) in
            if !(self?.canSave ?? true) {
                self?.canSave = true
            }
        }
        descriptionView.tapImageViewCallback = { [weak self] in
            if !(self?.canSave ?? true) {
                self?.canSave = true
            }
            if self?.memoDescription?.memoPicture.key.isEmpty ?? true {
                self?.trackClick("pic_add", target: "none")
            } else {
                self?.trackClick("pic_detail", target: "profile_pic_detail_view")

                var viewParams: [AnyHashable: Any] = [:]
                viewParams["contact_type"] = LarkProfileTracker.userMap[self?.userID ?? ""]?["contact_type"] ?? ""
                viewParams["to_user_id"] = self?.userID
                Tracker.post(TeaEvent(Homeric.PROFILE_PIC_DETAIL_VIEW, params: viewParams, md5AllowList: ["to_user_id"]))
            }
        }
        descriptionView.superview?.layoutIfNeeded()
        descriptionView.updateMemo(text: self.memoText, image: self.memoImage)
        if let memoDescription = self.memoDescription {
            descriptionView.setMemoDescription(memoDescription)
        }
    }

    private func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
    }

    @objc
    private func tapped(_ sender: UITapGestureRecognizer) {
        self.aliasTextField.resignFirstResponder()
        let _ = self.descriptionView.descriptionMultilineTextField.resignFirstResponder()
    }

    @objc
    private func didTapCancel() {
        trackClick("cancel", target: "profile_main_view")
        dismiss(isSuccess: false)
    }

    private func dismiss(isSuccess: Bool = true) {
        var alias = ""
        if self.aliasTextField.text ?? "" != name || didBeginEditing || !self.alias.isEmpty {
            alias = (self.aliasTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let memoDes = self.descriptionView.text.trimmingCharacters(in: .whitespacesAndNewlines)

        if isSuccess {
            self.dismissCallback?(alias, memoDes, self.descriptionView.image)
        }
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @objc
    private func didTapSave() {
        var alias = ""
        if self.aliasTextField.text ?? "" != name || didBeginEditing || !self.alias.isEmpty {
            alias = (self.aliasTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let memoDes = self.descriptionView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let memoPicKey = self.descriptionView.hasChange ? "" : self.memoDescription?.memoPicture.key ?? ""
        guard let imageApi = try? self.userResolver.resolve(assert: ImageAPI.self) else { return }
        guard let profileApi = try? self.userResolver.resolve(assert: LarkProfileAPI.self) else { return }
        trackClick("save", target: "profile_main_view")
        let loadingHUD = UDToast.showDefaultLoading(on: self.view, disableUserInteraction: true)
        if self.descriptionView.hasChange, let data = self.descriptionView.image?.pngData() {
            imageApi.uploadSecureImage(data: data, type: .normal, imageCompressedSizeKb: 0)
                .flatMap { [weak self] key -> Observable<Void> in
                    guard let `self` = self else { return .just(()) }
                    return profileApi.setUserMemoBy(userID: self.userID,
                                                         alias: alias,
                                                         memoText: memoDes,
                                                         memoPicKey: key)
                }.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    loadingHUD.remove()
                    self?.dismiss()
                }, onError: { error in
                    UDToast.showFailure(
                        with: BundleI18n.LarkProfile.Lark_Legacy_ActionFailedTryAgainLater,
                        on: self.view,
                        error: error.transformToAPIError()
                    )
                }).disposed(by: disposeBag)
        } else {
            profileApi.setUserMemoBy(userID: self.userID,
                                          alias: alias,
                                          memoText: memoDes,
                                          memoPicKey: memoPicKey)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    loadingHUD.remove()
                    self?.dismiss()
                }, onError: { error in
                    UDToast.showFailure(
                        with: BundleI18n.LarkProfile.Lark_Legacy_ActionFailedTryAgainLater,
                        on: self.view,
                        error: error.transformToAPIError()
                    )
                }).disposed(by: disposeBag)
        }
    }

    private func trackClick(_ click: String, target: String) {
        var viewParams: [AnyHashable: Any] = [:]
        viewParams["contact_type"] = LarkProfileTracker.userMap[userID]?["contact_type"] ?? ""
        viewParams["to_user_id"] = userID
        viewParams["click"] = click
        viewParams["target"] = target
        Tracker.post(TeaEvent(Homeric.PROFILE_ALIAS_SETTING_CLICK, params: viewParams, md5AllowList: ["to_user_id"]))
    }

    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        if !canSave {
            self.canSave = true
        }
        didBeginEditing = true
        self.aliasTextField.config.textColor = UIColor.ud.textTitle
    }

    @objc
    func textFieldDidChange(_ textField: UITextField) {
        // 中文输入法，正在输入拼音时不进行截取处理
        if let language = textField.textInputMode?.primaryLanguage, language == "zh-Hans" {
            // 获取高亮部分
            let selectRange = textField.markedTextRange ?? UITextRange()
            // 对已输入的文字进行字数统计和限制
            if textField.position(from: selectRange.start, offset: 0) == nil {
                if textField.text?.count ?? 0 > 16 {
                    textField.text = String(textField.text?.prefix(16) ?? "")
                }
            } else {
                // 正在输入拼音时，不对文字进行统计和限制
                return
            }
        } else {
            // 中文输入法以外的直接对其统计限制即可，不考虑其他语种情况
            if textField.text?.count ?? 0 > 16 {
                textField.text = String(textField.text?.prefix(16) ?? "")
            }
        }
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.descriptionView.updateLayoutConstraints(contentSize: descriptionViewContentSize)
    }

    /// PAD屏幕旋转更新显示
    private func padTransitionUpdateDisplay() {
        guard Display.pad else { return }
        self.descriptionView.superview?.layoutIfNeeded()
        self.descriptionView.layoutIfNeeded()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.descriptionView.updateLayoutConstraints(contentSize: self.descriptionViewContentSize)
        }
    }

    var descriptionViewContentSize: CGSize {
        return CGSize(width: self.view.frame.size.width - 2 * Cons.descriptionHMargin, height: self.view.frame.size.height - self.descriptionTitleLabel.frame.bottom - Cons.descriptionTopMargin - Cons.descriptionBottomMargin)
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] (_) in
            guard let `self` = self else { return }
            self.padTransitionUpdateDisplay()
        }, completion: nil)
    }
}

extension LarkProfileAliasViewController {
    enum Cons {
        static var descriptionHMargin: CGFloat { 16 }
        static var descriptionTopMargin: CGFloat { 4 }
        static var descriptionBottomMargin: CGFloat { 20 }
    }
}
