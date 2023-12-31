import SnapKit
import SKUIKit
import UniverseDesignColor
import UIKit

final class ChatterHeaderView: UIView {
    
    lazy var seprateLine: UIView = {
        let v = UIView()
        v.backgroundColor = UDColor.N300
        return v
    }()
    
    lazy var label: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 14)
        view.textColor = UDColor.textCaption
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UDColor.bgFloat
        
        addSubview(seprateLine)
        addSubview(label)
        
        seprateLine.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(2 / SKDisplay.scale)
        }
        
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(20)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
