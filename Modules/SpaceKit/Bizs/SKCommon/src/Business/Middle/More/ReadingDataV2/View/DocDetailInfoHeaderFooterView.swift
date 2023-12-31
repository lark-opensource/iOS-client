//
//  DocDetailInfoHeaderView.swift
//  SKCommon
//
//  Created by huayufan on 2021/10/19.
//  


import UIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon

class DocDetailInfoHeaderView: UIView {

    enum Event {
       case close
       case refresh
    }
    
    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = UDColor.textTitle
        label.textAlignment = .center
        label.text = BundleI18n.SKResource.CreationMobile_Stats_title
        return label
    }()

    private(set) lazy var closeButton = UIButton().construct { it in
        it.setImage(UDIcon.closeSmallOutlined, withColorsForStates: [
            (UDColor.iconN1, .normal),
            (UDColor.iconN3, .highlighted),
            (UDColor.iconDisabled, .disabled)
        ])
        it.hitTestEdgeInsets = UIEdgeInsets(edges: -10)
    }
    
    private(set) lazy var reloadButton = UIButton().construct { it in
        let icon = UDIcon.getIconByKey(.refreshOutlined, iconColor: UDColor.primaryContentDefault, size: CGSize(width: 24, height: 24))
        it.setImage(icon, for: [.normal, .highlighted])
        it.hitTestEdgeInsets = UIEdgeInsets(edges: -10)
        it.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        it.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        it.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        it.isHidden = true
    }
    
    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()
    
    var buttonAction: ((Event) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(closeButton)
        addSubview(titleLabel)
        addSubview(lineView)
        addSubview(reloadButton)
    }

    private func setupConstraints() {
        closeButton.snp.makeConstraints { make in
            make.leading.equalTo(safeAreaLayoutGuide.snp.leading).inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        closeButton.addTarget(self, action: #selector(closeClick), for: .touchUpInside)
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
        }
        lineView.snp.makeConstraints { (make) in
            make.height.equalTo(1)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        reloadButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        reloadButton.addTarget(self, action: #selector(refreshClick), for: .touchUpInside)
    }
    
    @objc
    func closeClick() {
        buttonAction?(.close)
    }
    
    @objc
    func refreshClick() {
        buttonAction?(.refresh)
        reloadButton.isHidden = true
    }
}


class DocDetailInfoFooterView: UIView {
    
    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UDColor.textPlaceholder
        label.textAlignment = .center
        label.text = BundleI18n.SKResource.CreationMobile_Stats_Visits_StartFromDate
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var leftLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()
 
    private lazy var rightLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(titleLabel)
        addSubview(leftLineView)
        addSubview(rightLineView)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(16)
            make.width.equalTo(160)
            make.centerX.equalToSuperview()
        }
        
        leftLineView.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.left.equalToSuperview().inset(16)
            make.top.equalTo(titleLabel.snp.top).offset(7)
            make.right.equalTo(titleLabel.snp.left).offset(-10)
        }
        
        rightLineView.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.right.equalToSuperview().inset(16)
            make.top.equalTo(leftLineView)
            make.left.equalTo(titleLabel.snp.right).offset(10)
        }
    }
}
