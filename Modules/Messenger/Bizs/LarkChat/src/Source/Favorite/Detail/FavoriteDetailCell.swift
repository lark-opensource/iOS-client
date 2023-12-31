//
//  FavoriteDetailCell.swift
//  LarkFavorite
//
//  Created by liuwanlin on 2018/6/14.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkContainer
import RxSwift
import LKCommonsLogging
import LarkModel
import LarkMessageCore
import LarkMessengerInterface
import LarkAI
import RustPB
import LarkRichTextCore

public class FavoriteDetailCell: UITableViewCell {
    static private let logger = Logger.log(FavoriteDetailCell.self, category: "Lark.FavoriteDetailCell")

    public class var identifier: String {
        return FavoriteCellViewModel.identifier
    }

    public var disposeBag: DisposeBag = DisposeBag()

    public var dispatcher: RequestDispatcher!

    public var viewModel: FavoriteCellViewModel! {
        didSet {
            self.updateCellContent()
        }
    }

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.setupUI()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public func setupUI() {

    }

    public func updateCellContent() {

    }

    func showEnterpriseEntityWordCard(abbres: AbbreviationInfoWrapper, query: String, chatId: String, triggerView: UIView, trigerLocation: CGPoint?) {
        FavoriteDetailCell.logger.info("FavoriteDetailCell: show ner menu",
                                       additionalData: ["cellId": FavoriteDetailCell.identifier,
                                                        "favoriteId": viewModel.favorite.id])
        var id = AbbreviationV2Processor.getAbbrId(wrapper: abbres, query: query)
        self.dispatcher?.send(ShowEnterpriseEntityWordCardMessage(abbrId: id ?? "",
                                                                  chatId: chatId,
                                                                  triggerView: triggerView,
                                                                  triggerLocation: trigerLocation))
    }
}
