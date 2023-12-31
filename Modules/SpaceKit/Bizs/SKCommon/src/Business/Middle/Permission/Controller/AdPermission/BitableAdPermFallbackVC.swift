//
//  BitableAdPermFallbackVC.swift
//  SKCommon
//
//  Created by zhysan on 2023/9/20.
//

import Foundation
import SKUIKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignFont
import SKResource

private enum TableSection {
    case roles(_ roles: [BitablePermissionRule])
    case forbidden
    
    var rowCount: Int {
        switch self {
        case .roles(let roles):
            return roles.count
        case .forbidden:
            return 1
        }
    }
}

private struct Const {
    static let panelRadius: CGFloat = 12.0
    
    static let cellInsetH: CGFloat = 16.0
    static let cellRadius: CGFloat = 10.0
    
    static let checkMarkSize: CGFloat = 20.0
    static let checkMarkRightSpace: CGFloat = 16.0
    
    static let cardBgColor = UDColor.bgFloat
    
    static let cellLabelInsetH: CGFloat = 16.0
    
    static let roleCellH: CGFloat = 70.0
    static let forbiddenCellH: CGFloat = 48.0

    static let transitioningDuration = 0.25
}

final class BitableAdPermFallbackVC: DraggableViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate {
    
    // MARK: - public
    
    enum FallbackSelectResult {
        case role(_ role: BitablePermissionRule)
        case forbidden
        case empty
    }
    
    // MARK: - life cycle
    
    init(roles: BitablePermissionRules, dismissCallback: ((FallbackSelectResult) -> Void)?) {
        self.allRoles = roles
        self.dismissCallback = dismissCallback
        self.dataSouce = [.roles(roles.allRoles), .forbidden]
        super.init(nibName: nil, bundle: nil)
        
        transitioningDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        subviewsInit()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func dragDismiss() {
        dismissWithSelectResult(.empty)
    }
    
    // MARK: - private
    
    private let contentWrapper: UIView = UIView().construct { it in
        it.backgroundColor = UDColor.bgBase
        it.layer.cornerRadius = Const.panelRadius
        it.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        it.layer.masksToBounds = true
    }
    
    private let headerWrapper = UIView()
    
    private let closeBtn = UIButton(type: .custom).construct { it in
        it.setImage(UDIcon.closeSmallOutlined.ud.withTintColor(UDColor.iconN1), for: .normal)
    }
    
    private let titleLabel: UILabel = UILabel().construct { it in
        it.font = UDFont.title3
        it.textColor = UDColor.textTitle
        it.textAlignment = .center
        it.text = BundleI18n.SKResource.Bitable_AdvancedPermissionsInherit_NotAssignedRoles_ForOtherCollaborators_Title
    }
    
    private let headerSpLine = UIView().construct { it in
        it.backgroundColor = UDColor.lineDividerDefault
    }
    
    private let tableView: UITableView = UITableView(frame: .zero, style: .grouped).construct { it in
        it.showsVerticalScrollIndicator = false
        it.backgroundColor = .clear
        it.separatorStyle = .none
        it.contentInsetAdjustmentBehavior = .never
        it.allowsSelection = true
        it.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 16))
        it.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    }
    
    private let allRoles: BitablePermissionRules
    
    private let dataSouce: [TableSection]
    
    private let dismissCallback: ((FallbackSelectResult) -> Void)?
    
    private func dismissWithSelectResult(_ result: FallbackSelectResult) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.dismissCallback?(result)
        }
    }
    
    @objc
    private func onCloseClick(_ sender: UIButton) {
        dismissWithSelectResult(.empty)
    }
    
    private func subviewsInit() {
        view.addSubview(contentWrapper)
        contentWrapper.addSubview(headerWrapper)
        contentWrapper.addSubview(tableView)
        headerWrapper.addSubview(closeBtn)
        headerWrapper.addSubview(titleLabel)
        headerWrapper.addSubview(headerSpLine)
        
        contentWrapper.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        headerWrapper.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(48)
        }
        closeBtn.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.left.equalTo(16)
            make.centerY.equalToSuperview().offset(2)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(closeBtn.snp.right).offset(12)
            make.centerX.equalToSuperview()
            make.height.equalTo(24)
            make.centerY.equalTo(closeBtn)
        }
        headerSpLine.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        tableView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(headerWrapper.snp.bottom)
        }
        
        tableView.register(PermRoleCell.self, forCellReuseIdentifier: PermRoleCell.reuseIdentifier)
        tableView.register(ForbiddenCell.self, forCellReuseIdentifier: ForbiddenCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        
        closeBtn.addTarget(self, action: #selector(onCloseClick(_:)), for: .touchUpInside)
        
        contentView = contentWrapper
        contentWrapper.addGestureRecognizer(panGestureRecognizer)
    }
    
    // MARK: - UITableViewDataSource, UITableViewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        dataSouce.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSouce[section].rowCount
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = dataSouce[indexPath.section]
        switch section {
        case .roles:
            return Const.roleCellH
        case .forbidden:
            return Const.forbiddenCellH
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        UIView()
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 8
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = dataSouce[indexPath.section]
        switch section {
        case .roles(let roles):
            let role = roles[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: PermRoleCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? PermRoleCell {
                cell.topLabel.text = role.name
                cell.botLabel.text = role.ruleDes
                cell.isSelected = (role.ruleID == allRoles.accessConfig?.defaultConfig.roleId)
                cell.updateStyle(isFirstCell: indexPath.row == 0, isLastCell: indexPath.row == roles.count - 1)
            }
            return cell
        case .forbidden:
            let cell = tableView.dequeueReusableCell(withIdentifier: ForbiddenCell.reuseIdentifier, for: indexPath)
            cell.isSelected = (allRoles.accessConfig?.defaultConfig.accessStrategy == .forbidden)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isSelected = false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.isSelected = true
        let section = dataSouce[indexPath.section]
        switch section {
        case .roles(let roles):
            dismissWithSelectResult(.role(roles[indexPath.row]))
        case .forbidden:
            dismissWithSelectResult(.forbidden)
        }
    }
    
    // MARK: - Animation Transition,  UIViewControllerTransitioningDelegate
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DimmingPresentAnimation(animateDuration: Const.transitioningDuration, layerAnimationOnly: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DimmingDismissAnimation(animateDuration: Const.transitioningDuration, layerAnimationOnly: true)
    }
}

private class PermRoleCell: UITableViewCell {
    // MARK: - public
    
    let topLabel: UILabel = UILabel().construct { it in
        it.font = UDFont.body0
        it.textColor = UDColor.textTitle
    }
    
    let botLabel: UILabel = UILabel().construct { it in
        it.font = UDFont.body2
        it.textColor = UDColor.textPlaceholder
    }
    
    func updateStyle(isFirstCell: Bool, isLastCell: Bool) {
        if isFirstCell && isLastCell {
            // only one
            cardWrapper.layer.cornerRadius = 10
            cardWrapper.layer.maskedCorners = .all
            spLine.isHidden = true
        } else if isFirstCell {
            // first but not last
            cardWrapper.layer.cornerRadius = 10
            cardWrapper.layer.maskedCorners = .top
            spLine.isHidden = false
        } else if isLastCell {
            // last but not first
            cardWrapper.layer.cornerRadius = 10
            cardWrapper.layer.maskedCorners = .bottom
            spLine.isHidden = true
        } else {
            // middle position, not first nor last
            cardWrapper.layer.cornerRadius = 0
            spLine.isHidden = false
        }
    }
    
    // MARK: - life cycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isSelected: Bool {
        didSet {
            checkMark.isHidden = !isSelected
        }
    }
    
    // MARK: - private
    
    private let cardWrapper: UIView = UIView().construct { it in
        it.backgroundColor = Const.cardBgColor
    }
    
    private let spLine: UIView = UIView().construct { it in
        it.backgroundColor = UDColor.lineDividerDefault
    }
    
    private let checkMark: UIImageView = UIImageView().construct { it in
        it.image = UDIcon.listCheckBoldOutlined.ud.withTintColor(UDColor.primaryPri500)
    }
    
    private func subviewsInit() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(cardWrapper)
        cardWrapper.addSubview(topLabel)
        cardWrapper.addSubview(botLabel)
        cardWrapper.addSubview(checkMark)
        cardWrapper.addSubview(spLine)
        cardWrapper.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(Const.cellInsetH)
        }
        topLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.left.equalToSuperview().inset(Const.cellLabelInsetH)
            make.height.equalTo(22)
        }
        botLabel.snp.makeConstraints { make in
            make.left.right.equalTo(topLabel)
            make.top.equalTo(topLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().inset(12)
        }
        checkMark.snp.makeConstraints { make in
            make.width.height.equalTo(Const.checkMarkSize)
            make.right.equalToSuperview().inset(Const.checkMarkRightSpace)
            make.centerY.equalToSuperview()
            make.left.equalTo(topLabel.snp.right).offset(12)
        }
        spLine.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        checkMark.isHidden = true
        updateStyle(isFirstCell: false, isLastCell: false)
    }
}

private class ForbiddenCell: UITableViewCell {
    // MARK: - public
    
    // MARK: - life cycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isSelected: Bool {
        didSet {
            checkMark.isHidden = !isSelected
        }
    }
    
    // MARK: - private
    
    private let cardWrapper: UIView = UIView().construct { it in
        it.backgroundColor = Const.cardBgColor
    }
    
    private let checkMark: UIImageView = UIImageView().construct { it in
        it.image = UDIcon.listCheckBoldOutlined.ud.withTintColor(UDColor.primaryPri500)
    }
    
    private func subviewsInit() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(cardWrapper)
        cardWrapper.backgroundColor = Const.cardBgColor
        cardWrapper.layer.cornerRadius = Const.cellRadius
        cardWrapper.layer.masksToBounds = true
        cardWrapper.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(Const.cellInsetH)
        }
        
        let label = UILabel()
        label.font = UDFont.body0
        label.text = BundleI18n.SKResource.Bitable_AdvancedPermissionsInherit_NotAssignedRoles_NoPermissions_Option
        label.textColor = UDColor.functionDanger500
        cardWrapper.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(Const.cellLabelInsetH)
        }
        
        cardWrapper.addSubview(checkMark)
        checkMark.snp.makeConstraints { make in
            make.width.height.equalTo(Const.checkMarkSize)
            make.right.equalToSuperview().inset(Const.checkMarkRightSpace)
            make.centerY.equalTo(label)
        }
        checkMark.isHidden = true
    }
}
