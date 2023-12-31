//
//  AllTabItemCell.swift
//  AllTabItemCell
//
//  Created by 袁平 on 2021/9/13.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkModel
import UniverseDesignTabs

/// 全部
struct AllTabItemModel: TabItemBaseModel {
    var itemType: TabItemType
    var cellType: TabItemBaseCell.Type
    var title: String
    var chatObserverable: BehaviorRelay<Chat>
}

final class AllTabItemCell: TabItemBaseCell {
    private let redPointView = UIView()
    /// 记录上一次用户已读位置的badgeCount，只有点击/处于点击态才可以更新时间
    private var readThreadPositionBadgeCount: Int32 = 0
    private var disposeBag = DisposeBag()
    private var model: AllTabItemModel?

    override var isSelected: Bool {
        didSet {
            if oldValue == isSelected { return }
            update(isSelected: isSelected)
        }
    }

    override func commonInit() {
        super.commonInit()
        redPointView.clipsToBounds = true
        redPointView.layer.cornerRadius = SegmentLayout.redDotSize / 2
        redPointView.backgroundColor = UIColor.ud.colorfulRed
        self.contentView.addSubview(redPointView)
        redPointView.snp.makeConstraints { (make) in
            make.trailing.equalTo(titleLabel).offset(SegmentLayout.redDotSize)
            make.top.equalTo(titleLabel).offset(SegmentLayout.redDotSize)
            make.width.height.equalTo(SegmentLayout.redDotSize)
        }
        self.contentView.clipsToBounds = false
    }

    override func config(model: TabItemBaseModel) {
        guard let model = model as? AllTabItemModel else { return }
        self.model = model
        // 获取用户读取位置的badgeCount
        self.readThreadPositionBadgeCount = model.chatObserverable.value.readThreadPositionBadgeCount
        // 获取该话题群最新位置的badgeCount
        let lastThreadPositionBadgeCount = model.chatObserverable.value.lastThreadPositionBadgeCount
        // 判断我有没有读完所有的消息
        if self.readThreadPositionBadgeCount >= lastThreadPositionBadgeCount {
            self.redPointView.isHidden = true
        } else {
            self.redPointView.isHidden = false
        }

        self.addObservers(model: model)
    }

    private func addObservers(model: AllTabItemModel) {
        self.disposeBag = DisposeBag()
        model.chatObserverable.observeOn(MainScheduler.instance).distinctUntilChanged({ (chat1, chat2) -> Bool in
            return (chat1.lastThreadPositionBadgeCount == chat2.lastThreadPositionBadgeCount)
                && (chat1.readThreadPositionBadgeCount == chat2.readThreadPositionBadgeCount)
        }).subscribe(onNext: { [weak self] (chat) in
            guard let `self` = self else { return }
            // 如果用户选择全部tab，默认已读了所有的话题
            if self.itemModel?.isSelected ?? false {
                self.redPointView.isHidden = true
                self.readThreadPositionBadgeCount = chat.lastThreadPositionBadgeCount
            } else {
                // 判断我有没有读完所有的消息
                if self.readThreadPositionBadgeCount >= model.chatObserverable.value.lastThreadPositionBadgeCount {
                    self.redPointView.isHidden = true
                } else {
                    self.redPointView.isHidden = false
                }
            }
        }).disposed(by: disposeBag)
    }

    private func update(isSelected: Bool) {
        guard let model = self.model else { return }
        // 如果用户选择全部tab，默认已读了所有的话题
        if isSelected {
            redPointView.isHidden = true
            self.readThreadPositionBadgeCount = model.chatObserverable.value.lastThreadPositionBadgeCount
        } else {
            // 判断我有没有读完所有的消息
            if self.readThreadPositionBadgeCount >= model.chatObserverable.value.lastThreadPositionBadgeCount {
                self.redPointView.isHidden = true
            } else {
                self.redPointView.isHidden = false
            }
        }
    }
}
