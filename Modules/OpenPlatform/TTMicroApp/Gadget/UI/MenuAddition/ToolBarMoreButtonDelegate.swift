//
//  ToolBarMoreButtonDelegate.swift
//  TTMicroApp
//
//  Created by 刘洋 on 2021/2/26.
//

import UIKit
import LarkUIKit
import UniverseDesignIcon

@objc
/// 菜单按钮的代理，主要是动画器的事件代理，权限动画器的数据代理
public final class ToolBarMoreButtonDelegate: NSObject {
    /// 地理定位权限视图
    private lazy var locationImageView: UIImageView = {
        let image = UDIcon.getIconByKey(UDIconType.privacyLocationOutlined, size: CGSize.init(width: 20.0, height: 20.0))
        var imageView = UIImageView()
        imageView.contentMode = .center
        imageView.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        imageView.image = image
        return imageView
    }()


    /// 麦克风权限视图
    private lazy var microphoneImageView: UIImageView = {
        let image = UDIcon.getIconByKey(UDIconType.micOutlined, size: CGSize.init(width: 20.0, height: 20.0))
        var imageView = UIImageView()
        imageView.contentMode = .center
        imageView.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        imageView.image = image
        return imageView
    }()

    /// 按钮原来正常状态下的image
    private var buttonOriginImage: UIImage?
}


extension ToolBarMoreButtonDelegate: PrivacyAlternateAnimatorDataSource {
    public func privacyAlternateAnimator(_ animator: PrivacyAlternateAnimator, for status: BDPPrivacyAccessStatus) -> [UIView] {
        var result: [UIView] = []
        if status.contains(.location) {
            result.append(self.locationImageView)
        }
        if status.contains(.microphone) {
            result.append(self.microphoneImageView)
        }
        return result
    }
}

extension ToolBarMoreButtonDelegate: AlternateAnimatorDelegate {
    public func animationWillStart(for view: UIView) {
        guard let button = view as? UIButton else {
            return
        }
        // 动画开始，将按钮自身视图隐藏
        self.buttonOriginImage = button.image(for: .normal)
        button.setImage(nil, for: .normal)
    }
    
    public func animationDidEnd(for view: UIView) {
        guard let button = view as? UIButton else {
            return
        }
        // 动画结束，将按钮自身视图显示
        button.setImage(self.buttonOriginImage, for: .normal)
    }
    
    public func animationDidAddSubView(for targetView: UIView, subview: UIView) {
        // 居中对齐
        subview.snp.makeConstraints{
            make in
            make.centerX.centerY.equalToSuperview()
        }
    }
    
    public func animationDidRemoveSubView(for targetView: UIView, subview: UIView) {

    }
}
