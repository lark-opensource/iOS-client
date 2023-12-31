//
//  WikiWorkSpaceCell.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/9/30.
//

import UIKit
import SKCommon
import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import RxSwift
import UniverseDesignTag
import SKWorkspace
import LarkDocsIcon
import LarkContainer
import LarkIcon

class WikiWorkSpaceCell: UITableViewCell {

    var reuseBag = DisposeBag()

    var contentEnable: Bool = true {
        didSet {
            if !contentEnable {
                titleIcon.alpha = 0.3
                titleView.alpha = 0.3
                contentLabel.alpha = 0.3
            } else {
                titleIcon.alpha = 1
                titleView.alpha = 1
                contentLabel.alpha = 1
            }
        }
    }

    // 标题 + tag
    private lazy var titleView = SKListCellView()
    // 副标题
    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UDColor.textCaption
        return label
    }()
    // icon
    private let titleIcon = UIImageView()
    private let customIcon = WikiSpaceCustomIcon(frame: CGRect(origin: .zero, size: CGSize(width: 40, height: 40)))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _setupUI()
        contentView.docs.addStandardHover()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func _setupUI() {
        contentView.backgroundColor = UDColor.bgBody
        addSubview(titleView)
        addSubview(contentLabel)
        addSubview(titleIcon)
        titleView.snp.makeConstraints { (make) in
            make.left.equalTo(titleIcon.snp.right).offset(12)
            make.right.lessThanOrEqualToSuperview().offset(-16)
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(24)
        }
        contentLabel.snp.makeConstraints { (make) in
            make.left.equalTo(titleIcon.snp.right).offset(12)
            make.right.equalToSuperview().offset(-30)
            make.top.equalTo(titleView.snp.bottom)
            make.height.equalTo(20)
            make.bottom.equalToSuperview().inset(12)
        }
        titleIcon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.height.width.equalTo(40)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // reuse 时重置下状态
        contentEnable = true
        reuseBag = DisposeBag()
    }

    func update(with space: WikiSpace) {
        let title = NSAttributedString(string: space.displayTitle)
        contentLabel.text = space.displayDescription
        // 配置icon
        setupIcon(with: space)
        
        var elements: [SKListCellElementType] = [.richLabel(attributedString: title)]
        if let customTag = space.getDisplayTag(preferTagFromServer: true,
                                               currentTenantID: User.current.basicInfo?.tenantID) {
            elements.append(.customTag(text: customTag, visable: true))
        }
        titleView.update(views: elements)
    }
    
    private func setupIcon(with space: WikiSpace) {
        guard UserScopeNoChangeFG.MJ.wikiSpaceCustomIconEnable else {
            titleIcon.image = UDIcon.wikibookCircleColorful
            return
        }
        
        //取的反向fg
        if !UserScopeNoChangeFG.HZK.larkIconDisable {
            guard let iconInfo = space.iconInfo else {
                titleIcon.image = UDIcon.wikibookCircleColorful
                return
            }
            
            var iconKey = iconInfo.key
            var iconExtend: LarkIconExtend
            if iconInfo.iconType == .word { //显示文字
                iconKey = DocsIconInfo.getIconWord(spaceName: space.spaceName)
                let borderColor = DocsIconInfo.getIconColor(spaceId: space.spaceID)
                let iconLayer = IconLayer(backgroundColor: UDColor.bgFloat,
                                          border: IconLayer.Border(borderWidth: 1.0, borderColor: borderColor))
                iconExtend = LarkIconExtend(shape: .CORNERRADIUS(value: 11.0),
                                            layer: iconLayer,
                                            placeHolderImage: UDIcon.wikibookCircleColorful)
            } else if iconInfo.iconType == .unicode { //显示emoji配置
                let iconLayer = IconLayer(backgroundColor: UDColor.bgFloat,
                                          border: IconLayer.Border(borderWidth: 1.0, borderColor: UDColor.lineDividerDefault))
                iconExtend = LarkIconExtend(shape: .CORNERRADIUS(value: 11.0),
                                            layer: iconLayer,
                                            placeHolderImage: UDIcon.wikibookCircleColorful)
            } else { //其他类型正常显示
                iconExtend = LarkIconExtend(placeHolderImage: UDIcon.wikibookCircleColorful)
            }
            
            titleIcon.li.setLarkIconImage(iconType: iconInfo.iconType,
                                          iconKey: iconKey,
                                          iconExtend: iconExtend,
                                          userResolver: Container.shared.getCurrentUserResolver())
            
            return
        }
        
        
        //旧逻辑，后面larkIconDisable删掉，旧删除下面的代码，customIcon也要删除
        if space.iconInfo?.iconType == .word {
            titleIcon.di.clearDocsImage()
            titleIcon.image = customIcon.getImage(spaceName: space.spaceName, spaceId: space.spaceID)
        } else {
            titleIcon.di.setDocsImage(iconInfo: space.iconInfo?.infoString ?? "",
                                      token: "",
                                      type: .wiki,
                                      shape: .SQUARE,
                                      container: ContainerInfo(isWikiRoot: true,
                                                               defaultCustomIcon: UDIcon.wikibookCircleColorful,
                                                               wikiCustomIconEnable: UserScopeNoChangeFG.MJ.wikiSpaceCustomIconEnable),
                                      userResolver: Container.shared.getCurrentUserResolver())
        }
    }
}
