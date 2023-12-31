//
//  Components.swift
//  Todo
//
//  Created by 张威 on 2020/11/12.
//

import RxSwift
import LarkAccountInterface
import TodoInterface

// MARK: TimeContext

struct TimeContext {
    var currentTime: Int64
    var timeZone: TimeZone
    var is12HourStyle: Bool
}

// MARK: DueTime

struct DueTimeFormatContext {
    var currentTime: Int64
    var timeZone: TimeZone
    var is12HourStyle: Bool
}

struct DueRemindTuple {
    var startTime: Int64?
    var dueTime: Int64?
    var reminder: Reminder?
    var isAllDay: Bool
    var rrule: String?
}

typealias TimeComponents = DueRemindTuple

extension DueRemindTuple {
    init?(from pb: Rust.Todo) {
        guard pb.isDueTimeValid || pb.isStartTimeValid else {
            return nil
        }
        var reminder: Reminder?
        if let pbReminder = pb.reminders.first {
            reminder = Reminder(pb: pbReminder)
        }
        self = .init(
            startTime: pb.isStartTimeValid ? pb.startTimeForFormat : nil,
            dueTime: pb.isDueTimeValid ? pb.dueTime : nil,
            reminder: reminder,
            isAllDay: pb.isAllDay,
            rrule: pb.isRRuleValid ? pb.rrule : nil
        )
    }

    func appendSelf(to pb: inout Rust.Todo) {
        pb.startMilliTime = (startTime ?? 0) * Utils.TimeFormat.Thousandth
        pb.dueTime = dueTime ?? 0
        pb.isAllDay = isAllDay
        if let rrule = rrule {
            pb.rrule = rrule
        } else {
            pb.rrule = ""
        }
        if let reminder = reminder {
            pb.reminders = [reminder.toPb()]
        } else {
            pb.reminders = []
        }
    }
}

// MARK: - Member

struct AvatarSeed {
    var avatarId: String
    var avatarKey: String
}

protocol UserType {
    var chatterId: String { get }   // chatterId
    var tenantId: String { get }    // tenantId
    var name: String { get }        // 用户名
    var otherName: UserName? { get }  // 其他名字
    var avatar: AvatarSeed { get }  // 头像
}

enum Member {
    case user(UserType)         // 用户
    case group(chatId: String)  // 群
    case unknown(id: String)    // 未知类型

    fileprivate func assertionUnsupport() {
        switch self {
        case .group:
            assertionFailure("不支持 group 类型")
        case .unknown:
            assertionFailure("不支持 unknown 类型")
        case .user:
            break
        }
    }
}

/// 当前用户的角色
struct MemberRole: OptionSet {
    let rawValue: Int

    /// 创建者
    static let creator = MemberRole(rawValue: 1 << 0)

    /// 执行者
    static let assignee = MemberRole(rawValue: 1 << 1)

    /// 关注者
    static let follower = MemberRole(rawValue: 1 << 2)

    /// 负责人
    static let owner = MemberRole(rawValue: 1 << 3)
}

protocol MemberConvertible {
    func asMember() -> Member
}

extension MemberConvertible {
    func asUser() -> UserType? {
        guard case .user(let user) = asMember() else { return nil }
        return user
    }
}

extension Member: MemberConvertible {
    func asMember() -> Member { self }
}

struct Owner: MemberConvertible {
    typealias RustModel = Rust.Owner

    private var model: RustModel

    init(model: RustModel) {
        self.model = model
    }

    init(member: Member, readMilliTime: Int64 = 0) {
        model = Rust.Owner()
        switch member {
        case .user(let u):
            var rUser = Rust.User()
            rUser.userID = u.chatterId
            rUser.avatarKey = u.avatar.avatarKey
            rUser.name = u.name
            rUser.tenantID = u.tenantId
            model.readMilliTime = readMilliTime
            model.user = rUser
        case .group, .unknown:
            member.assertionUnsupport()
        }
    }

    func asMember() -> Member {
        assert(isValid)
        return .user(User(pb: model.user))
    }

    func asModel() -> RustModel {
        return model
    }

    var isValid: Bool {
        return !model.user.userID.isEmpty
    }
}

struct Assignee: MemberConvertible {
    typealias RustModel = Rust.Assignee

    var completedTime: Int64? {
        get {
            guard model.type == .user, case .user(let u) = model.assignee else {
                return nil
            }
            return u.completedMilliTime == 0 ? nil : u.completedMilliTime
        }
        set {
            guard model.type == .user, case .user(var u) = model.assignee else {
                return
            }
            if let time = newValue {
                u.completedMilliTime = time
            } else {
                u.completedMilliTime = 0
            }
            model.assignee = .user(u)
        }
    }

    private var model: RustModel

    init(model: RustModel) {
        self.model = model
    }

    init(member: Member, completedMilliTime: Int64 = 0) {
        model = Rust.Assignee()
        switch member {
        case .user(let u):
            var rUser = Rust.User()
            rUser.userID = u.chatterId
            rUser.avatarKey = u.avatar.avatarKey
            rUser.name = u.name
            rUser.tenantID = u.tenantId

            var userWrapper = RustModel.User()
            userWrapper.user = rUser
            userWrapper.completedMilliTime = completedMilliTime

            model.assignee = .user(userWrapper)
            model.assigneeID = rUser.userID
            model.type = .user
        case .group(let chatId):
            model.type = .group
            model.assigneeID = chatId
            member.assertionUnsupport()
        case .unknown(let id):
            model.type = .unknown
            model.assigneeID = id
            member.assertionUnsupport()
        }
    }

    func asMember() -> Member {
        switch model.type {
        case .user:
            assert(model.user.hasUser)
            return .user(User(pb: model.user.user))
        case .group:
            return .group(chatId: model.assigneeID)
        case .app, .docs:
            return .unknown(id: model.assigneeID)
        case .unknown:
            return .unknown(id: model.assigneeID)
        @unknown default:
            return .unknown(id: model.assigneeID)
        }
    }

    func asModel() -> RustModel {
        return model
    }

    /// 用于展示的 sorter
    /// 排序策略：我 > 未完成 > 已完成
    static func displaySorter(with currentUserId: String) -> (Self, Self) -> Bool {
        return { a1, a2 in
            if a1.identifier == currentUserId && a2.identifier == currentUserId {
                return false
            } else if a1.identifier != currentUserId && a2.identifier == currentUserId {
                return false
            } else if a1.identifier == currentUserId && a2.identifier != currentUserId {
                return true
            } else {
                return a1.completedTime == nil && a2.completedTime != nil
            }
        }
    }
}

struct Follower: MemberConvertible {
    typealias RustModel = Rust.Follower

    private var model: RustModel

    init(model: RustModel) {
        self.model = model
    }

    init(member: Member) {
        model = Rust.Follower()
        switch member {
        case .user(let u):
            var rUser = Rust.User()
            rUser.userID = u.chatterId
            rUser.avatarKey = u.avatar.avatarKey
            rUser.name = u.name
            rUser.tenantID = u.tenantId

            var userWrapper = RustModel.User()
            userWrapper.user = rUser

            model.follower = .user(userWrapper)
            model.followerID = rUser.userID
            model.type = .user
        case .group(let chatId):
            model.type = .group
            model.followerID = chatId
            member.assertionUnsupport()
        case .unknown(let id):
            model.type = .unknown
            model.followerID = id
            member.assertionUnsupport()
        }
    }

    func asMember() -> Member {
        switch model.type {
        case .user:
            assert(model.user.hasUser)
            return .user(User(pb: model.user.user))
        case .group:
            return .group(chatId: model.followerID)
        case .app, .docs:
            return .unknown(id: model.followerID)
        case .unknown:
            return .unknown(id: model.followerID)
        @unknown default:
            return .unknown(id: model.followerID)
        }
    }

    func asModel() -> RustModel {
        return model
    }
}

extension MemberConvertible {
    var identifier: String {
        switch asMember() {
        case .user(let user):
            return user.chatterId
        case .group(let chatId):
            return chatId
        case .unknown(let id):
            return id
        }
    }

    var avatar: AvatarSeed {
        switch asMember() {
        case .user(let user):
            return user.avatar
        case .group, .unknown:
            return AvatarSeed(avatarId: "", avatarKey: "")
        }
    }

    var name: String {
        switch asMember() {
        case .user(let user):
            return user.name
        case .group, .unknown:
            return ""
        }
    }

}

struct User: UserType {
    var chatterId: String
    var tenantId: String
    var name: String
    var otherName: UserName?
    var avatar: AvatarSeed

    init(chatterId: String, tenantId: String, name: String, avatarKey: String) {
        self.chatterId = chatterId
        self.tenantId = tenantId
        self.name = name
        self.avatar = AvatarSeed(avatarId: chatterId, avatarKey: avatarKey)
    }

    static func current(_ passportService: PassportUserService?) -> Self? {
        guard let passportService = passportService else { return nil }
        let chatterId = passportService.user.userID
        let tenantId = passportService.userTenant.tenantID
        let name = passportService.user.displayName ?? passportService.user.localizedDisplayName
        let avatarKey = passportService.user.avatarKey
        return .init(chatterId: chatterId, tenantId: tenantId, name: name, avatarKey: avatarKey)
    }
}

extension User {
    init(pb: Rust.User) {
        self = User(
            chatterId: pb.userID,
            tenantId: pb.tenantID,
            name: pb.name,
            avatarKey: pb.avatarKey
        )
    }

    init(chatter: Rust.Chatter) {
        var user = User(
            chatterId: chatter.id,
            tenantId: chatter.tenantID,
            name: chatter.name,
            avatarKey: chatter.avatarKey
        )
        user.otherName = .init(
            alias: chatter.alias,
            anotherName: chatter.anotherName,
            localizedName: chatter.localizedName
        )
        self = user
    }
}

// MARK: - Parent Todo

struct ParentTodo {

    var todo: Rust.SimpleTodo?
    // 用于UI上显示重复任务
    var isLoadSdk: Bool = true
}

// MARK: - Reminder

enum Reminder {
    /// 绝对时间：时间戳
    case absolute(Int64)

    /// 与截止时间的相对时间
    case relativeToDueTime(Int64)

    /// 不绑定时区的相对时间
    case adaptFromUtc(Int64)
}

extension Reminder {

    init?(pb: Rust.Reminder) {
        switch pb.type {
        case .absolute:
            self = .absolute(pb.time)
        case .floating:
            self = .adaptFromUtc(pb.time)
        case .relative:
            if pb.time == NonAllDayReminder.noAlert.rawValue {
                return nil
            }
            self = .relativeToDueTime(pb.time)
        default: return nil
        }
    }

    func toPb() -> Rust.Reminder {
        var pb = Rust.Reminder()
        switch self {
        case .absolute(let time):
            pb.type = .absolute
            pb.time = time
        case .adaptFromUtc(let time):
            pb.type = .floating
            pb.time = time
        case .relativeToDueTime(let time):
            pb.type = .relative
            pb.time = time
        }
        return pb
    }

    var hasReminder: Bool {
        var hasReminder = false
        switch self {
        case .relativeToDueTime(let time):
            if time != NonAllDayReminder.noAlert.rawValue {
                hasReminder = true
            }
        case .absolute(let time):
            hasReminder = time != 0
        default:
            break
        }
        return hasReminder
    }

    func description() -> String {
        var description: String
        switch self {
        case .absolute(let time):
            description = "absolute: \(time)"
        case .adaptFromUtc(let time):
            description = "adaptFromUtc: \(time)"
        case .relativeToDueTime(let time):
            description = "relativeToDueTime: \(time)"
        }
        return description
    }
}

/// 图片附件

struct ImageAttachment {
    var token: String // 文件 token
    var position: Int // 位置
    var imageSet: Rust.ImageSet?
}

enum ImageSeed {
    case uiData(UIImage)
    case imageSet(Rust.ImageSet)
}

extension Rust.ImageSet {

    enum DownloadType: Int {
        case thumbnail = 0
        case middle = 1
        case origin = 2
    }

    func downloadKey(forPriorityType type: DownloadType) -> String {
        var keys = [thumbnail.key, middle.key, origin.key]
        for i in type.rawValue..<keys.count where !keys[i].isEmpty {
            return keys[i]
        }
        return key
    }

}

// MARK: V3 Task Center

enum ContainerKey: String {
    case owned = "__container_owned_tasks"
    case followed = "__container_followed_tasks"
    case all = "__container_all_tasks"
    case created = "__container_created_tasks"
    case assigned = "__container_assigned_tasks"
    case completed = "__container_completed_tasks"
}

enum FieldKey: String {
    case completeStatus = "__field_task_complete_status"
    case section = "__field_task_section"
    case assignee = "__field_task_assignee"
    case creator = "__field_task_creator"
    case startTime = "__field_task_start_time"
    case dueTime = "__field_task_due_time"
    case completeTime = "__field_task_complete_time"
    case source = "__field_task_source"
    case createTime = "__field_task_create_time"
    case updateTime = "__field_task_update_time"
    case assigner = "__field_task_assigner"
    case follower = "__field_task_follower"
}

extension ContainerKey {
    init(fromApplink key: String) {
        switch key {
        case "owned":
            self = .owned
        case "followed":
            self = .followed
        case "all":
            self = .all
        case "created":
            self = .created
        case "assigned":
            self = .assigned
        case "completed":
            self = .completed
        default:
            self = .owned
        }
    }
}
