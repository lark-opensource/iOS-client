//
//  BTItemViewBannerView.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/7/24.
//

import Foundation
import SKFoundation
import Kingfisher
import SKUIKit

protocol BTItemViewBannerViewDelegate: AnyObject {
    func bannerView(_ view: BTItemViewBannerView, didClickAtIndex index: Int)
    func bannerView(_ view: BTItemViewBannerView, updateCurrentIndex index: Int)
}

final class BTItemViewBannerView: UIView {
    private static var indicatorHeight = 20

    weak var delegate: BTItemViewBannerViewDelegate?

    private var attachments: [BTAttachmentModel] = []
    private var localStorageURLs: [String: URL] = [:]
    private var collectionView: UICollectionView? = nil

    private lazy var indicatorBlurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .regular)
        let view = UIVisualEffectView(effect: blurEffect)
        view.contentView.backgroundColor = .clear
        view.layer.masksToBounds = true
        view.layer.cornerRadius = CGFloat(Self.indicatorHeight / 2)
        return view
    }()

    private lazy var indicator = BTInsetLabel().construct { it in
        it.font = .systemFont(ofSize: 10, weight: .medium)
        it.textColor = UIColor.ud.textTitle
        it.textAlignment = .center
    }

    private var currentIndex = 0

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(indicatorBlurView)
        indicatorBlurView.contentView.addSubview(indicator)

        indicatorBlurView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-8)
            make.height.equalTo(Self.indicatorHeight)
        }
        indicator.snp.makeConstraints { make in
            make.top.equalTo(2)
            make.leading.equalTo(6)
            make.bottom.equalTo(-2)
            make.trailing.equalTo(-6)
        }
    }

    private func updateCollectionView(size: CGSize) {
        collectionView?.removeFromSuperview()
        collectionView = nil

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: size.width, height: Self.bannerHeight(itemViewSize: size))
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView?.isPagingEnabled = true
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.layer.masksToBounds = false
        collectionView?.alwaysBounceHorizontal = true
        collectionView?.register(BTItemViewBannerViewCell.self, forCellWithReuseIdentifier: BTItemViewBannerViewCell.reuseIdentifier)
        guard let collectionView = collectionView else { return }
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        bringSubviewToFront(indicatorBlurView)

        currentIndex = 0
    }

    func update(attachments: [BTAttachmentModel], localStorageURLs: [String: URL], size: CGSize) {
        self.attachments = attachments
        self.localStorageURLs = localStorageURLs
        updateCollectionView(size: size)
        collectionView?.reloadData()
        indicator.text = "\(1)/\(attachments.count)"
        indicatorBlurView.isHidden = attachments.count <= 1
    }

    func scrollViewDidScroll(offsetY: CGFloat) {
        guard !attachments.isEmpty else { return }
        guard offsetY < 0 else { return }
        guard let cell = collectionView?.visibleCells.first as? BTItemViewBannerViewCell else { return }
        let height = bounds.size.height
        guard height > 0 else { return }
        let scale = 1 + abs(offsetY) / height

        var bannerTransform: CGAffineTransform = CGAffineTransform.identity
        bannerTransform = bannerTransform.translatedBy(x: 0, y: offsetY/2)
        bannerTransform = bannerTransform.scaledBy(x: scale, y: scale)
        cell.bannnerContentView.transform = bannerTransform
    }

    func update(_ isScrollEnabled: Bool) {
        collectionView?.isScrollEnabled = isScrollEnabled
    }

    func scrollTo(index: Int) {
        guard index >= 0, index < self.attachments.count else {
            return
        }
        guard currentIndex != index else {
            return
        }
        self.currentIndex = index
        DispatchQueue.main.async {
            self.collectionView?.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: false)
            self.indicator.text = "\(index + 1)/\(self.attachments.count)"
        }
    }

    static func bannerHeight(itemViewSize: CGSize) -> CGFloat {
        let isLandscape = LKDeviceOrientation.isLandscape()
        let itemViewWidth = itemViewSize.width
        let itemViewHeight = itemViewSize.height
        if SKDisplay.phone {
            if isLandscape {
                return itemViewHeight * 0.86
            }
            return itemViewWidth
        }
        let height = itemViewHeight * 0.44
        if height >= itemViewWidth {
            return itemViewWidth
        }
        return height
    }
}

extension BTItemViewBannerView: UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateIndicator()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        updateIndicator()
    }

    private func updateIndicator() {
        guard let collectionView = collectionView else {
            return
        }
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        for indexPath in visibleIndexPaths {
            guard let attributes = collectionView.layoutAttributesForItem(at: indexPath) else {
                continue
            }
            let cellFrame = attributes.frame
            let collectionViewBounds = collectionView.bounds
            guard collectionViewBounds.contains(cellFrame.center) else {
                continue
            }
            indicator.text = "\(indexPath.row + 1)/\(attachments.count)"
            currentIndex = indexPath.row
            delegate?.bannerView(self, updateCurrentIndex: indexPath.row)
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attachments.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BTItemViewBannerViewCell.reuseIdentifier,
                                                            for: indexPath)
        if let cell = cell as? BTItemViewBannerViewCell {
            guard indexPath.row < attachments.count else {
                DocsLogger.btError("[BTItemViewBannerView] indexPath.row exceed attachments")
                return cell
            }
            let attachment = attachments[indexPath.row]
            cell.load(data: attachment, localStorageURL: localStorageURLs[attachment.attachmentToken])
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.bannerView(self, didClickAtIndex: indexPath.row)
    }
}

