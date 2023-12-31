//
//  UrgentTipViewModel.swift
//  LarkMessageCore
//
//  Created by JackZhao on 2020/8/3.
//

import UIKit
import Foundation
import LarkModel
import RichLabel
import RxSwift
import LKCommonsLogging

// 加急提示
struct UrgentTip {
    var users: [UrgentTipUser] = []
    var attributedString = NSAttributedString()

    struct AttributedStyle {
        /// 加急已读颜色
        var buzzReadColor: UIColor
        /// 加急未读颜色
        var buzzUnReadColor: UIColor
        var nameAttributes: [NSAttributedString.Key: Any] = [:]
        var tipAttributes: [NSAttributedString.Key: Any] = [:]
    }
}

// 加急的人名
struct UrgentTipUser {
    var width: CGFloat = 0
    var length: Int = 0
    var id: String = ""
    var characters: [UrgentTipUserCharacter] = []
    var attributedString = NSAttributedString()
    var range = NSRange(location: 0, length: 0)
}

protocol UrgentTipChatter {
    var id: String { get }
    var displayName: String { get }
}

// 加急人名的字符
struct UrgentTipUserCharacter {
    var width: CGFloat = 0
    var range = NSRange(location: 0, length: 0)
}

// 要显示的加急人名计算的结果
struct CaculateResult {
    var users: [UrgentTipUser] = []
    var isNeedCut = false
}

// 裁剪人名的计算结果
struct CutResult {
    var users: [UrgentTipUser] = []
    var isNeedCutFirstUser = false
}

final class UrgentTipViewModel {
    static private let logger = Logger.log(UrgentTipViewModel.self, category: "UrgentTipViewModel")
    // key: chatterId，value： 点击的range
    private(set) var chatterIdToRange: [String: NSRange] = [:]
    // 当人名展示不下时展示...的range
    private(set) var tipMoreRange: NSRange = NSRange()
    // 可点击人名range
    private(set) var tapRanges: [NSRange] = []
    // 加急提示的属性字符串
    var attributedString: NSAttributedString {
        return self.urgentTip.attributedString
    }

    // 加急提示
    private var urgentTip: UrgentTip = UrgentTip()
    // 属性字符串 "<icon>加急给:"
    private let tipHead: NSAttributedString
    private var tipTail: NSAttributedString = NSAttributedString()
    private var tipTailWidth: CGFloat {
        return calculateWidth(string: tipTail.string)
    }
    private var attributedStyle: UrgentTip.AttributedStyle
    private let tipMarginLeft: CGFloat = 56
    private let tipIconWidth: CGFloat = 12
    private let tipMariginRight: CGFloat = 30
    private var maxCellWidth: CGFloat

    lazy private var commaWidth = {
        return self.calculateWidth(string: ", ")
    }()

    // 最大能显示的人名的长度,包括...等x人
    private var maxNamesWidth: CGFloat {
        let maxTipWidth = maxCellWidth - tipMarginLeft - tipMariginRight - tipIconWidth
        let maxNamesWidth = maxTipWidth - calculateWidth(string: tipHead.string)
        return maxNamesWidth
    }

    lazy private var readPointAttributes: [NSAttributedString.Key: Any] = {
        return [LKPointAttributeName: attributedStyle.buzzReadColor,
          LKPointRadiusAttributeName: 2.5]
    }()

    lazy private var unreadPointAttributes: [NSAttributedString.Key: Any] = {
        return [LKPointAttributeName: attributedStyle.buzzUnReadColor,
          LKPointRadiusAttributeName: 2.5,
     LKPointInnerRadiusAttributeName: 2.5 - 0.8]
    }()

    private var ackUrgentChatters: [UrgentTipChatter]
    private var ackUrgentChatterIds: [String]
    private var unackUrgentChatters: [UrgentTipChatter]
    private var unackUrgentChatterIds: [String]

    init(ackUrgentChatters: [UrgentTipChatter],
         ackUrgentChatterIds: [String],
         unackUrgentChatters: [UrgentTipChatter],
         unackUrgentChatterIds: [String],
         maxCellWidth: CGFloat,
         attributedStyle: UrgentTip.AttributedStyle) {
        self.tipHead = NSAttributedString(string: BundleI18n.LarkMessageCore.Lark_Chat_BuzzMessageTip + " ", attributes: attributedStyle.tipAttributes)
        self.maxCellWidth = maxCellWidth
        self.attributedStyle = attributedStyle
        self.ackUrgentChatters = ackUrgentChatters
        self.ackUrgentChatterIds = ackUrgentChatterIds
        self.unackUrgentChatters = unackUrgentChatters
        self.unackUrgentChatterIds = unackUrgentChatterIds
        self.urgentTip.attributedString = parseAttributedString()
        self.logWhileUrgentChattersAreMissing()
    }

    func updateStyle(_ style: UrgentTip.AttributedStyle) {
        self.attributedStyle = style
    }

    func update(ackUrgentChatterIds: [String],
                ackUrgentChatters: [UrgentTipChatter],
                unackUrgentChatterIds: [String],
                unackUrgentChatters: [UrgentTipChatter],
                maxCellWidth: CGFloat) {
        // 目前SDK会出现pushMessage不包含urgentChatter的问题，这里添加判断避免有问题的数据影响UI
        if (ackUrgentChatterIds.isEmpty && unackUrgentChatterIds.isEmpty) ||
            (ackUrgentChatters.count != ackUrgentChatterIds.count) ||
            (unackUrgentChatters.count != unackUrgentChatterIds.count) {
            Self.logger.info(
                "urgentChatters are missing," + "ackUrgentChatterIds: \(ackUrgentChatterIds), " +
                "ackUrgentChatter => ids: \(ackUrgentChatters.map { $0.id }), " +
                "unackUrgentChatterIds: \(unackUrgentChatterIds), " +
                "unackUrgentChatter => ids: \(unackUrgentChatters.map { $0.id }), ")
            return
        }
        let ackIsChange = arrayIsChange(new: ackUrgentChatterIds, old: self.ackUrgentChatterIds)
        let unackIsChange = arrayIsChange(new: unackUrgentChatterIds, old: self.unackUrgentChatterIds)
        if ackIsChange || unackIsChange {
            self.maxCellWidth = maxCellWidth
            self.ackUrgentChatters = ackUrgentChatters
            self.ackUrgentChatterIds = ackUrgentChatterIds
            self.unackUrgentChatters = unackUrgentChatters
            self.unackUrgentChatterIds = unackUrgentChatterIds
            self.urgentTip.attributedString = parseAttributedString()
        }
    }

    func resize(maxCellWidth: CGFloat) {
        self.maxCellWidth = maxCellWidth
        self.urgentTip.attributedString = parseAttributedString()
    }

    private func logWhileUrgentChattersAreMissing() {
        if ackUrgentChatterIds.isEmpty, unackUrgentChatterIds.isEmpty {
            Self.logger.info("urgentChatterIds are missing")
        }
        // 当已读chatters和ids不对等时打点
        if ackUrgentChatters.count != ackUrgentChatterIds.count {
            Self.logger.info(
                "ackUrgentChatters are missing," + "expect chatters' Ids = \(ackUrgentChatterIds)," +
                "actually chatters' Ids = \(ackUrgentChatters.map({ $0.id }))")
        }
        // 当未读chatters和ids不对等时打点
        if unackUrgentChatters.count != unackUrgentChatterIds.count {
            Self.logger.info(
                "unackUrgentChatters are missing," + "expect chatters' Ids = \(unackUrgentChatterIds)," +
                "actually chatters' Ids = \(unackUrgentChatters.map({ $0.id }))")
        }
    }

    private func parseAttributedString() -> NSAttributedString {
        if ackUrgentChatters.isEmpty, unackUrgentChatters.isEmpty {
            Self.logger.info(
                "ackUrgentChatters and unackUrgentChatters are empty," + "ackIds = \(ackUrgentChatterIds), unackIds = \(unackUrgentChatterIds)")
            return NSMutableAttributedString()
        }
        // name排序，如果name相同，用id再排序
        let chatters = (ackUrgentChatters + unackUrgentChatters).sorted { (chatter0, chatter1) -> Bool in
            return chatter0.displayName != chatter1.displayName ?
                chatter0.displayName < chatter1.displayName : chatter0.id < chatter1.id
        }
        let result: NSMutableAttributedString = NSMutableAttributedString()
        // 加入头部内容
        result.append(tipHead)
        let namesAttr = self.caculateNamesTipAttr(chatters: chatters)
        result.append(namesAttr)
        return result
    }

    private func caculateNamesTipAttr(chatters: [UrgentTipChatter]) -> NSAttributedString {
        let caculateResult = caculateUsers(chatters: chatters)
        // 是否需要截取人名去显示
        if !caculateResult.isNeedCut {
            // 根据当前计算users生成属性字符串
            return self.getAttrFromUsers(caculateResult.users, isNeedAddTail: false)
        }
        // 是否需要截取第一个人名
        if caculateResult.users.isEmpty {
            return self.caculateFirstNameTipAttr(chatters: chatters)
        }
        let cutResult = cutUsers(users: caculateResult.users)
        // 为了去显示...是否需要截取第一个人名
        if cutResult.isNeedCutFirstUser {
            return self.caculateFirstNameTipAttr(chatters: chatters)
        }
        return self.getAttrFromUsers(cutResult.users, isNeedAddTail: true)
    }

    // 计算要显示的人名
    private func caculateUsers(chatters: [UrgentTipChatter]) -> CaculateResult {
        guard !chatters.isEmpty else {
            Self.logger.info("excuted caculateUsers chatters is empty")
            return CaculateResult()
        }
        var result = CaculateResult()
        var users: [UrgentTipUser] = []
        var startLength = tipHead.length
        var namesWidth: CGFloat = 0
        let maxNamesWidth = self.maxNamesWidth
        // 遍历所有人
        for i in 0 ..< chatters.count {
            let user = getUser(chatter: chatters[i], chatters: chatters, startLength: &startLength)
            // +2是commaWidth的长度
            startLength += 2
            // 最后一个人不需要添加comma，因此不用计算commaWidth
            let testWidth = namesWidth + user.width + (i == chatters.count - 1 ? 0 : commaWidth)
            // 测试是否可以装下
            if testWidth <= maxNamesWidth {
                namesWidth = testWidth
                users.append(user)
                continue
            }
            self.tipTail = getUrgentTipTail(chatterNumber: chatters.count)
            result.users = users
            result.isNeedCut = true
            return result
        }
        result.users = users
        return result
    }

    func cutUsers(users: [UrgentTipUser]) -> CutResult {
        var users = users
        var result = CutResult()
        let tipTailWidth = self.tipTailWidth

        // name 总宽度使用 commaWidth 以及 userName 宽度拼接而成
        var namesWidth = users.reduce(0) { (result, user) -> CGFloat in
            return result + user.width
        } + commaWidth * CGFloat((users.count - 1))

        let test = namesWidth + tipTailWidth
        // 如果不能放下从当前users不断出栈直到可以放下"...等x人"
        if test > maxNamesWidth {
            repeat {
                // 当发现第一个人名加上"...等x人"仍然显示不下，直接返回结果
                if users.count == 1 {
                    result.isNeedCutFirstUser = true
                    return result
                }
                let user = users.popLast()
                namesWidth -= (user?.width ?? 0 + commaWidth)
            } while(namesWidth + tipTailWidth > maxNamesWidth)
        }
        result.users = users
        return result
    }

    // 根据人名数组获取属性字符串
    private func getAttrFromUsers(_ users: [UrgentTipUser], isNeedAddTail: Bool) -> NSAttributedString {
        let result = NSMutableAttributedString()
        // 增加人名间的"逗号和空格"
        users.forEach { (user) in
            result.append(user.attributedString)
            if let last = users.last, user.id != last.id {
                result.append(NSAttributedString(string: ", "))
            }
        }
        // 添加...等x人
        if isNeedAddTail {
            result.append(self.tipTail)
            let location = self.tipHead.length + result.length - tipTail.length
            self.tipMoreRange = NSRange(location: max(location, 0), length: tipTail.length)
        }
        var chatterIdToRangeDic: [String: NSRange] = [:]
        // 建立id到range的字典
        users.forEach { (user) in
            chatterIdToRangeDic[user.id] = user.range
        }
        self.chatterIdToRange = chatterIdToRangeDic
        self.tapRanges = self.chatterIdToRange.map({ $1 }) + [self.tipMoreRange]
        self.urgentTip.attributedString = result
        self.urgentTip.users = users
        return result
    }

    // 当第一个要显示的人名超过了maxTipWidth或者人名加上"...等x人"超过了maxTipWidth，截取第一个人名进行展示
    private func caculateFirstNameTipAttr(chatters: [UrgentTipChatter]) -> NSAttributedString {
        guard let firstChatter = chatters.first else {
            Self.logger.info("excuted caculateFirstNameTipAttr firstChatter is empty")
            return NSAttributedString()
        }
        var startLength = tipHead.length
        let maxDisplayWidth = self.maxNamesWidth - self.tipTailWidth
        let user = getUser(chatter: firstChatter, chatters: chatters, startLength: &startLength, isAddPoint: false)
        // 初始值为5，近似右上角圆圈的宽度
        var width: CGFloat = 5
        var range = NSRange(location: 0, length: 0)
        var lastCharacter = UrgentTipUserCharacter()
        // 遍历到最合适的character
        for i in 0 ..< user.characters.count {
            width += user.characters[i].width
            if width < maxDisplayWidth {
                continue
            }
            guard i >= 1 else {
                Self.logger.info("excuted caculateFirstNameTipAttr characters index error, index = \(i)")
                return NSAttributedString()
            }
            lastCharacter = user.characters[i - 1]
            range.length = lastCharacter.range.upperBound
            break
        }
        let result = NSMutableAttributedString(attributedString: user.attributedString.attributedSubstring(from: range))
        var pointAttributes: [NSAttributedString.Key: Any] = [:]
        if unackUrgentChatterIds.contains(firstChatter.id) {
            // 未读
            pointAttributes = self.unreadPointAttributes
        } else if ackUrgentChatterIds.contains(firstChatter.id) {
            // 已读
            pointAttributes = self.readPointAttributes
        }
        // 添加右上角小点
        result.addAttributes(pointAttributes,
                             range: NSRange(location: lastCharacter.range.location, length: lastCharacter.range.length))
        // 添加尾部...等x人的属性字符串
        result.append(self.tipTail)
        let chatterIdToRangeDic = [user.id: NSRange(location: user.range.location, length: range.length)]
        self.chatterIdToRange = chatterIdToRangeDic
        self.tipMoreRange = NSRange(location: self.tipHead.length + result.length - tipTail.length, length: tipTail.length)
        self.tapRanges = self.chatterIdToRange.map({ $1 }) + [self.tipMoreRange]
        self.urgentTip.users = [user]
        return result
    }

    // 根据chatter获取User结构体（从缓存中/创建）
    private func getUser(chatter: UrgentTipChatter, chatters: [UrgentTipChatter], startLength: inout Int, isAddPoint: Bool = true) -> UrgentTipUser {
        guard let firstChatter = chatters.first else {
            Self.logger.info("excuted getUser characters firstChatter is empty")
            return UrgentTipUser()
        }
        let nameAttr = NSMutableAttributedString(
            string: chatter.displayName,
            attributes: attributedStyle.nameAttributes
        )
        var user = getUserFromCache(id: chatter.id, name: chatter.displayName) ??
            createUser(nameAttr: nameAttr, chatterId: chatter.id, firstChatterId: firstChatter.id, startLength: startLength)
        if isAddPoint {
            var pointAttributes: [NSAttributedString.Key: Any] = [:]
            if unackUrgentChatterIds.contains(chatter.id) {
                // 未读
                pointAttributes = self.unreadPointAttributes
            } else if ackUrgentChatterIds.contains(chatter.id) {
                // 已读
                pointAttributes = self.readPointAttributes
            }
            if nameAttr.length > 0, let last = user.characters.last, last.range.location + last.range.length <= nameAttr.length {
                nameAttr.addAttributes(pointAttributes,
                                       range: NSRange(location: last.range.location, length: last.range.length))
            }
        }
        user.attributedString = nameAttr
        startLength += nameAttr.length
        return user
    }

    // 根据chatter生成User结构体
    private func createUser(nameAttr: NSAttributedString,
                            chatterId: String,
                            firstChatterId: String,
                            startLength: Int) -> UrgentTipUser {
        var user = UrgentTipUser()

        // 多添加的5像素来近似人名右上角圆点的宽度
        let nameWidth = calculateWidth(string: nameAttr.string) + 5
        user.width = nameWidth
        user.id = chatterId
        let charactersRange = calculateCharactersRange(attrString: nameAttr)
        let characters = charactersRange.map { (range) -> UrgentTipUserCharacter in
            var character = UrgentTipUserCharacter()
            character.range = range
            // 只存储第一个人名的字符宽度信息
            if chatterId == firstChatterId {
                character.width = calculateWidth(string: nameAttr.attributedSubstring(from: range).string)
            }
            return character
        }
        user.characters = characters
        user.length = nameAttr.length
        user.range = NSRange(location: startLength, length: nameAttr.length)
        return user
    }

    // 根据id从缓存中取出User结构体
    private func getUserFromCache(id: String, name: String) -> UrgentTipUser? {
        if let user = self.urgentTip.users.first(where: { (user) -> Bool in
            return user.id == id && user.attributedString.string == name
            }) {
            return user
        }
        return nil
    }

    // 获取加急提示的末尾
    private func getUrgentTipTail(chatterNumber: Int) -> NSAttributedString {
        // 当加急的人数大于1，才显示...等x人, 否则显示...
        // "\u{2026}" 表示 "..."
        guard chatterNumber > 1 else { return NSAttributedString(string: "\u{2026}") }
        let tip = BundleI18n.LarkMessageCore.Lark_Chat_BuzzHasMorePerson(chatterNumber)
        return NSAttributedString(string: "\u{2026}" + tip, attributes: attributedStyle.tipAttributes)
    }

    private func calculateWidth(string: String) -> CGFloat {
        return (string  as NSString).boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 15),
            options: .usesLineFragmentOrigin,
            attributes: attributedStyle.nameAttributes,
            context: nil).width
    }

    private func calculateCharactersRange(attrString: NSAttributedString) -> [NSRange] {
        if attrString.string.isEmpty {
            return []
        }
        var ranges: [NSRange] = []
        var prevEncodeOffset = 0
        var unicodeLength = 0
        let string = attrString.string
        for index in string.indices {
            let encodeOffset = index.utf16Offset(in: string)
            unicodeLength = encodeOffset - prevEncodeOffset
            ranges.append(NSRange(location: prevEncodeOffset, length: unicodeLength))
            prevEncodeOffset = encodeOffset
        }
        unicodeLength = attrString.length - prevEncodeOffset
        ranges.append(NSRange(location: prevEncodeOffset, length: unicodeLength))
        // 去除第一个没有价值的数据
        ranges.remove(at: 0)

        return ranges
    }

    private func arrayIsChange(new: [String], old: [String]) -> Bool {
        if new.isEmpty, old.isEmpty { return false }
        if new.count != old.count { return true }
        if Set(new) != Set(old) { return true }
        return false
    }
}
