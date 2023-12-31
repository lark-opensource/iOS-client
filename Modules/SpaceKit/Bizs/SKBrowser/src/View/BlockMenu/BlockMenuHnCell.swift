//
//  BlockMenuHnCell.swift
//  SKDoc
//
//  Created by zoujie on 2021/2/1.
//  


import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignIcon

class BlockMenuHnCell: UICollectionViewCell, BlockHorizontalCellType {

    private lazy var icon: UIImageView = UIImageView()
    private lazy var iconView: UIView = UIView()

    private lazy var rightArrows: UIImageView = UIImageView()
    private lazy var rightArrowsView: UIView = UIView()

    private lazy var selectedView: UIView = {
        let selectView = UIView()
        selectView.layer.cornerRadius = 8
        selectView.backgroundColor = UDColor.N900.withAlphaComponent(0.1)
        return selectView
    }()

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
    }

    private func setUpView() {
        addSubview(iconView)
        addSubview(rightArrowsView)

        iconView.addSubview(icon)
        rightArrowsView.addSubview(rightArrows)

        icon.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(20)
        }

        rightArrows.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        iconView.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(rightArrowsView.snp.left)
        }

        rightArrowsView.snp.makeConstraints { (make) in
            make.right.top.bottom.equalToSuperview()
            make.left.equalTo(iconView.snp.right)
            make.width.equalTo(BlockMenuConst.hnCellArrowWidth)
        }

        self.layer.cornerRadius = 8
        self.backgroundColor = UIColor.ud.N100

        self.selectedBackgroundView = selectedView
        self.docs.addStandardHover()
        icon.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }

    override class func awakeFromNib() {
        super.awakeFromNib()
    }

    public func update(light: Bool, enable: Bool, image: UIImage) {
        self.rightArrows.image = BundleResources.SKResource.Common.Tool.icon_expand_left_filled.ud.withTintColor(UDColor.iconN2)
        if !enable {
            self.backgroundColor = UIColor.ud.bgBodyOverlay
            self.icon.image = image.ud.withTintColor(UDColor.N400)
            self.rightArrows.image = BundleResources.SKResource.Common.Global.icon_expand_right_nor.ud.withTintColor(UDColor.N400)
            return
        }

        if light {
            self.backgroundColor = UIColor.ud.fillActive
            self.icon.image = image.ud.withTintColor(UDColor.primaryContentDefault)
        } else {
            self.backgroundColor = UIColor.ud.bgBodyOverlay
            self.icon.image = image.ud.withTintColor(UDColor.iconN1)
        }
    }
}
