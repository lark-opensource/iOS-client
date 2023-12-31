//
//  MinutesCommentsContentCell.swift
//  Minutes
//
//  Created by yangyao on 2021/1/29.
//

import UIKit
import YYText
import UniverseDesignColor
import Kingfisher
import UniverseDesignIcon
import MinutesFoundation
import MinutesNetwork

class MinutesCommentsContentCell: UITableViewCell {
    struct LayoutContext {
        static let font: UIFont = UIFont.systemFont(ofSize: 16)
        static let originalFont: UIFont = UIFont.systemFont(ofSize: 13)

        static let collectionInset: CGFloat = 16
        static let leftMargin: CGFloat = 20
        static let rightMargin: CGFloat = leftMargin

        static let contentLineHeight: CGFloat = 28

        static let topMargin: CGFloat = 12
        static let bottomMargin: CGFloat = 10

        static let imageSize: CGFloat = 36
        static let verticalOffset: CGFloat = 4
        static let verticalOffset2: CGFloat = 6
        static let horizontalOffset: CGFloat = 7

        static let timeHeight: CGFloat = 18
        static let nameHeight: CGFloat = 18
    }

    static func getContentWidth(wholeWidth: CGFloat) -> CGFloat {
        return wholeWidth - LayoutContext.leftMargin - LayoutContext.imageSize - LayoutContext.horizontalOffset - LayoutContext.rightMargin - LayoutContext.collectionInset * 2
    }

    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.frame.size = CGSize(width: LayoutContext.imageSize, height: LayoutContext.imageSize)
        imageView.layer.cornerRadius = LayoutContext.imageSize / 2
        imageView.layer.masksToBounds = true
        return imageView
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textDisable
        return label
    }()
        
    func createCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 4
        layout.minimumInteritemSpacing = 4
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(MinutesCommentsContentImageCell.self, forCellWithReuseIdentifier: MinutesCommentsContentImageCell.description())
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.bounces = false
        collectionView.isScrollEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isHidden = true
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleImageLongTapGesture(_:)))
        collectionView.addGestureRecognizer(longGesture)
        return collectionView
    }
    
    lazy var contentImageCollectionView: UICollectionView = {
        return createCollectionView()
    }()
    
    lazy var originalContentImageCollectionView: UICollectionView = {
        return createCollectionView()
    }()

    lazy var contentTextView: YYTextView = {
        let textView = YYTextView()
        textView.allowsCopyAttributedString = false
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.isScrollEnabled = false
        textView.isSelectable = false
        textView.isEditable = false
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleTextLongTapGesture(_:)))
        textView.addGestureRecognizer(longGesture)
        return textView
    }()

    lazy var originalContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N50
        view.layer.cornerRadius = 4.0
        view.isHidden = true
        return view
    }()

    lazy var originalContentTextView: YYTextView = {
        let textView = YYTextView()
        textView.allowsCopyAttributedString = false
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.isScrollEnabled = false
        textView.isSelectable = false
        textView.isEditable = false
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleTextLongTapGesture(_:)))
        textView.addGestureRecognizer(longGesture)
        return textView
    }()

    private lazy var sep: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    var textSize: CGSize = .zero
    var originalTextSize: CGSize = .zero
    var viewModel: MinutesCommentsContentViewModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = UIColor.ud.bgFloat
        selectionStyle = .none

        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(contentTextView)
        contentView.addSubview(contentImageCollectionView)
        contentView.addSubview(originalContainer)
        originalContainer.addSubview(originalContentTextView)
        originalContainer.addSubview(originalContentImageCollectionView)
        contentView.addSubview(timeLabel)
        contentView.addSubview(sep)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var textLongTapBlock: (() -> Void)?
    var imageLongTapBlock: (() -> Void)?
    var textTapBlock: ((_ userID: String) -> Void)?
    var linkTapBlock: ((_ url: String) -> Void)?
    var imageTapBlock: ((_ imageItems: [ContentForIMItem], _ index: Int) -> Void)?

    @objc func handleTextLongTapGesture(_ gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            textLongTapBlock?()
        }
    }
    
    @objc func handleImageLongTapGesture(_ gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            imageLongTapBlock?()
        }
    }

    @objc func dismissKeyboard() {
        UIApplication.shared.windows.first?.endEditing(true)
    }

    func setSeperateLineHidden(_ hidden: Bool) {
        sep.isHidden = hidden
    }

    func configure(_ viewModel: MinutesCommentsContentViewModel) {
        self.viewModel = viewModel
        viewModel.delegate = self
        if let url = viewModel.avatarUrl {
            avatarImageView.setAvatarImage(with: url, placeholder: UIImage.dynamicIcon(.adsMobileAvatarCircle, dimension: 48, color: UIColor.ud.N300))
        } else {
            avatarImageView.image = UIImage.dynamicIcon(.adsMobileAvatarCircle, dimension: 48, color: UIColor.ud.N300)
        }
        nameLabel.text = viewModel.name
        timeLabel.text = viewModel.timeStr
        contentTextView.attributedText = viewModel.getAttributedText()
        textSize = viewModel.getTextLayout()?.textBoundingSize ?? .zero
        if viewModel.isInTranslationMode {
            originalContentTextView.attributedText = viewModel.getOriginalAttributedText()
            originalTextSize = viewModel.getOriginalTextLayout()?.textBoundingSize ?? .zero
        }
        originalContainer.isHidden = !viewModel.isInTranslationMode
        contentImageCollectionView.isHidden = viewModel.imageContents.isEmpty
        originalContentImageCollectionView.isHidden = originalContainer.isHidden || viewModel.imageContents.isEmpty
        if !contentImageCollectionView.isHidden {
            contentImageCollectionView.reloadData()
        }
        if !originalContentImageCollectionView.isHidden {
            originalContentImageCollectionView.reloadData()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        let imageSize: CGFloat = LayoutContext.imageSize
        avatarImageView.frame = CGRect(x: LayoutContext.leftMargin,
                                       y: LayoutContext.topMargin,
                                       width: imageSize,
                                       height: imageSize)

        nameLabel.frame = CGRect(x: avatarImageView.frame.maxX + LayoutContext.horizontalOffset,
                                 y: avatarImageView.frame.minY,
                                 width: bounds.width - avatarImageView.frame.maxX - LayoutContext.horizontalOffset - LayoutContext.rightMargin,
                                 height: LayoutContext.nameHeight)

        let width = bounds.width - nameLabel.frame.minX - LayoutContext.rightMargin
        contentTextView.frame = CGRect(x: nameLabel.frame.minX,
                                       y: nameLabel.frame.maxY + LayoutContext.verticalOffset,
                                       width: width,
                                       height: textSize.height)
        
        let imageCollectionViewHeight = viewModel?.imageContentHeight(width) ?? 0
        let imageOffset = imageCollectionViewHeight > 0 ?  (imageCollectionViewHeight + LayoutContext.verticalOffset) : 0
        
        if (!contentImageCollectionView.isHidden) {
            contentImageCollectionView.frame = CGRect(x: contentTextView.frame.minX,
                                                      y: contentTextView.frame.maxY + LayoutContext.verticalOffset,
                                                      width: width,
                                                      height: imageCollectionViewHeight)
        }
        
        layoutOriginContainer(width, contentTextView.frame.maxY + imageOffset)

        if viewModel?.isInTranslationMode == true {
            timeLabel.frame = CGRect(x: nameLabel.frame.minX,
                                     y: originalContainer.frame.maxY + LayoutContext.verticalOffset * 2,
                                     width: width,
                                     height: LayoutContext.timeHeight)
        } else {
            timeLabel.frame = CGRect(x: nameLabel.frame.minX,
                                     y: contentTextView.frame.maxY + imageCollectionViewHeight + LayoutContext.verticalOffset * 2,
                                     width: width,
                                     height: LayoutContext.timeHeight)
        }

        sep.frame = CGRect(x: timeLabel.frame.minX,
                           y: timeLabel.frame.maxY + LayoutContext.bottomMargin - 0.5,
                           width: bounds.width - timeLabel.frame.minX,
                           height: 0.5)
    }
    
    func layoutOriginContainer(_ width: CGFloat, _ yOffset: CGFloat) {
        if viewModel?.isInTranslationMode == false {
            return
        }
        
        originalContentTextView.frame = CGRect(x: 8,
                                               y: 6,
                                               width: width - 8 * 2,
                                               height: originalTextSize.height)
        
        let hasImage = !originalContentImageCollectionView.isHidden
        var originalContainerHeight = originalTextSize.height + LayoutContext.verticalOffset2 * 2
        if (hasImage) {
            let originImageCollectionViewHeight = viewModel?.imageContentHeight(width - 8 * 2) ?? 0
            let originImageOffset = originImageCollectionViewHeight > 0 ?  (originImageCollectionViewHeight + LayoutContext.verticalOffset) : 0
            originalContainerHeight += originImageOffset
            originalContentImageCollectionView.frame = CGRect(x: originalContentTextView.frame.minX,
                                                              y: originalContentTextView.frame.maxY + LayoutContext.verticalOffset2,
                                                              width: originalContentTextView.frame.width,
                                                              height: originImageCollectionViewHeight)
        }
        originalContainer.frame = CGRect(x: contentTextView.frame.minX,
                                         y: yOffset,
                                         width: width,
                                         height: originalContainerHeight)
    }
}

extension MinutesCommentsContentCell: MinutesCommentsContentViewModelDelegate {
    func didSelectUser(userId: String) {
        self.textTapBlock?(userId)
    }
    func didSelectUrl(url: String) {
        self.linkTapBlock?(url)
    }
}

//image collection
extension MinutesCommentsContentCell: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.imageContents.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MinutesCommentsContentImageCell.description(), for: indexPath) as? MinutesCommentsContentImageCell else {
            return UICollectionViewCell()
        }
        if indexPath.row < viewModel?.imageContents.count ?? 0 {
            guard let contentItem = viewModel?.imageContents[indexPath.row] else { return cell }
            cell.viewModel = contentItem
            cell.update()
        }
        return cell
    }
}

extension MinutesCommentsContentCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = viewModel?.imageItemSize(collectionView.bounds.width) ?? 0
        return CGSize(width:size, height:size)
    }
}

extension MinutesCommentsContentCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let imageContent = viewModel?.imageContents else { return }
        self.imageTapBlock?(imageContent, indexPath.row)
    }

}
