//
//  File.swift
//  FileList
//
//  Created by Bytedance_sibo on 11/01/2018.
//

import UIKit
import SnapKit
import SKResource
import RxSwift

public typealias SwipeClosureType = () -> Void
open class SwipeView: UIView {
    let imageView = UIImageView()
    let titleLabel = UILabel()
    var swipeClosure: SwipeClosureType = {}
    private let disposeBag = DisposeBag()

    public init(_ title: String, _ color: UIColor, _ image: UIImage, _ action: @escaping SwipeClosureType) {
        super.init(frame: CGRect())
        backgroundColor = color
        isUserInteractionEnabled = true
        titleLabel.text = title
        titleLabel.textColor = UIColor.ud.N00
        titleLabel.font = UIFont.docs.pfsc(17)
        titleLabel.isHidden = true
        imageView.image = image
        accessibilityIdentifier = title
        imageView.contentMode = .scaleAspectFit
        swipeClosure = action
        addSubview(actionViewButton)
        addSubview(imageView)
        addSubview(titleLabel)
        actionViewButton.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        imageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(24)
            make.left.equalToSuperview().offset(25)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(21)
            make.bottom.equalTo(-21)
            make.centerX.equalToSuperview().offset(-33)
        }

        docs.addStandardHover()
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    lazy var actionViewButton: UIButton = {
        let obj = UIButton()
        obj.addTarget(self, action: #selector(buttonAction(sender:)), for: UIControl.Event.touchUpInside)
        return obj
    }()

    @objc
    func buttonAction(sender: UIButton) {
        self.swipeClosure()
    }
}
