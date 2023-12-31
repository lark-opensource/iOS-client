//
//  EmotionShopViewBaseTableViewCell.swift
//  LarkUIKit
//
//  Created by huangjianming on 2019/8/13.
//

import UIKit
import Foundation
import SnapKit
import LarkModel
import RustPB
import ByteWebImage

class EmotionShopViewBaseTableViewCell: UITableViewCell {
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.N900
        return titleLabel
    }()

    lazy var subTitleLabel: UILabel = {
        let subTitleLabel = UILabel()
        subTitleLabel.font = .systemFont(ofSize: 14)
        subTitleLabel.textColor = UIColor.ud.N500
        return subTitleLabel
    }()

    lazy var lineView: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.N300
        return line
    }()

    var pics = [UIImageView]()
    let picsContainer = UIView()
    private var speratorstyle: EmotionShopCellSperatorlineStyle = .full

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(stickerSet: RustPB.Im_V1_StickerSet) {
        self.titleLabel.text = stickerSet.title
        self.subTitleLabel.text = stickerSet.description_p

        //先把所有图片隐藏,再把有值的图片显示
        self.hiddenAllPics()
        for (idx, sticker) in stickerSet.stickers.prefix(4).enumerated() {
            guard idx < pics.count else { break }
            let pic = pics[idx]
            pic.isHidden = false
            pic.bt.setLarkImage(with: .sticker(key: sticker.image.thumbnail.key,
                                               stickerSetID: sticker.stickerSetID),
                                placeholder: BundleResources.emotionPlaceholderIcon,
                                trackStart: {
                                    return TrackInfo(scene: .Chat, fromType: .sticker)
                                })
        }
    }

    func setupSubviews() {
        //titleLabel
        self.contentView.addSubview(titleLabel)
        //subTitleLabel
        self.contentView.addSubview(subTitleLabel)
        //separatorLine, add to self due to appear normally in editting mode
        self.addSubview(lineView)
        lineView.frame = CGRect(x: 0, y: 0, width: self.contentView.frame.size.width, height: 0.5)

        //图片
        setupPics()
        layout()
    }

    enum EmotionShopCellSperatorlineStyle {
        case full
        case half
    }

    func setSperatorlineStyle(style: EmotionShopCellSperatorlineStyle) {
        self.speratorstyle = style
        switch style {
        case .full:
            self.lineView.snp.updateConstraints { (make) in
                make.left.equalToSuperview()
            }
        case .half:
            self.lineView.snp.updateConstraints { (make) in
                make.left.equalTo(16)
            }
        }
    }

    //设置4个图片
   private func setupPics() {
        let picCount = 4
        for _ in 1...picCount {
            let pic = UIImageView()
            pic.contentMode = .scaleAspectFit
            self.contentView.addSubview(pic)
            self.pics.append(pic)
        }
    }

    private func hiddenAllPics() {
        for pic in self.pics {
            pic.isHidden = true
        }
    }

    private func layout() {
        self.titleLabel.snp.makeConstraints({ (make) in
            make.left.equalTo(16)
            make.top.equalTo(12)
            make.right.equalTo(-80)
        })

        self.subTitleLabel.snp.makeConstraints({ (make) in
            make.left.equalTo(16)
            make.top.equalTo(38)
            make.right.equalTo(-100)
        })

        self.lineView.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.bottom.right.equalToSuperview()
            make.height.equalTo(0.5)
        }

        for (idx, pic) in self.pics.enumerated() {
            pic.snp.makeConstraints { (make) in
                make.left.equalTo(52 * idx + 16)
                make.width.height.equalTo(40)
                make.bottom.equalTo(-12)
            }
        }
    }

}
