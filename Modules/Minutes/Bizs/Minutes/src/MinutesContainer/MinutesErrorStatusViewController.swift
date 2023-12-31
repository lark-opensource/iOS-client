//
//  MinutesErrorStatusViewController.swift
//  Minutes
//
//  Created by Todd Cheng on 2021/1/14.
//

import UIKit
import LarkUIKit
import UniverseDesignColor
import MinutesFoundation
import MinutesNetwork
import UniverseDesignToast
import EENavigator
import UniverseDesignIcon
import UniverseDesignEmpty
import MinutesInterface
import LarkContainer

class MinutesErrorStatusViewController: UIViewController {

    var onClickBackButton: (() -> Void)?

    var source: MinutesSource?

    private var minutes: Minutes?
    private var minutesStatus: MinutesInfoStatus

    private var tracker: MinutesTracker?

    private var permissionTimer: Timer?

    private var isClip: Bool

    private lazy var backButton: UIButton = {
        let button: UIButton = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        button.addTarget(self, action: #selector(onClickBackButton(_:)), for: .touchUpInside)
        return button
    }()

    private var minutesResourceDeletedView: MinutesResourceDeletedView?
    private weak var minutesServerErrorView: MinutesServerErrorView?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let userResolver: UserResolver
    init(resolver: UserResolver, minutes: Minutes) {
        self.minutes = minutes
        self.userResolver = resolver
        self.minutesStatus = minutes.info.status
        self.tracker = MinutesTracker(minutes: minutes)
        self.isClip = minutes.isClip
        super.init(nibName: nil, bundle: nil)
    }

    init(resolver: UserResolver, minutesStatus: MinutesInfoStatus, isClip: Bool) {
        self.minutes = nil
        self.userResolver = resolver
        self.minutesStatus = minutesStatus
        self.isClip = isClip
        super.init(nibName: nil, bundle: nil)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    public override var shouldAutorotate: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        show()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        switch minutesStatus {
        case .noPermission:
            tracker?.tracker(name: .pageView, params: ["from_source": source?.rawValue ?? "", "page_name": "permission_page"])
        case .resourceDeleted:
            tracker?.tracker(name: .pageView, params: ["from_source": source?.rawValue ?? "", "page_name": "deleted_page"])
        default:
            tracker?.tracker(name: .pageView, params: ["from_source": source?.rawValue ?? "", "page_name": "abnormal_page"])
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()
    }

    func updateResourceDeletedViewIfNeeded() {
        if minutesResourceDeletedView?.superview != nil {
            minutesResourceDeletedView?.updateMessage(isClip: isClip)
        }
    }

    func updateServerErrorViewIfNeeded() {
        minutesServerErrorView?.reloadView()
    }

    func show(with status: MinutesInfoStatus) {
        minutesStatus = status
        show()
    }

    private func show() {
        switch minutesStatus {
        case .noPermission:
            showMinutesErrorStatusLoadingView()

            tracker?.tracker(name: .permissionView, params: ["is_risky": false])
        case .pathNotFound:
            showMinutesPathNotFoundView()
        case .resourceDeleted:
            showMinutesResourceDeletedView()

            tracker?.tracker(name: .detailView, params: ["page_name": "deleted_page", "is_risky": false])
        case .serverError:
            showMinutesServerErrorView()

            tracker?.tracker(name: .detailView, params: ["page_name": "abnormal_page", "is_risky": false])
        case .transcoding:
            showMinutesTranscodingView()

            tracker?.tracker(name: .detailView, params: ["page_name": "pre_detail_page", "is_risky": false])
        case .otherError:
            showMinutesPathNotFoundView()

            tracker?.tracker(name: .detailView, params: ["page_name": "abnormal_page", "is_risky": false])
        default:
            showMinutesPathNotFoundView()
        }
    }

    @objc
    private func onClickBackButton(_ sender: UIButton) {
        onClickBackButton?()
    }

    private func addBackButton() {
        if Display.pad { return }
        self.view.addSubview(backButton)
        backButton.snp.makeConstraints { maker in
            maker.top.equalTo(view.safeAreaLayoutGuide)
            maker.left.equalToSuperview()
            maker.width.equalTo(60)
            maker.height.equalTo(44)
        }
    }

    private func showMinutesNoPermissionWithApplyView(authorName: String, userID: String) {
        let minutesNoPermissionWithApplyView = MinutesNoPermissionWithApplyView(frame: self.view.bounds, authorName: authorName, userID: userID)
        minutesNoPermissionWithApplyView.delegate = self
        minutesNoPermissionWithApplyView.onClickCommitButton = { [weak self] applyText in
            guard let wSelf = self else { return }
            wSelf.requestSubmitApply(applyText)

            var trackParams: [AnyHashable: Any] = [:]
            trackParams.append(.apply)
            trackParams.append(.permissionPage)
            wSelf.tracker?.tracker(name: .clickButton, params: trackParams)

            wSelf.tracker?.tracker(name: .permissionClick, params: ["click": "apply", "target": "none"])
        }
        view.addSubview(minutesNoPermissionWithApplyView)
        minutesNoPermissionWithApplyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        addBackButton()
    }

    private func showMinutesNoPermissionWithoutApplyView() {
        let minutesNoPermissionWithoutApplyView = MinutesNoPermissionWithoutApplyView(frame: self.view.bounds, isClip: isClip)
        view.addSubview(minutesNoPermissionWithoutApplyView)
        minutesNoPermissionWithoutApplyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        addBackButton()
    }

    private func showMinutesServerErrorView() {
        let minutesServerErrorView = MinutesServerErrorView(frame: self.view.bounds)
        minutesServerErrorView.onClickRefreshButton = { [weak self] in
            guard let wSelf = self, let someMinutes = wSelf.minutes else { return }
            someMinutes.refresh(catchError: false, refreshAll: true, completionHandler: nil)
        }
        view.addSubview(minutesServerErrorView)
        minutesServerErrorView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        addBackButton()
        self.minutesServerErrorView = minutesServerErrorView
    }

    private func showMinutesErrorStatusLoadingView() {
        let minutesErrorStatusLoadingView = MinutesErrorStatusLoadingView(frame: self.view.bounds)
        view.addSubview(minutesErrorStatusLoadingView)
        minutesErrorStatusLoadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        addBackButton()

        requestPermissionData()
    }

    private func showMinutesTranscodingView() {
        let minutesTranscodingView = MinutesTranscodingView(frame: self.view.bounds)
        view.addSubview(minutesTranscodingView)
        minutesTranscodingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        addBackButton()
    }

    private func showMinutesPathNotFoundView() {
        let minutesPathNotFoundView = MinutesPathNotFoundView(frame: self.view.bounds)
        view.addSubview(minutesPathNotFoundView)
        minutesPathNotFoundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        addBackButton()
    }

    private func showMinutesResourceDeletedView() {
        let minutesResourceDeletedView = MinutesResourceDeletedView(frame: self.view.bounds)
        minutesResourceDeletedView.updateMessage(isClip: isClip)
        view.addSubview(minutesResourceDeletedView)
        minutesResourceDeletedView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        addBackButton()
        self.minutesResourceDeletedView = minutesResourceDeletedView
    }

    private func requestPermissionData() {
        guard let someMinutes = self.minutes else { return }
        someMinutes.permissionApplyInfo { [weak self] (result: (Result<PermissionApplyInfo, Error>)) in
            guard let wSelf = self else { return }
            switch result {
            case .success(let permissionApplyInfo):
                DispatchQueue.main.async {
                    if permissionApplyInfo.allowApply {
                        wSelf.showMinutesNoPermissionWithApplyView(authorName: permissionApplyInfo.owner, userID: permissionApplyInfo.ownerId)
                    } else {
                        wSelf.showMinutesNoPermissionWithoutApplyView()
                    }
                }
            case.failure(let error):
                DispatchQueue.main.async {
                    wSelf.showMinutesServerErrorView()
                }
            }
        }
    }

    private func requestSubmitApply(_ appleText: String) {
        guard let someMinutes = self.minutes else { return }
        someMinutes.applyAction(catchError: true, applyText: appleText, completionHandler: { [weak self] result in
            guard let wSelf = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success:
                    wSelf.startTimer()
                    UDToast.showSuccess(with: BundleI18n.Minutes.MMWeb_G_RequestSentShort, on: wSelf.view, delay: 2)
                case .failure: break
                }
            }
        })
    }

    private func startTimer() {
        if permissionTimer == nil {
            permissionTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: { [weak self]_ in
                guard let wSelf = self else { return }
                wSelf.minutes?.refresh(catchError: false, refreshAll: true, completionHandler: nil)
            })
        }
    }

    private func stopTimer() {
        permissionTimer?.invalidate()
        permissionTimer = nil
    }
}

extension MinutesErrorStatusViewController: MinutesNoPermissionWithApplyViewDelegate {
    func gotoProfile(userID: String) {
        let from = userResolver.navigator.mainSceneTopMost
        tracker?.tracker(name: .clickButton, params: ["page_name": "permission_page", "action_name": "owner_name"])
        tracker?.tracker(name: .permissionClick, params: ["click": "owner_name", "target": "none"])
        MinutesProfile.personProfile(chatterId: userID, from: from, resolver: userResolver)
    }
}
// MARK: - MinutesErrorStatusLoadingView

class MinutesErrorStatusLoadingView: UIView {

    private lazy var loadingView: LoadingPlaceholderView = {
        let view = LoadingPlaceholderView(frame: .zero)
        view.isHidden = false
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody

        addSubview(loadingView)
        loadingView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.width.height.equalTo(150)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: - MinutesTranscodingView

class MinutesTranscodingView: UIView {

    private lazy var loadingView: LoadingPlaceholderView = {
        let view = LoadingPlaceholderView(frame: .zero)
        view.isHidden = false
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.text = BundleI18n.Minutes.MMWeb_G_GeneratingContent
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 15)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody

        addSubview(loadingView)
        addSubview(titleLabel)

        loadingView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.width.height.equalTo(150)
        }
        titleLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.left.equalToSuperview().offset(20)
            maker.right.equalToSuperview().offset(-20)
            maker.top.equalTo(loadingView.snp.bottom).offset(20)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - MinutesNoPermissionWithoutApplyView

/// base-info: HTTPCode == 403
/// apply/info: allow_apply == true
class MinutesNoPermissionWithoutApplyView: UIView {

    private let minutesNoAccess: UDEmptyType = .noAccess

    private lazy var imageView: UIImageView = {
        let imageView: UIImageView = UIImageView(image: minutesNoAccess.defaultImage())
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.text = BundleI18n.Minutes.MMWeb_G_NoAccessPermission
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 20)
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 15)
        return label
    }()

    init(frame: CGRect, isClip: Bool) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody

        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        imageView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview().multipliedBy(0.66)
        }

        titleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(imageView.snp.bottom).offset(24)
            maker.left.right.equalToSuperview().inset(20)
        }

        subtitleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(16)
            maker.left.right.equalToSuperview().inset(20)
        }
        if isClip {
            subtitleLabel.text = BundleI18n.Minutes.MMWeb_G_OwnerSetNoPermit
        } else {
            subtitleLabel.text = BundleI18n.Minutes.MMWeb_G_AdminRestrictedAccess
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - MinutesNoPermissionWithApplyView

/// base-info: HTTPCode == 403
/// apply/info: allow_apply == false
protocol  MinutesNoPermissionWithApplyViewDelegate: NSObjectProtocol {
    func gotoProfile(userID: String)
}

class MinutesNoPermissionWithApplyView: UIView {

    var onClickCommitButton: ((String) -> Void)?

    private let minutesNoAccess: UDEmptyType = .noAccess

    private var authorName: String
    private var userID: String
    weak var delegate: MinutesNoPermissionWithApplyViewDelegate?
    private lazy var imageView: UIImageView = {
        let imageView: UIImageView = UIImageView(image: minutesNoAccess.defaultImage())
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.text = BundleI18n.Minutes.MMWeb_G_NoAccessPermission
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 20)
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label: UILabel = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 15)
        label.isUserInteractionEnabled = true
        let ownerGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(showProfile))
        label.addGestureRecognizer(ownerGestureRecognizer)
        return label
    }()

    private lazy var textView: PlaceholderTextView = {
        let textView: PlaceholderTextView = PlaceholderTextView(frame: CGRect.zero)
        textView.placeholderLabel.text = " " + BundleI18n.Minutes.MMWeb_G_RequestPermissionPlaceholder
        textView.placeholderLabel.textColor = UIColor.ud.textDisable
        textView.layer.borderWidth = 1.0
        textView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        textView.layer.cornerRadius = 3
        textView.font = UIFont.systemFont(ofSize: 15)
        return textView
    }()

    private lazy var commitButton: UIButton = {
        let button: UIButton = UIButton(type: .custom)
        button.setTitle(BundleI18n.Minutes.MMWeb_G_SendRequest, for: .normal)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.backgroundColor = UIColor.ud.primaryContentDefault
        button.layer.cornerRadius = 3
        button.addTarget(self, action: #selector(onClickCommitButton(_:)), for: .touchUpInside)
        return button
    }()

    init(frame: CGRect, authorName: String, userID: String) {
        self.authorName = authorName
        self.userID = userID

        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody

        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(textView)
        addSubview(commitButton)

        subtitleLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview().multipliedBy(0.922)
            maker.left.right.equalToSuperview().inset(20)
        }

        titleLabel.snp.makeConstraints { maker in
            maker.bottom.equalTo(subtitleLabel.snp.top).offset(-16)
            maker.left.right.equalToSuperview().inset(20)
        }

        imageView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(titleLabel.snp.top).offset(-24)
        }

        textView.snp.makeConstraints { maker in
            maker.top.equalTo(subtitleLabel.snp.bottom).offset(20)
            maker.left.right.equalToSuperview().inset(20)
            maker.height.equalTo(187)
        }

        commitButton.snp.makeConstraints { maker in
            maker.top.equalTo(textView.snp.bottom).offset(24)
            maker.left.right.equalToSuperview().inset(20)
            maker.height.equalTo(48)
        }

        configSubtitleLabel(authorName: authorName)

        let viewTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard(_:)))
        addGestureRecognizer(viewTapGestureRecognizer)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func onClickCommitButton(_ sender: UIButton) {
        onClickCommitButton?(textView.text)
    }

    @objc
    private func keyboardWillShow(_ notification: Notification) {
        if self.frame.minY < 0 { return }
        let commitButtonBotton = self.frame.height - commitButton.frame.minY - commitButton.frame.height
        if let keyboardEndFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
           commitButtonBotton < keyboardEndFrame.height + 5 {
            let moveDistance = keyboardEndFrame.height + 5 - commitButtonBotton
            let animationDuration: TimeInterval = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
            let animationCurveUInt: UInt = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0

            UIView.animate(withDuration: animationDuration, delay: 0, options: UIView.AnimationOptions(rawValue: animationCurveUInt), animations: {
                self.frame = CGRect(x: self.frame.minX, y: self.frame.minY - moveDistance, width: self.frame.width, height: self.frame.height)
            })
        }
    }

    @objc private func hideKeyboard(_ gesture: UITapGestureRecognizer) {
        if self.frame.minY == 0 { return }
        self.endEditing(true)
        UIView.animate(withDuration: 0.25, delay: 0, options: UIView.AnimationOptions(rawValue: 0), animations: {
            self.frame = CGRect(x: self.frame.minX, y: 0, width: self.frame.width, height: self.frame.height)
        })
    }

    @objc private func showProfile(_ gesture: UITapGestureRecognizer) {
        let authorName = "@" + self.authorName
        let nameRange = (BundleI18n.Minutes.MMWeb_G_RequestPermissionInfo(authorName, BundleI18n.Minutes.MMWeb_G_ViewPermissions) as NSString).range(of: authorName)
        if gesture.didTapAttributedTextInLabel(label: subtitleLabel, inRange: nameRange) {
            delegate?.gotoProfile(userID: self.userID)
        }
    }

    func configSubtitleLabel(authorName: String) {
        // 设置author文字高亮及label内容
        let authorName = "@" + authorName
        let subtitleText: String = BundleI18n.Minutes.MMWeb_G_RequestPermissionInfo(authorName, BundleI18n.Minutes.MMWeb_G_ViewPermissions)
        let nsSubtitleText = subtitleText as NSString
        let authorNameRange = nsSubtitleText.range(of: authorName)
        let lkSubtitleText = NSMutableAttributedString.init(string: subtitleText)
        lkSubtitleText.addAttribute(.foregroundColor, value: UIColor.ud.primaryContentPressed, range: authorNameRange)
        subtitleLabel.attributedText = lkSubtitleText
    }
}

extension UITapGestureRecognizer {

    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        guard let attributedText = label.attributedText else { return false }

        let mutableStr = NSMutableAttributedString.init(attributedString: attributedText)
        mutableStr.addAttributes([NSAttributedString.Key.font: label.font!], range: NSRange.init(location: 0, length: attributedText.length))

        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: mutableStr)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize

        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)

        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x, y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)

        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x, y: locationOfTouchInLabel.y - textContainerOffset.y)
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        return NSLocationInRange(indexOfCharacter, targetRange)
    }

}
// MARK: - MinutesPathNotFoundView

/// base-info: HTTPCode == 404
class MinutesPathNotFoundView: UIView {

    private let minutesErrorNoData: UDEmptyType = .loadingFailure

    private lazy var imageView: UIImageView = {
        let imageView: UIImageView = UIImageView(image: minutesErrorNoData.defaultImage())
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.text = BundleI18n.Minutes.MMWeb_G_SomethingWentWrong
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 15)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody

        addSubview(imageView)
        addSubview(titleLabel)

        imageView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview().multipliedBy(1)
        }

        titleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(imageView.snp.bottom).offset(10)
            maker.left.right.equalToSuperview().inset(20)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - MinutesResourceDeletedView

/// base-info: HTTPCode == 410
class MinutesResourceDeletedView: UIView {

    private let minutesErrorDeleteEmptyType: UDEmptyType = .noContent

    private lazy var imageView: UIImageView = {
        let imageView: UIImageView = UIImageView(image: minutesErrorDeleteEmptyType.defaultImage())
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 15)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody

        addSubview(imageView)
        addSubview(titleLabel)

        imageView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview().multipliedBy(1)
        }

        titleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(imageView.snp.bottom).offset(10)
            maker.left.right.equalToSuperview().inset(20)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func errorMessage(isClip: Bool) -> String {
        if !isClip {
            let key1 = MinutesAPIPath.status
            let key2 = MinutesAPIPath.simpleBaseInfo
            if let msg = MinutesCommonErrorToastManger.message(forKey: key1)?.newMsg?.content?.body {
                return msg
            }
            if let msg = MinutesCommonErrorToastManger.message(forKey: key2)?.newMsg?.content?.body {
                return msg
            }
            return BundleI18n.Minutes.MMWeb_G_DeletedByOwner
        } else {
            return BundleI18n.Minutes.MMWeb_G_ClipDeleted
        }
    }

    func updateMessage(isClip: Bool) {
        titleLabel.text = errorMessage(isClip: isClip)
    }
}

// MARK: - MinutesServerErrorView
let noKeyCode = 11010
/// base-info: HTTPCode == 500
class MinutesServerErrorView: UIView {

    var onClickRefreshButton: (() -> Void)?

    private var minutesErrorType: UDEmptyType = .loadingFailure

    private lazy var imageView: UIImageView = {
        let imageView: UIImageView = UIImageView(image: minutesErrorType.defaultImage())
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.text = BundleI18n.Minutes.MMWeb_G_SomethingWentWrong
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 15)
        return label
    }()

    private lazy var refreshButton: UIButton = {
        let button: UIButton = UIButton(type: .custom)
        button.setTitle(BundleI18n.Minutes.MMWeb_G_Reload, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.backgroundColor = UIColor.ud.bgBody
        button.layer.cornerRadius = 3
        button.layer.borderWidth = 1
        button.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
        button.addTarget(self, action: #selector(onClickRefreshButton(_:)), for: .touchUpInside)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody

        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(refreshButton)
        createConstraints()
    }
    
    func createConstraints() {
        imageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().multipliedBy(1)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(10)
            $0.left.right.equalToSuperview().inset(20)
        }

        let label: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.width - 40, height: 1000))
        label.text = BundleI18n.Minutes.MMWeb_G_Reload
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14)
        label.sizeToFit()
        let refreshButtonWidth = max(88, label.bounds.width + 20)
        refreshButton.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(24)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(refreshButtonWidth)
            $0.height.equalTo(36)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        reloadView()
    }

    @objc
    private func onClickRefreshButton(_ sender: UIButton) {
        onClickRefreshButton?()
    }

    private func errorMessage() -> String {
        let key1 = MinutesAPIPath.baseInfo
        let key2 = MinutesAPIPath.simpleBaseInfo
        let key3 = MinutesAPIPath.status
        if let error = MinutesCommonErrorToastManger.message(forKey: key1), error.code == noKeyCode {
            minutesErrorType = .ccmDocumentKeyUnavailable
            return BundleI18n.Minutes.MMWeb_NoKeyNoInfo_EmptyState
        }
        if let error = MinutesCommonErrorToastManger.message(forKey: key2), error.code == noKeyCode {
            minutesErrorType = .ccmDocumentKeyUnavailable
            return BundleI18n.Minutes.MMWeb_NoKeyNoInfo_EmptyState
        }
        if let error = MinutesCommonErrorToastManger.message(forKey: key3), error.code == noKeyCode {
            minutesErrorType = .ccmDocumentKeyUnavailable
            return BundleI18n.Minutes.MMWeb_NoKeyNoInfo_EmptyState
        }
        return BundleI18n.Minutes.MMWeb_G_SomethingWentWrong
    }

    func reloadView() {
        titleLabel.text = errorMessage()
        imageView.image = minutesErrorType.defaultImage()
        switch minutesErrorType {
        case .ccmDocumentKeyUnavailable:
            refreshButton.isHidden = true
        default:
            refreshButton.isHidden = false
        }
    }
}

open class PlaceholderTextView: UITextView {

    private struct Constants {
        static let defaultiOSPlaceholderColor: UIColor = {
            return UIColor.ud.textDisable
        }()
    }

    public let placeholderLabel: UILabel = UILabel()

    private var placeholderLabelConstraints = [NSLayoutConstraint]()

    public var placeholder: String = "" {
        didSet {
            placeholderLabel.text = placeholder
        }
    }

    public var placeholderColor: UIColor = PlaceholderTextView.Constants.defaultiOSPlaceholderColor {
        didSet {
            placeholderLabel.textColor = placeholderColor
        }
    }

    override public var font: UIFont! {
        didSet {
            if placeholderFont == nil {
                placeholderLabel.font = font
            }
        }
    }

    public var placeholderFont: UIFont? {
        didSet {
            let font = (placeholderFont != nil) ? placeholderFont : self.font
            placeholderLabel.font = font
        }
    }

    override public var textAlignment: NSTextAlignment {
        didSet {
            placeholderLabel.textAlignment = textAlignment
        }
    }

    override public var text: String! {
        didSet {
            textDidChange()
        }
    }

    override public init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        initHandler()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initHandler()
    }

    private func initHandler() {
        #if swift(>=4.2)
        let notificationName = UITextView.textDidChangeNotification
        #else
        let notificationName = NSNotification.Name.UITextView.textDidChangeNotification
        #endif

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textDidChange),
                                               name: notificationName,
                                               object: nil)
        initUI()
    }
    
    func initUI() {
        placeholderLabel.font = font
        placeholderLabel.textColor = placeholderColor
        placeholderLabel.textAlignment = textAlignment
        placeholderLabel.text = placeholder
        placeholderLabel.numberOfLines = 0
        placeholderLabel.backgroundColor = UIColor.clear
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(placeholderLabel)
        updatePlaceholderLabelConstraints()
    }

    private func updatePlaceholderLabelConstraints() {
        removeConstraints(placeholderLabelConstraints)
        var newConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(\(textContainerInset.left + textContainer.lineFragmentPadding))-[placeholder]",
            options: [],
            metrics: nil,
            views: ["placeholder": placeholderLabel])
        newConstraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-(\(textContainerInset.top))-[placeholder]",
            options: [],
            metrics: nil,
            views: ["placeholder": placeholderLabel])
        newConstraints.append(NSLayoutConstraint(
            item: self,
            attribute: .height,
            relatedBy: .greaterThanOrEqual,
            toItem: placeholderLabel,
            attribute: .height,
            multiplier: 1.0,
            constant: textContainerInset.top + textContainerInset.bottom
        ))
        newConstraints.append(NSLayoutConstraint(
            item: placeholderLabel,
            attribute: .width,
            relatedBy: .equal,
            toItem: self,
            attribute: .width,
            multiplier: 1.0,
            constant: -(textContainerInset.left + textContainerInset.right + textContainer.lineFragmentPadding * 2.0)
            ))
        addConstraints(newConstraints)
        placeholderLabelConstraints = newConstraints
    }

    @objc private func textDidChange() {
        placeholderLabel.isHidden = !text.isEmpty
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        placeholderLabel.preferredMaxLayoutWidth = textContainer.size.width - textContainer.lineFragmentPadding * 2.0
    }

    deinit {
      #if swift(>=4.2)
      let notificationName = UITextView.textDidChangeNotification
      #else
      let notificationName = NSNotification.Name.UITextView.textDidChangeNotification
      #endif

        NotificationCenter.default.removeObserver(self,
                                                  name: notificationName,
                                                  object: nil)
    }
}
