//
//  IconAloneCell.swift
//  SKDoc
//
//  Created by zoujie on 2021/1/20.
//  


import SKFoundation
import UniverseDesignColor

class IconAloneCell: UICollectionViewCell, BlockHorizontalCellType {
    private lazy var icon: UIImageView = UIImageView()

    private lazy var selectedView: UIView = {
        let selectView = UIView()
        selectView.backgroundColor = UDColor.bgBodyOverlay
        return selectView
    }()

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.docs.removeAllPointer()
    }
    
    private func setUpView() {
        contentView.addSubview(icon)
        self.backgroundColor = UDColor.bgBodyOverlay
        self.selectedBackgroundView = selectedView
        self.clipsToBounds = true
        icon.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(20)
        }
        self.update(.single)
    }

    override class func awakeFromNib() {
        super.awakeFromNib()
    }

    public func update(light: Bool, enable: Bool, backgroundColor: UIColor, image: UIImage) {
        self.docs.addStandardHover()
        if !enable {
            self.backgroundColor = backgroundColor
            self.icon.image = image.ud.withTintColor(UDColor.iconDisabled)
            return
        }
        if light {
            self.backgroundColor = UDColor.fillActive
            self.icon.image = image.ud.withTintColor(UDColor.primaryContentDefault)
        } else {
            self.backgroundColor = backgroundColor
            self.icon.image = image.ud.withTintColor(UDColor.iconN1)
        }
    }
}
