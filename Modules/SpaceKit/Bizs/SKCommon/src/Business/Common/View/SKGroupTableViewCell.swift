//
//  SKGroupTableViewCell.swift
//  SKCommon
//
//  Created by huayufan on 2021/8/24.
//  


import UIKit

private struct SKGroupElementKey {
    static var containerViewKey = "containerViewKey"
    static var separatorViewKey = "separatorViewKey"
}

private struct SKGroupViewLayout {
    static let padding: CGFloat = 16
    static let separatorMargin: CGFloat = 44
}

public enum SKGroupViewPosition {
    
    case head
    case middle
    case tail
    case single
    
    public static func converToPisition(rows: Int, indexPath: IndexPath) -> SKGroupViewPosition {
        if indexPath.row == 0, rows == 1 {
            return .single
        } else if indexPath.row == 0 {
            return .head
        } else if indexPath.row == rows - 1 {
            return .tail
        } else {
            return .middle
        }
    }
}

public protocol SKGroupViewType {
    var contentView: UIView { get }
}

extension SKGroupViewType where Self: UIView {
    
    public var containerView: UIView {
        return element(for: &SKGroupElementKey.containerViewKey)
    }
    
    public var separatorView: UIView {
        return element(for: &SKGroupElementKey.separatorViewKey)
    }
    
    private func element(for key: inout String) -> UIView {
        guard let element = objc_getAssociatedObject(self, &key) as? UIView else {
           let view = UIView()
           objc_setAssociatedObject(self, &key, view, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
           return view
        }
        return element
    }
}

extension SKGroupViewType where Self: UIView {
    
    func setupInit() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        containerView.construct {
            $0.backgroundColor = UIColor.ud.bgBody
        }
        separatorView.construct {
            $0.backgroundColor = UIColor.ud.lineDividerDefault
        }
        
        contentView.addSubview(containerView)
        containerView.insertSubview(separatorView, at: 10)
    }
    
    func setupLayout() {
        containerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(SKGroupViewLayout.padding)
        }
        separatorView.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
            make.left.equalToSuperview().offset(SKGroupViewLayout.separatorMargin)
        }
    }
    
    public func updateSeparator(_ margin: CGFloat) {
        separatorView.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(margin)
        }
    }
    
    public func update(_ position: SKGroupViewPosition) {
        separatorView.isHidden = false
        switch position {
        case .head:
            containerView.layer.cornerRadius = 10
            containerView.layer.maskedCorners = .top
        case .middle:
            containerView.layer.cornerRadius = 0
            containerView.layer.maskedCorners = []
        case .tail:
            separatorView.isHidden = true
            containerView.layer.cornerRadius = 10
            containerView.layer.maskedCorners = .bottom
        case .single:
            separatorView.isHidden = true
            containerView.layer.cornerRadius = 10
            containerView.layer.maskedCorners = .all
        }
    }
}

open class SKGroupTableViewCell: UITableViewCell, SKGroupViewType {
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        setupInit()
        setupLayout()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class SKGroupCollectionViewCell: UICollectionViewCell, SKGroupViewType {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupInit()
        setupLayout()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
