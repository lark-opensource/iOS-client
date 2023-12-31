//
//  FavoriteListCell.swift
//  Lark
//
//  Created by lichen on 2018/6/4.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkModel
import RxSwift
import LarkContainer
import LarkUIKit
import LarkCore
import Kingfisher
import RxCocoa
import LarkMessageCore
import LarkFeatureGating
import LarkSDKInterface
import LKCommonsLogging
import LarkMessengerInterface
import LarkAI
import RustPB
import LarkRichTextCore

public typealias CheckIsMe = (_ userId: String) -> Bool

public protocol FavoriteDataProvider: UserResolverWrapper {
    var checkIsMe: CheckIsMe { get }
    var audioPlayer: AudioPlayMediator { get }
    var favoriteAPI: FavoritesAPI { get }
    var deleteFavoritesPush: Observable<[String]> { get }
    var refreshObserver: PublishSubject<Void> { get }
    var audioResourceService: AudioResourceService { get }
    var is24HourTime: Driver<Bool> { get }
    var abbreviationEnable: Bool { get }
    var inlinePreviewVM: MessageInlineViewModel { get }
}

public class FavoriteListCell: BaseTableViewCell {

    enum Cons {
        static var sourceFont: UIFont { UIFont.ud.caption1 }
        static var timeFont: UIFont { UIFont.ud.caption1 }
    }

    static private let logger = Logger.log(FavoriteListCell.self, category: "Lark.FavoriteListCell")

    class var identifier: String {
        return FavoriteCellViewModel.identifier
    }

    public var disposeBag: DisposeBag = DisposeBag()

    public var dispatcher: RequestDispatcher!

    public var viewModel: FavoriteCellViewModel! {
        didSet {
            self.updateCellContent()
        }
    }

    public let contentInset: CGFloat = 16

    public var bubbleContentMaxWidth: CGFloat
    public var contentWraper: UIView = UIView()
    public lazy var sourceLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = Cons.sourceFont
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .left
        return label
    }()
    public lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = Cons.timeFont
        return label
    }()

    public lazy var riskTip: UIView = {
        let view = FileNotSafeTipView()
        view.isHidden = true
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.bubbleContentMaxWidth = UIScreen.main.bounds.width - 2 * self.contentInset
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func prepareForReuse() {
        self.disposeBag = DisposeBag()
        super.prepareForReuse()
    }

    public func setupUI() {
        self.backgroundColor = UIColor.clear

        self.contentView.addSubview(self.contentWraper)
        self.contentWraper.snp.makeConstraints { (make) in
            make.left.top.equalToSuperview().offset(contentInset)
            make.right.equalToSuperview().offset(-contentInset)
        }
        self.contentView.addSubview(self.riskTip)
        self.riskTip.snp.makeConstraints { make in
            make.top.equalTo(contentWraper.snp.bottom).offset(4)
            make.left.equalToSuperview().offset(contentInset)
            make.right.equalToSuperview().offset(-contentInset)
        }
        self.contentView.addSubview(self.sourceLabel)
        self.sourceLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.contentWraper.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(contentInset)
            make.bottom.equalToSuperview().offset(-contentInset)
        }
        self.sourceLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        self.contentView.addSubview(self.timeLabel)
        self.timeLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-contentInset)
            make.left.greaterThanOrEqualTo(sourceLabel.snp.right).offset(10)
            make.centerY.equalTo(sourceLabel.snp.centerY)
        }

        self.lu.addBottomBorder(color: UIColor.ud.lineDividerDefault)

        self.lu.addLongPressGestureRecognizer(action: #selector(longPressHandle(_:)), duration: 1)
    }

    private func updateRiskState(_ viewModel: FavoriteCellViewModel) {
        if viewModel.isRisk {
            self.sourceLabel.snp.remakeConstraints { make in
                make.top.equalTo(self.riskTip.snp.bottom).offset(6)
                make.left.equalToSuperview().offset(contentInset)
                make.bottom.equalToSuperview().offset(-contentInset)
            }
            self.riskTip.isHidden = false
        } else {
            self.sourceLabel.snp.remakeConstraints { make in
                make.top.equalTo(self.contentWraper.snp.bottom).offset(12)
                make.left.equalToSuperview().offset(contentInset)
                make.bottom.equalToSuperview().offset(-contentInset)
            }
            self.riskTip.isHidden = true
        }
    }

    public func updateCellContent() {
        self.timeLabel.text = self.viewModel.shortTime
        self.sourceLabel.text = self.viewModel.source
        if sourceLabel.superview != nil, riskTip.superview != nil {
            self.updateRiskState(viewModel)
        }
    }

    @objc
    func longPressHandle(_ gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            let location = gesture.location(in: self)
            self.dispatcher.send(FavoriteLongPressActionMessage(viewModel: self.viewModel, triggerView: self, triggerLocation: location))
        }
    }

    func willDisplay() {}
    func didEndDisplay() {}

    func showEnterpriseEntityWordCard(abbres: AbbreviationInfoWrapper, query: String, chatId: String, triggerView: UIView, trigerLocation: CGPoint?) {
        FavoriteListCell.logger.info("FavoriteListCell: showEnterpriseEntityWordCard",
                                     additionalData: ["cellId": FavoriteListCell.identifier,
                                                      "favoriteId": viewModel.favorite.id])
        var id = AbbreviationV2Processor.getAbbrId(wrapper: abbres, query: query)
        self.dispatcher?.send(ShowEnterpriseEntityWordCardMessage(abbrId: id ?? "",
                                                                  chatId: chatId,
                                                                  triggerView: triggerView,
                                                                  triggerLocation: trigerLocation))
    }
}
