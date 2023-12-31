import SKResource
import UIKit
import UniverseDesignColor
import UniverseDesignIcon

protocol RemindNotificationViewDelegate: AnyObject {
    func onRemindNotificationViewClick()
}

final class RemindNotificationView: UIControl {
    
    weak var delegate: RemindNotificationViewDelegate?
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = UDColor.fillPressed
            } else {
                backgroundColor = UDColor.bgFloat
            }
        }
    }
    
    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.tintColor = UDColor.iconN1
        view.image = UDIcon.sentOutlined.withRenderingMode(.alwaysTemplate)
        return view
    }()

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .left
        label.textColor = UDColor.textTitle
        label.text = BundleI18n.SKResource.Bitable_NewSurvey_Reminder_RemindThem_Button
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addTarget(self, action: #selector(didReceiveTapGesture), for: .touchUpInside)
        
        backgroundColor = UDColor.bgFloat
        
        addSubview(iconView)
        addSubview(titleLabel)
        
        iconView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview().inset(16)
            make.width.height.equalTo(20)
            make.top.bottom.equalTo(16)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.centerY.equalTo(iconView)
            make.right.equalToSuperview().offset(-12)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func didReceiveTapGesture() {
        delegate?.onRemindNotificationViewClick()
    }
    
}
