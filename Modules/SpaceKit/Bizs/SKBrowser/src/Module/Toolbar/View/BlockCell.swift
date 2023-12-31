// 
// Created by duanxiaochen.7 on 2020/7/1.
// Affiliated with SKCommon.
// 
// Description:

import Foundation
import UniverseDesignColor
import UniverseDesignBadge
import FigmaKit

class BlockCell: UICollectionViewCell {
    private var model: BlockModel!
    private var uiConstant = InsertBlockUIConstant()
    private var redDot: UDBadge!
    private var icon: SquircleView!
    
    var isPopover = false
    // icon设置了圆角,不能直接加redDot,所以需要在icon外层套一个UIView
    private var iconContainer: UIView = .init()
    private var name: UILabel = .init()

    func configure(with model: BlockModel, uiConstant: InsertBlockUIConstant) {
        self.model = model
        self.uiConstant = uiConstant
        contentView.layer.masksToBounds = false
        makeIconContainer()
        contentView.addSubview(iconContainer)
        iconContainer.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(uiConstant.blockCellIconTopSpace)
            make.width.height.equalTo(uiConstant.blockCellIconEdge)
            make.centerX.equalToSuperview()
        }
        makeIcon()
        iconContainer.addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        if model.showBadge == true && !model.adminLimit {
            makeRedDot()
            redDot.config.dotSize = .middle
        }

        if model.name != nil {
            makeName()
            contentView.addSubview(name)
            name.snp.makeConstraints { (make) in
                make.top.equalTo(icon.snp.bottom).offset(uiConstant.blockCellIconTextSpacing)
                make.centerX.equalTo(icon)
                make.width.equalToSuperview()
            }
        }

        icon.docs.addStandardLift()
    }
    
    private func makeIconContainer() {
        if iconContainer != nil {
            iconContainer.snp.removeConstraints()
            iconContainer.removeFromSuperview()
        }
        
        iconContainer = UIView()
    }
    
    // swiftlint:disable cyclomatic_complexity
    private func makeIcon() {
        if icon != nil {
            icon.snp.removeConstraints()
            icon.removeFromSuperview()
        }
        icon = SquircleView()
        var image = ToolBarItemInfo.loadImage(by: model.id)
        let iconBackgroundColor = isPopover ? UDColor.bgFloatOverlay : UDColor.bgBodyOverlay
        if model.adminLimit {
            image = image?.ud.withTintColor(UDColor.iconDisabled)
            icon.backgroundColor = iconBackgroundColor
        } else {
            switch model.id {
            case BarButtonIdentifier.insertImage.rawValue:
                image = image?.ud.withTintColor(UDColor.colorfulYellow)
                icon.backgroundColor = UDColor.Y50
            case BarButtonIdentifier.insertSeparator.rawValue:
                image = image?.ud.withTintColor(UDColor.colorfulIndigo)
                icon.backgroundColor = UDColor.I50
            case BarButtonIdentifier.mentionUser.rawValue:
                image = image?.ud.withTintColor(UDColor.colorfulBlue)
                icon.backgroundColor = UDColor.B50
            case BarButtonIdentifier.mentionChat.rawValue:
                image = image?.ud.withTintColor(UDColor.colorfulWathet)
                icon.backgroundColor = UDColor.W50
            case BarButtonIdentifier.mentionFile.rawValue:
                image = image?.ud.withTintColor(UDColor.colorfulBlue)
                icon.backgroundColor = UDColor.B50
            case BarButtonIdentifier.insertFile.rawValue:
                image = image?.ud.withTintColor(UDColor.colorfulOrange)
                icon.backgroundColor = UDColor.O50
            case BarButtonIdentifier.calloutBlock.rawValue:
                image = image?.ud.withTintColor(UDColor.colorfulYellow)
                icon.backgroundColor = UDColor.Y50
            case BarButtonIdentifier.pencilkit.rawValue:
                image = image?.ud.withTintColor(UDColor.colorfulWathet)
                icon.backgroundColor = UDColor.W50
            case BarButtonIdentifier.insertTable.rawValue:
                image = image?.ud.withTintColor(UDColor.colorfulTurquoise)
                icon.backgroundColor = UDColor.T50
            case BarButtonIdentifier.insertCalendar.rawValue:
                image = image?.ud.withTintColor(UDColor.colorfulOrange)
                icon.backgroundColor = UDColor.O50
            case BarButtonIdentifier.insertReminder.rawValue:
                image = image?.ud.withTintColor(UDColor.colorfulBlue)
                icon.backgroundColor = UDColor.B50
            case BarButtonIdentifier.insertTask.rawValue, BarButtonIdentifier.insertTaskList.rawValue:
                image = image?.ud.withTintColor(UDColor.colorfulIndigo)
                icon.backgroundColor = UDColor.I50
            case BarButtonIdentifier.insertSheet.rawValue:
                image = image?.ud.withTintColor(UDColor.colorfulGreen)
                icon.backgroundColor = UDColor.G50
            case BarButtonIdentifier.insertBitable.rawValue:
                image = image?.ud.withTintColor(UDColor.sk.bitableBrand)
                icon.backgroundColor = UDColor.P50
            case BarButtonIdentifier.insertMindnote.rawValue:
                image = image?.ud.withTintColor(UDColor.colorfulWathet)
                icon.backgroundColor = UDColor.W50
            case BarButtonIdentifier.okr.rawValue:
                image = image?.ud.withTintColor(UDColor.colorfulBlue)
                icon.backgroundColor = UDColor.B50
            case BarButtonIdentifier.ai.rawValue:
                icon.backgroundColor = UDColor.B50
            case BarButtonIdentifier.syncedSource.rawValue:
                icon.backgroundColor = UIColor.docs.gradientColor(direction: .diagonal135,
                                                                  size: CGSize(width: uiConstant.blockCellIconEdge, height: uiConstant.blockCellIconEdge),
                                                                  colors: [UDColor.B600.withAlphaComponent(0.08),
                                                                           UDColor.B400.withAlphaComponent(0.08),
                                                                           UDColor.W300.withAlphaComponent(0.08)])
            case BarButtonIdentifier.hyperLink.rawValue:
                image = image?.ud.withTintColor(UDColor.iconN1)
                icon.backgroundColor = iconBackgroundColor
            case BarButtonIdentifier.insertAgenda.rawValue:
                image = image?.ud.withTintColor(UDColor.I500)
                icon.backgroundColor = UDColor.I50
            case BarButtonIdentifier.folderBlock.rawValue:
                image = image?.ud.withTintColor(UDColor.colorfulBlue)
                icon.backgroundColor = UDColor.B50
            default:
                image = image?.ud.withTintColor(UDColor.iconN1)
                icon.backgroundColor = iconBackgroundColor
            }
        }
        let imageview = UIImageView(image: image)
        imageview.contentMode = .center
        icon.addSubview(imageview)
        imageview.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(uiConstant.blockCellImageEdge)
        }

//        icon.layer.masksToBounds = true
        icon.cornerRadius = uiConstant.blockCellIconCornerRadius
        icon.cornerSmoothness = .max
    }

    private func makeName() {
        if name != nil {
            name.snp.removeConstraints()
            name.removeFromSuperview()
        }
        name = UILabel()
        name.numberOfLines = 0
        name.textAlignment = .center
        name.lineBreakMode = .byWordWrapping
        name.font = UIFont.systemFont(ofSize: uiConstant.blockCellTextFontSize, weight: .regular)
        name.text = model.name
        name.textColor = model.adminLimit ? UDColor.N400: UIColor.ud.textCaption
    }

    private func makeRedDot() {
        iconContainer.badge?.removeFromSuperview()
        redDot = iconContainer.addBadge(.dot, anchor: .topRight, offset: .init(width: 0, height: 0))
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        if name != nil {
            name.snp.removeConstraints()
            name.removeFromSuperview()
            name.text = ""
        }
    }
}
