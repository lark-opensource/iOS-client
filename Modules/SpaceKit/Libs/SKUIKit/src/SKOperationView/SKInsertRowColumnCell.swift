//
// Created by zoujie.andy on 2021/12/13.
// Affiliated with SKUIKit.
//
// Description:

import Foundation
import SnapKit
import SKResource
import RxSwift
import RxCocoa
import UniverseDesignColor
import UniverseDesignIcon
import UIKit
import SKFoundation

extension SKOperationView: SKInsertRowColumnCellDelegate {
    func skInsertRowColumnCellDidSelect(_ cell: SKInsertRowColumnCell, identifier: String, itemIsEnable: Bool, disableReason: OperationItemDisableReason) {
        delegate?.didClickItem(identifier: identifier, finishGuide: false, itemIsEnable: itemIsEnable, disableReason: disableReason, at: self)
    }
}
// FIXME: 感觉这里没必要搞代理，直接注入闭包就可以了
protocol SKInsertRowColumnCellDelegate: AnyObject {
    func skInsertRowColumnCellDidSelect(_ cell: SKInsertRowColumnCell, identifier: String, itemIsEnable: Bool, disableReason: OperationItemDisableReason)
}

class SKInsertRowColumnCell: UICollectionViewCell {
    
    var disposeBag = DisposeBag()
    
    var items = [SKOperationItem]()
    
    var stackView = UIStackView().construct { (it) in
        it.axis = .horizontal
        it.distribution = .fillEqually
        it.alignment = .fill
        it.spacing = 1
        it.layer.cornerRadius = 8
        it.layer.masksToBounds = true
        it.clipsToBounds = true
    }
    
    weak var delegate: SKInsertRowColumnCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    private func setupUI() {
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }
    }
    
    func config(_ items: [SKOperationItem]) {
        let arrangedSubviews = stackView.arrangedSubviews
        for subview in arrangedSubviews {
            subview.removeFromSuperview()
        }
        let count = items.count
        for (idx, item) in items.enumerated() {
            guard let image = item.image else { break }
            let wrapperView = UIView().construct { (it) in
                it.backgroundColor = UDColor.bgBodyOverlay
            }
            let button = UIButton().construct { (it) in
                it.tag = idx
                it.isEnabled = item.isEnable
                if item.isEnable {
                    it.setImage(image.ud.withTintColor(UDColor.iconN1), for: .normal)
                    it.setBackgroundImage(backgroundImageWithColor(UDColor.N200), for: [.selected, .highlighted])
                } else {
                    it.setImage(image.ud.withTintColor(UDColor.iconDisabled), for: .normal)
                }
                it.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
                it.addTarget(self, action: #selector(didClickInsert(_:)), for: .touchUpInside)
            }
            if idx == 0 || idx == count - 1 {
                button.layer.cornerRadius = 8
                wrapperView.layer.cornerRadius = 8
                if idx == 0 && idx != count - 1 {
                    button.layer.maskedCorners = .left
                } else if idx == count - 1 && idx != 0 {
                    button.layer.maskedCorners = .right
                }
                wrapperView.layer.maskedCorners = button.layer.maskedCorners
                button.layer.masksToBounds = true
                wrapperView.layer.masksToBounds = true
            }
            wrapperView.addSubview(button)
            button.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            stackView.addArrangedSubview(wrapperView)
        }
        
        self.items = items
    }

    @objc
    func didClickInsert(_ sender: UIButton) {
        sender.isSelected = true
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) {
            sender.isSelected = false
            let item = self.items[sender.tag]
            self.delegate?.skInsertRowColumnCellDidSelect(self, identifier: item.identifier, itemIsEnable: item.isEnable, disableReason: item.disableReason)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func backgroundImageWithColor(_ color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        let context = UIGraphicsGetCurrentContext()
        color.setFill()
        context?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
