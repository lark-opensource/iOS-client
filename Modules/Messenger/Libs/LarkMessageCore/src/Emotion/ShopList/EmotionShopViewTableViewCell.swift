//
//  TableViewCell.swift
//  AudioSessionScenario
//
//  Created by huangjianming on 2019/8/2.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import LarkModel
import LarkMessengerInterface
import RustPB

final class EmotionShopViewTableViewCell: EmotionShopViewBaseTableViewCell {
    public let stateView = EmotionStateView()
    var disposeBag = DisposeBag()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    override func setupSubviews() {
        super.setupSubviews()
        self.contentView.addSubview(self.stateView)
        self.backgroundColor = UIColor.ud.bgBody
        self.stateView.style = .empty
        self.stateView.snp.makeConstraints { (make) in
            make.height.greaterThanOrEqualTo(28)
            make.width.greaterThanOrEqualTo(60)
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setHasPaid(hasPaid: Bool) {
        self.stateView.setHasPaid(hasPaid: hasPaid)
    }

    public func configure(stickerSet: RustPB.Im_V1_StickerSet, state: Observable<EmotionStickerSetState>?, addBtnOn on: @escaping () -> Void) {
        self.disposeBag = DisposeBag()
        self.configure(stickerSet: stickerSet)
        if let state = state {
            self.stateView.setState(state: state)
        }
        self.stateView.addBtn.rx.tap.subscribe {( _ ) in
            on()
        }.disposed(by: disposeBag)
    }
}
