//
//  IconWithTextCell.swift
//  SKDoc
//
//  Created by zoujie on 2021/1/20.
//  


import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import UIKit


class IconWithTextCell: UICollectionViewCell {
    private lazy var icon: UIImageView = {
        let imagView = UIImageView()
        imagView.contentMode = .center
        return imagView
    }()

    private lazy var selectedView: UIView = {
        let selectView = UIView()
        selectView.layer.cornerRadius = 4
        return selectView
    }()

    private lazy var label: UILabel = {
        var label = UILabel()
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        //新的设计规范，长文案需要暴露不省略
        //https://www.figma.com/file/24Px2UC0xVuNT169GStpPy/%E5%A4%9A%E8%AF%AD%E8%A8%80%E9%97%AE%E9%A2%98%E8%AE%BE%E8%AE%A1%E7%A8%BF%E6%B1%87%E6%80%BB?node-id=188%3A20915&t=pAdxWRcigRsPpbve-0
        label.numberOfLines = 6
        label.textColor = UIColor.ud.textCaption
        label.sizeToFit()
        label.font = UIFont.systemFont(ofSize: 12)
        label.highlightedTextColor = UDColor.N00
        return label
    }()
    
    var item: BlockMenuItem?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setContentView()

        self.docs.addHighlight(with: .zero, radius: 8)
    }

    private func setContentView() {
        contentView.addSubview(icon)
        contentView.addSubview(label)

        icon.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalTo(label.snp.top).offset(-6)
            make.centerX.equalTo(label.snp.centerX)
            make.width.height.equalTo(BlockMenuConst.iconWidth)
        }

        label.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(2)
            make.right.equalToSuperview().offset(-2)
            make.top.equalTo(icon.snp.bottom).offset(6)
        }
    }

    override class func awakeFromNib() {
        super.awakeFromNib()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let item = self.item else { return }
        let identifier = BlockMenuV2Identifier(rawValue: item.id)
        if identifier == .inlineAI {
            selectedView.backgroundColor = UDColor.AIPrimaryFillTransparent01(ofSize: selectedView.bounds.size)
            label.highlightedTextColor = UDColor.AIPrimaryContentDefault(ofSize: CGSize.init(width: bounds.size.width - 4, height: bounds.size.height))
        }
    }

    public func update(blockMenuItem: BlockMenuItem?, isNewMenu: Bool = false) {
        self.item = blockMenuItem
        guard let item = blockMenuItem else { return }
        label.text = item.text
        icon.image = item.loadImage()
        icon.highlightedImage = nil //重置高亮，避免复用串icon
        let selected = item.selected ?? false
        contentView.backgroundColor = .clear
        setCornerRadius(radius: 0, maskedCorners: [])
        let identifier = BlockMenuV2Identifier(rawValue: item.id)
        if isNewMenu {
            updateViewsWhenShowMenu(by: item)
            if selected {
                //选中样式
                self.backgroundColor = UDColor.fillActive
                icon.image = icon.image?.ud.withTintColor(UDColor.colorfulBlue)
                label.textColor = UDColor.colorfulBlue
                selectedView.backgroundColor = UDColor.B900.withAlphaComponent(0.16)
            } else {
                label.textColor = UDColor.N600
                self.backgroundColor = .clear
            }
            self.selectedBackgroundView = selectedView
            return
        }

        if item.id == BlockMenuIdentifier.delete.rawValue {
            selectedView.backgroundColor = UDColor.R400
        } else {
            selectedView.backgroundColor = UDColor.B400
        }

        self.selectedBackgroundView = selectedView
        if item.id != BlockMenuV2Identifier.alignleft.rawValue &&
            item.id != BlockMenuV2Identifier.alignright.rawValue &&
            item.id != BlockMenuV2Identifier.aligncenter.rawValue {
            self.icon.highlightedImage = self.icon.image?.withRenderingMode(.alwaysTemplate).ud.withTintColor(UDColor.N00)
        }
    }
    
    func updateViewsWhenShowMenu(by item: BlockMenuItem) {
        let identifier = BlockMenuV2Identifier(rawValue: item.id)
        let selected = item.selected ?? false
        
        func updateBaseViews(color: UIColor) {
            selectedView.backgroundColor = color.withAlphaComponent(0.1)
            label.highlightedTextColor = color
            icon.image = item.loadImage(iconSize: CGSize(width: 24, height: 24))?.ud.withTintColor(color)
        }
        
        switch identifier {
        case .comment, .fileOpenWith:
            updateBaseViews(color: UDColor.colorfulYellow)
        case .cut, .checkDetails, .fileSaveToDrive:
            updateBaseViews(color: UDColor.colorfulGreen)
        case .copy, .copyLink, .align, .fileDownload, .translate:
            updateBaseViews(color: UDColor.colorfulBlue)
        case .delete:
            updateBaseViews(color: UDColor.colorfulRed)
        case .style:
            updateBaseViews(color: UDColor.N700)
        case .cancelRealtimeReference, .cancelSyncTask, .caption:
            updateBaseViews(color: UDColor.colorfulIndigo)
        case .more:
            updateBaseViews(color: UDColor.N500)
        case .blockalignleft, .blockalignright, .blockaligncenter:
            selectedView.backgroundColor = UIColor.ud.fillActive
            label.highlightedTextColor = selected ? UIColor.ud.colorfulBlue : UIColor.ud.N600
            icon.image = icon.image?.ud.withTintColor(UIColor.ud.iconN1)
            contentView.backgroundColor = selected ? .clear : UIColor.ud.bgBodyOverlay
            if identifier == .blockalignleft {
                setCornerRadius(radius: 8, maskedCorners: .left)
            } else if identifier == .blockalignright {
                setCornerRadius(radius: 8, maskedCorners: .right)
            }
        case .editPencilKit:
            selectedView.backgroundColor = UDColor.colorfulTurquoise.withAlphaComponent(0.1)
            label.highlightedTextColor = UDColor.colorfulTurquoise
            icon.image = icon.image?.ud.withTintColor(UDColor.colorfulTurquoise)
        case .focusTask:
            let color = UDColor.colorfulWathet
            let size = CGSize(width: 24, height: 24)
            selectedView.backgroundColor = color.withAlphaComponent(0.1)
            label.highlightedTextColor = color
            if selected {
                icon.image = UDIcon.resolveOutlined.ud.resized(to: size).ud.withTintColor(color)
            } else {
                icon.image = item.loadImage(iconSize: size)?.ud.withTintColor(color)
            }
        case .inlineAI:
            selectedView.backgroundColor = UDColor.AIPrimaryFillTransparent01(ofSize: selectedView.bounds.size)
            label.highlightedTextColor = UDColor.AIPrimaryContentDefault(ofSize: label.bounds.size)

        case .contentReaction:
            updateBaseViews(color: UDColor.colorfulOrange)
        case .forward:
            updateBaseViews(color: UDColor.colorfulWathet)
        case .startTime, .pauseTime, .newLineBelow:
            updateBaseViews(color: UDColor.colorfulBlue)
        case .addTime, .editTime:
            updateBaseViews(color: UDColor.iconN1)
        default:
            selectedView.backgroundColor = UDColor.B400
            label.highlightedTextColor = UDColor.N00
            self.icon.highlightedImage = self.icon.image?.withRenderingMode(.alwaysTemplate).ud.withTintColor(UDColor.N00)
        }
    }
}

// MARK: - corner

extension IconWithTextCell {
    
    func setCornerRadius(radius: CGFloat, maskedCorners: CACornerMask) {
        self.layer.cornerRadius = 8
        self.layer.maskedCorners = maskedCorners
        self.clipsToBounds = true
    }
}
