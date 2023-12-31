//
//  CommentTableViewCell.swift
//  SpaceKit
//
//  Created by xurunkang on 2018/10/30.
//

import UIKit
import RxSwift
import RxCocoa
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignLoading

class CommentTableViewCellV2: CommentTableViewCell {

    static var cellId = "CommentTableViewCellV2"
    // 背景白板
    private(set) lazy var bgView: UIView = _setupBgView()


    
    override var avatarImagWidth: CGFloat {
        return 24.0
    }
    
    override var titleLeftMargin: CGFloat {
        return 12.0
    }
    
    override var reactionBottomMargin: CGFloat {
        return 12.0
    }
    
    override var cellVersion: CommentCellVersion {
        return .v2
    }

    override var fontLineSpace: CGFloat? {
        return 2
    }

    override var timeLabelColor: UIColor {
        return UIColor.ud.N600
    }

    override var emptySpaceForContent: CGFloat {
        return CGFloat(leftRightPadding * 2)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(statusBarOrientationChange),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentLabel.preferredMaxLayoutWidth = self.contentView.frame.size.width - leftRightPadding * 2
    }

    @objc
    func statusBarOrientationChange() {
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
            self.updateReactionViewMaxWidth()
        }
    }

    override func setupUI() {
        contentView.addSubview(bgView)
        super.setupUI()
        translationLoadingView.isHidden = true
        avatarImageView.layer.cornerRadius = avatarImagWidth / 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) {
            self.updateReactionViewMaxWidth()
        }
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        loadingView.layer.cornerRadius = bgView.layer.cornerRadius
    }

    override func setupConstraints() {
        super.setupConstraints()
        bgView.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-3)
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(3)
        }
        
        contentLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(avatarImageView.snp.bottom).offset(4.5)
            make.left.equalToSuperview().offset(leftRightPadding)
            make.right.lessThanOrEqualToSuperview().offset(-leftRightPadding)
        }
        
        errorMaskView.snp.remakeConstraints { make in
            make.right.equalToSuperview()
            make.left.equalTo(contentLabel)
            make.top.equalTo(avatarImageView.snp.bottom)
            make.bottom.equalTo(reactionView)
        }
    }



    override func reactionMaxLayoutWidth(_ cellWidth: CGFloat) -> CGFloat {
        return CGFloat(cellWidth - leftRightPadding * 2)
    }

}

/// 评论定位高亮动画执行者
protocol CommentHighLightAnimationPerformer: AnyObject {
    
    func setBgViewColor(color: UIColor)
}

extension CommentTableViewCellV2: CommentHighLightAnimationPerformer {

    func setBgViewColor(color: UIColor) {
        let bgColorView = self.bgView.viewWithTag(999)
        bgColorView?.backgroundColor = color
    }

}
