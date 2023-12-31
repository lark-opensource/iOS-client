//
//  ListCellSyncStatusSubTitle.swift
//  SKECM
//
//  Created by bupozhuang on 2020/8/3.
//

import UIKit
import SKCommon

class ListCellSyncStatusSubTitle: UIView {
    lazy var statusView: SyncStatusView = {
        let view = SyncStatusView()
        view.isHidden = true
        return view
    }()
    lazy var subTitle: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.docs.pfsc(14)
        label.textColor = UIColor.ud.N500
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(subTitle)
        addSubview(statusView)
        
        statusView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 0.0, height: 12))
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
        }
        subTitle.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(statusView.snp.right).offset(0)
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configSyncStatusAndSubTitle(syncConfig: SpaceEntry.SyncUIConfig, showSubTitle: Bool, subTitleString: String?) {
        // 下面是设置 同步状态图片和subTitle的
        subTitle.isHidden = !showSubTitle
        if syncConfig.show {
            // 展示同步状态
            statusView.image = syncConfig.image
            subTitle.text = syncConfig.title
            resetStatusAndSubtitleConstaints(statusIsHidden: false)
            if syncConfig.isSyncing {
                statusView.startRotation()
            } else {
                statusView.stopRotation()
            }
        } else {
            // 不展示同步状态
            subTitle.text = subTitleString
            resetStatusAndSubtitleConstaints(statusIsHidden: true)
            statusView.stopRotation()
        }
    }
    
    private func resetStatusAndSubtitleConstaints(statusIsHidden: Bool) {
        guard statusView.isHidden != statusIsHidden else { return }
        statusView.isHidden = statusIsHidden
        let statusImageViewWidth: CGFloat = statusIsHidden ? 0.0 : 12.0
        let offSet = statusIsHidden ? 0.0 : 4.0
        subTitle.snp.updateConstraints { (make) in
            make.left.equalTo(statusView.snp.right).offset(offSet)
        }
        statusView.snp.updateConstraints { (make) in
            make.size.equalTo(CGSize(width: statusImageViewWidth, height: 12.0))
        }
    }



}
