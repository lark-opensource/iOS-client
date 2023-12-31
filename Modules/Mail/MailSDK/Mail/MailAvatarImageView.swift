//
//  MailAvatarImageView.swift
//  MailSDK
//
//  Created by 谭志远 on 2019/6/23.
//

import Foundation
import UIKit
import LarkUIKit
import Kingfisher
import RxSwift
import UniverseDesignTheme

class MailAvatarImageView: LastingColorView {
    override var lastingColor: UIColor {
        didSet {
            setNeedsDisplay()
        }
    }

    var setImageTask: SetImageTask?
    var dafaultBackgroundColor = UIColor.ud.N50 {
        didSet {
            self.lastingColor = dafaultBackgroundColor
            self.backgroundColor = dafaultBackgroundColor
        }
    }

    private let disposeBag = DisposeBag()

    lazy private(set) var imageView: UIImageView = {
        var imageView = UIImageView(image: nil)
        imageView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        imageView.contentMode = .scaleAspectFill
        imageView.ud.setMaskView()
        return imageView
    }()
    
    static let placeHolderImage: UIImage? = I18n.image(named: "avatar_placeholder")

    lazy private(set) var letterLabel: UILabel = {
        var letterLabel = UILabel()
        letterLabel.font = UIFont.systemFont(ofSize: 17)
        letterLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        letterLabel.textAlignment = .center
        return letterLabel
    }()

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        self.lastingColor = dafaultBackgroundColor
        self.backgroundColor = dafaultBackgroundColor
        self.clipsToBounds = true
        self.addSubview(self.imageView)
        self.addSubview(self.letterLabel)
        self.imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.letterLabel.isHidden = true
        self.letterLabel.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    

    func loadAvatar(name: String = "", avatarKey: String = "", entityId: String = "", setBackground: Bool = false, completion: CompletionCallback? = nil) {
        letterLabel.isHidden = true
        imageView.isHidden = false
        imageView.image = MailAvatarImageView.placeHolderImage
        lastingColor = dafaultBackgroundColor
        if setBackground {
            backgroundColor = lastingColor
        }

        if !avatarKey.isEmpty && !entityId.isEmpty {
            set(name: name, avatarKey: avatarKey, entityId: entityId, setBackground: setBackground, completion: completion)
        } else if !entityId.isEmpty {
            let avatarKey = MailModelManager.shared.getAvatarKey(userid: entityId)
            if !avatarKey.isEmpty {
                set(name: name, avatarKey: avatarKey, entityId: entityId, setBackground: setBackground, completion: completion)
            } else {
                MailModelManager
                    .shared
                    .getUserAvatarKey(userId: entityId)
                    .subscribe { [weak self] (avatarKey) in
                        guard !avatarKey.isEmpty else {
                            self?.setAvatar(with: name, setBackground: setBackground)
                            return
                        }
                        self?.set(name: name, avatarKey: avatarKey, entityId: entityId, setBackground: setBackground, completion: completion)
                    } onError: { [weak self] (error) in
                        // 用首字母显示
                        self?.setAvatar(with: name, setBackground: setBackground)
                        MailLogger.debug("MailAvatarImageView load avatarKey Fail: \(error)")
                        completion?(nil, error)
                    }.disposed(by: disposeBag)
            }
        } else {
            setAvatar(with: name, setBackground: setBackground)
        }
    }

    func set(name: String = "", avatarKey: String = "", entityId: String = "", image: UIImage? = nil, setBackground: Bool = false, completion: CompletionCallback? = nil) {
        letterLabel.isHidden = true
        imageView.isHidden = false
        lastingColor = dafaultBackgroundColor
        guard !avatarKey.isEmpty else {
            self.imageView.image = image
            return
        }
        // TODO: 部分接口返回中rust没有处理好avatarKey,此处做容错，待rust修正后去除
        var fixedKey = avatarKey.replacingOccurrences(of: "lark.avatar/", with: "")
        fixedKey = fixedKey.replacingOccurrences(of: "mosaic-legacy/", with: "")
        if let task = setImageTask {
            task.cancel()
        }
        setImageTask = ProviderManager.default.imageProvider?.setAvatar(self.imageView,
                                                                        key: fixedKey,
                                                                        entityId: entityId,
                                                                        avatarImageParams: nil,
                                                                        placeholder: MailAvatarImageView.placeHolderImage,
                                                                        progress: nil,
                                                                        completion: { [weak self] (img, error) in
                                                                            if error != nil && name.count > 0 {
                                                                                // cant load avatar, fallback to initial with background
                                                                                self?.setAvatar(with: name, setBackground: setBackground)
                                                                            }
                                                                            completion?(img, error)
                                                                        })

    }

    /// 设Avatar
    /// - Parameters:
    ///   - name: 名字
    ///   - setBackground: 是否设backgroundColor，读信NativeCoponment中设lastingColor, 颜色不生效，需要设置backgroundColor，避免影响其他地方调用
    func setAvatar(with name: String, setBackground: Bool = false) {
        letterLabel.isHidden = false
        imageView.isHidden = true
        let letter = String(name.prefix(1).uppercased())
        letterLabel.text = letter
        self.lastingColor = getRGBValue(key: name.trimmingCharacters(in: .whitespacesAndNewlines))
        if setBackground {
            backgroundColor = lastingColor
        }
    }

    static let colorList: [UIColor] = [
        UIColor.ud.colorfulBlue,
        UIColor.ud.colorfulWathet,
        UIColor.ud.colorfulOrange,
        UIColor.ud.colorfulRed,
        UIColor.ud.colorfulViolet,
        UIColor.ud.colorfulIndigo,
        UIColor.ud.colorfulLime
    ]

    private func getRGBValue(key: String) -> UIColor {
        let length = key.unicodeScalars.map({ $0.value }).reduce(0, { $0 + Int($1) })
        let index = length % MailAvatarImageView.colorList.count
        if index < MailAvatarImageView.colorList.count {
            return MailAvatarImageView.colorList[Int(index)]
        } else {
            return UIColor.btd_color(withHexString: "#EFF0F1")
        }
    }
}
