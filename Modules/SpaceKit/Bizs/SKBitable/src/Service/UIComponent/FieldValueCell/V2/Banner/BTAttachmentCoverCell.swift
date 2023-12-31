//
//  BTAttachmentCoverCell.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/7/26.
//

import Foundation
import SKUIKit
import SKFoundation
import UniverseDesignIcon
import UniverseDesignColor
import SKResource
import UniverseDesignEmpty

protocol BTAttachmentCoverCellDelegate: AnyObject {
    func attachmentCoverCellGetCurrentCover(cell: BTAttachmentCoverCell) -> (token: String?, index: Int)?
    func attachmentCoverCell(cell: BTAttachmentCoverCell, updateCover cover: (token: String, index: Int))
}

final class BTAttachmentCoverCell: BTBaseField {
//    // 宽度超过 600 使用 emptyImageLargeHeight
    private static let emptyImageWithBoundary = 810
    private static let emptyImageLargeHeight = 140
    private static let emptyImageNormalHeight = 110

    weak var coverDelegate: BTAttachmentCoverCellDelegate?

    private lazy var noAttachmentBackgroundView = UIView().construct { it in
        it.backgroundColor = UDColor.bgBodyOverlay
    }

    private lazy var noAttachmentBackgroundLayer = CAGradientLayer().construct { it in
        it.colors = [UDColor.primaryPri50.cgColor, UDColor.bgBody.cgColor]
        it.startPoint = CGPoint(x: 0.5, y: 0)
        it.endPoint = CGPoint(x: 0.5, y: 1)
    }

    private var noAttachmentBallsView: BTAttachmentEmptyView?
//    private var noAttachmentSmallBlob: UIView?

    private lazy var noAttachmentLabel = UILabel().construct { it in
        it.font = .systemFont(ofSize: 14.0)
        it.textColor = UDColor.textCaption
        it.numberOfLines = 0
        it.lineBreakMode = .byWordWrapping
        it.textAlignment = .center
    }

    private lazy var noAttachmentContentStackView = UIStackView().construct { it in
        it.backgroundColor = .clear
        it.axis = .vertical
        it.alignment = .center
        it.spacing = 16
    }

    private lazy var bannerView = BTItemViewBannerView().construct() { it in
        it.delegate = self
    }

    override var bounds: CGRect {
        didSet {
            guard bounds != .zero else {
                return
            }

            updateEmptyBackgroundLayerLayout()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupLayout() {
        super.setupLayout()
        backgroundColor = UDColor.bgBody
        contentView.addSubview(noAttachmentBackgroundView)
        setupEmptyBackground()
        contentView.addSubview(bannerView)

        bannerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        noAttachmentBackgroundView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.bottom.equalTo(BTItemViewTiTleCell.cornerRadii)
        }
    }

    private func setupEmptyBackground() {
        noAttachmentBackgroundView.layer.addSublayer(noAttachmentBackgroundLayer)
        noAttachmentBackgroundView.addSubview(noAttachmentContentStackView)

        noAttachmentContentStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.lessThanOrEqualToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
        }

        noAttachmentContentStackView.addArrangedSubview(noAttachmentLabel)
        noAttachmentLabel.snp.makeConstraints { make in
            make.leading.trailing.lessThanOrEqualToSuperview()
        }
    }

    private func updateEmptyBackgroundLayerLayout() {
        var layerBounds = bounds
        layerBounds.size.height = bounds.size.height + CGFloat(BTItemViewTiTleCell.cornerRadii)
        noAttachmentBackgroundLayer.frame = layerBounds
    }

    func scrollViewDidScroll(offsetY: CGFloat) {
        bannerView.scrollViewDidScroll(offsetY: offsetY)
    }

    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        let sameWidth = fieldModel.width == model.width
        super.loadModel(model, layout: layout)

        let attachments = model.attachmentValue
        let showBanner = !attachments.isEmpty
        bannerView.isHidden = !showBanner
        noAttachmentBackgroundView.isHidden = showBanner
        if showBanner {
            bannerView.update(
                attachments: attachments,
                localStorageURLs: model.localStorageURLs,
                size: CGSize(width: model.width, height: model.itemViewHeight)
            )
            scrollToCurrentIndex()
        } else {
            updateNoAttachment(
                name: model.name,
                sameWidth: sameWidth
            )
        }
    }

    func revertIndexIfNeeded() {
        guard !fieldModel.attachmentValue.isEmpty else { return }
        bannerView.scrollTo(index: 0)
    }

    func update(isScrollEnabled: Bool) {
        bannerView.update(isScrollEnabled)
    }

    private func scrollToCurrentIndex() {
        guard !fieldModel.attachmentValue.isEmpty else { return }
        let index = getCurrentIndex()
        bannerView.scrollTo(index: index)
    }

    private func updateNoAttachment(name: String, sameWidth: Bool) {
        let width = fieldModel.width
        noAttachmentLabel.font = .systemFont(ofSize: width >= CGFloat(Self.emptyImageWithBoundary) ? 16.0 : 14.0)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.02
        paragraphStyle.alignment = .center
        noAttachmentLabel.attributedText = NSMutableAttributedString(
            string: BundleI18n.SKResource.Bitable_ItemView_Cover_NoAttachmentsInField_Desc(fieldName: name),
            attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle]
        )
        resetEmptyBallsViewIfNeed(sameWidth: sameWidth)
    }
    
    // 不需要监听暗黑模式的变化，因为模式变化时，itemView 会关闭
    private func resetEmptyBallsViewIfNeed(sameWidth: Bool) {
        let index = delegate?.getGlobalRecordIndex()
        let width = fieldModel.width
        guard let index = index else {
            DocsLogger.btError("[AttachmentCoverCell] index is nil")
            removeNoAttachmentBallsView()
            return
        }
        // noAttachmentBallsView 已存在，并且 width 没有发生变化，不需要重新创建 noAttachmentBallsView，更新颜色就可以了
        if noAttachmentBallsView != nil,
           sameWidth {
            updateNoAttachmentBallsViewColor(index: index)
            return
        }
        removeNoAttachmentBallsView()
        
        let isLarge = width >= CGFloat(Self.emptyImageWithBoundary) && SKDisplay.pad
        let ballsViewWidth = isLarge ? Self.emptyImageLargeHeight : Self.emptyImageNormalHeight

        let leftBlobWidth: CGFloat = isLarge ? 175 : 138
        let leftBlobLeftOffset: CGFloat = isLarge ? -75 : -60
        let leftBlodTopOffset: CGFloat = isLarge ? 70 : 55
        
        let rightBlobWidth: CGFloat = isLarge ? 249 : 197
        let rightBlobLeftOffset: CGFloat = isLarge ? 28 : 22
        let rightBlodTopOffset: CGFloat = isLarge ? 25 : 20
        
        let smallBlobWidth: CGFloat = isLarge ? 28 : 22
        let smallBlobLeftOffset: CGFloat = isLarge ? 23 : 18
        let smallBlodTopOffset: CGFloat = isLarge ? 18 : 14
        
        let leftBlobData = BTAttachmentEmptyView.BallItem(blobWidth: leftBlobWidth, topOffset: leftBlodTopOffset, leftOffset: leftBlobLeftOffset)
        let rightBlobData = BTAttachmentEmptyView.BallItem(blobWidth: rightBlobWidth, topOffset: rightBlodTopOffset, leftOffset: rightBlobLeftOffset)
        let smallBlobData = BTAttachmentEmptyView.BallItem(blobWidth: smallBlobWidth, topOffset: smallBlodTopOffset, leftOffset: smallBlobLeftOffset)

        let ballsView = BTAttachmentEmptyView(leftBlobData: leftBlobData,
                                              rightBlobData: rightBlobData,
                                              smallBlobData: smallBlobData)
        ballsView.layer.cornerRadius = isLarge ? 25.5 : 20
        ballsView.layer.masksToBounds = true

        noAttachmentContentStackView.insertArrangedSubview(ballsView, at: 0)
        ballsView.snp.makeConstraints { make in
            make.width.height.equalTo(ballsViewWidth)
        }
        noAttachmentBallsView = ballsView
        updateNoAttachmentBallsViewColor(index: index)
    }

    private func removeNoAttachmentBallsView() {
        noAttachmentBallsView?.removeNoAttachmentBallsView()

        noAttachmentBallsView?.removeFromSuperview()
        noAttachmentBallsView = nil
    }
    
    private func updateNoAttachmentBallsViewColor(index: Int) {
        guard let (top, bottom) = noAttachmentBallsView?.updateNoAttachmentBallsViewColor(index: index) else {
            return
        }
        updateEmptyBackgroundLayer(color: (top, bottom))
    }
    
    func updateEmptyBackgroundLayer(color: (top: UIColor, bottom: UIColor)) {
        noAttachmentBackgroundLayer.colors = [color.top.cgColor, color.bottom.cgColor]
    }
}

extension BTAttachmentCoverCell: BTItemViewBannerViewDelegate {
    func bannerView(_ view: BTItemViewBannerView, didClickAtIndex index: Int) {
        guard index < fieldModel.attachmentValue.count else {
            DocsLogger.btError("[Attachment cover] get attachment fail because index >= fieldModel.attachmentValue.count")
            return
        }
        delegate?.previewAttachments(fieldModel.attachmentValue, atIndex: index)
    }

    func bannerView(_ view: BTItemViewBannerView, updateCurrentIndex index: Int) {
        setCurrentIndex(index: index)
    }
}

extension BTAttachmentCoverCell {
    func getCurrentIndex() -> Int {
        guard let (currentToken, currentIndex) = coverDelegate?.attachmentCoverCellGetCurrentCover(cell: self) else {
            return 0
        }
        guard let index = fieldModel.attachmentValue.firstIndex(where: { $0.attachmentToken == currentToken }) else {
            return 0
        }
        guard index == currentIndex else {
            DocsLogger.btInfo("[AttachmentCoverCell] index is not equal currentIndex because attachments changed")
            return 0
        }
        return index
    }

    func setCurrentIndex(index: Int) {
        guard index >= 0, index < fieldModel.attachmentValue.count else {
            return
        }
        let token = fieldModel.attachmentValue[index].attachmentToken
        coverDelegate?.attachmentCoverCell(cell: self, updateCover: (token, index))
    }
}

final class BTAttachmentEmptyView: UIView {
    struct BallItem {
       let blobWidth: CGFloat// 圆的半径
       let topOffset: CGFloat // 顶部间距
       let leftOffset: CGFloat // 右边间距
    }
    
    /*
     top 和 bottom 为渐变色顶部和底部的颜色，ball 为小圆球的颜色
     */
    private static let emptyConfig: [(top: UIColor?, bottom: UIColor?, ball: UIColor?)] = [
        (UIColor(hexString: "#EAEEF6"), UIColor(hexString: "#EAEFFB"), UIColor(hexString: "#BEC8E0")),
        (UIColor(hexString: "#EFF5EF"), UIColor(hexString: "#E8EFE7"), UIColor(hexString: "#C1D7C2")),
        (UIColor(hexString: "#F5F1EF"), UIColor(hexString: "#F5EEEB"), UIColor(hexString: "#E6D2C5"))
    ]

    private static let emptyDarkConfig: [(top: UIColor?, bottom: UIColor?, ball: UIColor?)] = [
        (UIColor(hexString: "#202123"), UIColor(hexString: "#1E222A"), UIColor(hexString: "#333F5B")),
        (UIColor(hexString: "#1E211E"), UIColor(hexString: "#1D231D"), UIColor(hexString: "#3B473D")),
        (UIColor(hexString: "#232120"), UIColor(hexString: "#262220"), UIColor(hexString: "#4C423A"))
    ]

    private var noAttachmentSmallBlob: UIView?
    
    private var leftBlobData: BallItem
    private var rightBlobData: BallItem
    private var smallBlobData: BallItem
    
    private var rightBlobView: UIView?
    private var leftBlobView: UIView?
    
    init(leftBlobData: BallItem, rightBlobData: BallItem, smallBlobData: BallItem) {
        self.leftBlobData = leftBlobData
        self.rightBlobData = rightBlobData
        self.smallBlobData = smallBlobData
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        let rightBlobWidth = rightBlobData.blobWidth
        let rightBlob = UIView()
        rightBlob.layer.masksToBounds = true
        rightBlob.layer.cornerRadius = CGFloat(rightBlobWidth / 2)
        self.addSubview(rightBlob)
        rightBlob.snp.makeConstraints { make in
            make.width.height.equalTo(rightBlobWidth)
            make.leading.equalTo(rightBlobData.leftOffset)
            make.top.equalTo(rightBlobData.topOffset)
        }

        let leftBlobWidth = leftBlobData.blobWidth
        let leftBlob = UIView()
        leftBlob.layer.masksToBounds = true
        leftBlob.layer.cornerRadius = CGFloat(leftBlobWidth / 2)
        self.addSubview(leftBlob)
        leftBlob.snp.makeConstraints { make in
            make.width.height.equalTo(leftBlobWidth)
            make.leading.equalTo(leftBlobData.leftOffset)
            make.top.equalTo(leftBlobData.topOffset)
        }

        let smallBlobWidth = smallBlobData.blobWidth
        let smallBlob = UIView()
        smallBlob.layer.masksToBounds = true
        smallBlob.layer.cornerRadius = CGFloat(smallBlobWidth / 2)
        self.addSubview(smallBlob)
        smallBlob.snp.makeConstraints { make in
            make.width.height.equalTo(smallBlobWidth)
            make.leading.equalTo(smallBlobData.leftOffset)
            make.top.equalTo(smallBlobData.topOffset)
        }
        
        leftBlobView = leftBlob
        rightBlobView = rightBlob
        noAttachmentSmallBlob = smallBlob
        updateLeftAndRightBlobView()
    }
    
    func removeNoAttachmentBallsView() {
        noAttachmentSmallBlob?.removeFromSuperview()
        noAttachmentSmallBlob = nil
    }
    
    private func updateLeftAndRightBlobView() {
        let isDark = UIColor.docs.isCurrentDarkMode

        let rightBlobColor = isDark ? UIColor.white.withAlphaComponent(0.04) : UIColor.ud.staticWhite.withAlphaComponent(0.5)
        let leftBlobColor = isDark ? UIColor.white.withAlphaComponent(0.02) : UIColor.ud.staticWhite.withAlphaComponent(0.3)
        
        leftBlobView?.backgroundColor = leftBlobColor
        rightBlobView?.backgroundColor = rightBlobColor
    }
    
    func updateNoAttachmentBallsViewColor(index: Int) -> (top: UIColor, bottom: UIColor)? {
        let isDark = UIColor.docs.isCurrentDarkMode
        let config = isDark ? Self.emptyDarkConfig : Self.emptyConfig
        let colorIndex = index % 3
        guard let color = config.safe(index: colorIndex),
              let top = color.top,
              let bottom = color.bottom,
              let ball = color.ball else {
            return nil
        }
        noAttachmentSmallBlob?.backgroundColor = ball
        
        updateLeftAndRightBlobView()
        
        return (top, bottom)
    }
}

