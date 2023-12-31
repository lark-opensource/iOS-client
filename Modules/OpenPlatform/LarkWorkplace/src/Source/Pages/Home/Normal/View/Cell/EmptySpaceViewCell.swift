//
//  EmptySpaceViewCell.swift
//  LarkWorkplace
//
//  Created by lilun.ios on 2020/7/16.
//

import UIKit
import RxSwift
import LarkSceneManager
import LarkWorkplaceModel

final class EmptySpaceViewCell: UICollectionViewCell {
}

final class FillEmptySpaceCell: UICollectionViewCell {
}

protocol WorkPlaceCellExposeProtocol {
    /// 唯一标识
    var exposeId: String { get }

    /// cell 曝光时触发
    func didExpose()
}

class WorkplaceBaseCell: UICollectionViewCell, BadgeUpdateProtocol {
    var disposeBag: DisposeBag = DisposeBag()
    /// badgekey
    var badgeKey: WorkPlaceBadgeKey? {
        didSet {
            self.onBadgeUpdate()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        observeBadgeUpdate()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        unObserveBadgeUpdate()
    }
    func onBadgeUpdate() {
    }
    ///
    /// 用于返回 cell 拖拽手势
    ///
    func supportDragScene() -> Scene? {
        return nil
    }
    var workplaceItem: WPAppItem?
}
