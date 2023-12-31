//
//  V3ListApplyPermissionView.swift
//  Todo
//
//  Created by GCW on 2022/12/19.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignToast
import UniverseDesignEmpty
import UniverseDesignButton
import UniverseDesignIcon
import UniverseDesignInput
import UniverseDesignActionPanel
import TodoInterface
import LarkContainer
import LarkAccountInterface
import RxSwift
import LKCommonsLogging
import EENavigator
import UniverseDesignFont

enum applyState {
    case normal
    case loading
}

enum permissionType {
    case read
    case write
}

final class V3ListApplyPermissionView: UIView, UDTextFieldDelegate, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    weak var controller: UIViewController?

    private var currentUserName: String {
        passportUserService?.user.name ?? ""
    }
    private var currentTenantName: String {
        passportUserService?.userTenant.tenantName ?? ""
    }
    private var container: Rust.TaskContainer
    private var ownerName: String {
        container.owner.name
    }
    private var ownerId: String {
        container.owner.userID
    }
    private static let logger = Logger.log(V3ListShareViewModel.self, category: "Todo.V3ListApplyPermissionView")
    private let disposeBag = DisposeBag()
    private var ownerNameRange: NSRange?
    private var willShowObserver: NSObjectProtocol?
    private var willHideObserver: NSObjectProtocol?
    private var applyPermissionType: permissionType = .write

    @ScopedInjectedLazy private var listApi: TaskListApi?
    @ScopedInjectedLazy private var routeDependency: RouteDependency?
    @ScopedInjectedLazy private var passportUserService: PassportUserService?

    private var contentViewMaxY: CGFloat {
        // 获取到整个页面最下方container的偏移量y
        return applyContainer.convert(applyContainer.bounds, to: window).maxY
    }

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private lazy var headerContainer = UIView()

    private lazy var applyContainer: UIView = {
        let applyContainer = UIView()
        applyContainer.backgroundColor = UIColor.ud.bgBodyOverlay
        applyContainer.layer.cornerRadius = 4
        return applyContainer
    }()

    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.image = UDEmptyType.noAccess.defaultImage()
        return iconImageView
    }()

    private lazy var headerTitleLabel: UILabel = {
        let headerLabel = UILabel()
        headerLabel.numberOfLines = 0
        headerLabel.textAlignment = .center
        headerLabel.font = UDFont.systemFont(ofSize: 16, weight: .medium)
        headerLabel.textColor = UIColor.ud.textTitle
        headerLabel.text = I18N.Todo_List_NoPermission_EmptyTitle
        return headerLabel
    }()

    private lazy var headerDetailLabel: UILabel = {
        let headerDetailLabel = UILabel()
        headerDetailLabel.numberOfLines = 0
        headerDetailLabel.textAlignment = .center
        headerDetailLabel.font = UDFont.systemFont(ofSize: 14)
        headerDetailLabel.textColor = UIColor.ud.textCaption
        return headerDetailLabel
    }()

    private lazy var applyLabel: UILabel = {
        let applyLabel = UILabel()
        // todo：此处的文案应该无参数，permission代表的含义待确定
        applyLabel.text = I18N.Todo_List_NoPermissionRequestFormer_Text("")
        applyLabel.textColor = UIColor.ud.textTitle
        applyLabel.font = UDFont.systemFont(ofSize: 14)
        return applyLabel
    }()

    private lazy var permissionContainerView: UIView = {
        let view = UIView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapPermissionTypeBtn))
        view.addGestureRecognizer(tap)
        return view
    }()

    private lazy var permissionLabel: UILabel = {
        let label = UILabel()
        label.font = UDFont.systemFont(ofSize: 14, weight: .medium)
        label.numberOfLines = 0
        label.text = I18N.Todo_List_NoPermissionRequestEditLatter_Text
        label.textColor = UIColor.ud.primaryContentDefault
        return label
    }()

    private lazy var permissionArrow: UIImageView = {
        let imageView = UIImageView()
        let image = UDIcon.getIconByKey(.expandDownFilled, iconColor: UIColor.ud.blue, size: CGSize(width: 10, height: 10))
        imageView.image = image
        return imageView
    }()

    private lazy var applyRemarkField: UDTextField = {
        let applyRemarkFeild = UDTextField()
        applyRemarkFeild.layer.cornerRadius = 6
        var config = UDTextFieldUIConfig()
        config.isShowBorder = true
        config.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        applyRemarkFeild.config = config
        applyRemarkFeild.input.attributedPlaceholder = NSAttributedString(
            string: I18N.Todo_List_NoPermissionRequest_AddNote_Placeholder,
            attributes: [
                .foregroundColor: UIColor.ud.textPlaceholder,
                .font: UDFont.systemFont(ofSize: 12)
            ]
        )
        return applyRemarkFeild
    }()

    private lazy var applyBtn: UDButton = {
        var config = UDButtonUIConifg.primaryBlue
        config.type = .middle
        let applyBtn = UDButton(config)
        applyBtn.titleLabel?.font = UDFont.systemFont(ofSize: 16)
        applyBtn.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        applyBtn.setTitle(I18N.Todo_List_NoPermissionEmptyRequest_Button, for: .normal)
        applyBtn.layer.cornerRadius = 4
        applyBtn.addTarget(self, action: #selector(tapApplyPermission(_:)), for: .touchUpInside)
        return applyBtn
    }()

    private func handelKeyboard(name: NSNotification.Name, action: @escaping (CGRect, TimeInterval) -> Void) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { (notification) in
            guard let userinfo = notification.userInfo else {
                assertionFailure()
                return
            }
            let duration = userinfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
            guard let toFrame = userinfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                assertionFailure()
                return
            }
            action(toFrame, duration ?? 0)
        }
    }

    init(resolver: UserResolver, container: Rust.TaskContainer) {
        self.userResolver = resolver
        self.container = container
        super.init(frame: .zero)
        setupUI()
        setupSubViewsLayout()
        addObserver()
        addTapGesture()
        updateData()
    }

    deinit {
        if let willShowObserver = willShowObserver, let willHideObserver = willHideObserver {
            NotificationCenter.default.removeObserver(willShowObserver)
            NotificationCenter.default.removeObserver(willHideObserver)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor.ud.bgBody
        addSubview(scrollView)
        scrollView.addSubview(headerContainer)
        scrollView.addSubview(applyContainer)
        headerContainer.addSubview(iconImageView)
        headerContainer.addSubview(headerTitleLabel)
        headerContainer.addSubview(headerDetailLabel)
        applyContainer.addSubview(applyLabel)
        applyContainer.addSubview(permissionContainerView)
        permissionContainerView.addSubview(permissionLabel)
        permissionContainerView.addSubview(permissionArrow)
        applyContainer.addSubview(applyRemarkField)
        applyContainer.addSubview(applyBtn)
    }

    private func setupSubViewsLayout() {
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        headerContainer.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(100)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(320)
        }
        applyContainer.snp.makeConstraints { (make) in
            make.top.equalTo(headerContainer.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.width.equalTo(headerContainer)
        }
        iconImageView.snp.makeConstraints { (make) in
            make.top.centerX.equalToSuperview()
            make.width.height.equalTo(112)
        }
        headerTitleLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(iconImageView.snp.bottom).offset(20)
        }
        headerDetailLabel.snp.makeConstraints { (make) in
            make.top.equalTo(headerTitleLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        applyLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(17)
            make.left.equalToSuperview().offset(12)
            make.height.equalTo(24)
        }
        applyLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        permissionContainerView.snp.makeConstraints { make in
            make.left.equalTo(applyLabel.snp.right).offset(8)
            make.right.lessThanOrEqualToSuperview().offset(-12)
            make.top.equalToSuperview().offset(17)
            make.height.greaterThanOrEqualTo(24)
        }
        permissionArrow.snp.makeConstraints { make in
            make.width.height.equalTo(10)
            make.centerY.equalTo(permissionLabel)
            make.right.lessThanOrEqualToSuperview()
        }
        permissionLabel.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(permissionArrow.snp.left).offset(-4)
        }
        applyRemarkField.snp.makeConstraints { (make) in
            make.top.equalTo(permissionContainerView.snp.bottom).offset(15)
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
            make.height.equalTo(40)
        }
        applyBtn.snp.makeConstraints { (make) in
            make.top.equalTo(applyRemarkField.snp.bottom).offset(17)
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    private func addObserver() {
        willShowObserver = handelKeyboard(name: UIResponder.keyboardWillShowNotification, action: { [weak self] (keyboardRect, _) in
            guard let self = self else { return }
            if self.scrollView.superview != nil {
                let offsetY = keyboardRect.origin.y - self.contentViewMaxY
                if offsetY < 0 {
                    self.scrollView.setContentOffset(CGPoint(x: self.scrollView.contentOffset.x, y: self.scrollView.contentOffset.y - offsetY), animated: true)
                }
            }
        })
        willHideObserver = handelKeyboard(name: UIResponder.keyboardWillHideNotification, action: { [weak self] (_, _) in
            guard let self = self else { return }
            self.scrollView.setContentOffset(CGPoint(x: self.scrollView.contentOffset.x, y: 0), animated: true)
        })
    }

    private func updateData() {
        headerTitleLabel.text = I18N.Todo_List_NoPermission_EmptyTitle
        headerDetailLabel.attributedText = attributedStringForHeaderDetail()
        if let range = ownerNameRange {
            addTapRange(range)
        }
    }

    private func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapBackground(_:)))
        addGestureRecognizer(tap)
    }
}

extension V3ListApplyPermissionView {
    private func attributedStringForHeaderDetail() -> NSAttributedString {
        let currentUserName = "\(self.currentUserName)（\(self.currentTenantName)）"
        let ownerName = "\(self.ownerName)（\(I18N.Todo_ShareList_ManageCollaboratorsCanManage_Text)）"
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.02
        paragraph.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.ud.textCaption,
                .font: UDFont.systemFont(ofSize: 14),
                .paragraphStyle: paragraph
        ]
        let str = I18N.Todo_List_NoPermission_EmptyDesc(currentUserName, ownerName)
        let attrStr = NSMutableAttributedString(
            string: str,
            attributes: attributes
        )
        let currentUserNameRange = (str as NSString).range(of: currentUserName)
        let ownerNameRange = (str as NSString).range(of: ownerName)
        if currentUserNameRange.length > 0 {
            attrStr.addAttributes(
                [.font: UDFont.systemFont(ofSize: 14, weight: .medium), .foregroundColor: UIColor.ud.textTitle],
                range: currentUserNameRange
            )
        }
        if ownerNameRange.length > 0 {
            attrStr.addAttributes(
                [.font: UDFont.systemFont(ofSize: 14, weight: .medium), .foregroundColor: UIColor.ud.bgPricolor],
                range: ownerNameRange
            )
        }
        self.ownerNameRange = ownerNameRange
        return attrStr
    }

    private func addTapRange(_ range: NSRange) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapDetailLable(_:)))
        self.headerDetailLabel.addGestureRecognizer(tap)
        self.headerDetailLabel.isUserInteractionEnabled = true
    }

    @objc
    func tapDetailLable(_ ges: UITapGestureRecognizer) {
        let tapIndex = tapIndexAtPoint(ges.location(in: ges.view))
        guard let detailAttrStr = headerDetailLabel.attributedText,
              tapIndex >= 0,
              tapIndex < detailAttrStr.length,
              let ownerNameRange = self.ownerNameRange else { return }
        if tapIndex >= ownerNameRange.location && tapIndex <= (ownerNameRange.location + ownerNameRange.length) {
            showOwnerProfile()
        }
    }

    private func showOwnerProfile() {
        guard let controller = self.controller else { return }
        var routeParams = RouteParams(from: controller)
        routeParams.openType = .push
        routeDependency?.showProfile(with: ownerId, params: routeParams)
    }

    private func tapIndexAtPoint(_ location: CGPoint) -> Int {
        guard let detailLabelAttributedText = self.headerDetailLabel.attributedText else { return 0 }
        let textStorage = NSTextStorage(attributedString: detailLabelAttributedText)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: CGSize(width: self.headerDetailLabel.bounds.width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.maximumNumberOfLines = 100
        textContainer.lineBreakMode = self.headerDetailLabel.lineBreakMode
        textContainer.lineFragmentPadding = 0.0
        layoutManager.addTextContainer(textContainer)
        return layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
    }

    @objc
    func tapBackground(_ sender: UIGestureRecognizer) {
        applyRemarkField.resignFirstResponder()
    }

    @objc
    private func tapPermissionTypeBtn() {
        let sender = permissionContainerView
        let source = UDActionSheetSource(
            sourceView: sender,
            sourceRect: CGRect(x: sender.bounds.width * 0.5, y: 0, width: 0, height: 0),
            preferredContentWidth: 320,
            arrowDirection: .down
        )
        let config = UDActionSheetUIConfig(popSource: source)
        let actionSheet = UDActionSheet(config: config)
        actionSheet.addItem(
            UDActionSheetItem(
                title: I18N.Todo_List_NoPermissionRequestViewLatter_Text,
                titleColor: applyPermissionType == .read ? UIColor.ud.primaryContentDefault : UIColor.ud.textTitle,
                action: { [weak self] in
                    self?.permissionLabel.text = I18N.Todo_List_NoPermissionRequestViewLatter_Text
                    self?.applyPermissionType = .read
                }
            )
        )
        actionSheet.addItem(
            UDActionSheetItem(
                title: I18N.Todo_List_NoPermissionRequestEditLatter_Text,
                titleColor: applyPermissionType == .write ? UIColor.ud.primaryContentDefault : UIColor.ud.textTitle,
                action: { [weak self] in
                    self?.permissionLabel.text = I18N.Todo_List_NoPermissionRequestEditLatter_Text
                    self?.applyPermissionType = .write
                }
            )
        )
        // pad下默认不显示
        actionSheet.addItem(
            UDActionSheetItem(
                title: I18N.Todo_Common_Cancel,
                titleColor: UIColor.ud.textTitle,
                style: .cancel
            )
        )
        guard let controller = controller else { return }
        controller.present(actionSheet, animated: true, completion: nil)
    }

    @objc
    private func tapApplyPermission(_ sender: UDButton) {
        // 使用状态进行判断当前选择
        switch applyPermissionType {
        case .read:
            applyPermission(memmberRole: .reader, note: applyRemarkField.text)
        case .write:
            applyPermission(memmberRole: .writer, note: applyRemarkField.text)
        }
    }

    private func applyPermission(memmberRole: Rust.MemberRole, note: String?) {
        listApi?.applyTaskPermission(with: container.guid, todoMemberRole: memmberRole, note: note)
            .take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onSuccess: { [weak self] in
                guard let self = self, let window = self.controller?.view.window else { return }
                Utils.Toast.showSuccess(with: I18N.Todo_List_RequestSent_Toast, on: window)
                self.applyRemarkField.resignFirstResponder()
            },
            onError: { [weak self] (_) in
                guard let self = self else { return }
                self.applyRemarkField.resignFirstResponder()
                Self.logger.error(logId: "apply task list permission failed")
            })
            .disposed(by: disposeBag)
    }

    // 目前接口反应很快，暂时不用loading，默认为normal
    private func updateApplyBtnState(state: applyState = .normal) {
        switch state {
        case .normal:
            applyBtn.hideLoading()
        case .loading:
            applyBtn.showLoading()
        }
    }
}
