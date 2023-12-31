import SKResource
import SnapKit
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignIcon
import UIKit

final class QuickAddView: UIView {
    
    lazy var label: UILabel = {
        var view = UILabel()
        view.text = BundleI18n.SKResource.Bitable_GroupChat_NewGroup_Button
        view.textColor = UDColor.primaryPri500
        view.font = .systemFont(ofSize: 16)
        return view
    }()
    
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey(.rightBoldOutlined, iconColor: UDColor.textLinkHover, size: CGSize(width: 12, height: 12))
        return view
    }()
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        backgroundColor = UDColor.bgFloat
        
        addSubview(label)
        addSubview(imageView)
        
        label.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(24)
        }
        imageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
            make.left.equalTo(label.snp.right).offset(16)
            make.width.height.equalTo(12)
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
