//
//  SetLabelNameDocCell.swift
//  LarkSpaceKit
//
//  Created by zhangxingcheng on 2021/7/27.
//

import Foundation
import SnapKit
import LarkUIKit
import LarkModel
import RxSwift

#if MessengerMod
import LarkCore
import LarkSDKInterface
#endif

import LarkTag
import LarkFeatureGating
import LarkAvatar
import LarkBizAvatar
import UniverseDesignColor
import Swinject
import LarkContainer

class SetLabelNameDocCell: UITableViewCell {

    /**（1）doc图标*/
    private let docIcon = UIImageView()
    /**（2）标题*/
    private var titleLabel: UILabel = UILabel()
    /**（3）副标题*/
    private let subTitleLabel: UILabel = UILabel()
    /**（4）头像*/
    public let avatarImageView = BizAvatar()
    /**（5）Rx回收*/
    private let disposeBag = DisposeBag()
    #if MessengerMod
    /**（6）ChatterAPI*/
    @InjectedLazy var chatterAPI: ChatterAPI
    #endif

    /**（5）Cell数据源*/
    var docModel: SetLabelNameDocModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.backgroundColor = UDColor.bgBody

        //（1）doc图标
        self.contentView.addSubview(self.docIcon)
        self.docIcon.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.height.equalTo(35)
            make.width.equalTo(35)
            make.centerY.equalToSuperview()
        }

        //（2）标题
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.font = UIFont.systemFont(ofSize: 17)
        self.titleLabel.textColor = UDColor.textTitle
        self.titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(11)
            make.left.equalTo(self.docIcon.snp.right).offset(18.5)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(24)
        }

        //（3）副标题
        self.contentView.addSubview(self.subTitleLabel)
        self.subTitleLabel.font = UIFont.systemFont(ofSize: 14)
        self.subTitleLabel.textColor = UDColor.textPlaceholder
        self.subTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(2)
            make.left.equalTo(self.docIcon.snp.right).offset(18.5)
            make.height.equalTo(20)
        }

        //（4）头像
        self.contentView.addSubview(self.avatarImageView)
        self.avatarImageView.snp.makeConstraints { (make) in
            make.left.equalTo(self.subTitleLabel.snp.right).offset(4)
            make.height.equalTo(16)
            make.width.equalTo(16)
            make.centerY.equalTo(self.subTitleLabel)
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setCellModel(_ docModel: SetLabelNameDocModel, _ chat: Chat) {
        #if MessengerMod
        self.docModel = docModel
        //（1）doc图标
        let defaultIcon = LarkCoreUtils.docIcon(docType: docModel.sendDocModel.docType, fileName: docModel.sendDocModel.title)
        self.docIcon.image = defaultIcon
        //（2）主标题
        let title = docModel.sendDocModel.title.isEmpty ? BundleI18n.CCMMod.Lark_Legacy_DefaultName : docModel.sendDocModel.title
        var titleAttributed = NSAttributedString(string: title)
        titleAttributed = SearchResult.attributedText(attributedString: titleAttributed,
                                                      withHitTerms: docModel.sendDocModel.titleHitTerms,
                                                          highlightColor: UDColor.primaryContentDefault)
        let mutTitleAttributed = NSMutableAttributedString(attributedString: titleAttributed)
        mutTitleAttributed.addAttribute(.font,
                                        value: UIFont.systemFont(ofSize: 17),
                                        range: NSRange(location: 0, length: titleAttributed.length))
        self.titleLabel.attributedText = mutTitleAttributed

        //（3）副标题
        self.subTitleLabel.text = "\(BundleI18n.CCMMod.Lark_Legacy_SendDocDocOwner)\(BundleI18n.CCMMod.Lark_Legacy_Colon)\(docModel.sendDocModel.ownerName)"
        //（4）头像
        var chatterOb: Observable<LarkModel.Chatter?>
        chatterOb = self.chatterAPI.getChatter(id: docModel.sendDocModel.ownerID, forceRemoteData: false)
        chatterOb.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] response in
            self?.avatarImageView.setAvatarByIdentifier(docModel.sendDocModel.ownerID, avatarKey: response?.avatarKey ?? "", avatarViewParams: .init(sizeType: .size(16)))
        }).disposed(by: disposeBag)
        #endif
    }
}
