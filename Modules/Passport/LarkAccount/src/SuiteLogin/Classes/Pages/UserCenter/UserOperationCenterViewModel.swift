//
//  UserOperationCenterViewModel.swift
//  LarkAccount
//
//  Created by bytedance on 2021/6/11.
//

import Foundation
import Homeric
import RxSwift
import LarkContainer
import LKCommonsLogging
import ByteWebImage
import LarkReleaseConfig

struct OperationButton {
    let icon: UIImage
    let title: String
    let action: () -> Observable<Void>
}

struct OfficialEmailItem {
    var emailSuffix: String
    var tenantItems: [V4ResponseTenant]

    init(emailSuffix: String, tenantItems: [V4ResponseTenant]) {
        self.emailSuffix = emailSuffix
        self.tenantItems = tenantItems
    }
}

enum UserOperationCenterItems {
    case unLoginTenantItems(CredentialBindingIdentities)
    case officialEmailTenantItems(UIImage, Int)
    case operationItems([OperationButton])
}

class UserOperationCenterViewModel: V3ViewModel {

    let userCenterInfo: V4UserOperationCenterInfo

    var officialEmailItems: [OfficialEmailItem]?

    var items: [UserOperationCenterItems] = []

    @Provider var userManager: UserManager

    init(
        step: String,
        userCenterInfo: V4UserOperationCenterInfo,
        context: UniContextProtocol
    ) {
        self.userCenterInfo = userCenterInfo
        super.init(step: step, stepInfo: userCenterInfo, context: context)
    }

    func estimateTableHeight() -> CGFloat {
        var sumHeight:CGFloat = 0.0
        for item in self.items {
            switch item {
            case .unLoginTenantItems(let tenantItems):
                sumHeight += UserOperationCenterCell.Layout.cellHeight * CGFloat(tenantItems.userList.count)
            case .officialEmailTenantItems(_, _):
                sumHeight += UserOperationCenterCell.Layout.cellHeight
            case .operationItems(let buttons):
                sumHeight += UserOperationCenterCell.Layout.cellHeight * CGFloat(buttons.count)
            }
        }
        return sumHeight
    }

    func generateItems(completion: @escaping ()->()) {

        // 页面主体由三部分组成 1.根据 CP 获取的其它可登录身份；2. 可信邮箱带来的可加入团队；3. 加入已有企业、创建新企业、个人使用三个固定入口
        // 根据 CP 获取的其它身份，需要剔除重复身份，飞书：手机号>邮箱> CIdP; Lark：邮箱>手机号> CIdP
        // 所以这里做两件事：按照需求约定的顺序排序并剔除重复身份；剔除本地已经带有有效 session 的身份
        var userCenterItems: [UserOperationCenterItems] = []
        var orderedIdentityList = [CredentialBindingIdentities]()

        // 由于同一个 CP 可能会有不同的 CPID，先做同一 CP 的 merge
        let allPhoneList = userCenterInfo.credentialBindingUserList.filter { $0.credential?.credentialType == 1 }
        let allEmailList = userCenterInfo.credentialBindingUserList.filter { $0.credential?.credentialType == 2 }
        let allOtherList = userCenterInfo.credentialBindingUserList.filter { $0.credential?.credentialType != 1 && $0.credential?.credentialType != 2 }

        /// 拿到不重复的独立 CP 列表
        guard let phoneCPList = NSOrderedSet(array: allPhoneList.map { $0.credential?.credential ?? "" }).array as? [String],
              let emailCPList = NSOrderedSet(array: allEmailList.map { $0.credential?.credential ?? "" }).array as? [String],
              let otherCPList = NSOrderedSet(array: allOtherList.map { $0.credential?.credential ?? "" }).array as? [String] else {
                  completion()
                  return
              }

//        debugPrint(" -~- \(phoneCPList)")

        var phoneIdentityList = [CredentialBindingIdentities]()
        phoneCPList.forEach { cp in
            let userArray = allPhoneList.filter { $0.credential?.credential == cp }.flatMap { $0.userList }
            if !userArray.isEmpty, let credential = allPhoneList.first(where: { $0.credential?.credential == cp })?.credential {
                let id = CredentialBindingIdentities(credential: credential, userList: userArray)
                phoneIdentityList.append(id)
            }
        }
//        debugPrint(" -~- phoneIdentityList \(phoneIdentityList.flatMap { $0.userList.first?.user.name })")

        var emailIdentityList = [CredentialBindingIdentities]()
        emailCPList.forEach { cp in
            let userArray = allEmailList.filter { $0.credential?.credential == cp }.flatMap { $0.userList }
            if !userArray.isEmpty, let credential = allEmailList.first(where: { $0.credential?.credential == cp })?.credential {
                let id = CredentialBindingIdentities(credential: credential, userList: userArray)
                emailIdentityList.append(id)
            }
        }

        var otherIdentityList = [CredentialBindingIdentities]()
        otherCPList.forEach { cp in
            let userArray = allOtherList.filter { $0.credential?.credential == cp }.flatMap { $0.userList }
            if !userArray.isEmpty, let credential = allOtherList.first(where: { $0.credential?.credential == cp })?.credential {
                let id = CredentialBindingIdentities(credential: credential, userList: userArray)
                otherIdentityList.append(id)
            }
        }

        var displayUsers = [V4UserItem]()

        if ReleaseConfig.isLark {
            // Lark condition
            emailIdentityList.forEach { identity in
                let shouldDisplayUsers = identity.userList.filter { userItem in
                    !displayUsers.contains(where: { $0.user.id == userItem.user.id })
                }
                if !shouldDisplayUsers.isEmpty {
                    let shouldDisplayIdentity = CredentialBindingIdentities(credential: identity.credential, userList: shouldDisplayUsers)
                    displayUsers.append(contentsOf: shouldDisplayUsers)
                    orderedIdentityList.append(shouldDisplayIdentity)
                }
            }

            phoneIdentityList.forEach { identity in
                let shouldDisplayUsers = identity.userList.filter { userItem in
                    !displayUsers.contains(where: { $0.user.id == userItem.user.id })
                }
                if !shouldDisplayUsers.isEmpty {
                    let shouldDisplayIdentity = CredentialBindingIdentities(credential: identity.credential, userList: shouldDisplayUsers)
                    displayUsers.append(contentsOf: shouldDisplayUsers)
                    orderedIdentityList.append(shouldDisplayIdentity)
                }
            }
        } else {
            // Feishu condition
            phoneIdentityList.forEach { identity in
                let shouldDisplayUsers = identity.userList.filter { userItem in
                    !displayUsers.contains(where: { $0.user.id == userItem.user.id })
                }
//                debugPrint(" -~- shouldDisplayUsers \(shouldDisplayUsers.map { $0.user.name })")
                if !shouldDisplayUsers.isEmpty {
                    let shouldDisplayIdentity = CredentialBindingIdentities(credential: identity.credential, userList: shouldDisplayUsers)
//                    debugPrint(" -~- user count \(shouldDisplayIdentity.userList.count)")
                    displayUsers.append(contentsOf: shouldDisplayUsers)
                    orderedIdentityList.append(shouldDisplayIdentity)
                }
            }
//            debugPrint(" -~- names \(displayUsers.map { $0.user.name })")
//            debugPrint(" -~- orderedIdentityList count \(orderedIdentityList.count)")


            emailIdentityList.forEach { identity in
                let shouldDisplayUsers = identity.userList.filter { userItem in
                    !displayUsers.contains(where: { $0.user.id == userItem.user.id })
                }
                if !shouldDisplayUsers.isEmpty {
                    let shouldDisplayIdentity = CredentialBindingIdentities(credential: identity.credential, userList: shouldDisplayUsers)
                    displayUsers.append(contentsOf: shouldDisplayUsers)
                    orderedIdentityList.append(shouldDisplayIdentity)
                }
            }
        }

        // 处理手机和邮箱之外的内容，例如 IdP
        otherIdentityList.forEach { identity in
            let shouldDisplayUsers = identity.userList.filter { userItem in
                !displayUsers.contains(where: { $0.user.id == userItem.user.id })
            }
            if !shouldDisplayUsers.isEmpty {
                let shouldDisplayIdentity = CredentialBindingIdentities(credential: identity.credential, userList: shouldDisplayUsers)
                displayUsers.append(contentsOf: shouldDisplayUsers)
                orderedIdentityList.append(shouldDisplayIdentity)
            }
        }

        let existedUserList = userManager.getActiveUserList()
        var nonLoginItems = [UserOperationCenterItems]()

        orderedIdentityList.forEach { identity in
            let shouldDisplayUsers = identity.userList.filter { userItem in
                !existedUserList.contains(where: { $0.userID == userItem.user.id })
            }
            if !shouldDisplayUsers.isEmpty {
                let shouldDisplayIdentity = CredentialBindingIdentities(credential: identity.credential, userList: shouldDisplayUsers)
//                debugPrint(" -~- order identity \(shouldDisplayIdentity)")
                nonLoginItems.append(.unLoginTenantItems(shouldDisplayIdentity))
            }
        }

        userCenterItems.append(contentsOf: nonLoginItems)

        let operationItems: UserOperationCenterItems = .operationItems(self.setOperationButtons())
        userCenterItems.append(operationItems)
        self.items = userCenterItems

        if let emailItemMap = self.userCenterInfo.officialEmailTenantMap, !emailItemMap.isEmpty {
            self.officialEmailItems = []
            var imageUrls: [String] = []
            var tenantNum: Int = 0
            _ = emailItemMap.map { (key: String, value: [V4ResponseTenant]) in
                if !value.isEmpty {
                    _ = value.map { (tenant) in
                        imageUrls.append(tenant.iconURL)
                        tenantNum += 1
                    }
                    self.officialEmailItems?.append(OfficialEmailItem(emailSuffix: key, tenantItems: value))
                }
            }
            if imageUrls.count > 0 {
                self.items.insert(.officialEmailTenantItems(UIImage(), tenantNum), at: userCenterItems.count - 1)
                let differUrls = self.getDiffUrls(with: imageUrls)
                
                var differImages: [UIImage] = []
                let count = differUrls.count > 4 ? 4 : differUrls.count
                
                _ = (0...count-1).map {[weak self] i in
                    guard let self = self else { return }
                    self.generateImage(with: differUrls[i]) { image in
                        differImages.append(image)
                    }
                }

                self.combineImage(with: differImages, imageWidth: UserOperationCenterCell.Layout.iconImageDiameter, spaceWidth: UserOperationCenterCell.Layout.multiIconSpace) {[weak self] (image) in
                    print("UserOperationCenterViewModel.combineImage finished!")
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        print("UserOperationCenterViewModel.enter main asgnc")
                        self.reloadOfficialEmailItemIcon(newImage: image ?? UIImage(), num: tenantNum)
                        completion()
                    }
                }
            } else {
                completion()
            }
        }
    }

    private func generateImage(with urlStr: String, completion: @escaping (UIImage)->()) {
        let imageView = UIImageView()
        imageView.bt.setLarkImage(with: .default(key: urlStr), completion:  { (imageResult) in
            if let image = try? imageResult.get().image {
                completion(image)
            } else {
                Self.logger.error("UserOperationCenterViewModel.gernerateImage failed")
            }
        })
    }

    private func reloadOfficialEmailItemIcon(newImage: UIImage, num: Int) {
        _ = (0...self.items.count - 1).map { i in
            let item = self.items[i]
            switch item {
            case .officialEmailTenantItems:
                self.items[i] = .officialEmailTenantItems(newImage, num)
            default:
                break
            }
        }
    }
}

extension UserOperationCenterViewModel {
    func toNextPage(stepData: V4StepData) -> Observable<Void> {
        return Observable.create { ob -> Disposable in
//            if let type = self.userCenterInfo.currentIdentityBindings?.first?.credential?.credentialType,
//               let contact = self.userCenterInfo.currentIdentityBindings?.first?.credential?.credential {
//                let name = self.userCenterInfo.currentIdentityBindings?.first?.userList.first?.user.name
//                // 如果没有 region code，cp 是邮箱，这里放 86 只是占位作用
//                let regionCode = self.userCenterInfo.currentIdentityBindings?.first?.credential?.countryCode ?? 86
//                self.additionalInfo = V3InputInfo(contact: contact, countryCode: "\(regionCode)", method: type == 1 ? .phoneNumber : .email, name: name)
//            }
            if !(self.userCenterInfo.currentIdentityBindings?.isEmpty ?? true) {
                self.additionalInfo = self.userCenterInfo
            }
            if let event = stepData.stepName{
                self.post(event: event,
                          stepInfo: stepData.stepInfo,
                          additionalInfo: self.additionalInfo,
                          success:{
                            ob.onNext(())
                            ob.onCompleted()
                        }, error: { error in
                            ob.onError(error)
                        })
            }
            return Disposables.create()
        }
    }

    private func setOperationButtons() -> [OperationButton] {
        let joinTenant = OperationButton(icon: DynamicResource.user_center_join,
                                         title: I18N.Lark_Passport_AddAccountJoinTeamButton,
                                         action: { [weak self] in
                                            guard let self = self else { return .just(()) }
                                            let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.userCenterInfo.flowType ?? "", click: TrackConst.passportClickTrackJoinTeam, target: TrackConst.passportJoinTeamView)
                                            SuiteLoginTracker.track(Homeric.PASSPORT_CHANGE_OR_CREATE_TEAM_CLICK, params: params)
                                            if let stepData = self.userCenterInfo.joinTenantStep {
                                                return self.toNextPage(stepData: stepData)
                                            } else {
                                                return .just(())
                                            }
                                         })
        let createTenant = OperationButton(icon: DynamicResource.user_center_create,
                                           title: I18N.Lark_Passport_AddAccountCreateTeamButton,
                                           action: { [weak self] in
                                            guard let self = self else { return .just(()) }
                                            let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.userCenterInfo.flowType ?? "", click: TrackConst.passportClickTrackCreateTeam, target: TrackConst.passportTeamInfoSettingView)
                                            SuiteLoginTracker.track(Homeric.PASSPORT_CHANGE_OR_CREATE_TEAM_CLICK, params: params)
                                            if let stepData = self.userCenterInfo.createTenantStep {
                                                return self.toNextPage(stepData: stepData)
                                            } else {
                                                return .just(())
                                            }
                                           })
        let personalUser = OperationButton(icon: DynamicResource.user_center_personal_use,
                                           title: I18N.Lark_Passport_AddAccountPersonalUseButton,
                                           action: { [weak self] in
                                            guard let self = self else { return .just(()) }
                                            let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.userCenterInfo.flowType ?? "", click: TrackConst.passportClickTrackPersonalUse, target: TrackConst.passportUserInfoSettingView)
                                            SuiteLoginTracker.track(Homeric.PASSPORT_CHANGE_OR_CREATE_TEAM_CLICK, params: params)
                                            if let stepData = self.userCenterInfo.personalUseStep {
                                                return self.toNextPage(stepData: stepData)
                                            } else {
                                                return .just(())
                                            }
                                           })
        return [joinTenant, createTenant, personalUser]
    }
}

extension UserOperationCenterViewModel { // combine image: 1,2,3,4
    private func combineImage(with images: [UIImage], imageWidth: CGFloat, spaceWidth: CGFloat, completion: @escaping (UIImage?)->()) { //可信邮箱的tenant icon合并, 需要去重
        switch images.count {
        case 1:
            completion(images[0])
        case 2:
            return combineTwoImages(with: images, imageWidth: imageWidth, spaceWidth: spaceWidth, completion: completion)
        case 3:
            return combineThreeImages(with: images, imageWidth: imageWidth, spaceWidth: spaceWidth, completion: completion)
        default:
            return combineFourImages(with: images, imageWidth: imageWidth, spaceWidth: spaceWidth, completion: completion)

        }
    }

    private func combineTwoImages(with images: [UIImage], imageWidth: CGFloat, spaceWidth: CGFloat, completion: @escaping (UIImage?)->()) {
        guard images.count == 2 else {
            return
        }
        UIGraphicsBeginImageContext(CGSize(width: imageWidth, height: imageWidth))
        
        let image1 = images[0]
        let image2 = images[1]

        let imageLength = (imageWidth - spaceWidth)/2.0
        let rect1 = CGRect(x: 0, y: (imageWidth - imageLength)/2.0, width: imageLength, height: imageLength)
        let rect2 = CGRect(x: imageLength + spaceWidth, y: (imageWidth - imageLength)/2.0, width: imageLength, height: imageLength)

        UIGraphicsBeginImageContext(CGSize(width: imageWidth, height: imageWidth))
        let queue = DispatchQueue(label: "UserOperationCenterViewModel.combineTwoImages", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
        queue.async {
            image1.draw(in: rect1)
            print("UserOperationCenterViewModel.combineTwoImages: first image")
        }
        queue.async {
            image2.draw(in: rect2)
            print("UserOperationCenterViewModel.combineTwoImages: second image")
        }
        DispatchGroup.init().notify(qos: .default, flags: .barrier, queue: queue) {
            let resultImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            print("UserOperationCenterViewModel.combineTwoImages: result image")
            completion(resultImage)
        }
    }

    private func combineThreeImages(with images: [UIImage], imageWidth: CGFloat, spaceWidth: CGFloat, completion: @escaping (UIImage?)->()){
        guard images.count == 3 else {
            return
        }
        UIGraphicsBeginImageContext(CGSize(width: imageWidth, height: imageWidth))

        let imageLength = (imageWidth - spaceWidth)/2.0
        let rect1 = CGRect(x: (imageWidth - imageLength)/2.0, y: 0, width: imageLength, height: imageLength)
        let rect2 = CGRect(x: 0, y: imageLength + spaceWidth, width: imageLength, height: imageLength)
        let rect3 = CGRect(x: imageLength + spaceWidth, y: imageLength + spaceWidth, width: imageLength, height: imageLength)

        let image1 = images[0]
        let image2 = images[1]
        let image3 = images[2]
        let group = DispatchGroup.init()
        let queue = DispatchQueue(label: "UserOperationCenterViewModel.combineThreeImages", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
        queue.async(group: group, qos: .default, flags: []) {
            image1.draw(in: rect1)
        }

        queue.async(group: group, qos: .default, flags: []) {
            image2.draw(in: rect2)
        }
        
        queue.async(group: group, qos: .default, flags: []) {
            image3.draw(in: rect3)
        }
        
        group.notify(qos: .default, flags: .barrier, queue: queue) {
            let resultImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            completion(resultImage)
        }
    }

    private func combineFourImages(with images: [UIImage], imageWidth: CGFloat, spaceWidth: CGFloat, completion: @escaping (UIImage?)->()){
        guard images.count >= 4 else {
            return
        }
        UIGraphicsBeginImageContext(CGSize(width: imageWidth, height: imageWidth))

        let image1 = images[0]
        let image2 = images[1]
        let image3 = images[2]
        let image4 = images[3]

        let imageLength = (imageWidth - spaceWidth)/2.0
        let rect1 = CGRect(x: 0, y: 0, width: imageLength, height: imageLength)
        let rect2 = CGRect(x: imageLength + spaceWidth, y: 0, width: imageLength, height: imageLength)
        let rect3 = CGRect(x: 0, y: imageLength + spaceWidth, width: imageLength, height: imageLength)
        let rect4 = CGRect(x: imageLength + spaceWidth, y: imageLength + spaceWidth, width: imageLength, height: imageLength)
        
        let group = DispatchGroup.init()
        let queue = DispatchQueue(label: "UserOperationCenterViewModel.combineThreeImages", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
        queue.async(group: group, qos: .default, flags: [])  {
            image1.draw(in: rect1)
        }
        
        queue.async(group: group, qos: .default, flags: [])  {
            image2.draw(in: rect2)
        }

        queue.async(group: group, qos: .default, flags: [])  {
            image3.draw(in: rect3)
        }

        queue.async(group: group, qos: .default, flags: [])  {
            image4.draw(in: rect4)
        }

        group.notify(qos: .default, flags: .barrier, queue: queue) {
            let resultImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            completion(resultImage)
        }
    }

    private func getDiffUrls(with imageUrls: [String]) -> [String] {
        var urlList: [String] = []
        for url in imageUrls {
            if !urlList.contains(url) {
                urlList.append(url)
            }
            guard urlList.count < 4 else {
                return urlList
            }
        }
        return urlList
    }
}

extension UserOperationCenterViewModel {
    func initOfficialEmail(tenant: V4ResponseTenant) -> Observable<Void>? {
        Self.logger.info("click to init official email")
        return Observable.create { (observer) -> Disposable in
            self.service.initOfficialEmail(tenantId: tenant.id, flowType: self.userCenterInfo.flowType, userCenterInfo: self.userCenterInfo, success: {
                observer.onNext(())
                observer.onCompleted()
            }, error: { (error) in
                observer.onError(error)
            }, context: self.context)

            return Disposables.create()
        }
    }
}
