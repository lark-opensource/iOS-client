//
// DO NOT EDIT.
//
// Generated by the Swift generator for OPAPI.
// Source: https://bytedance.feishu.cn/sheets/shtcnUZgO5AFLcbcEaI4sbtvrZe

import Foundation

@objc
public enum OPGeneralAPICode: Int {

    /// 调用成功
    case ok = 10000

    /// 参数错误
    case param = 10001

    /// 错误的json（所有内部json数据的处理错误）
    case jsonError = 10002

    /// 文件不可读
    case fileCanNotRead = 10003

    /// 文件不可写
    case fileCanNotWrite = 10004

    /// 系统授权失败
    case systemAuthDeny = 10005

    /// 用户授权失败
    case userAuthDenied = 10006

    /// 用户取消操作
    case cancel = 10007

    /// 功能不可用（API未实现，主端依赖不可用）
    case unable = 10008

    /// App 在后台
    case background = 10009

    /// 未知错误
    case unkonwError = 10010
}


@objc
public enum RequestAPICode: Int {

    /// url为空、url不合法
    case invalidUrl = 20101

    /// 不在域名白名单里
    case invalidDomain = 20102

    /// method is invalid
    case invalidMethod = 20103

    /// 超过最大并发数
    case exceedOverTaskCount = 20104

    /// timeout
    case timeout = 20105

    /// abort
    case abort = 20106
}


@objc
public enum UploadFileAPICode: Int {

    /// Invalid url
    case invalidUrl = 20201

    /// Invalid filePath
    case InvalidFilePath = 20202

    /// invalid domain
    case invalidDomain = 20203

    /// file is empty
    case fileEmpty = 20204

    /// invalid name
    case nameEmpty = 20205

    /// abort
    case abort = 20206
}


@objc
public enum DownloadFileAPICode: Int {

    /// invalid url
    case invalidUrl = 20301

    /// invalid domain
    case invalidDomain = 20302

    /// 不支持该请求方法，只支持GET和POST
    case invalidMethod = 20303

    /// filePath(指定的下载后的文件路径)
    case fileNotExist = 20304

    /// user dir saved file size limit exceeded
    case overLimit = 20305

    /// abort
    case abort = 20306
}


@objc
public enum ConnectSocketAPICode: Int {

    /// invalid url
    case invalidUrl = 20401

    /// invalid domain
    case invalidDomain = 20402

    /// socket no create socketId
    case socketNoCreateSocketId = 20403

    /// illegal operationType
    case illegalOperationType = 20404

    /// SocketTask.send方法相关fail
    case sendError = 20405
}


@objc
public enum CreateSocketTaskAPICode: Int {

    /// 
    case invalidUrl = 20401
}


@objc
public enum OperateSocketTaskAPICode: Int {

    /// 
    case socketNoCreateSocketId = 20403

    /// 
    case illegalOperationType = 20404
}


@objc
public enum SaveImageToPhotosAlbumAPICode: Int {

    /// 无效的filePath
    case invalidFilePath = 30201

    /// invalid imageData
    case invalidImageData = 30202

    /// selected path cannot be empty
    case pathEmpty = 30203
}


@objc
public enum PreviewImageAPICode: Int {

    /// urls不是数组
    case invalidUrls = 30301

    /// urls数组里的本地url和网络url只能存在一种类型
    case urlsExclusive = 30302

    /// invalid header
    case invalidHeader = 30303

    /// url is empty
    case urlEmpty = 30304

    /// method必须是get或者post
    case invalidMethod = 30305
}


@objc
public enum CompressImageAPICode: Int {

    /// src为空、格式不对、文件找不到
    case invalidSrc = 30401

    /// decode image fail
    case decodeFail = 30402

    /// compress image fail
    case compressFail = 30403

    /// write image to file fail
    case writeImageFail = 30404
}


@objc
public enum GetImageInfoAPICode: Int {

    /// invalid src
    case invalidSrc = 30501

    /// no such file or directory 
    case fileNotExist = 30502
}


@objc
public enum GetRecorderManagerAPICode: Int {

    /// invalid operationType
    case typeInvalid = 30601
}


@objc
public enum ChooseVideoAPICode: Int {

    /// over the maxDuration
    case overMaxDuration = 30801
}


@objc
public enum SaveVideoToPhotosAlbumAPICode: Int {

    /// filePath is empty
    case filePathEmpty = 30901

    /// filePath not exist
    case fileNotExist = 30902

    /// file is not video
    case fileNotVidoe = 30903
}


@objc
public enum StartDeviceCredentialAPICode: Int {

    /// 用户未设置锁屏密码
    case passwordNotSet = 40000

    /// user cancel
    case userCancel = 40001

    /// 解锁失败
    case unlockFail = 40002

    /// authContent 字段不能为空
    case authContentEmpty = 40003
}


@objc
public enum StartPasswordVerifyAPICode: Int {

    /// 用户取消，验证失败
    case userCancel = 40101

    /// 密码错误，验证失败
    case passwordError = 40102

    /// 密码输入次数超限制，验证失败
    case retryTimeLimit = 40103
}


@objc
public enum LoginAPICode: Int {

    /// logining, not retrys
    case notRetry = 40501

    /// login failed
    case fail = 40502
}


@objc
public enum CheckSessionAPICode: Int {

    /// invalid session 
    case invalidSession = 40601
}


@objc
public enum GetUserInfoAPICode: Int {

    /// not login
    case notLogin = 40701

    /// get user info failed
    case getUserInfoFail = 40702
}


@objc
public enum EnterProfileAPICode: Int {

    /// Get userId failed
    case getUseridFail = 40801
}


@objc
public enum AuthorizeAPICode: Int {

    /// invalid scope
    case invalidScope = 41201

    /// auth deny
    case authDeny = 41202
}


@objc
public enum EnterChatAPICode: Int {

    /// 通过openChatId获取chatId失败
    case getChatIdFail = 41301

    /// openChatId and chatId is both null
    case idEmpty = 41302
}


@objc
public enum ChooseContactAPICode: Int {

    /// open contact list failed
    case openContactFail = 41401

    /// get openId fail
    case getOpenIdFail = 41402

    /// 获取userInfo 失败
    case getUserInfoFail = 41403
}


@objc
public enum ChooseChatAPICode: Int {

    /// 获取chat失败
    case getChatinfoFail = 41501

    /// 服务端获取openChatId失败
    case getOpenchatidFail = 41502
}


@objc
public enum ShareAppMessageDirectlyAPICode: Int {

    /// feed模式不支持分享
    case notSupportFeedMode = 41810
}


@objc
public enum ShowShareMenuAPICode: Int {

    /// invalid type
    case invalidType = 41901

    /// forbidden in blackList
    case forbiddenInBlackList = 41902
}


@objc
public enum EnterBotAPICode: Int {

    /// 该app未配置bot
    case botidIsEmpty = 42001
}


@objc
public enum GetKAInfoAPICode: Int {

    /// app not in oklist
    case appNotInOklist = 42101
}


@objc
public enum TriggerCheckUpdateAPICode: Int {

    /// 
    case getOnlineVersionFail = 42201

    /// 
    case noNeedUpdate = 42202

    /// 
    case installPackageFail = 42203
}


@objc
public enum GetBlockActionSourceDetailAPICode: Int {

    /// triggerCode为空
    case codeEmpty = 42301

    /// triggerCode不合法
    case codeInvalid = 42302

    /// 未登录
    case platformSessionEmpty = 42303

    /// 获取message信息失败
    case getBlockActionFail = 42304

    /// 依赖服务不可用、iOS需要
    case serviceNotValid = 42305

    /// result is empty
    case resultIsEmpty = 42306

    /// 
    case invalidAppId = 42307
}


@objc
public enum SendMessageCardAPICode: Int {

    /// 
    case codeAndIdNeed = 42401

    /// 
    case idCountExceedTen = 42402

    /// 
    case cardContentIsEmpty = 42403

    /// 
    case failConvertToPb = 42404

    /// 
    case triggerCodeIsInvalid = 42405

    /// 
    case partOfIdInvalid = 42406
}


@objc
public enum CallLightServiceAPICode: Int {

    /// 轻服务调用错误
    case cloudServiceRequestFail = 42701

    /// 资源不存在
    case resourceNotFound = 42702
}


@objc
public enum UpdateBadgeAPICode: Int {

    /// nonexistent badge
    case nonexistentBadge = 42501
}


@objc
public enum ReportBadgeAPICode: Int {

    /// nonexistent badge
    case nonexistentBadge = 42601

    /// badge number not match
    case badgeNumberNotMatch = 42602
}


@objc
public enum SaveFileAPICode: Int {

    /// tempFilePath不合法：字段为空、不可读、文件不存在
    case invalidTempFilePath = 50101

    /// filePath不合法：不可写、文件不存在
    case invalidFilePath = 50102

    /// PC暂无限制
    case limitExceeded = 50103

    /// move file fail
    case moveFileFail = 50104
}


@objc
public enum OpenDocumentAPICode: Int {

    /// filetype not supported
    case filetypeNotSupported = 50401

    /// invalid filePath
    case invalidFilePath = 50402

    /// 指定云空间文档，但传入的filePath不是合法的云空间文档地址
    case spaceFileInvalid = 50403

    /// file not exist
    case fileNotExist = 50404

    /// 打开文件处理器失败
    case openFileFail = 50405
}

@objc
public enum GetTenantAppScopesAPICode: Int {

    /// app is not visible
    case notVisible = 42801

    /// app is not installed
    case notInstalled = 42802
}


@objc
public enum ApplyTenantAppScopeAPICode: Int {

    /// user agrees to apply
    case agreeApply = 42901

    /// user cancels application
    case cancelApplication = 42902

    /// administrator is processing
    case processing = 42903

    /// no application list to apply
    case noList = 42904

    /// the number of applications exceeds the limit
    case exceedLimit = 42905
}


@objc
public enum SaveFileAsAPICode: Int {

    /// 
    case emptyFilepath = 50501

    /// 
    case invalidFielpath = 50502

    /// 
    case copyFail = 50503
}


@objc
public enum RemoveSavedFileAPICode: Int {

    /// file is not in user or temp
    case fileCannotAccess = 50601

    /// file not exist
    case fileNotExist = 50602

    /// file is dir cannot delete dir
    case fileIsDir = 50603

    /// file delete failed
    case fileDeleteFailed = 50604
}


@objc
public enum GetStorageAPICode: Int {

    /// param.key should pass String
    case keyIllegal = 60101

    /// key对应的数据找不到
    case keyNotFound = 60102
}


@objc
public enum SetStorageAPICode: Int {

    /// key is illegal
    case keyIllegal = 60301

    /// exceed storage item max size
    case itemStorageExceed = 60302

    /// total storage size exceed 
    case totalStorageExceed = 60303
}


@objc
public enum RemoveStorageAPICode: Int {

    /// 没有传参数key
    case keyIllegal = 60501

    /// key对应的数据找不到
    case keyNotFound = 60502
}


@objc
public enum ClearStorageAPICode: Int {

    /// clear storage fail
    case clearFail = 60701
}


@objc
public enum GetEnvVariableAPICode: Int {

    /// get config fail
    case getConfigFail = 60801
}


@objc
public enum GetLocationAPICode: Int {

    /// unable access location
    case unableAccessLocation = 70101

    /// invalid latitude or longitude
    case invalidResult = 70102

    /// location fail
    case locationFail = 70103
}


@objc
public enum OpenLocationAPICode: Int {

    /// invalid latitude
    case invalidLatitude = 70201

    /// invalid longitude
    case invalidLongitude = 70202

    /// invalid scale
    case invalidScale = 70205
}


@objc
public enum GetConnectedWifiAPICode: Int {

    /// wifi not turned on
    case wifiNotTurnedOn = 70902

    /// invalid SSID
    case invalidSsid = 70903
}


@objc
public enum GetWifiListAPICode: Int {

    /// wifi not turned on
    case wifiNotTurnedOn = 71102

    /// gps not turned on
    case gpsNotTurnedOn = 71103
}


@objc
public enum StartAccelerometerAPICode: Int {

    /// not support accelerometers
    case accelerometerNotSupport = 71401

    /// Accelerometer is running
    case accelerometerIsRunning = 71402
}


@objc
public enum OperateCompassAPICode: Int {

    /// not support compass
    case compassNotSupport = 71501
}


@objc
public enum MakePhoneCallAPICode: Int {

    /// invalid phone number
    case invalidPhoneNumber = 72001
}


@objc
public enum ScanCodeAPICode: Int {

    /// 扫一扫已经开启
    case scanCodeRunning = 72101
}


@objc
public enum SetClipboardDataAPICode: Int {

    /// 
    case paramsNotString = 72301
}


@objc
public enum PrintAPICode: Int {

    /// 
    case emptyUrl = 72901

    /// 
    case protocolFail = 72902

    /// 
    case deviceError = 72903
}


@objc
public enum ShowToastAPICode: Int {

    /// invalid title
    case invalidTitle = 80101
}


@objc
public enum ShowModalAPICode: Int {

    /// invalid title and content
    case invalidModal = 80501
}


@objc
public enum ShowActionSheetAPICode: Int {

    /// empty item list param
    case emptyItem = 80601

    /// item list count limited
    case listOverLimit = 80602
}


@objc
public enum SetNavigationBarColorAPICode: Int {

    /// invalid front clolor param
    case invalidFrontColor = 80801

    /// invalid background color param
    case invalidBackgroundColor = 80802
}


@objc
public enum SetTabBarBadgeAPICode: Int {

    /// config没有配置tab
    case noTab = 81201

    /// text为空
    case textEmpty = 81202

    /// params.index is not number
    case indexIsNotNumber = 81203

    /// tab item index out of bounds
    case indexError = 81204
}


@objc
public enum ShowTabBarRedDotAPICode: Int {

    /// config没有配置tab
    case noTab = 81301

    /// 传入的index参数不是number
    case indexIsNotNumber = 81302

    /// tab item index out of bounds
    case indexError = 81303
}


@objc
public enum RemoveTabBarBadgeAPICode: Int {

    /// no tabBar in the current app
    case noTab = 81401

    /// params.index is not number
    case indexIsNotNumber = 81402

    /// tab item index out of bounds
    case indexError = 81403
}


@objc
public enum HideTabBarRedDotAPICode: Int {

    /// no tabBar in the current app
    case noTab = 81501

    /// params.index is not number
    case indexIsNotNumber = 81502

    /// tab item index out of bounds
    case indexError = 81503
}


@objc
public enum HideTabBarAPICode: Int {

    /// no tabBar in the current app
    case noTab = 81601
}


@objc
public enum ShowTabBarAPICode: Int {

    /// no tabBar in the current app
    case noTab = 81701
}


@objc
public enum SetTabBarItemAPICode: Int {

    /// no tabBar in the current app
    case noTab = 81801

    /// params.index is not number
    case indexIsNotNumber = 81802

    /// tab item index out of bounds
    case indexError = 81803

    /// icon path not found
    case iconNotFound = 81804

    /// selected icon path not found
    case selectedIconNotFound = 81806
}


@objc
public enum SetTabBarStyleAPICode: Int {

    /// no tabBar in the current app
    case noTab = 81901
}


@objc
public enum NavigateToAPICode: Int {

    /// only navigate to non-tab page
    case navigateTabPage = 90101

    /// page count limited
    case overPageCountLimit = 90102

    /// target page not exist
    case pageNotExist = 90103
}


@objc
public enum RedirectToAPICode: Int {

    /// only redirect to non-tab page
    case redirectTabPage = 90201

    /// target page not exist
    case pageNotExist = 90202
}


@objc
public enum SwitchTabAPICode: Int {

    /// target page not tab
    case switchNonTab = 90301

    /// target page not exist
    case pageNotExist = 90302
}


@objc
public enum ReLaunchAPICode: Int {

    /// target page not exist	
    case pageNotExist = 90501
}


@objc
public enum OpenschemaAPICode: Int {

    /// empty schema param
    case emptySchema = 90601

    /// 非法schema
    case illegalSchema = 90602

    /// not in the white list
    case notWhite = 90603

    /// current mode not supported
    case notSupportedMode = 90604

    /// open schema failed
    case openFailed = 90605
}


@objc
public enum OnChatBadgeChangeAPICode: Int {

    /// 
    case sameOpenchatid = 402001

    /// 
    case getChatidFailed = 402002
}


@objc
public enum OffChatBadgeChangeAPICode: Int {

    /// 
    case offSameId = 402101

    /// 
    case GETCHATIDFAILED = 402102
}


@objc
public enum GetChatInfoAPICode: Int {

    /// 
    case noAuth = 402101

    /// 
    case getFailOpenchatid = 402102

    /// 
    case emptyOpenchatid = 402103

    /// 
    case invalidChatId = 402104
}

/// 备注：小程序增加addTabBarItem的API，下面设置为三端统一错误码，但是iOS这里入参错误有统一错误码，因此部分没有用到的错误码先行注释
@objc
public enum AddTabBarItemAPICode: Int {

    /// api业务中model为空
    // case getNilModel = -10001

    /// api业务中的添加tab的page path为空
    case getNilPagePath = -10002

    /// api业务中的添加tab的page text为空
    // case getNilPageText = -10003

    /// api业务中的添加tab的light icon model为空
    // case getNilLightIconModel = -10004
    
    /// api业务中的添加tab的light icon path为空
    case getNilLightIconPath = -10005
    
    /// api业务中的添加tab的light icon selected path为空
    case getNilLightSelectedIconPath = -10006
    
    /// api业务中的添加tab的dark icon model为空
    // case getNilDarkIconModel = -10007
    
    /// api业务中的添加tab的dark icon path为空
    case getNilDarkIconPath = -10008
    
    /// api业务中的添加tab的dark icon selected path为空
    case getNilTabDarkSelectedIconPath = -10009
    
    /// 已有最多5个tab，无法添加
    case atMost5TabsCanBeAdded = -10010
    
    /// 添加tabBarItem位置不合法
    case indexToAddItemIsInvalid = -10011
    
    /// 添加的tabBarItem的pagePath存在重复
    case pagePathAlreadyExists = -10012
    
    /// 删除正在选中的tab
    case deleteSelectingPage = -10013
    
    /// 最少2个tab，不能继续删除
    case least2TabsNeed = -10014
    
    /// 删除不存在的tab
    case deleteNotFoundPage = -10015
    
}
