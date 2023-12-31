//longweiwei

import UIKit
import SKCommon
import SKResource
import UniverseDesignColor
import UniverseDesignIcon

class DriveVideoDisplayHeaderView: UIView {
    let rotateButton = DriveVideoHeaderButton(type: .custom)

    private let leftInsetValue: CGFloat = 16
    private let rightInsetValue: CGFloat = 14
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        rotateButton.setImage(UDIcon.screenRotationOutlined.ud.withTintColor(UDColor.primaryOnPrimaryFill), for: .normal)
        rotateButton.isHidden = true
        configButton(rotateButton)
        self.addSubview(rotateButton)
        rotateButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-rightInsetValue)
            make.width.height.equalTo(44)
        }
    }

    func configButton(_ button: UIButton) {
        button.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        button.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.5).nonDynamic
        button.layer.cornerRadius = 22
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class DriveVideoHeaderButton: UIButton {

    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {

        let imageSize = CGSize(width: 24, height: 24)

        return CGRect(x: (contentRect.size.width - imageSize.width) * 0.5,
                      y: (contentRect.size.height - imageSize.height) * 0.5,
                      width: imageSize.width,
                      height: imageSize.height)
    }
}
