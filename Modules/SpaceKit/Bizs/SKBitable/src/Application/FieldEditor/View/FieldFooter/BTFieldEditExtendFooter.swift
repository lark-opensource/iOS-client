//
//  BTFieldEditExtendFooter.swift
//  SKBitable
//
//  Created by zhysan on 2023/3/31.
//

import UIKit
import SKFoundation
import SKResource
import SKCommon
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignSwitch
import UniverseDesignCheckBox
import UniverseDesignIcon
import UniverseDesignButton
import UniverseDesignTag

private struct Const {
    static var cellH: CGFloat = 52.0
    static var headerH: CGFloat = 36.0
    static var tagH: CGFloat = 16
    
    struct OriginView {
        static let headerH = 36.0
        static let originH = 52.0
        static let spacerH = 14.0
        static let refreshH = 52.0
    }
}

protocol BTFieldEditExtendFooterDelegate: AnyObject {
    func footerHeightDidChange(_ footer: BTFieldEditExtendFooter)
    
    func onExtendConfigSwitchTap(_ footer: BTFieldEditExtendFooter, config: FieldExtendConfig, valueChanged: Bool)
    
    func onExtendConfigItemCheckboxTap(_ footer: BTFieldEditExtendFooter, config: FieldExtendConfig, item: FieldExtendConfigItem, valueChanged: Bool)
    
    func footerExtendOriginRefreshButtonDidTap(_ footer: BTFieldEditExtendFooter, extendInfo: FieldExtendInfo?)
}

enum FieldExtendRefreshButtonState {
    case hidden
    case disable
    case normal
    
    var isVisible: Bool {
        switch self {
        case .hidden:
            return false
        case .disable, .normal:
            return true
        }
    }
    
    var isEnable: Bool {
        switch self {
        case .hidden, .disable:
            return false
        case .normal:
            return true
        }
    }
}

struct FooterExtendOriginModel {
    let refreshState: FieldExtendRefreshButtonState
    let extendInfo: FieldExtendInfo
}

class BTFieldEditExtendFooter: UIView {
    
    // MARK: - public
    
    weak var delegate: BTFieldEditExtendFooterDelegate?
    
    private(set) var configs: [FieldExtendConfig] = []
    
    private(set) var extraDisableReason: ExtraExtendDisableReason = []
    
    func insertDisableReason(_ reason: ExtraExtendDisableReason) {
        extraDisableReason.insert(reason)
        onExtraExtendDisableReasonChanged()
    }
    
    func removeDisableReason(_ reason: ExtraExtendDisableReason) {
        extraDisableReason.remove(reason)
        onExtraExtendDisableReasonChanged()
    }
    
    func update(originModel: FooterExtendOriginModel? = nil, configs: [FieldExtendConfig] = []) {
        self.originModel = originModel
        self.configs = configs
        
        var contentHeightChange = false
        if let originModel = originModel, let origin = originModel.extendInfo.originField {
            if originView.superview == nil {
                stackView.insertArrangedSubview(originView, at: 0)
            }
            originView.update(origin, refreshState: originModel.refreshState)
            contentHeightChange = adjustOriginViewHeight()
        } else if originView.superview != nil {
            originView.removeFromSuperview()
            contentHeightChange = true
        }
        
        if !configs.isEmpty {
            if tableView.superview == nil {
                stackView.addArrangedSubview(tableView)
            }
            tableView.reloadData()
            contentHeightChange = adjustConfigsTableHeight()
        } else if tableView.superview != nil {
            tableView.removeFromSuperview()
            contentHeightChange = true
        }
        
        if contentHeightChange {
            delegate?.footerHeightDidChange(self)
        }
    }
    
    // MARK: - life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - private
    
    private var originModel: FooterExtendOriginModel? = nil
    
    private var stackView = UIStackView().construct { it in
        it.axis = .vertical
    }
    
    private let tableView = UITableView(frame: .zero, style: .grouped).construct { it in
        it.bounces = false
        it.separatorStyle = .none
        it.backgroundColor = .clear
        it.isScrollEnabled = false
    }
    
    private let originView = ExtendOriginView()
    
    private func adjustOriginViewHeight() -> Bool {
        let height = originView.contentHeight
        if originView.frame.height != height {
            originView.frame.size.height = height
            originView.snp.updateConstraints { make in
                make.height.equalTo(height).priority(.high)
            }
            return true
        }
        return false
    }
    
    private func adjustConfigsTableHeight() -> Bool {
        let height = calcTableHeight()
        if tableView.frame.height != height {
            tableView.frame.size.height = height
            tableView.snp.updateConstraints { make in
                make.height.equalTo(height).priority(.high)
            }
            return true
        }
        return false
    }
    
    private func calcTableHeight() -> CGFloat {
        configs.reduce(0) { partialResult, config in
            let h1 = Const.headerH + Const.cellH
            let h2 = isConfigSwitchOn(config) ? (Const.headerH + Const.cellH * CGFloat(config.extendItems.count)) : 0
            return partialResult + h1 + h2
        }
    }
    
    private func onExtraExtendDisableReasonChanged() {
        tableView.reloadData()
        if adjustConfigsTableHeight() {
            delegate?.footerHeightDidChange(self)
        }
    }
    
    @objc
    private func onOriginRefreshButtonTapped(_ sender: UIButton) {
        delegate?.footerExtendOriginRefreshButtonDidTap(self, extendInfo: originModel?.extendInfo)
    }
    
    private func subviewsInit() {
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SwitchCell.self, forCellReuseIdentifier: SwitchCell.defaultReuseID)
        tableView.register(FieldCell.self, forCellReuseIdentifier: FieldCell.defaultReuseID)
        
        originView.refreshButton.addTarget(self, action: #selector(onOriginRefreshButtonTapped(_:)), for: .touchUpInside)
    }
}

// MARK: - Helper

extension BTFieldEditExtendFooter {
    
    private func isSwitchSection(_ section: Int) -> Bool {
        return section % 2 == 0
    }
    
    private func realIndexForSection(_ section: Int) -> Int {
        if isSwitchSection(section) {
            return section / 2
        }
        return (section - 1) / 2
    }
    
    private func configForSection(_ section: Int) -> FieldExtendConfig {
        configs[realIndexForSection(section)]
    }
    
    private func shouldShowSection(_ section: Int) -> Bool {
        if isSwitchSection(section) {
            return true
        }
        let config = configForSection(section)
        return isConfigSwitchOn(config)
    }
    
    private func isConfigEditable(_ config: FieldExtendConfig) -> Bool {
        if !extraDisableReason.isEmpty {
            return false
        }
        return config.editable
    }
    
    private func isConfigSwitchOn(_ config: FieldExtendConfig) -> Bool {
        if !extraDisableReason.isEmpty {
            return false
        }
        return config.extendState
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension BTFieldEditExtendFooter: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        configs.count * 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard configs.count > 0 else {
            return 0
        }
        if isSwitchSection(section) {
            return 1
        }
        let config = configForSection(section)
        if isConfigSwitchOn(config) {
            return config.extendItems.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if isSwitchSection(indexPath.section) {
            cell = tableView.dequeueReusableCell(withIdentifier: SwitchCell.defaultReuseID, for: indexPath)
            
            guard let cell = cell as? SwitchCell else { return cell }
            
            let config = configForSection(indexPath.section)
            cell.titleLabel.text = config.editInfo
            cell.switchView.setOn(isConfigSwitchOn(config), animated: false)
            cell.switchView.isEnabled = isConfigEditable(config)
            cell.switchView.tapCallBack = { [weak self] sender in
                OnboardingManager.shared.markFinished(for: [OnboardingID.bitableFieldExtendSwitchNew])
                guard let self = self else { return }
                guard sender.isEnabled else {
                    self.delegate?.onExtendConfigSwitchTap(self, config: config, valueChanged: false)
                    return
                }
                let configIdx = self.realIndexForSection(indexPath.section)
                self.configs[configIdx].extendState = !sender.isOn
                self.delegate?.onExtendConfigSwitchTap(self, config: self.configs[configIdx], valueChanged: true)
                self.tableView.reloadData()
                if self.adjustConfigsTableHeight() {
                    self.delegate?.footerHeightDidChange(self)
                }
            }
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: FieldCell.defaultReuseID, for: indexPath)
            
            guard let cell = cell as? FieldCell else { return cell }

            let config = configForSection(indexPath.section)
            let item = config.extendItems[indexPath.row]
            cell.iconView.update(item.compositeType.icon(), showLighting: true, tintColor: UDColor.iconN1)
            cell.titleLabel.text = item.name
            cell.checkBox.isEnabled = isConfigEditable(config)
            cell.checkBox.isSelected = item.isChecked
            cell.checkBox.respondsToUserInteractionWhenDisabled = true
            cell.updateStyle(
                isFirstCell: indexPath.row == 0,
                isLastCell: indexPath.row == config.extendItems.count - 1
            )
            cell.checkBox.tapCallBack = { [weak self] sender in
                OnboardingManager.shared.markFinished(for: [OnboardingID.bitableFieldExtendSwitchNew])
                guard let self = self else { return }
                guard sender.isEnabled else {
                    self.delegate?.onExtendConfigItemCheckboxTap(self, config: config, item: item, valueChanged: false)
                    return
                }
                sender.isSelected = !sender.isSelected
                let configIdx = self.realIndexForSection(indexPath.section)
                let childIdx = indexPath.row
                self.configs[configIdx].extendItems[childIdx].isChecked = sender.isSelected
                let currentConfig = self.configs[configIdx]
                let currentItem = currentConfig.extendItems[childIdx]
                self.delegate?.onExtendConfigItemCheckboxTap(self, config: currentConfig, item: currentItem, valueChanged: true)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard !isSwitchSection(indexPath.section) else {
            return
        }
        guard let cell = tableView.cellForRow(at: indexPath) as? FieldCell else {
            return
        }
        
        OnboardingManager.shared.markFinished(for: [OnboardingID.bitableFieldExtendSwitchNew])
        
        let config = configForSection(indexPath.section)
        let item = config.extendItems[indexPath.row]
     
        guard config.editable else {
            delegate?.onExtendConfigItemCheckboxTap(self, config: config, item: item, valueChanged: false)
            return
        }
        
        let configIdx = realIndexForSection(indexPath.section)
        let childIdx = indexPath.row
        configs[configIdx].extendItems[childIdx].isChecked = !item.isChecked
        
        cell.checkBox.isSelected = !item.isChecked
        
        let currentConfig = configs[configIdx]
        let currentItem = currentConfig.extendItems[childIdx]
        delegate?.onExtendConfigItemCheckboxTap(self, config: currentConfig, item: currentItem, valueChanged: true)
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Const.cellH
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if shouldShowSection(section) {
            return Const.headerH
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard shouldShowSection(section) else {
            return nil
        }
        let header: SectionHeader
        if let reuse = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeader.reuseIdentifier) as? SectionHeader {
            header = reuse
        } else {
            header = SectionHeader(reuseIdentifier: SectionHeader.reuseIdentifier)
        }
        if isSwitchSection(section) {
            header.titleLabel.text = BundleI18n.SKResource.Bitable_PeopleField_ExtendableField_Title
        } else {
            header.titleLabel.text = configForSection(section).fromInfo
        }
        return header
    }
}

// MARK: - origin view

private class ExtendOriginRefreshButton: UIButton {
    // MARK: - public
    let textLabel: UILabel = UILabel().construct { it in
        it.font = UDFont.body0
        it.textColor = UDColor.primaryContentDefault
    }
    
    // MARK: - life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UDColor.N900.withAlphaComponent(0.1) : UDColor.bgFloat
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            textLabel.textColor = isEnabled ? UDColor.primaryContentDefault : UDColor.textDisabled
        }
    }
    
    // MARK: - private
    
    private func subviewsInit() {
        addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
        }
        backgroundColor = UDColor.bgFloat
        textLabel.text = BundleI18n.SKResource.Bitable_PeopleField_RefreshData_Button
        layer.cornerRadius = 10.0
        clipsToBounds = true
    }
}

private class ExtendOriginView: UIView {
    // MARK: - public
    
    let refreshButton = ExtendOriginRefreshButton()
    
    var contentHeight: CGFloat {
        let originH = Const.OriginView.headerH + Const.OriginView.originH
        if !refreshState.isVisible {
            return originH
        }
        return originH + Const.OriginView.spacerH + Const.OriginView.refreshH
    }
    
    func update(_ originInfo: FieldExtendInfo.OriginInfo, refreshState: FieldExtendRefreshButtonState) {
        originImgView.image = originInfo.compositeType.icon(color: UDColor.iconN3)
        originLabel.text = originInfo.fieldName
        self.refreshState = refreshState
    }
    
    // MARK: - life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        refreshButton.snp.remakeConstraints { make in
            make.top.equalTo(originWrapper.snp.bottom).offset(refreshState.isVisible ? Const.OriginView.spacerH : 0)
            make.left.right.equalToSuperview()
            make.height.equalTo(refreshState.isVisible ? Const.OriginView.refreshH : 0).priority(.high)
        }
        super.updateConstraints()
    }
    
    // MARK: - private
    
    private var refreshState: FieldExtendRefreshButtonState = .normal {
        didSet {
            refreshButton.isEnabled = refreshState.isEnable
            refreshButton.isHidden = !refreshState.isVisible
            setNeedsUpdateConstraints()
        }
    }
    
    private let headerWrapper = UIView()
    
    private let headerLabel: UILabel = {
        let vi = UILabel()
        vi.textColor = UDColor.textPlaceholder
        vi.font = UDFont.body2
        vi.text = BundleI18n.SKResource.Bitable_PeopleField_DataSorceField_Title
        return vi
    }()
    
    private let originWrapper: UIView = UIView().construct { it in
        it.backgroundColor = UDColor.bgFloat
        it.layer.cornerRadius = 10
    }
    
    private let titleLabel = UILabel().construct { it in
        it.textColor = UDColor.textTitle
        it.font = UDFont.body0
        it.text = BundleI18n.SKResource.Bitable_PeopleField_DataSorceField_Title
    }
    
    private let originImgView = UIImageView()
    
    private let originLabel = UILabel().construct { it in
        it.textColor = UDColor.iconN3
        it.font = UDFont.body0
    }
    
    
    private func subviewsInit() {
        addSubview(headerWrapper)
        addSubview(originWrapper)
        addSubview(refreshButton)
        headerWrapper.addSubview(headerLabel)
        originWrapper.addSubview(titleLabel)
        originWrapper.addSubview(originImgView)
        originWrapper.addSubview(originLabel)
        
        headerWrapper.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(Const.headerH)
        }
        headerLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(20)
            make.bottom.equalToSuperview().inset(2)
        }
        
        originWrapper.snp.makeConstraints { make in
            make.top.equalTo(headerWrapper.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(Const.OriginView.originH).priority(.high)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().inset(16)
        }
        originImgView.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(8)
            make.size.equalTo(20)
            make.centerY.equalToSuperview()
        }
        originLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(originImgView.snp.right).offset(4)
            make.right.equalToSuperview().inset(16)
        }
        
        refreshButton.snp.makeConstraints { make in
            make.top.equalTo(originWrapper.snp.bottom).offset(14)
            make.left.right.equalToSuperview()
            make.height.equalTo(Const.OriginView.refreshH).priority(.high)
        }
        
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        originLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        refreshState = .hidden
    }
}


// MARK: - SwitchCell

private class SwitchCell: UITableViewCell {
    
    // MARK: - public
    
    static var defaultReuseID = "SwitchCell"
    
    let titleLabel = UILabel().construct { it in
        it.font = UDFont.body0
        it.textColor = UDColor.textTitle
    }
    
    let switchView = UDSwitch().construct { it in
        
    }
    
    let onboardingTagView: UILabel = UILabel().construct { it in
        it.text = "New"
        it.font = UDFont.caption0
        it.textAlignment = .center
        it.backgroundColor = UDColor.functionDangerContentDefault
        it.textColor = UDColor.staticWhite
        it.clipsToBounds = true
        it.layer.cornerRadius = Const.tagH * 0.5
    }
    
    // MARK: - life cycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        onboardingTagView.isHidden = OnboardingManager.shared.hasFinished(OnboardingID.bitableFieldExtendSwitchNew)
    }
    
    // MARK: - private
    
    private func subviewsInit() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = UDColor.bgFloat
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
        contentView.addSubview(titleLabel)
        contentView.addSubview(switchView)
        contentView.addSubview(onboardingTagView)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview()
        }
        switchView.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(16)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
        }
        onboardingTagView.snp.makeConstraints { make in
            make.width.equalTo(34)
            make.height.equalTo(Const.tagH)
            make.right.equalTo(switchView.snp.left).offset(-12)
            make.centerY.equalToSuperview()
        }
    }
}

// MARK: - FieldCell

private class FieldCell: UITableViewCell {
    
    // MARK: - public
    
    static var defaultReuseID = "FieldCell"
    
    let iconView = BTLightingIconView(frame: .zero)
    
    let titleLabel = UILabel().construct { it in
        it.font = UDFont.body0
        it.textColor = UDColor.textTitle
    }
    
    let checkBox = UDCheckBox(boxType: .multiple)
    
    func updateStyle(isFirstCell: Bool, isLastCell: Bool) {
        if isFirstCell && isLastCell {
            // only one
            layer.cornerRadius = 10
            layer.maskedCorners = .all
            spLine.isHidden = true
        } else if isFirstCell {
            // first but not last
            layer.cornerRadius = 10
            layer.maskedCorners = .top
            spLine.isHidden = false
        } else if isLastCell {
            // last but not first
            layer.cornerRadius = 10
            layer.maskedCorners = .bottom
            spLine.isHidden = true
        } else {
            // middle position, not first nor last
            layer.cornerRadius = 0
            spLine.isHidden = false
        }
    }
    
    // MARK: - life cycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - private
    
    private let spLine: UIView = UIView().construct { it in
        it.backgroundColor = UDColor.lineDividerDefault
        it.isUserInteractionEnabled = false
    }
    
    private let selectBgView: UIView = UIView().construct { vi in
        vi.backgroundColor = UDColor.N900.withAlphaComponent(0.1)
    }
    
    private func subviewsInit() {
        clipsToBounds = true
        backgroundColor = UDColor.bgFloat
        selectedBackgroundView = selectBgView
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = true
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(checkBox)
        contentView.addSubview(spLine)
        iconView.snp.makeConstraints { make in
            make.size.equalTo(20)
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(8)
            make.top.bottom.equalToSuperview()
        }
        checkBox.snp.makeConstraints { make in
            make.size.equalTo(20)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
            make.left.equalTo(titleLabel.snp.right).offset(16)
        }
        checkBox.tapCallBack = { sender in
            sender.isSelected = !sender.isSelected
        }
        spLine.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview()
            make.left.equalTo(iconView)
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        
    }
}

// MARK: - SectionHeader

private class SectionHeader: UITableViewHeaderFooterView {
    // MARK: - public
    
    static var defaultReuseID = "SectionHeader"
    
    let titleLabel = UILabel().construct { it in
        it.font = UDFont.body2
        it.textColor = UDColor.textPlaceholder
    }
    
    // MARK: - life cycle
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - private
    
    private func subviewsInit() {
        backgroundColor = .clear
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(20)
            make.bottom.equalToSuperview().inset(2)
        }
    }
}
