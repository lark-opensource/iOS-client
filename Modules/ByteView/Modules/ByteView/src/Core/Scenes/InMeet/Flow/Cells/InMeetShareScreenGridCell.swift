//
//  InMeetShareScreenGridCell.swift
//  ByteView
//
//  Created by fakegourmet on 2022/4/20.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

typealias InMeetShareScreenGridCellDelegate = InMeetShareScreenGridCellActionDelegate & InMeetShareScreenGridCellLayoutDelegate

protocol InMeetShareScreenGridCellActionDelegate: AnyObject {
    func didSingleTapContent(cell: UICollectionViewCell)
}

protocol InMeetShareScreenGridCellLayoutDelegate: AnyObject {
    func didLayoutSubviews()
}

extension InMeetShareScreenGridCellLayoutDelegate {
    func didLayoutSubviews() {}
}

class InMeetShareScreenGridCell: UICollectionViewCell {

    weak var delegate: InMeetShareScreenGridCellDelegate?

    private(set) lazy var singleTapGesture: UIFullScreenGestureRecognizer = {
        let gesture = UIFullScreenGestureRecognizer(target: self, action: #selector(singleTap))
        gesture.numberOfTapsRequired = 1
        return gesture
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addGestureRecognizer(singleTapGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        delegate?.didLayoutSubviews()
    }

    @objc private func singleTap() {
        self.delegate?.didSingleTapContent(cell: self)
    }
}
