//
//  NewCalendarSidebarCell.swift
//  Calendar
//
//  Created by huoyunjie on 2021/8/26.
//

import UIKit
import UniverseDesignIcon
import Foundation
import UniverseDesignCheckBox
import LarkActivityIndicatorView
import CalendarFoundation
import LarkContainer

protocol SidebarCellViewData {
    var uniqueId: String { get }// 唯一标识
    var isVisible: Bool { get }// 可见性
    var displayName: String { get }// 名称
    var color: UIColor { get }// 颜色
    var isResign: Bool { get }// 离职
    var isInactive: Bool { get }// 失效
    var isNeedApproval: Bool { get }// 审批
    var isExternal: Bool { get }// 外部
    var trailBtnImg: UIImage? { get }// 尾部按钮图片，nil 为 hidden btn
    var isLoading: Bool { get }// 是否正在loading
}

public class NewCalendarSidebarCell: UITableViewCell {

    private let bgView = UIView()
    private(set) var settingButton: UIButton = {
        let btn = UIButton()
        btn.increaseClickableArea(top: -14, left: -12, bottom: -14, right: -16)
        return btn
    }()

    private var checkboxConfig: UDCheckBoxUIConfig {
        didSet {
            self.checkbox.updateUIConfig(boxType: .multiple, config: checkboxConfig)
        }
    }
    private let checkbox: UDCheckBox = UDCheckBox(boxType: .multiple, config: UDCheckBoxUIConfig(style: .circle))
    private let indicatorView = LarkActivityIndicatorView.ActivityIndicatorView()

    private let stackView: UIStackView = UIStackView()
    private var label: UILabel = UILabel.cd.textLabel(fontSize: 16)
    private let inactivateTag = TagViewProvider.inactivate()
    private let needApprovalTag = TagViewProvider.needApproval
    private let resignedTagView = TagViewProvider.resignedTagView
    private let externalTag = TagViewProvider.externalNormal

    var settingTaped: (() -> Void)?
    var checkboxTaped: ((UDCheckBox) -> Void)? {
        didSet {
            checkbox.tapCallBack = checkboxTaped
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.checkboxConfig = UDCheckBoxUIConfig(style: .circle)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    private func setupView() {
        contentView.backgroundColor = UIColor.ud.bgBody

        bgView.backgroundColor = UIColor.ud.Y100
        bgView.alpha = 0.0
        bgView.isHidden = true
        contentView.addSubview(bgView)
        bgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.addSubview(settingButton)
        settingButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
            make.right.equalToSuperview().offset(CalendarSidebarStyle.FilterItemCell.labelRight)
        }
        settingButton.addTarget(self, action: #selector(onSettingTaped), for: .touchUpInside)

        contentView.addSubview(checkbox)
        checkbox.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(CalendarSidebarStyle.FilterItemCell.checkboxLeft)
            make.centerY.equalToSuperview()
        }
        checkbox.tapCallBack = checkboxTaped
        checkbox.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(CalendarSidebarStyle.FilterItemCell.checkboxLeft)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(CalendarSidebarStyle.FilterItemCell.checkboxSize)
        }
        checkbox.hitTestEdgeInsets = UIEdgeInsets(top: -14, left: -CalendarSidebarStyle.FilterItemCell.checkboxLeft, bottom: -14, right: -16)

        contentView.addSubview(indicatorView)
        indicatorView.snp.makeConstraints { make in
            make.edges.equalTo(checkbox).inset(1)
        }

        contentView.addSubview(stackView)
        stackView.axis = .horizontal
        stackView.spacing = 6
        stackView.distribution = .fill
        stackView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().offset(-37)
            make.left.equalTo(checkbox.snp.right).offset(CalendarSidebarStyle.FilterItemCell.labelLeftOffset)
        }
        label.textColor = CalendarSidebarStyle.FilterItemCell.labelTextColor
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(inactivateTag)
        stackView.addArrangedSubview(needApprovalTag)
        stackView.addArrangedSubview(resignedTagView)
        stackView.addArrangedSubview(externalTag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var viewData: SidebarCellViewData? {
        didSet {
            guard let model = viewData else { return }
            label.text = model.displayName
            resignedTagView.isHidden = !model.isResign
            inactivateTag.isHidden = !model.isInactive
            needApprovalTag.isHidden = !model.isNeedApproval
            externalTag.isHidden = !model.isExternal

            indicatorView.color = model.color
            setCheckBoxColor(color: model.color)
            settingButton.isHidden = model.trailBtnImg == nil
            if let image = model.trailBtnImg {
                settingButton.setImage(image.ud.resized(to: CGSize(width: 20, height: 20)).renderColor(with: .n3), for: .normal)                
            }

            if model.isVisible && model.isLoading {
                startLoading()
            } else {
                stopLoading()
            }
            checkbox.isSelected = model.isVisible
        }
    }

    private func reset() {
        label.text = ""
        resignedTagView.isHidden = true
        inactivateTag.isHidden = true
        needApprovalTag.isHidden = true
        externalTag.isHidden = true
        settingButton.isHidden = true
        checkbox.isHidden = false
        checkbox.isSelected = false
    }

    public func setupIsChecked(_ isChecked: Bool, _ showLoading: Bool = true) {
        guard self.checkbox.isSelected != isChecked else { return }
        if isChecked && showLoading {
            startLoading()
        } else {
            stopLoading()
            checkbox.isSelected = isChecked
        }
    }

    @objc
    private func onSettingTaped() {
        self.settingTaped?()
    }

     func setCheckBoxColor(color: UIColor) {
        checkboxConfig = UDCheckBoxUIConfig(borderEnabledColor: color,
                                            selectedBackgroundEnabledColor: color,
                                            style: .circle)
    }

    func startLoading() {
        indicatorView.startAnimating()
        checkbox.isHidden = true
    }

    func stopLoading() {
        checkbox.isHidden = false
        indicatorView.stopAnimating()
    }

    public func doblinking() {
        self.bgView.isHidden = false
        blink(showFrom: false)
    }

    private func blink(showFrom: Bool, blinkCount: Int = 5) {
        guard blinkCount > 0 else { return }
        UIView.animate(withDuration: 0.6) {
            self.bgView.alpha = showFrom ? 0.0 : 1.0
        } completion: { _ in
            self.blink(showFrom: !showFrom, blinkCount: blinkCount - 1)
        }
    }

    public func hiddenBlink() {
        self.bgView.isHidden = true
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        self.reset()
        self.removeFromSuperview()
    }
}

// MARK: tag Hidden
extension CalendarModel {
    var hiddenResignedTag: Bool {
        let successorChatterID = getCalendarPB().successorChatterID
        let isResigned = !(successorChatterID.isEmpty || successorChatterID == "0")
        return isLocalCalendar() ? true : !isResigned
    }

    var hiddenInactivateTag: Bool {
        return !isDisabled
    }

    var hiddenNeedApprovalTag: Bool {
        return !(!isDisabled && needApproval)
    }
}
