//
// Created by duanxiaochen.7 on 2021/1/12.
// Affiliated with SKCommon.
//
// Description:

import SKFoundation
import SKUIKit
import SnapKit
import UniverseDesignLoading

public final class SKLoadingView: UIView {

    public init(backgroundAlpha: CGFloat = 0.9) {
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.N00.withAlphaComponent(backgroundAlpha)

        let animationView = UDLoading.loadingImageView()
        addSubview(animationView)
        animationView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
