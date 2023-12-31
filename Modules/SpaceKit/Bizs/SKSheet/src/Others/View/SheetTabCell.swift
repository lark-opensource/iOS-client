//
// Created by duanxiaochen.7 on 2019/7/30.
// Affiliated with SpaceKit.
//
// Description: Sheet Redesign - TabSwitcher - TabCell
//

import SnapKit
import Foundation
import SKCommon
import SKResource
import UniverseDesignIcon
import UniverseDesignColor

class SheetTabCell: UICollectionViewCell {

    // MARK: - Subviews

    lazy var leftSeparator = UIView().construct { it in
        it.backgroundColor = UDColor.N300
    }

    let defaultLinkSelectedImage = BundleResources.SKResource.Common.Global.icon_global_sheetapp_nor
    let defaultLinkUnselectedImage = BundleResources.SKResource.Common.Global.icon_global_sheetapp_nor.change(alpha: 0.5)
    
    lazy var linkImageView = UIImageView(image: defaultLinkSelectedImage).construct { (it) in
        it.contentMode = .scaleAspectFit
    }
    
    /// Only the protected tab has a visible lock icon
    lazy var lock = UIImageView(image: UDIcon.lockOutlined.withRenderingMode(.alwaysTemplate))

    lazy var name = UILabel().construct { it in
        it.backgroundColor = .clear
        it.font = UIFont.systemFont(ofSize: 13)
        it.numberOfLines = 1
        it.textAlignment = .center
        it.lineBreakMode = .byTruncatingTail
    }

    /// Only the selected tab in a editable sheet has a visible panel indicator
    lazy var panelIndicator = UIImageView(image: UDIcon.expandDownFilled.ud.withTintColor(UDColor.colorfulBlue))

    lazy var rightSeparator = UIView().construct { it in
        it.backgroundColor = UDColor.lineDividerDefault
    }

    // MARK: - Configurations

    private var info = SheetTabInfo()

    var tapCount: Int = 0

    private let paddingLR: CGFloat = 12.0
    private let textPaddingRightWithIndicator: CGFloat = 30.0

    func update(_ info: SheetTabInfo, selectedIndex: Int) {
        self.info = info
        lock.removeFromSuperview()
        panelIndicator.removeFromSuperview()
        linkImageView.removeFromSuperview()
        
        let showLinkIcon = info.customIconType != .none
        let isLocked = info.isLocked

        // 有关联图标
        if showLinkIcon {
            contentView.addSubview(linkImageView)
            linkImageView.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(paddingLR)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(16)
            }
        }
        
        // lock
        if isLocked {
            contentView.addSubview(lock)
            lock.isHidden = false
            lock.snp.remakeConstraints { (make) in
                if showLinkIcon {
                    make.left.equalTo(lock.snp.right).offset(6)
                } else {
                    make.left.equalToSuperview().offset(paddingLR)
                }
                
                make.centerY.equalToSuperview()
                make.width.height.equalTo(16)
            }
        }
        
        // tab name
        name.text = info.text
        contentView.addSubview(name)
        name.snp.remakeConstraints { (make) in
            if isLocked {
                make.left.equalTo(lock.snp.right).offset(4)
            } else if showLinkIcon {
                make.left.equalTo(linkImageView.snp.right).offset(4)
            } else {
                make.left.equalToSuperview().inset(paddingLR)
            }
            
            if info.editable && info.isSelected {
                make.right.equalToSuperview().inset(textPaddingRightWithIndicator)
            } else {
                make.right.equalToSuperview().inset(paddingLR)
            }
            make.centerY.equalToSuperview()
            make.height.equalTo(18)
        }
        // panel indicator
        if info.editable && info.isSelected {
            contentView.addSubview(panelIndicator)
            panelIndicator.snp.remakeConstraints { (make) in
                make.left.equalTo(name.snp.right).offset(4)
                make.width.height.equalTo(10)
                make.centerY.equalToSuperview()
            }
        }
        // separators
        contentView.addSubview(rightSeparator)
        rightSeparator.snp.remakeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(4)
            make.right.equalToSuperview()
            make.width.equalTo(0.7)
        }
        contentView.addSubview(leftSeparator)
        leftSeparator.snp.remakeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(4)
            make.left.equalToSuperview()
            make.width.equalTo(0.3)
        }

        
        // cell's select state
        configSelectState(info, selectedIndex: selectedIndex)

        layoutIfNeeded()
    }
    
    func configSelectState(_ info: SheetTabInfo, selectedIndex: Int) {
        // cell's select state
        if info.customIconType == .universal {
            linkImageView.kf.cancelDownloadTask()
            useDefaultLinkImage(isSelected: info.isSelected)
        } else if info.customIconType == .url {
            if let urlString = info.selectedUrl, info.isSelected {
                let url = URL(string: urlString)
                linkImageView.kf.setImage(with: url, placeholder: defaultLinkSelectedImage, options: nil)
            } else if let urlString = info.unselectedUrl, !info.isSelected {
                let url = URL(string: urlString)
                linkImageView.kf.setImage(with: url, placeholder: defaultLinkUnselectedImage, options: nil)
            } else {
                useDefaultLinkImage(isSelected: info.isSelected)
            }
        }
        contentView.docs.removeAllPointer()
        if info.isSelected {
            tapCount = 1
            contentView.docs.addStandardLift()
            layer.masksToBounds = false
//            layer.shadowColor = UDColor.N1000.cgColor
            layer.ud.setShadowColor(UDColor.N1000 & UIColor.clear)
            layer.shadowRadius = 2
            layer.shadowOpacity = 0.25
            layer.zPosition = 1  // 这行非常重要，没有这行右边的阴影会被右边的 cell 盖住
            layer.shadowOffset = CGSize(width: 0, height: 0)
            let shadowRect: CGRect = self.bounds.insetBy(dx: 0, dy: 2)
            layer.shadowPath = UIBezierPath(rect: shadowRect).cgPath
            backgroundColor = UDColor.N00 & UDColor.bgBodyOverlay
            leftSeparator.isHidden = true
            rightSeparator.isHidden = true
            lock.tintColor = UDColor.colorfulBlue
            name.textColor = UDColor.colorfulBlue
            if info.editable {
                panelIndicator.isHidden = false
            }
        } else {
            tapCount = 0
            contentView.docs.addHighlight(with: UIEdgeInsets(top: 4, left: 2, bottom: 4, right: 2), radius: 8)
            layer.shadowRadius = 0
            layer.masksToBounds = true
            layer.zPosition = 0
            backgroundColor = UDColor.N200 & UDColor.bgBase
            if info.index == selectedIndex - 1 {
                leftSeparator.isHidden = false
                rightSeparator.isHidden = true
            } else if info.index == selectedIndex + 1 {
                leftSeparator.isHidden = true
                rightSeparator.isHidden = false
            } else {
                leftSeparator.isHidden = false
                rightSeparator.isHidden = false
            }
            lock.tintColor = UDColor.N600
            if info.enabled {
                name.textColor = UDColor.N600
            } else {
                name.textColor = UDColor.N400
            }
            panelIndicator.isHidden = true
        }
    }
    
    func useDefaultLinkImage(isSelected: Bool) {
        linkImageView.image = linkImage(isSelected: isSelected)
    }
    
    func linkImage(isSelected: Bool) -> UIImage? {
        return isSelected ? defaultLinkSelectedImage : defaultLinkUnselectedImage
    }

    func tapped() {
        tapCount = min(2, tapCount + 1)
    }

    func clearTapCount() {
        tapCount = 0
    }
}
