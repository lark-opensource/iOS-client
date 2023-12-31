//
//  BTCardViewCell.swift
//  SKBitable
//
//  Created by zoujie on 2023/10/30.
//  

import RxSwift
import SnapKit
import Kingfisher
import SKFoundation
import UniverseDesignIcon
import UniverseDesignColor
import SkeletonView

protocol BTCardViewCellDelegate: AnyObject {
    func didClickItem(index: Int)
    func didClickCover(index: Int)
    func didClickComment(params: [String: Any])
}

final class BTCardViewCell: UICollectionViewCell {
    
    struct LayoutConfig {
        var isGroupFirst: Bool // 是否是分组的第一个
        var isGroupLast: Bool // 是否是分组的最后的一个
        var hasGroup: Bool // 是否有分组
    }
    
    fileprivate struct Profile {
        var drawCost: TimeInterval = 0
        var layoutCost: TimeInterval = 0
        var setDataCost: TimeInterval = 0
    }
    
    var cardSetting: CardSettingModel?
    var context: BTNativeRenderContext?
    
    weak var delegate: BTCardViewCellDelegate?
    private let thumbnailProvider = BTAttachmentThumbnailProvider()
        
    private var profile: Profile = Profile()
    private var isShowLoading = false
    
    var columnCount: Int {
        cardSetting?.columnCount ?? 1
    }
    
    private var model: CardRecordModel?
    private var index: Int?
    
    private var hasSubTitle: Bool {
        cardSetting?.showSubTitle ?? false
    }
    
    private var hasCover: Bool {
        cardSetting?.showCover ?? false
    }
    
    private var fieldLayoutMode: BTFieldBaseCell.LayoutMode {
        if cardSetting?.columnCount == 1 {
            return .leftRight(hasCover: hasCover)
        }
        
        return .topBottom
    }
    
    /// 背景层，避免卡片连在一起的场景下，点击卡片缩放时会漏出下面的背景
    private lazy var containerBgView = UIView()
    
    private lazy var containerView = BTPressAnimateView().construct { it in
        it.backgroundColor = UDColor.bgBody
    }
    
    private lazy var coverView = BTRecordCoverView().construct { it in
        it.layer.cornerRadius = 6
    }
            
    private(set) lazy var fieldList: BTNativeRenderFieldListView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionHeadersPinToVisibleBounds = true
        let view = BTNativeRenderFieldListView(frame: .zero, collectionViewLayout: layout)
        view.collectionViewLayout = layout
        view.register(BTFieldBaseCell.self, forCellWithReuseIdentifier: BTFieldBaseCell.reuseIdentifier)
        view.register(BTCardOptionFieldCell.self, forCellWithReuseIdentifier: BTCardOptionFieldCell.reuseIdentifier)
        view.register(BTCardChatterFieldCell.self, forCellWithReuseIdentifier: BTCardChatterFieldCell.reuseIdentifier)
        view.register(BTCardTitleView.self, forCellWithReuseIdentifier: BTCardTitleView.reuseIdentifier)
        view.register(BTCardDateFieldCell.self, forCellWithReuseIdentifier: BTCardDateFieldCell.reuseIdentifier)
        view.register(BTCardSimpleTextFieldCell.self, forCellWithReuseIdentifier: BTCardSimpleTextFieldCell.reuseIdentifier)
        view.register(BTCardRichTextFieldCell.self, forCellWithReuseIdentifier: BTCardRichTextFieldCell.reuseIdentifier)
        view.register(BTCardButtonFieldCell.self, forCellWithReuseIdentifier: BTCardButtonFieldCell.reuseIdentifier)
        view.register(BTCardStageFieldCell.self, forCellWithReuseIdentifier: BTCardStageFieldCell.reuseIdentifier)
        view.register(BTCardLinkFieldCell.self, forCellWithReuseIdentifier: BTCardLinkFieldCell.reuseIdentifier)
        view.register(BTCardCheckBoxFieldCell.self, forCellWithReuseIdentifier: BTCardCheckBoxFieldCell.reuseIdentifier)
        view.register(BTCardAttachmentFieldCell.self, forCellWithReuseIdentifier: BTCardAttachmentFieldCell.reuseIdentifier)
        view.register(BTCardProgressFieldCell.self, forCellWithReuseIdentifier: BTCardProgressFieldCell.reuseIdentifier)
        view.register(BTCardRatingFieldCell.self, forCellWithReuseIdentifier: BTCardRatingFieldCell.reuseIdentifier)
        view.register(BTCardNotSupportField.self, forCellWithReuseIdentifier: BTCardNotSupportField.reuseIdentifier)
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = .clear
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        coverView.resetForReuse()
    }
    
    override func layoutSubviews() {
        let start = CACurrentMediaTime() * 1000
        super.layoutSubviews()
        let cost = (CACurrentMediaTime() * 1000 - start)
        profile.layoutCost = cost
    }
    
    override func draw(_ rect: CGRect) {
        let start = CACurrentMediaTime() * 1000
        super.draw(rect)
        let cost = (CACurrentMediaTime() * 1000 - start)
        profile.drawCost = cost
    }
    
    func setUpUI() {
        contentView.addSubview(containerBgView)
        contentView.addSubview(containerView)
        
        containerBgView.snp.makeConstraints { make in
            make.edges.equalTo(containerView)
        }
        
        containerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(4)
        }
        
        containerView.addSubview(coverView)
        containerView.addSubview(fieldList)
        
        coverView.snp.makeConstraints { make in
            make.width.height.equalTo(0)
            make.left.equalToSuperview().offset(14)
            make.top.equalToSuperview().offset(16)
        }
        
        fieldList.snp.makeConstraints { make in
            make.left.equalTo(coverView.snp.right).offset(0)
            make.right.equalToSuperview().inset(14)
            make.top.bottom.equalToSuperview().inset(16)
        }
        
        containerView.clickCallback = { [weak self] in
            guard let index = self?.index else { return }
            self?.delegate?.didClickItem(index: index)
        }
        
        coverView.clickCallback = {
            [weak self] in
            guard let index = self?.index  else { return }
            self?.delegate?.didClickCover(index: index)
        }
        
        contentView.gestureRecognizers?.first(where: { $0 is UILongPressGestureRecognizer })?.delegate = self
    }
    
    private func updateCorners(_ config: LayoutConfig) {
        let notFirstAndLast = !config.isGroupFirst && !config.isGroupLast
        let isFirstAndLast = config.isGroupFirst && config.isGroupLast
        containerView.layer.cornerRadius = 12
        
        if config.hasGroup {
            containerView.layer.cornerRadius = 12
            if hasCover {
                // 有分组且有封面
                if isFirstAndLast {
                    // 独立卡片，显示圆角
                    containerView.layer.maskedCorners = .all
                } else if notFirstAndLast {
                    // 分组中间的卡片不显示圆角
                    containerView.layer.cornerRadius = 0
                } else if config.isGroupFirst {
                    // 分组第一张卡片，显示上圆角
                    containerView.layer.maskedCorners = .top
                } else if config.isGroupLast {
                    // 分组最后一张卡片，显示下圆角
                    containerView.layer.maskedCorners = .bottom
                }
            } else {
                // 有分组无封面
                // 独立卡片，显示圆角
                containerView.layer.maskedCorners = .all
            }
        } else {
            if hasCover {
                // 无分组有封面
                containerView.layer.cornerRadius = 0
            } else {
                // 无分组无封面
                containerView.layer.cornerRadius = 12
                // 独立卡片，显示圆角
                containerView.layer.maskedCorners = .all
            }
        }
        
        containerBgView.layer.maskedCorners = containerView.layer.maskedCorners
        containerBgView.layer.cornerRadius = containerView.layer.cornerRadius
    }
    
    func updateUI(_ config: LayoutConfig) {
        updateCorners(config)
        let hasGroup = config.hasGroup
        
        let coverSize = cardSetting?.columnCount == 1 ? CardViewConstant.LayoutConfig.coverViewSingleCloSize :
                                                        CardViewConstant.LayoutConfig.coverViewSize
        coverView.snp.remakeConstraints { make in
            make.width.height.equalTo(hasCover ? coverSize : .zero)
            make.left.equalToSuperview().offset(14)
            make.top.equalToSuperview().offset(16)
        }
        
        fieldList.snp.remakeConstraints { make in
            make.left.equalTo(coverView.snp.right).offset(hasCover ? 10 : 0)
            make.right.equalToSuperview().inset(14)
            make.top.bottom.equalToSuperview().inset(16)
        }
        
        var topInset = (hasCover || config.isGroupFirst)  ? 0.0 : CardViewConstant.LayoutConfig.cardCellInset / 2
        var bottomInset = (hasCover || config.isGroupLast) ? 0.0 : CardViewConstant.LayoutConfig.cardCellInset / 2
        let leftAndRightInset = (!hasGroup && hasCover) ? 0.0 : CardViewConstant.LayoutConfig.cardCellInset
        if hasGroup {
            if config.isGroupFirst {
                topInset += CardViewConstant.LayoutConfig.groupHeightAdjustHeight
            }
            if config.isGroupLast {
                bottomInset += CardViewConstant.LayoutConfig.groupHeightAdjustHeight
            }
        }
        
        if containerView.layer.maskedCorners == .all && containerView.layer.cornerRadius != 0 {
            // 单个卡片展现，背景色跟列表背景色保持一致
            containerBgView.backgroundColor = .clear
        } else {
            // 卡片连在一起，背景色跟卡片保持一致
            containerBgView.backgroundColor = UDColor.bgBody
        }
        
        containerView.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(topInset)
            make.bottom.equalToSuperview().inset(bottomInset)
            make.left.right.equalToSuperview().inset(leftAndRightInset)
        }
        
        if let highlightColor = model?.highlightColor, !highlightColor.isEmpty {
            containerView.backgroundColor = UIColor.docs.rgb(highlightColor)
        } else {
            containerView.backgroundColor = UDColor.bgBody
        }
    }

    func updateModel(index: Int,
                     config: LayoutConfig,
                     model: CardRecordModel?,
                     cardSetting: CardSettingModel?) {
        let start = CACurrentMediaTime() * 1000
        self.model = model
        self.index = index
        self.cardSetting = cardSetting
        updateUI(config)
        if model == nil, hasCover {
            showLoading()
        } else {
            hideLoading()
            coverView.load(model: model?.cardCover,
                           thumbnailProvider: thumbnailProvider)
        }
        self.layoutIfNeeded()
        DispatchQueue.main.async {
            self.fieldList.layoutIfNeeded()
            DispatchQueue.main.async {
                self.fieldList.reloadData()
            }
        }
        profile.setDataCost = (CACurrentMediaTime() * 1000 - start)
    }
    
    private func showLoading() { 
        guard !isShowLoading else {
            return
        }
        
        isShowLoading = true
        // 封面显示loading
        let skeletonGradient = SkeletonGradient(baseColor: UIColor.ud.N900.withAlphaComponent(0.05), secondaryColor: UIColor.ud.N900.withAlphaComponent(0.1))
        coverView.isSkeletonable = true
        coverView.showAnimatedGradientSkeleton(usingGradient: skeletonGradient)
        coverView.startSkeletonAnimation()
    }
    
    private func hideLoading() {
        guard isShowLoading else {
            return
        }
        
        self.coverView.hideSkeleton()
    }
    
    private func getFieldHeight(indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0, indexPath.row == 0 {
            // title的高度
            // 文本字段标题最多两行 48
            // 其它字读啊标题仅一行 24
            var height = CardViewConstant.LayoutConfig.textTitleSingleLineHeight
            if let titleModel = model?.title {
                let isSingleLine = BTCardTitleTextCalculaor.isSingleLine(titleModel,
                                                                         font: CardViewConstant.LayoutConfig.textTtileFont,
                                                                         containerWidth: getTitleWidth())
                height = isSingleLine ? CardViewConstant.LayoutConfig.textTitleSingleLineHeight : CardViewConstant.LayoutConfig.textTitleMutilLineHeight
            }
            return height
        }
        
        if indexPath.section == 0, indexPath.row == 1, hasSubTitle {
            // 副标题只有一行
            return CardViewConstant.LayoutConfig.textTitleSingleLineHeight
        }
        
        if columnCount == 1 {
            // 左右排布
            return CardViewConstant.LayoutConfig.fieldHeightForRL
        } else {
            // 上下排布
            return CardViewConstant.LayoutConfig.fieldHeightForTB
        }
    }
    
    private func getTitleWidth() -> CGFloat {
        var commentWidth: CGFloat = 0
        if let commentText = model?.comment?.text {
            commentWidth = BTCardTitleTextCalculaor.caculateTextWidth(text: commentText,
                                                                      font: .systemFont(ofSize: BTCardCommentConst.commentFontSize),
                                                                      inset: BTCardCommentConst.textInset) + BTCardCommentConst.leftInset
        }
        return fieldList.bounds.width - commentWidth
    }

    private func getFieldListWidth() -> CGFloat {
        return fieldList.bounds.width
    }
    
    private func getFieldWidth(indexPath: IndexPath) -> CGFloat {
        let index = indexPath.row
        let fieldWidth = floor((getFieldListWidth() - (CGFloat(columnCount) - 1) * CardViewConstant.LayoutConfig.fieldInteritemSpacing) / CGFloat(columnCount))
        if index == getFieldItemsCount() - 1 {
            // 最后一个字段，需要填满剩下的空间
            let mod = (index + 1) % columnCount
            if mod != 0 {
                return getFieldListWidth() - (fieldWidth + CardViewConstant.LayoutConfig.fieldInteritemSpacing) * CGFloat(mod - 1)
            }
        }
        
        return fieldWidth
    }
    
    private func getFieldItemsCount() -> Int {
        return model?.cardRecordCells.count ?? cardSetting?.fieldCount ?? 0
    }
    
    private func getFieldItemModel(index: Int) -> BTCardFieldCellModel? {
        guard index < (model?.cardRecordCells.count ?? 0) else {
            return nil
        }
        
        return model?.cardRecordCells[index]
    }
    
    private func getLineSpacing() -> CGFloat {
        return cardSetting?.columnCount == 1 ? CardViewConstant.LayoutConfig.fieldSingleCloLineSpacing :
                                               CardViewConstant.LayoutConfig.fieldLineSpacing
    }
    
    private func getSectionSpacing() -> CGFloat {
        return cardSetting?.columnCount == 1 ?
        CardViewConstant.LayoutConfig.titleAndFieldSectionSpacingForSingleLine :
        CardViewConstant.LayoutConfig.titleAndFieldSectionSpacing
    }
}

extension BTCardViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0, indexPath.row == 0 {
            // 标题
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BTCardTitleView.reuseIdentifier, for: indexPath)
            if let cell = cell as? BTCardTitleView {
                cell.delegate = self
                cell.updateModel(model?.title, comment: model?.comment, containerWidth: getTitleWidth())
            }
            return cell
        } else if indexPath.section == 0, hasSubTitle, indexPath.row == 1 {
            // 副标题
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BTCardTitleView.reuseIdentifier, for: indexPath)
            if let cell = cell as? BTCardTitleView {
                cell.updateModel(model?.subTitle, 
                                 comment: nil,
                                 containerWidth: getTitleWidth(),
                                 isSubtitle: true)
            }
            return cell
        } else {
            // 字段内容
            let model = getFieldItemModel(index: indexPath.row)
            let reuseIdentifier = model?.fieldUIType.reusableCellForNativeRender ?? BTCardNotSupportField.self
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier.reuseIdentifier, for: indexPath)
            if let cell = cell as? BTFieldBaseCell {
                cell.context = context
                cell.updateModel(model, layoutMode: fieldLayoutMode, containerWidth: getFieldWidth(indexPath: indexPath))
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = getFieldHeight(indexPath: indexPath)
        
        if indexPath.section == 0 {
            return CGSize(width: getFieldListWidth(), height: height)
        }
        
        let width = getFieldWidth(indexPath: indexPath)
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        
        // 设置单元格行间距
        return getLineSpacing()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 {
            return UIEdgeInsets(top: 0, left: 0, bottom: getSectionSpacing(), right: 0)
        }
        
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        // 设置单元格列间距
        return CardViewConstant.LayoutConfig.fieldInteritemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return hasSubTitle ? 2 : 1
        }
        
        return getFieldItemsCount()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
}

extension BTCardViewCell: BTCardTitleViewDelegate {
    func didClickComment(params: [String: Any]) {
        delegate?.didClickComment(params: params)
    }
}

final class BTNativeRenderFieldListView: UICollectionView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view is UIButton {
            return view
        }
        
        return nil
    }
}

extension BTCardViewCell: BTNativeRenderCardStatisticProtocol {
    var setData: TimeInterval {
        profile.setDataCost
    }
    
    var layout: TimeInterval {
        profile.layoutCost
    }
    
    var draw: TimeInterval {
        profile.drawCost
    }
    
    var type: NativeRenderViewType {
        .cardView
    }
    
    
}

extension BTCardViewCell: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let touchView = touch.view
        if gestureRecognizer is UILongPressGestureRecognizer,
           touchView?.isDescendant(of: coverView) == true  {
            return false
        }
        
        return true
    }
}
