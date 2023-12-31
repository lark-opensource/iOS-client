//
//  BaseFlagListTableCell.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import Foundation
import UIKit
import LarkModel
import RxSwift
import LarkContainer
import LarkUIKit
import LarkCore
import Kingfisher
import LarkFeatureGating
import LarkSDKInterface
import LKCommonsLogging
import LarkMessengerInterface
import RustPB
import LarkRichTextCore
import LarkSwipeCellKit
import LarkAI

public class BaseFlagListTableCell: SwipeTableViewCell {

    static private let logger = Logger.log(BaseFlagListTableCell.self, category: "Lark.BaseFlagListTableCell")

    class var identifier: String {
        return BaseFlagTableCellViewModel.identifier
    }

    public var disposeBag: DisposeBag = DisposeBag()

    public var dispatcher: RequestDispatcher!

    public var viewModel: BaseFlagTableCellViewModel! {
        didSet {
            self.updateCellContent()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func updateCellContent() {

    }

    public override func prepareForReuse() {
        self.disposeBag = DisposeBag()
        super.prepareForReuse()
    }

    func showEnterpriseEntityWordCard(abbres: AbbreviationInfoWrapper, query: String, chatId: String, triggerView: UIView, trigerLocation: CGPoint?) {
            let id = AbbreviationV2Processor.getAbbrId(wrapper: abbres, query: query)
            self.dispatcher?.send(ShowEnterpriseEntityWordCardMessage(abbrId: id ?? "",
                                                                      chatId: chatId,
                                                                      triggerView: triggerView,
                                                                      triggerLocation: trigerLocation))
    }
}
