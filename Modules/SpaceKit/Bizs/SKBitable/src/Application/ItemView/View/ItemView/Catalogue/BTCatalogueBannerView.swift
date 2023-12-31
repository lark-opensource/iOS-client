//
//  BTCatalogueBannerView.swift
//  SKBitable
//
//  Created by yinyuan on 2023/11/8.
//

import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import SKUIKit

protocol BTCatalogueBannerViewDelegate: AnyObject {
    func didFirstLevelLabelClick()
    func didSecondLevelLabelClick()
}

final class BTCatalogueBannerView: UIControl {
    
    weak var delegate: BTCatalogueBannerViewDelegate?
    
    lazy var contentStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .center
        view.spacing = 2
        return view
    }()
    
    lazy var firstLevelLabel: UIButton = {
        let view = UIButton()
        view.setTitle("", for: .normal)
        view.setTitleColor(UDColor.textCaption, for: .normal)
        view.titleLabel?.font = .systemFont(ofSize: 12)
        view.setBackgroundImage(UIImage.docs.color(UDColor.udtokenBtnTextBgNeutralFocus.withAlphaComponent(0.1)), for: .highlighted)
        view.addTarget(self, action: #selector(firstLevelLabelClick), for: .touchUpInside)
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
        view.contentEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        view.titleLabel?.lineBreakMode = .byTruncatingTail
        return view
    }()
    
    lazy var divider = UIImageView().construct { it in
        it.contentMode = .scaleAspectFit
        it.image = UDIcon.rightBoldOutlined.withRenderingMode(.alwaysTemplate)
        it.tintColor = UDColor.iconN3.withAlphaComponent(1)
    }
    
    lazy var secondLevelLabel: UIButton = {
        let view = UIButton()
        view.setTitle("", for: .normal)
        view.setTitleColor(UDColor.textCaption, for: .normal)
        view.titleLabel?.font = .systemFont(ofSize: 12)
        view.setBackgroundImage(UIImage.docs.color(UDColor.udtokenBtnTextBgNeutralFocus.withAlphaComponent(0.1)), for: .highlighted)
        view.addTarget(self, action: #selector(secondLevelLabelClick), for: .touchUpInside)
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
        view.contentEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        view.titleLabel?.lineBreakMode = .byTruncatingTail
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(statusBarOrientationChange),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        
        addSubview(contentStackView)
        
        contentStackView.addArrangedSubview(firstLevelLabel)
        firstLevelLabel.snp.makeConstraints { make in
            make.height.equalTo(22)
        }
        
        contentStackView.addArrangedSubview(divider)
        divider.snp.makeConstraints { make in
            make.width.equalTo(12)
            make.height.equalTo(12)
        }
        
        contentStackView.addArrangedSubview(secondLevelLabel)
        secondLevelLabel.snp.makeConstraints { make in
            make.height.equalTo(22)
        }
    }
    
    @objc
    private func statusBarOrientationChange() {
        updateViews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateViews()
    }
    
    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        updateViews()
    }
    
    fileprivate func updateViews() {
        let rightPadding: CGFloat = 0
        contentStackView.snp.remakeConstraints { make in
            let orientation = LKDeviceOrientation.getInterfaceOrientation()
            make.left.equalToSuperview().offset(orientation == .landscapeRight ? self.safeAreaInsets.left : 0)
            make.top.bottom.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().offset(-rightPadding - (orientation == .landscapeLeft ? self.safeAreaInsets.right : 0))
        }
        
        let maxFirstLevelLabelWidth = ceil(firstLevelLabel.sizeThatFits(CGSize(width: CGFLOAT_MAX, height: CGFLOAT_MAX)).width)
        let minFirstLevelLabelWidth: CGFloat = min(50, maxFirstLevelLabelWidth)  // 一级目录文本的最短宽度
        firstLevelLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        firstLevelLabel.snp.remakeConstraints { make in
            make.width.greaterThanOrEqualTo(minFirstLevelLabelWidth)
            make.height.equalTo(22)
        }
        
        secondLevelLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }
    
    func setData(firstLevelTitle: String, secondLevelTitle: String) {
        firstLevelLabel.setTitle(firstLevelTitle, for: .normal)
        secondLevelLabel.setTitle(secondLevelTitle, for: .normal)
        
        // 在部分场景下直接刷新 UIStackView 会有布局错乱
        layoutIfNeeded()
        
        updateViews()
    }
    
    @objc
    private func firstLevelLabelClick() {
        delegate?.didFirstLevelLabelClick()
    }
    
    @objc
    private func secondLevelLabelClick() {
        delegate?.didSecondLevelLabelClick()
    }
    
}
