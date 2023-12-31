//
//  File.swift
//  Calendar
//
//  Created by sunxiaolei on 2019/10/30.
//

import UIKit
import Foundation
import CalendarFoundation
import LarkUIKit
import UniverseDesignButton

final class AttachmentCollectionViewFlowLayout: UICollectionViewFlowLayout {

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)

        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0
        attributes?.forEach { layoutAttribute in
            if layoutAttribute.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }

            layoutAttribute.frame.origin.x = leftMargin

            leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
            maxY = max(layoutAttribute.frame.maxY, maxY)
        }

        return attributes
    }
}

protocol AttachmentListDelegate: AnyObject {
    func attachmentList(_ attachmentList: AttachmentList, didSelectAttachAt index: Int)
}

final class AttachmentList: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
    weak var delegate: AttachmentListDelegate?

    private var maxVisibleCount = 4

    private var data: [AttachmentUIData] = []

    private lazy var visibleData: [AttachmentUIData] = []

    var source: Rust.CalendarEventSource?

    private lazy var sizeView: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var collectionView: UICollectionView = {
        let defaultLayout = AttachmentCollectionViewFlowLayout()
        defaultLayout.scrollDirection = .vertical
        defaultLayout.itemSize = CGSize(width: Display.sceneSize(for: self).width - 85, height: AttachmentViewStyle.height)
        defaultLayout.minimumLineSpacing = AttachmentViewStyle.itemSpacing // 每个相邻layout的左右间隔
        let view = UICollectionView(frame: self.bounds, collectionViewLayout: defaultLayout)
        view.backgroundColor = .clear
        view.dataSource = self
        view.delegate = self
        view.register(AttachmentCell.self, forCellWithReuseIdentifier: "AttachmentCell")
        view.bounces = false
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        return view
    }()

    private lazy var viewMore: UIView = {
        let view = UILabel()
        view.text = I18n.Calendar_G_ViewMore_BlueClick
        view.textColor = UIColor.ud.textLinkNormal
        view.font = UIFont.ud.body2(.fixed)
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewMoreClicked))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap)
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.addSubview(collectionView)
        self.addSubview(sizeView)
        self.addSubview(viewMore)
        sizeView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(20)
        }
        collectionView.snp.makeConstraints({make in
            make.top.equalTo(sizeView.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        })

        viewMore.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(AttachmentViewStyle.itemSpacing)
            make.right.lessThanOrEqualToSuperview()
            make.left.bottom.equalToSuperview()
            make.height.equalTo(22)
        }
    }

    func onWidthChange(width: CGFloat) {
        let defaultLayout = AttachmentCollectionViewFlowLayout()
        defaultLayout.scrollDirection = .vertical
        defaultLayout.itemSize = CGSize(width: width - 85, height: AttachmentViewStyle.height)
        defaultLayout.minimumInteritemSpacing = AttachmentViewStyle.itemSpacing // 每个相邻layout的左右间隔
        collectionView.collectionViewLayout = defaultLayout
        collectionView.layoutSubviews()
    }

    @objc
    func viewMoreClicked() {
        self.maxVisibleCount = data.count
        self.visibleData = data
        self.viewMore.isHidden = true
        reloadCollectionView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateData(data: [AttachmentUIData], source: Rust.CalendarEventSource?) {
        self.data = data
        self.visibleData = Array(data.prefix(maxVisibleCount))
        self.source = source
        var sum: UInt64 = 0
        data.forEach { sum += $0.size }
        let sizeFormat = CalendarEventAttachmentEntity.sizeString(for: sum)
        if let source = source, source == .google {
            sizeView.text = BundleI18n.Calendar.Calendar_Plural_Attachment(number: data.count)
        } else {
            sizeView.text = BundleI18n.Calendar.Calendar_Plural_Attachment(number: data.count) + "(\(sizeFormat))"
        }
        viewMore.isHidden = data.count <= maxVisibleCount
        reloadCollectionView()
    }

    private func reloadCollectionView() {
        collectionView.reloadData()
        invalidateIntrinsicContentSize()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visibleData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AttachmentCell", for: indexPath) as? AttachmentCell else {
            return UICollectionViewCell()
        }
        if let cellData = visibleData[safeIndex: indexPath.row] {
            cell.updateContent(cellData: cellData, source: source)
        }
        return cell
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        let sizeLabelHeight: CGFloat = 32
        let listItemHeight: CGFloat = AttachmentViewStyle.height
        let itemCount = visibleData.count
        let viewMoreButtonHeight: CGFloat = viewMore.isHidden ? 0 : 22
        let spacingHeight: CGFloat = itemCount > 1 ? AttachmentViewStyle.itemSpacing * CGFloat(itemCount - 1) : 0
        size.height = sizeLabelHeight + CGFloat(itemCount) * listItemHeight + spacingHeight + viewMoreButtonHeight
        return size
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.attachmentList(self, didSelectAttachAt: indexPath.row)
    }
}

final class AttachmentCell: UICollectionViewCell {
    var view: AttachmentView?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    func updateContent(cellData: AttachmentUIData, source: Rust.CalendarEventSource?) {
        if let view = view {
            view.updateData(uiData: cellData, source: source)
        } else {
            let attachView = AttachmentView(cellData, source: source)
            self.contentView.addSubview(attachView)
            attachView.snp.makeConstraints({make in
                make.top.left.bottom.equalToSuperview()
                make.right.equalToSuperview().inset(12)
            })
            view = attachView
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
