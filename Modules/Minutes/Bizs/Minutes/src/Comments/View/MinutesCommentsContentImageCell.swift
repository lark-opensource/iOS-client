//
//  MinutesCommentsContentImageCell.swift
//  Minutes
//
//  Created by ByteDance on 2023/10/31.
//

import Foundation
import MinutesFoundation
import ByteWebImage
import RustPB
import MinutesNetwork

class MinutesCommentsContentImageCell: UICollectionViewCell {
    var viewModel : ContentForIMItem?
    lazy var imageView: UIImageView = {
        let img = UIImageView()
        img.layer.masksToBounds = true
        img.contentMode = .scaleAspectFit
        return img
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }
    func update() {
        guard let key = viewModel?.attr?.thumbnail?.key ?? viewModel?.attr?.origin?.key else { return }
        let fsUnit = viewModel?.attr?.thumbnail?.fsUnit ?? viewModel?.attr?.origin?.fsUnit
        var passThrough = ImagePassThrough()
        passThrough.key = key
        passThrough.fsUnit = fsUnit
        
        let crypto = viewModel?.attr?.crypto
        if crypto != nil && crypto?.type ?? 0 > 0 {
            guard let secretStr = viewModel?.attr?.crypto?.cipher.secret else { return }
            guard let nonceStr = viewModel?.attr?.crypto?.cipher.nonce else { return }
            var cipher = ImagePassThrough.SerCrypto.Cipher()
            cipher.secret = Data(base64Encoded: secretStr) ?? Data()
            cipher.nonce = Data(base64Encoded: nonceStr) ?? Data()
            var sec = ImagePassThrough.SerCrypto()
            sec.cipher = cipher
            sec.type = ImagePassThrough.SerCrypto.TypeEnum(rawValue:Int(crypto?.type ?? 0))
            passThrough.crypto = sec
        }
        let resource: LarkImageResource = .rustImage(key: key, fsUnit: fsUnit)
        imageView.bt.setLarkImage(resource, placeholder: nil, passThrough: passThrough)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
