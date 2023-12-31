//
//  BTTableLayoutTypeSettingView.swift
//  SKBitable
//
//  Created by zhysan on 2023/1/10.
//

import UIKit
import SKCommon
import SKResource
import SKFoundation
import UniverseDesignBadge
import UniverseDesignCheckBox
import UniverseDesignColor
import UniverseDesignFont

protocol BTTableLayoutTypeSettingViewDelegate: AnyObject {
    func onViewTypeChanged(_ sender: BTTableLayoutTypeSettingView, viewType: BTTableLayoutSettings.ViewType)
}

final class BTTableLayoutTypeSettingView: BTTableSectionCardView {
    
    // MARK: - public
    
    weak var delegate: BTTableLayoutTypeSettingViewDelegate?
    
    var currentType: BTTableLayoutSettings.ViewType = .classic {
        didSet {
            updateSelectionUnit()
        }
    }
    
    // MARK: - life cycle
    
    init(frame: CGRect = .zero, delegate: BTTableLayoutTypeSettingViewDelegate? = nil) {
        self.delegate = delegate
        super.init(frame: frame)
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - private
    
    private let gridUnitView = SettingUnit().construct { it in
        it.text = BundleI18n.SKResource.Bitable_Mobile_CardMode_Grid
    }
    
    private let spLine1 = UIView().construct { it in
        it.backgroundColor = UDColor.lineDividerDefault
    }
    
    private let cardUnitView = SettingUnit().construct { it in
        it.text = BundleI18n.SKResource.Bitable_Mobile_CardMode_Card
    }
    
    private func onUnitTapped(_ sender: SettingUnit) {
        let selectType: BTTableLayoutSettings.ViewType?
        switch sender {
        case gridUnitView:
            selectType = .classic
        case cardUnitView:
            selectType = .card
            if UserScopeNoChangeFG.ZJ.btCardViewCoverEnable {
                OnboardingManager.shared.markFinished(for: [OnboardingID.bitableCardViewCoverSupportSwitch])
            }
        default:
            spaceAssertionFailure("unsupported sender!")
            selectType = nil
            return
        }
        if let nextType = selectType, nextType != currentType {
            currentType = nextType
            delegate?.onViewTypeChanged(self, viewType: currentType)
        }
    }
    
    private func updateSelectionUnit() {
        gridUnitView.selected = (currentType == .classic)
        cardUnitView.selected = (currentType == .card)
        
        if UserScopeNoChangeFG.ZJ.btCardViewCoverEnable {
            if currentType == .classic {
                cardUnitView.shouldShowNewBadge = !OnboardingManager.shared.hasFinished(OnboardingID.bitableCardViewCoverSupportSwitch)
            } else if currentType == .card  {
                cardUnitView.shouldShowNewBadge = false
                OnboardingManager.shared.markFinished(for: [OnboardingID.bitableCardViewCoverSupportSwitch])
            }
        }
    }
    
    private func subviewsInit() {
        contentView.addSubview(gridUnitView)
        contentView.addSubview(spLine1)
        contentView.addSubview(cardUnitView)
        
        gridUnitView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(48)
        }
        spLine1.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.right.equalToSuperview()
            make.bottom.equalTo(gridUnitView.snp.bottom)
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        cardUnitView.snp.makeConstraints { make in
            make.top.equalTo(gridUnitView.snp.bottom)
            make.height.equalTo(48)
            make.left.right.bottom.equalToSuperview()
        }
        
        updateSelectionUnit()
        
        gridUnitView.tapAction = {[weak self] sender in
            self?.onUnitTapped(sender)
        }
        cardUnitView.tapAction = {[weak self] sender in
            self?.onUnitTapped(sender)
            sender.shouldShowNewBadge = false
        }
    }
}

private final class SettingUnit: UIView {
    
    // MARK: - public
    
    var tapAction: ((SettingUnit) -> Void)?
    
    var selected: Bool {
        set {
            checkBox.isSelected = newValue
        }
        get {
            checkBox.isSelected
        }
    }
    
    var text: String? = nil {
        didSet {
            textLabel.text = text
        }
    }
    
    var shouldShowNewBadge: Bool = false {
        didSet {
            textLabel.badge?.isHidden = !shouldShowNewBadge
        }
    }
    
    // MARK: - lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - private
    
    private let checkBox = UDCheckBox()
    
    private let textWrapperView = UIView().construct { it in
        it.backgroundColor = .clear
    }
    
    private let textLabel = UILabel().construct { it in
        it.textColor = UDColor.textTitle
        it.font = UDFont.body0
    }
    
    @objc
    private func onBodyTapped(_ sender: UITapGestureRecognizer) {
        tapAction?(self)
    }
    
    private func subviewsInit() {
        backgroundColor = .clear
        addSubview(checkBox)
        addSubview(textWrapperView)
        checkBox.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
        }
        textWrapperView.snp.makeConstraints { make in
            make.left.equalTo(checkBox.snp.right).offset(12)
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().inset(16)
        }
        
        textWrapperView.addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
        
        checkBox.isUserInteractionEnabled = false
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onBodyTapped(_:)))
        addGestureRecognizer(tap)
        
        let config = UDBadgeConfig(type: .dot)
        textLabel.layer.masksToBounds = false
        textLabel.addBadge(config,
                           offset: CGSize(width: 12, height: 10))
        textLabel.badge?.isHidden = true
    }
}
