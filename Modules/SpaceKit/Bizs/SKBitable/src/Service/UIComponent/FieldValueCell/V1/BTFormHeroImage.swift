//
// Created by duanxiaochen.7 on 2021/12/16.
// Affiliated with SKBitable.
//
// Description:
//

import Foundation
import UIKit
import SnapKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import ByteWebImage
import SKFoundation

final class BTFormHeroImageCell: UICollectionViewCell {

    private let bgImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        bgImageView.contentMode = .scaleAspectFill
        bgImageView.image = BundleResources.SKResource.Bitable.bitable_form_bg // 特殊大图，没有 UDIcon
        bgImageView.backgroundColor = UDColor.primaryContentDefault
        bgImageView.clipsToBounds = true

        contentView.addSubview(bgImageView)
        bgImageView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(BTFieldLayout.Const.formHeroImageHeight)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 封面模式，标准or自定义
enum BTCustomFormCoverCellMode {
    case normal
    case custom(url: String)
}

/// 表单封面Cell，全量后删除上边的BTFormHeroImageCell
final class BTCustomFormCoverCell: UICollectionViewCell {
    
    lazy var bgImageView = ByteImageView()
    
    lazy var loadingAndFailView = BTCustomFormCoverLoadingAndFailView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // 需求讨论结论：如果后端图片不符合规范，则端上「按照"图片的宽高"比例缩放图片至图片的宽度或者高度和UIImageView一样, 并且让整个图片都在UIImageView中. 然后居中显示」
        bgImageView.contentMode = .scaleAspectFill
        bgImageView.backgroundColor = UDColor.primaryContentDefault
        bgImageView.clipsToBounds = true
        
        contentView.addSubview(bgImageView)
        bgImageView.addSubview(loadingAndFailView)
        
        bgImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        loadingAndFailView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(mode: BTCustomFormCoverCellMode) {
        switch mode {
        case .normal:
            bgImageView.image = BundleResources.SKResource.Bitable.bitable_form_bg
            loadingAndFailView.stopAnimation()
            loadingAndFailView.isHidden = true
        case .custom(let url):
            loadingAndFailView.isHidden = false
            loadingAndFailView.update(mode: .loading)
            loadingAndFailView.startAnimation()
            
            DocsLogger.info("start request banner by setLarkImage with url: \(url)")
            bgImageView.bt.setLarkImage(
                .default(key: url),
                modifier: { (req) -> URLRequest in
//                    var req = req
//                    req.setValue("boe_pic_custom", forHTTPHeaderField: "x-tt-env")
                    return req
                }
            ) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    DocsLogger.info("success request banner by setLarkImage with url: \(url)")
                    self.loadingAndFailView.stopAnimation()
                    self.loadingAndFailView.isHidden = true
                case .failure(let error):
                    DocsLogger.error("fail request banner by setLarkImage with url: \(url) code: \(error.code) userinfo: \(error.userInfo) localizedDescription: \(error.localizedDescription)", error: error)
                    self.loadingAndFailView.stopAnimation()
                    self.loadingAndFailView.isHidden = false
                    self.loadingAndFailView.update(mode: .fail)
                }
            }
        }
    }
}

/// 自定义封面加载&失败模式
enum BTCustomFormCoverMode {
    case loading
    case fail
}

/// 自定义封面Loading和失败图
final class BTCustomFormCoverLoadingAndFailView: UIView {
    
    lazy var imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UDColor.bgBase
        addSubview(imageView)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(mode: BTCustomFormCoverMode) {
        if mode == .loading {
            imageView.image = UDIcon.getIconByKey(.loadingOutlined, iconColor: UDColor.primaryContentDefault, size: CGSize(width: 24, height: 24))
            imageView.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(24)
            }
        } else {
            imageView.image = UDIcon.getIconByKey(.loadfailFilled, iconColor: UDColor.iconDisabled, size: CGSize(width: 40, height: 40))
            imageView.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(40)
            }
        }
    }
    
    func startAnimation() {
        BTUtil.startRotationAnimation(view: imageView)
    }
    
    func stopAnimation() {
        BTUtil.stopRotationAnimation(view: imageView)
    }
}
