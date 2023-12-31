//
//  CommentInputImageGalleryView.swift
//  Todo
//
//  Created by 张威 on 2021/3/6.
//

import CTFoundation
import LarkActivityIndicatorView
import UniverseDesignIcon

/// Comment - Input - ImageGalleryView

class CommentInputImageGalleryView: UIView {

    enum ImageItem {
        /// rust 数据
        case rustMeta(Rust.ImageSet)
        /// 上传中
        case uploading(data: UIImage)
        /// 已上传
        case uploaded(data: UIImage)
    }

    var items = [ImageItem]() {
        didSet { reloadData() }
    }

    var onItemDelete: ((_ index: Int) -> Void)?
    var onItemTap: ((_ index: Int) -> Void)?

    private var itemViews = [KeyboardImageGalleryItemView]()
    private var containerView = UIScrollView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.lessThanOrEqualTo(self).offset(16)
            make.right.greaterThanOrEqualTo(self).offset(-16)
            make.height.equalTo(80)
        }
        containerView.contentInsetAdjustmentBehavior = .never
        containerView.showsVerticalScrollIndicator = false
        containerView.showsHorizontalScrollIndicator = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func reloadData() {
        while itemViews.count > items.count {
            let ret = itemViews.removeLast()
            ret.removeFromSuperview()
        }
        while itemViews.count < items.count {
            itemViews.append(.init())
        }
        var offsetX: CGFloat = 0
        for i in 0..<items.count {
            if i > 0 { offsetX += 4 }
            let (itemView, item) = (itemViews[i], items[i])
            itemView.frame = CGRect(x: offsetX, y: 0, width: 80, height: 80)
            itemView.item = item
            itemView.onDelete = { [weak self] in self?.onItemDelete?(i) }
            itemView.onTap = { [weak self] in self?.onItemTap?(i) }
            offsetX += 80
            if itemView.superview != containerView {
                containerView.addSubview(itemView)
            }
        }
        containerView.contentSize = CGSize(width: offsetX, height: 80)
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.noIntrinsicMetric, height: 80)
    }

}

private class KeyboardImageGalleryItemView: UIView {

    var item: CommentInputImageGalleryView.ImageItem? {
        didSet {
            guard let item = item else { return }
            var showIndicator = false
            switch item {
            case .rustMeta(let imageSet):
                // TODO: 此处需要优化
                let key = imageSet.downloadKey(forPriorityType: .thumbnail)
                contentImageView.bt.setLarkImage(with: .default(key: key))
            case .uploaded(let data):
                contentImageView.image = data
            case .uploading(let data):
                contentImageView.image = data
                showIndicator = true
            }
            if showIndicator {
                loadingView.isHidden = false
                loadingView.startAnimating()
            } else {
                loadingView.isHidden = true
                loadingView.stopAnimating()
            }
        }
    }

    var onDelete: (() -> Void)?
    var onTap: (() -> Void)?

    private let contentImageView = UIImageView()
    private let deleteView = UIImageView()
    private let loadingView = ActivityIndicatorView(color: UIColor.ud.textLinkLoading)

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentImageView.contentMode = .scaleAspectFill
        contentImageView.layer.cornerRadius = 4
        contentImageView.clipsToBounds = true
        contentImageView.layer.borderWidth = 0.5
        contentImageView.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        deleteView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        addSubview(contentImageView)
        contentImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        deleteView.image = UDIcon.closeFilled
        deleteView.isUserInteractionEnabled = true
        deleteView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDelete)))
        addSubview(deleteView)
        deleteView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.top.equalToSuperview().offset(4)
            make.right.equalToSuperview().offset(-4)
        }

        loadingView.isUserInteractionEnabled = false
        addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(20)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func handleTap() {
        onTap?()
    }

    @objc
    private func handleDelete() {
        onDelete?()
    }

}
