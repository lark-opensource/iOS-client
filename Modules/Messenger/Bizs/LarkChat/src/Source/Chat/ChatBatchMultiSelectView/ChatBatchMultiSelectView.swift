//
//  ChatBatchMultiSelectView.swift
//  LarkChat
//
//  Created by 赵家琛 on 2021/3/2.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkMessageCore
import RxSwift
import RxCocoa
import Homeric
import LKCommonsTracker

protocol ChatBatchMultiSelectViewDelegate: AnyObject {
    func clickBatchSelect(centerPoint: CGPoint)
}

final class ChatBatchMultiSelectView: UIView {
    private let leftLine: UIView = {
        let leftLine = UIView()
        leftLine.backgroundColor = UIColor.ud.lineBorderComponent
        return leftLine
    }()

    private let rightLine: UIView = {
        let rightLine = UIView()
        rightLine.backgroundColor = UIColor.ud.lineBorderComponent
        return rightLine
    }()

    private let batchMultiSelectControl: BatchMultiSelectControl = {
        let batchMultiSelectControl = BatchMultiSelectControl()
        batchMultiSelectControl.layer.borderWidth = 1
        batchMultiSelectControl.layer.cornerRadius = 8
        batchMultiSelectControl.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        return batchMultiSelectControl
    }()

    weak var delegate: ChatBatchMultiSelectViewDelegate?
    private let disposeBag = DisposeBag()

    init(chatPageAPI: ChatPageAPI, chatMessageViewModel: ChatMessagesViewModel, chatTableView: ChatTableView) {
        super.init(frame: .zero)

        self.isHidden = true
        self.backgroundColor = .clear
        self.addSubview(leftLine)
        self.addSubview(batchMultiSelectControl)
        self.addSubview(rightLine)
        leftLine.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(16)
            make.width.equalTo(36)
            make.height.equalTo(1)
            make.centerY.equalToSuperview()
        }
        batchMultiSelectControl.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(leftLine.snp.right)
        }
        rightLine.snp.makeConstraints { (make) in
            make.left.equalTo(batchMultiSelectControl.snp.right)
            make.height.equalTo(1)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
        }

        Driver.combineLatest(chatPageAPI.inSelectMode.asDriver(onErrorJustReturn: false),
                             chatMessageViewModel.tableRefreshDriver)
            .drive(onNext: { [weak self, weak chatTableView, weak chatMessageViewModel] (inSelectMode, _) in
                guard let self = self,
                      let chatTableView = chatTableView,
                      let chatMessageViewModel = chatMessageViewModel else { return }

                if !inSelectMode {
                    self.isHidden = true
                    return
                }
                /// MyAI场景不展示：有thread平铺展示，逻辑走不通
                if chatMessageViewModel.chat.isP2PAi {
                    self.isHidden = true
                    return
                }
                /// 消息列表超一屏时展示按钮
                if chatTableView.contentSize.height + chatTableView.contentInset.bottom + chatTableView.contentInset.top > chatTableView.bounds.height {
                    self.isHidden = false
                    return
                }
                /// 可选择消息数量 >= 5 时展示按钮
                if chatMessageViewModel.uiDataSource.compactMap({ $0 as? ChatMessageCellViewModel }).filter({ $0.showCheckBox }).count >= 5 {
                    self.isHidden = false
                    return
                }
                self.isHidden = true
            }).disposed(by: self.disposeBag)

        self.batchMultiSelectControl
            .rx.controlEvent(.touchUpInside)
            .asDriver()
            .throttle(RxTimeInterval.seconds(1), latest: false)
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.delegate?.clickBatchSelect(centerPoint: self.center)
                Tracker.post(TeaEvent(Homeric.MULTISELECT_FOLLOWINGMESSAGE_CLICK))
            }).disposed(by: self.disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if hitView == self { return nil }
        return hitView
    }
}

final class BatchMultiSelectControl: UIControl {
    private lazy var tipLabel: UILabel = {
        let tipLabel = UILabel()
        tipLabel.textColor = UIColor.ud.textTitle
        tipLabel.text = BundleI18n.LarkChat.Lark_Chat_SelectFollowingMessages
        tipLabel.font = UIFont.systemFont(ofSize: 14)
        tipLabel.textAlignment = .center
        return tipLabel
    }()

    override var isHighlighted: Bool {
        didSet {
            self.backgroundColor = isHighlighted ? UIColor.ud.N200 : UIColor.ud.N00
        }
    }

    init() {
        super.init(frame: .zero)

        self.backgroundColor = UIColor.ud.N00
        self.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(8)
            make.top.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
