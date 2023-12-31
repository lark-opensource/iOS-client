//
//  FloatPickerIndexItem.swift
//
//  Created by bytedance on 2022/1/5.
//

import Foundation
import UIKit
import SnapKit

public final class FloatPickerIndexItem {
    public let idx: Int
    public var isSelected: Bool
    public init(idx: Int, isSelected: Bool) {
        self.idx = idx
        self.isSelected = isSelected
    }
}

public final class FloatDisplayImageView: UIImageView {
    let setImageBlock: ((UIImage?)-> Void)?
    init(setImageBlock: ((UIImage?)-> Void)?) {
        self.setImageBlock = setImageBlock
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var image: UIImage? {
        didSet {
            self.setImageBlock?(image)
        }
    }
}

open class FloatPickerBaseItemView: UIView {

    var tapCallBack: (() -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: .zero)
        self.addTapGesture()
    }
    
    private func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        self.addGestureRecognizer(tap)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didTap() {
        self.tapCallBack?()
    }

    ///刷新数据，子类重写
    open func reloadData() {
        assertionFailure("子类需要重写，用来更新数据")
    }
}

public final class FloatPickerDisplayItemView: FloatPickerBaseItemView {
    let imageMaxSize = CGSize(width: 32, height: 32)
    let item: FloatPickerIndexItem
    public private(set) lazy var imageView: UIImageView = {
        let imageV = FloatDisplayImageView { [weak self] image in
            self?.updateImageSize(image: image)
        }
        return imageV
    }()

    public init(item: FloatPickerIndexItem) {
        self.item = item
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        self.layer.cornerRadius = 6
        self.imageView.backgroundColor = .clear
        self.addSubview(imageView)
        self.backgroundColor = item.isSelected ? UIColor.ud.primaryFillHover : UIColor.clear
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(self.imageMaxSize)
        }
    }

    public override func reloadData() {
        self.backgroundColor = item.isSelected ? UIColor.ud.primaryFillHover : UIColor.clear
    }
    
    private func updateImageSize(image: UIImage?) {
        if let image = image {
            var size = image.size
            let imageRatio = size.width / size.height
            let maxRatio = self.imageMaxSize.width / self.imageMaxSize.height
            if  imageRatio >= maxRatio  {
                size.height = self.imageMaxSize.width / size.width *  size.height
                size.width = self.imageMaxSize.width
            } else {
                size.height = self.imageMaxSize.height / size.height *  size.width
                size.height = self.imageMaxSize.height
            }
            self.imageView.snp.updateConstraints { make in
                make.size.equalTo(size)
            }
        } else {
            self.imageView.snp.updateConstraints { make in
                make.size.equalTo(self.imageMaxSize)
            }
        }
    }
}
