//
//  BTCardLayoutTitleView.swift
//  SKBitable
//
//  Created by zhysan on 2023/1/10.
//

import UIKit
import SKResource
import SKFoundation
import SKCommon
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignIcon
import UniverseDesignBadge

protocol BTCardLayoutTitleViewDelegate: AnyObject {
    func onTitleChangeRequest(_ view: BTCardLayoutTitleView)
    func onSubTitleChangeRequest(_ view: BTCardLayoutTitleView)
    func onCoverChangeRequest(_ view: BTCardLayoutTitleView)
}

final class BTCardLayoutTitleView: BTTableSectionCardView {
    
    // MARK: - public
    
    weak var delegate: BTCardLayoutTitleViewDelegate?
    
    func update(_ data: BTCardLayoutSettings.TitleAndCoverSection) {
        mainUnitView.detail = data.titleField.name
        if let subTitle = data.subTitleField?.name {
            sumUnitView.detail = subTitle
        } else {
            sumUnitView.detail = BundleI18n.SKResource.Bitable_Mobile_FieldNotSelected
        }
        
        if UserScopeNoChangeFG.ZJ.btCardViewCoverEnable {
            if let coverTitle = data.coverField?.name {
                coverUnitView.detail = coverTitle
            } else {
                coverUnitView.detail = BundleI18n.SKResource.Bitable_Mobile_FieldNotSelected
            }
        }
    }
    
    // MARK: - life cycle
    
    init(frame: CGRect = .zero, delegate: BTCardLayoutTitleViewDelegate? = nil) {
        self.delegate = delegate
        super.init(frame: frame)
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - private
    
    private let stackView = UIStackView().construct { it in
        it.axis = .vertical
    }
    
    private let coverUnitView = SettingUnitView().construct { it in
        it.title = BundleI18n.SKResource.Bitable_Mobile_Configuration_Cover_Title
    }
    
    private let mainUnitView = SettingUnitView().construct { it in
        it.title = BundleI18n.SKResource.Bitable_Mobile_CardMode_TitleSettings_Title_Title
    }
    
    private let sumUnitView = SettingUnitView().construct { it in
        it.title = BundleI18n.SKResource.Bitable_Mobile_CardMode_TitleSettings_Subtitle_Title
    }
    
    @objc
    private func onTitleTapped(_ sender: UITapGestureRecognizer) {
        delegate?.onTitleChangeRequest(self)
    }
    
    @objc
    private func onSubTitleTapped(_ sender: UITapGestureRecognizer) {
        delegate?.onSubTitleChangeRequest(self)
    }
    
    @objc
    private func onCoverTapped(_ sender: UITapGestureRecognizer) {
        // 打开封面字段选择面板
        delegate?.onCoverChangeRequest(self)
        OnboardingManager.shared.markFinished(for: [OnboardingID.bitableCardViewCoverNew])
        coverUnitView.shouldShowNewBadge = false
    }
    
    private func subviewsInit() {
        if UserScopeNoChangeFG.ZJ.btCardViewCoverEnable {
            headerText =  BundleI18n.SKResource.Bitable_Mobile_Configuration_Title
        } else {
            headerText = BundleI18n.SKResource.Bitable_Mobile_CardMode_TitleSettings_Title
        }
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        if UserScopeNoChangeFG.ZJ.btCardViewCoverEnable {
            stackView.addArrangedSubview(coverUnitView)
            coverUnitView.shouldShowNewBadge = !OnboardingManager.shared.hasFinished(OnboardingID.bitableCardViewCoverNew)
            coverUnitView.showSpLine = true
        }
        stackView.addArrangedSubview(mainUnitView)
        stackView.addArrangedSubview(sumUnitView)
        
        mainUnitView.showSpLine = true
        
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(onTitleTapped(_:)))
        mainUnitView.addGestureRecognizer(tap1)
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(onSubTitleTapped(_:)))
        sumUnitView.addGestureRecognizer(tap2)
        
        if UserScopeNoChangeFG.ZJ.btCardViewCoverEnable {
            let tap3 = UITapGestureRecognizer(target: self, action: #selector(onCoverTapped(_:)))
            coverUnitView.addGestureRecognizer(tap3)
        }
    }
}

private final class SettingUnitView: UIView {
    
    // MARK: - public
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    var shouldShowNewBadge: Bool = false {
        didSet {
            titleLabel.badge?.isHidden = !shouldShowNewBadge
        }
    }
    
    var detail: String? {
        didSet {
            detailLabel.text = detail
        }
    }
    
    var showSpLine: Bool = false {
        didSet {
            bottomSpLine.isHidden = !showSpLine
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
    
    private let titleWrapperView = UIView().construct { it in
        it.backgroundColor = .clear
    }
    
    private let titleLabel = UILabel().construct { it in
        it.textColor = UDColor.textTitle
        it.font = UDFont.body0
        it.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    private let detailLabel = UILabel().construct { it in
        it.textColor = UDColor.textCaption
        it.font = UDFont.body2
        it.textAlignment = .right
        it.setContentHuggingPriority(.required, for: .horizontal)
    }
    
    private let arrawView = UIImageView().construct { it in
        it.image = UDIcon.rightSmallCcmOutlined.ud.withTintColor(UDColor.iconN3)
    }
    
    private let bottomSpLine = UIView().construct { it in
        it.isHidden = true
        it.isUserInteractionEnabled = false
        it.backgroundColor = UDColor.lineDividerDefault
    }
    
    private func subviewsInit() {
        addSubview(titleWrapperView)
        addSubview(detailLabel)
        addSubview(arrawView)
        addSubview(bottomSpLine)
        titleWrapperView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.height.equalTo(48)
            make.left.equalToSuperview().inset(16)
        }
        
        titleWrapperView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
        
        detailLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(titleWrapperView.snp.right).offset(16)
        }
        arrawView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.left.equalTo(detailLabel.snp.right).offset(8)
        }
        bottomSpLine.snp.makeConstraints { make in
            make.bottom.right.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
            make.left.equalTo(titleWrapperView)
        }
        
        let config = UDBadgeConfig(type: .dot)
        titleLabel.layer.masksToBounds = false
        titleLabel.addBadge(config,
                            offset: CGSize(width: 12, height: 10))
        titleLabel.badge?.isHidden = true
    }
}
