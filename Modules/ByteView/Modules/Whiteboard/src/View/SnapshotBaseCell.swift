//
//  SnapshotBaseCell.swift
//  Whiteboard
//
//  Created by helijian on 2022/12/6.
//

import Foundation
import ByteViewUI

class SnapshotBaseCell: UICollectionViewCell {

    var loadingView: LoadingView = {
        let view = LoadingView(style: .grey)
        view.isHidden = true
        return view
    }()

    // snapshot图像
    var snapshotImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 6
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleToFill
        return imageView
    }()

    // 图像index索引
    var indexLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .center
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 1
        return label
    }()

    // 边框（选中和非选中颜色及宽度不同）
    var selectedView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
        view.layer.borderWidth = 2
        view.layer.ud.setBorderColor(UIColor.ud.primaryFillHover)
        view.isHidden = false
        return view
    }()

    /// 删除白板页
    lazy var deleteButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(deletePage), for: .touchUpInside)
        return button
    }()

    var item: WhiteboardSnapshotItem?
    weak var delegate: DeleteWhiteboardPageDeledate?

    // 需要根据cell的选择状态确定边框的形态
    func configCell(with item: WhiteboardSnapshotItem) {
        // should override and call this parent's method
        self.item = item
        if item.state == .normal {
            selectedView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
            selectedView.layer.borderWidth = 1
        } else {
            selectedView.layer.ud.setBorderColor(UIColor.ud.primaryFillHover)
            selectedView.layer.borderWidth = 2
        }
        if item.image != nil {
            loadingView.stop()
            loadingView.isHidden = true
        } else {
            loadingView.isHidden = false
            loadingView.play()
        }
    }

    @objc func deletePage() {
        delegate?.deletePage(item: self.item)
    }
}
