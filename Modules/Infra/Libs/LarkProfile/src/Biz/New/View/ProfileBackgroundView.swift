//
//  ProfileBackgroundView.swift
//  LarkProfile
//
//  Created by Yuri on 2022/8/17.
//

import Foundation
import ByteWebImage
import RustPB
import UIKit

final class ProfileBackgroundView: UIImageView {
    
    var backgroundView = UIImageView()
    var didMedalTapHandler: (() -> Void)?
    
    lazy var medalView: NewMedalStackView = {
        let medalView = NewMedalStackView()
        self.medalView = medalView

        medalView.tapCallback = { [weak self] in
            self?.didMedalTapHandler?()
        }
        return medalView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        backgroundView.isUserInteractionEnabled = true
        backgroundView.contentMode = .scaleAspectFill
        backgroundView.ud.setMaskView()
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private var imageKey: String?
    private var fsUnit: String?
    func update(imageKey: String, fsUnit: String?, placeholder: UIImage?) {
        if self.imageKey == imageKey && self.fsUnit == fsUnit { return } // 去重
        self.imageKey = imageKey
        self.fsUnit = fsUnit
        var passThrough = ImagePassThrough()
        let key = getProfileKey(imageKey, sizeType: .middle)
        passThrough.key = key
        passThrough.fsUnit = fsUnit
        passThrough.fileType = .profileTopImage

        backgroundView.bt.setLarkImage(with: .default(key: key),
                                  placeholder: placeholder,
                                  passThrough: passThrough,
                                  trackStart: {
                                    return TrackInfo(scene: .Profile, fromType: .avatar)
                                  })
    }
    
    func updateMedal(showSwitch: Bool, userInfo: UserInfoProtocol, isSelf: Bool,
                     moreIcon: UIImage?, pushIcon: UIImage?, title: String?) {
        guard showSwitch else {
            return
        }
        backgroundView.addSubview(medalView)
        medalView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-16)
            make.height.equalTo(28)
        }
        medalView.moreImageView.image = moreIcon
        medalView.pushView.image = pushIcon
        
        medalView.isHidden = !userInfo.avatarMedal.showSwitch

        let count = Int(userInfo.medalList.totalNum)
        // swiftlint:disable empty_count
        if count == 0,
           userInfo.medalList.medalMeta.isEmpty,
            isSelf {
            medalView.setTitle(title ?? "")
        } else {
            medalView.setMedals(userInfo.medalList.medalMeta, count: count)
        }
        backgroundView.layoutIfNeeded()
    }
    
    
    private func getProfileKey(_ key: String, sizeType: ProfileImageSizeType? = nil) -> String {
        if let type = sizeType {
            return key + "_" + type.rawValue.uppercased()
        }
        return key
    }
}
