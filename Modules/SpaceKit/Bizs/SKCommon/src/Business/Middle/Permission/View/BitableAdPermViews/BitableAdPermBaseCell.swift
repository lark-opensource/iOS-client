//
//  BitableAdPermBaseCell.swift
//  SKCommon
//
//  Created by zhysan on 2022/7/18.
//

import UIKit
import RxSwift
import SKUIKit
import UniverseDesignColor
import SnapKit

class BitableAdPermBaseCell: UICollectionViewCell {
    
    static let unknownReuseID = "BitableAdPermBaseCellUnknown"
    
    private(set) var cellWidth: CGFloat = 0
    
    let disposeBag: DisposeBag = DisposeBag()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UDColor.bgFloat
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        contentView.docs.removeAllPointer()
        contentView.docs.addHover(with: UIColor.ud.fillHover, disposeBag: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateWidth(_ w: CGFloat) {
        cellWidth = w
        contentView.snp.updateConstraints { make in
            make.width.equalTo(w)
        }
    }
}
