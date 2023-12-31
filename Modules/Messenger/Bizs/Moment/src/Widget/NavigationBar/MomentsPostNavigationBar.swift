//
//  SendPostNavigationBar.swift
//  Moment-Moment
//
//  Created by bytedance on 2021/1/5.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit

protocol PostNavigationBarDelegate: AnyObject {
    /// 点击左边按钮
    func MomentsNavigationViewOnClose(_ view: MomentsPostNavigationBar)
    func MomentsNavigationViewOnRightButtonTapped(_ view: MomentsPostNavigationBar)
    func titleViewForNavigation() -> UIView?
    func titleViewAlignmentStyle() -> MomentsPostNavigationBar.AlignmentStyle
}
extension PostNavigationBarDelegate {
    func titleViewAlignmentStyle() -> MomentsPostNavigationBar.AlignmentStyle { return .center }
}

class MomentsPostNavigationBar: UIView {

    enum AlignmentStyle {
        case left(CGFloat)
        case center
    }

    static let navigationBarHeight: CGFloat = UIApplication.shared.statusBarFrame.height + 44
    static let navigationBarHeightForModalView: CGFloat = 44

    private weak var delegate: PostNavigationBarDelegate?

    let backImage: UIImage

    //右上角button的图片
    let rightBtnImage: UIImage?

    lazy var leftBtn: UIButton = {
        let btn = LKBarButtonItem(image: backImage).button
        btn.addTarget(self, action: #selector(closeBtnTapped), for: .touchUpInside)
        return btn
    }()

    lazy var rightBtn: UIButton = {
        let btn = LKBarButtonItem(image: rightBtnImage).button
        btn.addTarget(self, action: #selector(menuBtnTapped), for: .touchUpInside)
        return btn
    }()

    init(backImage: UIImage, rightBtnImage: UIImage? = nil, delegate: PostNavigationBarDelegate?) {
        self.backImage = backImage
        self.delegate = delegate
        self.rightBtnImage = rightBtnImage
        super.init(frame: .zero)
        self.setupSubview()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubview() {
        addSubview(leftBtn)
        if let tintColor = btnTintColor() {
            leftBtn.tintColor = tintColor
            rightBtn.tintColor = tintColor
        }
        leftBtn.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(12)
            make.width.height.equalTo(24)
            make.bottom.equalToSuperview().offset(-10)
        }
        if rightBtnImage != nil {
            addSubview(rightBtn)
            rightBtn.snp.makeConstraints { make in
                make.width.height.centerY.equalTo(leftBtn)
                make.right.equalToSuperview().offset(-12)
            }
        }
        if let titleView = self.delegate?.titleViewForNavigation(),
            let style = self.delegate?.titleViewAlignmentStyle() {
            self.addSubview(titleView)
            switch style {
            case .center:
                titleView.snp.makeConstraints { (make) in
                    make.centerX.equalToSuperview()
                    make.centerY.equalTo(leftBtn)
                    make.left.greaterThanOrEqualTo(leftBtn.snp.right).offset(8)
                    make.right.lessThanOrEqualToSuperview().offset(-40)
                }
            case .left(let space):
                titleView.snp.makeConstraints { (make) in
                    make.centerY.equalTo(leftBtn)
                    make.left.equalTo(leftBtn.snp.right).offset(space)
                    make.right.lessThanOrEqualToSuperview().offset(-40)
                }
            }
        }
    }

    func btnTintColor() -> UIColor? {
        return UIColor.ud.iconN1
    }

    @objc
    func closeBtnTapped() {
        delegate?.MomentsNavigationViewOnClose(self)
    }

    @objc
    func menuBtnTapped() {
        delegate?.MomentsNavigationViewOnRightButtonTapped(self)
    }
}
