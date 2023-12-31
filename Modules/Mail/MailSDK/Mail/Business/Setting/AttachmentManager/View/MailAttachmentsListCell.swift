//
//  MailAttachmentsListCell.swift
//  MailSDK
//
//  Created by ByteDance on 2023/4/20.
//

import UIKit
import LarkUIKit
import LarkTag
import RustPB
import RxSwift
import LarkExtensions
import ThreadSafeDataStructure
import YYText
import LarkSwipeCellKit
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignTheme

protocol MailAttachmentsListCellDelegate: AnyObject {
    func didClickFlag(_ cell: MailAttachmentsListCell, cellModel: MailAttachmentsListCellViewModel)
}

@objc protocol AttachmentslLongPressDelegate: AnyObject {
    func cellLongPress(reconizer: MailLongPressGestureRecognizer, view: UIView)
}

//MARK: - MailAttachmentsListCell
class MailAttachmentsListCell: SwipeTableViewCell, MailThreadAppearance {
    let timeLabelFont = UIFont.systemFont(ofSize: 12)
    let nameFontSize: CGFloat = 17
    let nameLabelLeftMargin = 16
    
    var displaysAsynchronously: Bool = false
    var clearContentsBeforeAsynchronouslyDisplay: Bool = true
    var rootSizeClassIsRegular: Bool = false
    var fileIconView: UIImageView = UIImageView()
    var threadAppearanceRef: ThreadSafeDataStructure.SafeAtomic<MailThreadAppearanceRef> = MailThreadAppearanceRef() + .readWriteLock

    var longPressGesture: MailLongPressGestureRecognizer?
    weak var mailDelegate: MailAttachmentsListCellDelegate?
    weak var longPressDelegate: AttachmentslLongPressDelegate?
    
    var selectedIndexPath: IndexPath = IndexPath(row: 0, section: 0) {
        didSet {
            longPressGesture?.selectedIndexPath = selectedIndexPath
        }
    }
    var enableLongPress: Bool = false {
        didSet {
            updateLongPress()
        }
    }
    var isMultiSelecting: Bool = false {
        didSet {
            displaysAsynchronously = !isMultiSelecting
            clearContentsBeforeAsynchronouslyDisplay = !isMultiSelecting
        }
    }
    var cellViewModel: MailAttachmentsListCellViewModel? {
        didSet {
            if let cellViewModel = cellViewModel {
                self.configCellViewModel(cellViewModel)
            }
        }
    }
    
    // MARK: life cycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configUI(container: self.swipeView, displaysAsynchronously: displaysAsynchronously)
        self.selectionStyle = .none
        // nameLabel截断适配暗黑模式
        var trucationTokenDark = NSMutableAttributedString(string: "...", attributes: [.font: nameLabel.font ?? UIFont.systemFont(ofSize: nameFontSize),
                                                                                  .foregroundColor: UIColor.ud.textTitle.alwaysDark])
        var trucationTokenlight = NSMutableAttributedString(string: "...", attributes: [.font: nameLabel.font ?? UIFont.systemFont(ofSize: nameFontSize),
                                                                                  .foregroundColor: UIColor.ud.textTitle.alwaysLight])

        if let label = nameLabel as? YYLabel {
            label.ud.setValue(forKeyPath: \.truncationToken,
                        dynamicProvider: UDDynamicProvider(trucationTokenlight, trucationTokenDark))
        }
        self.flagButton.addTarget(self, action: #selector(didClickFlagButton), for: .touchUpInside)

        // 需要先layout一次, 下面name label计算文本长度时需要用
        layoutIfNeeded()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !isMultiSelecting {
            normalLayoutSubviews()
        } else {
            editingLayoutSubViews()
        }
        updateLayouts(edit: isMultiSelecting)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        setNeedsLayout()
//        layoutIfNeeded()
    }
    
    // MARK: config
    private func configCellViewModel(_ cellVM: MailAttachmentsListCellViewModel) {
        nameLabel.isHidden = true
        timeLabel.isHidden = true
        draftLabel.isHidden = true
        tagWrapperView.isHidden = true
        unreadIcon.isHidden = true
        convLabel.isHidden = true
        attachmentIcon.isHidden = true
        priorityIcon.isHidden = true
        shareIcon.isHidden = true
        scheduleTimeIcon.isHidden = true
        scheduleTimeLabel.isHidden = true
        timeLabel.isHidden = true
        flagButton.isHidden = false
        fileIconView.isHidden = false
        
        flagButton.setImage(UDIcon.getIconByKey(UDIconType.moreOutlined).ud.withTintColor(UIColor.ud.iconN3), for: .normal)
        flagButton.isSelected = false

        fileIconView.image = cellVM.infoListType == .transferFolder ? UDIcon.fileFolderBlueColorful : UIImage.fileLadderIcon(with: cellVM.fileName ?? "")
        titleLabel.displaysAsynchronously = displaysAsynchronously
        titleLabel.clearContentsBeforeAsynchronouslyDisplay = clearContentsBeforeAsynchronouslyDisplay
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.truncationToken = NSMutableAttributedString(string: "...",
                                                               attributes: [.font: titleLabel.font ?? UIFont.systemFont(ofSize: 14),
                                                                            .foregroundColor: titleLabel.textColor ?? UIColor.ud.textTitle])
        titleLabel.setText(cellVM.fileName ?? "")
        titleLabel.backgroundColor = swipeView.backgroundColor
        descLabel.displaysAsynchronously = displaysAsynchronously
        descLabel.backgroundColor = swipeView.backgroundColor
        descLabel.clearContentsBeforeAsynchronouslyDisplay = clearContentsBeforeAsynchronouslyDisplay
        descLabel.font = UIFont.systemFont(ofSize: 12)
        descLabel.textColor = UIColor.ud.textCaption
        if cellVM.status == .banned {
            descLabel.textColor = UIColor.ud.functionDanger500
            descLabel.setText(BundleI18n.MailSDK.Mail_Shared_LargeAttachment_Harmful_Tooltip)
        } else if cellVM.status == .highRisk {
            descLabel.textColor = UIColor.ud.functionDanger500
            descLabel.setText(BundleI18n.MailSDK.Mail_Shared_LargeAttachment_HighRisk_Tooltip)
        } else if cellVM.status == .deleted {
            descLabel.textColor = UIColor.ud.textPlaceholder
        } else {
            descLabel.textColor = UIColor.ud.textPlaceholder
            descLabel.setText(cellVM.desc ?? "")
        }
    }
    
    private func normalLayoutSubviews() {
        var targetBgColor = caculateBackgroundColor()
        if isSelected {
            targetBgColor = UIColor.ud.fillHover
        }
        if rootSizeClassIsRegular {
            selectedBgView.isHidden = !(isHighlighted || isSelected)
            bottomLine.isHidden = isHighlighted || isSelected
        } else {
            selectedBgView.isHidden = true
            bottomLine.isHidden = false
        }
        swipeView.backgroundColor = (isSelected || isSelected) ? UIColor.clear : targetBgColor
        // 有透明度问题
        updateColor(isHighlighted || isSelected ? UIColor.clear : swipeView.backgroundColor)
        backgroundView?.isHidden = isHighlighted || isSelected
        multiSelecteView.isHidden = true
        bottomLine.snp.updateConstraints { make in
            make.left.equalTo(20)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
    
    private func editingLayoutSubViews() {
        var targetBgColor = caculateBackgroundColor()
        if isHighlighted {
            targetBgColor = caculateBackgroundColor(ignoreHighlight: true)
        }

        swipeView.backgroundColor = (isSelected || isSelected) ? UIColor.clear : targetBgColor
        updateColor(swipeView.backgroundColor)
        if rootSizeClassIsRegular {
            selectedBgView.isHidden = true
            bottomLine.isHidden = isHighlighted || isSelected
        }
        multiSelecteView.isAttachmentSelectIcon = true
        multiSelecteView.isSelected = isSelected
        multiSelecteView.frame = CGRect(x: 0, y: 0, width: 48, height: self.bounds.height)
        multiSelecteView.isHidden = false
    }

    private func updateColor(_ bgColor: UIColor?) {
        nameLabel.backgroundColor = bgColor
        timeLabel.backgroundColor = bgColor
        titleLabel.backgroundColor = bgColor
        descLabel.backgroundColor = bgColor
        attachmentIcon.backgroundColor = bgColor
    }
    
    private func updateLayouts(edit: Bool) {
        let padding = (edit ? 48 : 16) + 48
        self.swipeView.addSubview(fileIconView)
        
        nameContainer.snp.updateConstraints { make in
            make.top.equalTo(8)
            make.height.equalTo(0)
            make.left.equalTo(padding)
        }
        
        titleLabel.snp.updateConstraints { make in
            make.left.equalTo(padding)
        }
        
        descLabel.snp.updateConstraints { make in
            make.left.equalTo(titleLabel)
        }
        
        fileIconView.snp.makeConstraints { make in
            make.right.equalTo(titleLabel.snp.left).offset(-8)
            make.width.height.equalTo(40)
            make.centerY.equalToSuperview()
        }
        
        flagButton.snp.remakeConstraints { make in
            make.size.equalTo(CGSize(width: 32, height: 32))
            make.right.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
        }
    }
    
    @objc
    func didClickFlagButton() {
        if let viewModel = cellViewModel {
            flagButton.isSelected = !flagButton.isSelected
            mailDelegate?.didClickFlag(self, cellModel: viewModel)
        }
    }
    
    func updateLongPress() {
        if !enableLongPress {
            return
        }
        longPressGesture = makeLongPressGesture()
        if let longPressGesture = longPressGesture {
            self.addGestureRecognizer(longPressGesture)
        }
    }

    func makeLongPressGesture() -> MailLongPressGestureRecognizer {
        let longPressGesture = MailLongPressGestureRecognizer.init(target: self, action: #selector(MailAttachmentsListCell.enterMultiSelect(_:)))
        return longPressGesture
    }
    
    @objc
    func enterMultiSelect(_ sender: MailLongPressGestureRecognizer) {
        longPressDelegate?.cellLongPress(reconizer: sender, view: self)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        if let longPressGesture = longPressGesture {
            removeGestureRecognizer(longPressGesture)
        }
        longPressGesture = nil
    }
}

// MARK: helper
extension MailAttachmentsListCell {
    func caculateBackgroundColor(ignoreHighlight: Bool = false) -> UIColor {
        var targetBgColor = UIColor.clear
        if !ignoreHighlight && isHighlighted {
            targetBgColor = UIColor.ud.fillHover
        } else if Display.pad {
            targetBgColor = UIColor.ud.bgBody
        } else {
            targetBgColor = UIColor.ud.bgBody
        }
        return targetBgColor
    }
}
