//
//  CagegoryEditCell.swift
//  Moment
//
//  Created by liluobin on 2021/5/13.
//

import Foundation
import UIKit
import SnapKit
import LarkInteraction

final class CagegoryFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForInteractivelyMovingItem(at indexPath: IndexPath, withTargetPosition position: CGPoint) -> UICollectionViewLayoutAttributes {
        let attributes = super.layoutAttributesForInteractivelyMovingItem(at: indexPath, withTargetPosition: position)
        attributes.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        return attributes
    }
}

final class CategoryIcon: UIView {
    let imageView = UIImageView()
    let tap: (() -> Void)?
    init(tap: (() -> Void)?) {
        self.tap = tap
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func setupUI() {
        self.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 20, height: 20))
            make.center.equalToSuperview()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapView))
        self.addGestureRecognizer(tap)
    }

    func setImage(_ image: UIImage?) {
        imageView.image = image
        self.isHidden = image == nil
    }

    @objc
    func tapView() {
        tap?()
    }
}

final class CagegoryEditCell: UICollectionViewCell {
    static let reuseId: String = "CagegoryEditCell"
    let shakeKey = "shakeKey"
    private let label = UILabel()
    private var isNomalIconScale: Bool {
        return icon.transform == CGAffineTransform.identity
    }

    private lazy var icon: CategoryIcon = {
        return CategoryIcon { [weak self] in
            self?.onTap()
        }
    }()

    var iconTap: ((CagegoryEditCell) -> Void)?
    var viewModel: CategoryEditCellViewModel? {
        didSet {
            updateUI()
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        self.contentView.backgroundColor = UIColor.ud.N100
        self.contentView.layer.cornerRadius = 8
        self.contentView.addSubview(label)
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-8)
            make.left.equalToSuperview().offset(8)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }
        self.contentView.addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 38, height: 38))
            make.centerX.equalTo(self.snp.right).offset(-5)
            make.centerY.equalTo(self.snp.top).offset(5)
        }
        self.addPointer(.lift)
    }

    func updateUI() {
        guard let vm = viewModel else {
            return
        }
        label.text = vm.tab.name
        label.textColor = textColorWithVM(vm)
        self.contentView.backgroundColor = backgroundColorWithVM(vm)
        icon.setImage(iconImageWithVM(vm))
    }

    func updateIconWithImage(_ image: UIImage) {
        icon.setImage(image)
    }

    private func textColorWithVM(_ vm: CategoryEditCellViewModel) -> UIColor {
        guard vm.onEditing else {
            return vm.isSelected ? UIColor.ud.B600 : UIColor.ud.N800
        }
        return vm.tab.canRemove ? UIColor.ud.N800 : UIColor.ud.N400
    }

    private func backgroundColorWithVM(_ vm: CategoryEditCellViewModel) -> UIColor {
         guard vm.onEditing else {
             return vm.isSelected ? UIColor.ud.B100 : UIColor.ud.N200
         }
         return UIColor.ud.N200
     }

    private func iconImageWithVM(_ vm: CategoryEditCellViewModel) -> UIImage? {
        guard vm.onEditing else {
            return nil
        }
        if !vm.tab.canRemove {
            return nil
        }
        return vm.iconImage
    }
    private func onTap() {
        iconTap?(self)
    }

    func startShakeAnimation() {
        if self.layer.animation(forKey: shakeKey) != nil || !(viewModel?.showAnimation ?? false) {
            return
        }
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = -Double.pi / 300
        animation.toValue = Double.pi / 300
        animation.repeatCount = MAXFLOAT
        animation.beginTime = CFTimeInterval(Float(Int.random(in: 1...10)) * 0.05)
        animation.duration = 0.15
        animation.autoreverses = true
        self.layer.add(animation, forKey: shakeKey)
    }

    func zoomActionIcon(reduce: Bool) {
        if isNomalIconScale, !reduce {
            return
        }
        if !isNomalIconScale, reduce {
            return
        }

        UIView.animate(withDuration: 0.25) { [weak self] in
            if reduce {
                self?.icon.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            } else {
                self?.icon.transform = CGAffineTransform.identity
            }
        }completion: { [weak self] (_) in
            self?.icon.isHidden = reduce
        }
    }

    func stopShareAnimation() {
        if self.layer.animation(forKey: shakeKey) == nil {
            return
        }
        self.layer.removeAnimation(forKey: shakeKey)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view == nil {
            let point = self.icon.convert(point, from: self)
            if self.icon.bounds.contains(point), !self.icon.isHidden {
                return self.icon
            }
        }
        return view
    }
}
