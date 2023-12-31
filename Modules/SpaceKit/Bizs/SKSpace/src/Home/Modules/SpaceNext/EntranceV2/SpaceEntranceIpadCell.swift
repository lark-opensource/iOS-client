//
//  SpaceEntranceIpadCell.swift
//  SKSpace
//
//  Created by majie.7 on 2023/9/25.
//

import Foundation
import UniverseDesignColor
import RxSwift


public struct SpaceEntranceIpadLayout: SpaceEntranceLayoutType {
    public var sectionHorizontalInset: CGFloat { 0 }
    
    public var itemSize: CGSize {
        CGSize(width: containerWidth, height: 48)
    }
    
    public var footerHeight: CGFloat { 0 }
    
    public var footerColor: UIColor { UDColor.bgBody }
    
    private var containerWidth: CGFloat = 375
    
    public init(itemCount: Int) {}
    
    public mutating func update(itemCount: Int) {}
    
    public mutating func update(containerWidth: CGFloat) {
        self.containerWidth = containerWidth
    }
}


public class SpaceEntranceIpadCell: UICollectionViewCell, SpaceEntranceCellType {
    
    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private lazy var selectBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textTitle
        label.numberOfLines = 1
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    private(set) var hoverGesture: UIGestureRecognizer?
    private var isSelect = false
    private let disposeBag = DisposeBag()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        if #available(iOS 13.0, *) {
            setupHoverInteraction()
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .clear
        
        contentView.addSubview(selectBackgroundView)
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        
        selectBackgroundView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(8)
            make.top.bottom.equalToSuperview()
        }
        
        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(26)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(8)
            make.centerY.equalToSuperview()
        }
        
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        iconView.image = nil
        selectBackgroundView.backgroundColor = .clear
        titleLabel.text = nil
        isSelect = false
    }
    
    @available(iOS 13.0, *)
    private func setupHoverInteraction() {
        let gesture = UIHoverGestureRecognizer()
        gesture.rx.event.subscribe(onNext: { [weak self] gesture in
            guard let self = self else { return }
            switch gesture.state {
            case .began, .changed:
                if !self.isSelect {
                    self.selectBackgroundView.backgroundColor = UDColor.fillHover
                }
            case .ended, .cancelled:
                if !self.isSelect {
                    self.selectBackgroundView.backgroundColor = .clear
                }
            default:
                break
            }
        }).disposed(by: disposeBag)
        hoverGesture = gesture
        contentView.addGestureRecognizer(gesture)
    }
    
    public func update(entrance: SpaceEntrance) {
        iconView.image = entrance.image
        titleLabel.text = entrance.title
    }
    
    public func update(needHighlight: Bool) {
        isSelect = needHighlight
        if needHighlight {
            titleLabel.textColor = UDColor.functionInfoContentDefault
            titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
            selectBackgroundView.backgroundColor = UDColor.fillSelected
        } else {
            titleLabel.textColor = UDColor.textTitle
            titleLabel.font = .systemFont(ofSize: 16)
            selectBackgroundView.backgroundColor = .clear
        }
    }
}
