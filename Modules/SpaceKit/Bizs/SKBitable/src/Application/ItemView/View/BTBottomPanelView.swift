//
//  BottomPanelView.swift
//  SKBitable
//
//  Created by qiyongka on 2023/7/14.
//

import Foundation
import SKCommon
import SKResource
import UniverseDesignEmpty
import UniverseDesignIcon
import UniverseDesignColor
import SKUIKit
import SKFoundation
import UniverseDesignNotice


final class PaginationView: UIView {
    
    struct Const {
        static let containerH: CGFloat = 46.0
        
        // 不是 containerH * 0.5，这样让它看起来更扁平
        static let cornerRadius: CGFloat = 26.0
    }
    
    weak var delegate: BTRecordDelegate?
    
    var currentIndex: Int = 1 {
        didSet {
            leftButton.isEnabled = currentIndex == 0 ? false: true
            rightButton.isEnabled = currentIndex == total - 1 ? false: true
        }
    }

    var total: Int = 1 {
        didSet {
            leftButton.isEnabled = currentIndex == 0 ? false: true
            rightButton.isEnabled = currentIndex == total - 1 ? false: true
        }
    }
    
    private var length: Int = 32
    
    private lazy var contentView = UIView()
    
    lazy var textLabel = UILabel().construct { it in
        it.font = .systemFont(ofSize: 14)
        it.textColor = UDColor.textTitle
        it.textAlignment = .center
    }
    
    lazy var leftButton = UIButton().construct { it in
        it.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: UDColor.iconN1, size: CGSize(width: 20, height: 20)), for: .normal)
        it.addTarget(self, action: #selector(switchLeft), for: .touchUpInside)
    }
    
    lazy var rightButton = UIButton().construct { it in
        it.setImage(UDIcon.getIconByKey(.rightOutlined, iconColor: UDColor.iconN1, size: CGSize(width: 20, height: 20)), for: .normal)
        it.addTarget(self, action: #selector(switchRight), for: .touchUpInside)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
        updateTextLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func switchLeft() {
        guard currentIndex > 0 else { return }
        delegate?.switchCardToLeft()
    }
    
    @objc func switchRight() {
        guard currentIndex < total - 1 else { return }
        delegate?.switchCardToRight()
    }
    
    func updateRecordIndex() {
        guard let result = delegate?.getCurrentRecordIndex() else { return }
        currentIndex = result.current
        total = result.total
    }
    
    func updateTextLabel() {
        updateRecordIndex()
        let currentLength = (String(total).count + String(currentIndex + 1).count) * 9 + 14
        if length != currentLength {
            length = currentLength
            textLabel.snp.updateConstraints { make in
                make.width.equalTo(currentLength)
            }
        }
        textLabel.text = "\(currentIndex + 1)/\(total)"
    }
    
    func setLayout() {
        addSubview(contentView)
        contentView.addSubview(leftButton)
        contentView.addSubview(textLabel)
        contentView.addSubview(rightButton)
        
        layer.ud.setShadow(type: .s4Down)
        
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = PaginationView.Const.cornerRadius
        contentView.backgroundColor = UDColor.bgBody.withAlphaComponent(0.8)
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        leftButton.snp.makeConstraints { make in
            make.top.left.equalToSuperview()
            make.width.height.equalTo(PaginationView.Const.containerH)
        }
        
        textLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalTo(leftButton.snp.right)
            make.right.equalTo(rightButton.snp.left)
            make.width.equalTo(length)
            make.height.equalTo(PaginationView.Const.containerH)
        }
        
        rightButton.snp.makeConstraints { make in
            make.top.right.equalToSuperview()
            make.width.height.equalTo(PaginationView.Const.containerH)
        }
    }
}
