//
//  FilePinConfirmView.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/29.
//

import UIKit
import Foundation
import LarkMessageCore
import LarkContainer
import LarkAccountInterface
import LarkModel
import LarkCore
import LarkMessengerInterface

final class FileAndFolderPinConfirmView: PinConfirmContainerView, UserResolverWrapper {
    let userResolver: UserResolver
    @ScopedInjectedLazy var chatSecurityControlService: ChatSecurityControlService?
    var icon: UIImageView
    var title: UILabel
    var sizeAndPermission: UILabel
    // 局域网传输icon
    private lazy var lanTransIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.clear
        imageView.image = Resources.lan_Trans_Icon
        return imageView
    }()

    init(userResolver: UserResolver, frame: CGRect) {
        self.userResolver = userResolver
        self.icon = UIImageView(frame: .zero)
        self.icon.contentMode = .scaleAspectFit
        self.title = UILabel(frame: .zero)
        title.font = UIFont.systemFont(ofSize: 16)
        title.textColor = UIColor.ud.N900
        title.numberOfLines = 1
        self.sizeAndPermission = UILabel(frame: .zero)
        sizeAndPermission.font = UIFont.systemFont(ofSize: 12)
        sizeAndPermission.textColor = UIColor.ud.N500
        sizeAndPermission.numberOfLines = 0
        super.init(frame: frame)
        self.addSubview(icon)
        self.addSubview(title)
        self.addSubview(sizeAndPermission)
        self.addSubview(lanTransIcon)
        icon.snp.makeConstraints { (make) in
            make.left.top.equalTo(BubbleLayout.commonInset.left)
            make.width.equalTo(48)
            make.height.equalTo(48)
            make.bottom.equalTo(self.nameLabel.snp.top).offset(-BubbleLayout.commonInset.bottom)
        }
        lanTransIcon.snp.makeConstraints { (make) in
            make.right.equalTo(icon.snp.right).offset(9)
            make.bottom.equalTo(icon.snp.bottom).offset(7)
            make.size.equalTo(24)
        }
        lanTransIcon.isHidden = true
        title.snp.makeConstraints { (make) in
            make.top.equalTo(icon)
            make.left.equalTo(icon.snp.right).offset(8)
            make.right.lessThanOrEqualToSuperview().offset(-BubbleLayout.commonInset.right)
        }
        sizeAndPermission.snp.makeConstraints { (make) in
            make.top.equalTo(title.snp.bottom).offset(8)
            make.left.equalTo(title)
            make.right.lessThanOrEqualToSuperview().offset(-BubbleLayout.commonInset.right)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setPinConfirmContentView(_ contentVM: PinAlertViewModel) {
        super.setPinConfirmContentView(contentVM)

        guard let fileContentVM = contentVM as? FileAndFolderPinConfirmViewModel else {
            return
        }
        icon.image = fileContentVM.icon
        title.text = fileContentVM.name
        var authorityAllowed = fileContentVM.hasPermissionPreview && fileContentVM.dynamicAuthorityEnum.authorityAllowed
        title.textColor = authorityAllowed ? UIColor.ud.N900 : .ud.textPlaceholder
        sizeAndPermission.textColor = authorityAllowed ? UIColor.ud.N500 : .ud.textPlaceholder
        if !authorityAllowed {
            sizeAndPermission.text = ChatSecurityControlServiceImpl.getNoPermissionSummaryText(permissionPreview: fileContentVM.hasPermissionPreview,
                                                                                               dynamicAuthorityEnum: fileContentVM.dynamicAuthorityEnum,
                                                                                               sourceType: .file)
            lanTransIcon.isHidden = true
            return
        }
        sizeAndPermission.text = fileContentVM.size
        lanTransIcon.isHidden = !fileContentVM.isLan
    }
}

final class FileAndFolderPinConfirmViewModel: PinAlertViewModel, UserResolverWrapper {
    let userResolver: UserResolver
    let hasPermissionPreview: Bool
    let dynamicAuthorityEnum: DynamicAuthorityEnum
    var name: String {
        if let fileContent = message.content as? FileContent {
            return fileContent.name
        }
        if let folderContent = message.content as? FolderContent {
            return folderContent.name
        }
        return ""
    }

    var currentId: String { userResolver.userID }

    var size: String {
        // 局域网文件/文件夹显示特定的文案
        if isLan {
            return message.isMeSend(userId: currentId) ? BundleI18n.LarkChat.Lark_Message_file_lan_sendreceived :
                BundleI18n.LarkChat.Lark_Message_file_lan_mobilereceived
        }
        if let fileContent = message.content as? FileContent {
            let size = ByteCountFormatter.string(
                fromByteCount: fileContent.size,
                countStyle: .binary
            )
            return "\(size)"
        }
        if let folderContent = message.content as? FolderContent {
            let size = ByteCountFormatter.string(
                fromByteCount: folderContent.size,
                countStyle: .binary
            )
            return "\(size)"
        }
        return ""
    }

    public var icon: UIImage {
        if let fileContent = message.content as? FileContent {
            return LarkCoreUtils.fileLadderIcon(with: fileContent.name)
        }
        return Resources.icon_folder_message
    }

    // 是否是局域网文件/文件夹
    var isLan: Bool {
        if let fileContent = message.content as? FileContent {
            return fileContent.fileSource == .lanTrans
        }
        if let folderContent = message.content as? FolderContent {
            return folderContent.fileSource == .lanTrans
        }
        return false
    }

    init?(userResolver: UserResolver, fileMessage: Message, getSenderName: @escaping (Chatter) -> String, hasPermissionPreview: Bool, dynamicAuthorityEnum: DynamicAuthorityEnum) {
        guard fileMessage.type == .file || fileMessage.type == .folder else { return nil }
        self.userResolver = userResolver
        self.hasPermissionPreview = hasPermissionPreview
        self.dynamicAuthorityEnum = dynamicAuthorityEnum
        super.init(message: fileMessage, getSenderName: getSenderName)
    }
}
