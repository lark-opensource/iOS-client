//
//  ShareTokenManager.swift
//  LarkShareToken
//
//  Created by 赵冬 on 2020/4/14.
//

import UIKit
import Foundation
import EENavigator
import RxSwift
import LKCommonsLogging
import LarkModel
import LarkExtensions
import EEImageService
import LarkUIKit
import Homeric
import LKCommonsTracker
import LarkAlertController

//public typealias ShareTokenHandler = ((_ map: [String: String]) -> Void)
//
//public struct ObservePasteboardManager {
//    public struct Notification {
//        public static let startToObservePasteboard: NSNotification.Name = NSNotification.Name("lark.shareToken.startToObservePasteboard")
//    }
//    public static let throttle: DispatchTimeInterval = .microseconds(1000)
//}
//
//final public class ShareTokenManager {
//    public static var shared = ShareTokenManager()
//
//    private var dependecy: ShareTokenDependecy
//
//    init(dependecy: ShareTokenDependecy = ShareTokenDependecy()) {
//        self.dependecy = dependecy
//    }
//
//    static let log = Logger.log(ShareTokenManager.self, category: "ShareTokenManager")
//
//    private let pasteboardContentKey = "lark_shareToken_pasteboardContentKey"
//
//    private let disposeBag = DisposeBag()
//
//    static private(set) var handlersDic = [String: ShareTokenHandler]()
//
//    let scheduler = SerialDispatchQueueScheduler(internalSerialQueueName: "ShareTokenManager.scheduler")
//
//    var getPasterboard: Observable<String?> = {
//        return Observable<String?>.create({ (observer) -> Disposable in
//            DispatchQueue.global().async {
//                if let str = UIPasteboard.general.string {
//                    observer.onNext(str)
//                } else {
//                    observer.onNext(nil)
//                }
//             }
//            return Disposables.create()
//        })
//    }()
//
//    public func cachePasteboardContent(string: String? = nil) {
//        // 如果传入string, 则用string, 默认取剪切板内容
//        if let str = string {
//            UserDefaults.standard.set(str, forKey: self.pasteboardContentKey)
//        } else {
//            self.getPasterboard.observeOn(self.scheduler)
//            .flatMap({ (str) -> Observable<String> in
//                if let string = str {
//                    return .just(string)
//                } else {
//                    ShareTokenManager.log.error("getPasterboard error")
//                    return .empty()
//                }
//            })
//            .subscribe(onNext: { (pasteboardString) in
//                UserDefaults.standard.set(pasteboardString, forKey: self.pasteboardContentKey)
//            }).disposed(by: self.disposeBag)
//        }
//    }
//
//    private func getPasteboardContentFormCache() -> String? {
//        return UserDefaults.standard.value(forKey: self.pasteboardContentKey) as? String ?? nil
//    }
//
//    private func deletePasteboardContentFormCache() {
//        UserDefaults.standard.removeObject(forKey: self.pasteboardContentKey)
//    }
//
//    public func registerHandler(source: String, handler: @escaping ShareTokenHandler) {
//        if Self.handlersDic[source] == nil {
//            Self.handlersDic[source] = handler
//        }
//    }
//
//    private func openTokenAlert(content: TemplateShareContent,
//                                templateID: Int32,
//                                business: String,
//                                isLoginIn: Bool) {
//        // 取当前最顶部vc
//        // TODO @zhaodong: topMost会废弃， 需要调整
//        let vc = UIViewController.topMost
//        let newVC = ShareTokenAlertVC()
//        let paras = ["business_line": business, "timing": isLoginIn] as [String: Any]
//        // 如果templateID == 4 (失效模版), 不使用口令弹窗, 而使用通用的弹窗
//        if templateID == 4 {
//            let alertController = LarkAlertController()
//            alertController.setTitle(text: BundleI18n.LarkShareToken.Lark_Chat_TokenExpiredTitle,
//                                     color: UIColor.ud.N900,
//                                     font: .systemFont(ofSize: 16, weight: .medium),
//                                     alignment: .center, numberOfLines: 0)
//            alertController.addPrimaryButton(text: BundleI18n.LarkShareToken.Lark_Chat_TokenGotIt)
//            Navigator.shared.present(alertController, from: vc, animated: true)
//        } else {
//            // 判断所使用的口令弹窗模版
//            var template: Template
//            if templateID == 1 {
//                template = .normal
//            } else if templateID == 2 || templateID == 3 {
//                template = .noTopImage
//            } else {
//                 template = .normal
//            }
//            let vm = self.praseDataAndMakeVM(content: content,
//                                             template: template,
//                                             vc: newVC, paras: paras)
//            newVC.shareTokenAlertViewModel = vm
//            // 展示弹窗 打点
//            Tracker.post(TeaEvent(Homeric.TOKEN_POPUP, params: paras))
//
//            // 如果重复触发, dissmiss第一个弹窗, 然后新添加一个弹窗
//            if vc?.isMember(of: ShareTokenAlertVC.self) ?? false {
//                vc?.dismiss(animated: false, completion: {
//                    // TODO @zhaodong: topMost会废弃， 需要调整
//                    let topMost = UIViewController.topMost
//                    Navigator.shared.present(newVC, from: topMost, animated: true)
//                })
//            } else {
//                Navigator.shared.present(newVC, from: vc, animated: true)
//            }
//        }
//    }
//
//    private func praseDataAndMakeVM(content: TemplateShareContent,
//                                    template: Template,
//                                    vc: ShareTokenAlertVC,
//                                    paras: [String: Any] = [:]) -> ShareTokenAlertViewModel {
//        // 解析数据
//        let buttonInfo =  content.actionDesc.first
//        let mainTitleDesc = content.mainTitle
//        var subtitle = content.subTitle.first?.descContent
//        var descImageSet: ImageItemSet = ImageItemSet()
//        var userClickEnableMap: [String: Bool] = [:]
//        var rangeMap: [String: [NSRange]] = [:]
//        // 从{{at_users}}***字符串中替换人名
//        let regex: String = "{{at_users}}"
//        if let desc = content.subTitle.first {
//            desc.atUserInfoVec.forEach({ (userInfo) in
//                if let range = subtitle?.range(of: regex) {
//                    let username = userInfo.userName
//                    subtitle = subtitle?.replacingOccurrences(of: regex, with: username, options: .caseInsensitive, range: range)
//                    if let userRange = subtitle?.range(of: username) {
//                        let nsrange = NSRange(userRange, in: subtitle ?? "")
//                        rangeMap[userInfo.userID] = [nsrange]
//                        userClickEnableMap[userInfo.userID] = userInfo.isClickable
//                    }
//                }
//            })
//        }
//
//        // 解析image
//        if let image = content.imgVec.first {
//            var item = ImageItem()
//            item.type = .normal
//            if image.type == .encrypted {
//                item.type = .encrypted
//            }
//            item.key = image.key
//            item.urls = image.urls
//            descImageSet.origin = item
//            descImageSet.key = item.key
//            // 由于未登陆态无法使用key加载图片, 因此这里加上url
//            descImageSet.urls = item.urls
//            descImageSet.middle = item
//            descImageSet.thumbnail = item
//        }
//
//        // 构造vm
//        let vm = ShareTokenAlertViewModel(template: template)
//        vm.mainTitle = mainTitleDesc.first?.descContent
//        vm.subtitle = subtitle
//        vm.atUserIdRangeMap = rangeMap
//        vm.userClickEnableMap = userClickEnableMap
//        vm.tapableRangeList = rangeMap.flatMap({ $1 })
//        vm.openButtonTitle = buttonInfo?.btnInfo.btnText
//        vm.descImageSet = descImageSet
//
//        // 点击人名进入profile页面的handler注册
//        vm.openAtHandler = { [unowned vc] userId in
//            vc.dismiss(animated: true) {
//                // TODO @zhaodong: topMost会废弃， 需要调整
//                let topMost = UIViewController.topMost
//                let prefix = "//client/contact/personcard"
//                let url = URL(string: "\(prefix)/\(userId)")!
//                if Display.phone {
//                    Navigator.shared.push(url, from: topMost)
//                } else {
//                    Navigator.shared.present(
//                        url,
//                        wrap: LkNavigationController.self,
//                        from: topMost,
//                        prepare: { vc in
//                            vc.modalPresentationStyle = .formSheet
//                        })
//                }
//            }
//        }
//
//        // 点击关闭弹窗的handler注册
//        vm.clickShutButtonHandler = { [unowned vc] button in
//            vc.dismiss(animated: true) {
//            }
//        }
//
//        // 点击进入二级页面按钮的handler注册
//        vm.clickOpenButtonHandler = { [unowned vc] button in
//            // 点击按钮进入二级页面 打点
//            Tracker.post(TeaEvent(Homeric.TOKEN_POPUP_CLICK_THROUGH, params: paras))
//
//            vc.dismiss(animated: true) {
//                // 处理internalHandler的跳转
//                if buttonInfo?.actionType == .internalHandler, let handlerInfo = buttonInfo?.internalHandlerInfo {
//                    if let handler = ShareTokenManager.handlersDic[handlerInfo.handlerName] {
//                        handler(handlerInfo.parameterMap)
//                    }
//                } else if buttonInfo?.actionType == .scheme,
//                    let schemeInfo = buttonInfo?.schemeInfo,
//                    let url = URL(string: schemeInfo.schemeUri) { // 处理scheme的跳转
//                    // TODO @zhaodong: topMost会废弃， 需要调整
//                    let topMost = UIViewController.topMost
//                    Navigator.shared.open(url, from: topMost)
//                }
//            }
//        }
//        return vm
//    }
//
//    public func parsePasteboardToCheckWhetherOpenTokenAlert() {
//        self.getPasterboard.observeOn(self.scheduler)
//            .flatMap({ (str) -> Observable<String> in
//                if let string = str {
//                    return .just(string)
//                } else {
//                    ShareTokenManager.log.error("getPasterboard error")
//                    return .empty()
//                }
//            })
//            .subscribe(onNext: { (pasteboardString) in
//                self.dependecy.shareTokenAPI.getShareTokenByTextRequest(text: pasteboardString).flatMap { [weak self] (result) -> Observable<(GetShareTokenContentResponse)> in
//                    guard let self = self else { return .empty() }
//                      if result.hasShareToken {
//                          // 解决分享人回到app弹窗被识别的问题
//                          if let cacheString = self.getPasteboardContentFormCache(),
//                              pasteboardString == cacheString ||
//                                  pasteboardString.range(of: cacheString) != nil ||
//                                  cacheString.range(of: pasteboardString) != nil {
//                              // 清空剪切板内容的缓存
//                              self.deletePasteboardContentFormCache()
//                              // 清空剪切板内容
//                              self.emptyPasteboard()
//                              return .empty()
//                          }
//                        return self.dependecy.shareTokenAPI.getShareTokenContentRequest(token: result.shareToken)
//                      }
//                      return .empty()
//                  }
//                  .throttle(ObservePasteboardManager.throttle, scheduler: self.scheduler)
//                  .observeOn(MainScheduler.instance)
//                  .subscribe(onNext: { [weak self] (result) in
//                      guard let self = self else { return }
//                      if result.code == 0 {
//                          // 清空剪切板内容
//                          self.emptyPasteboard()
//                          // 打开弹窗
//                          self.openTokenAlert(content: result.templateShareContent,
//                                              templateID: result.templateID,
//                                              business: result.extraInfo["biz_name"] ?? "",
//                                              isLoginIn: !self.dependecy.currentAccountIsEmpty)
//                        ShareTokenManager.log.info("display alert")
//                      } else {
//                          ShareTokenManager.log.info("not to display shareTokenAlert, code = \(result.code)")
//                      }
//                  }, onError: { (error) in
//                      ShareTokenManager.log.error("getShareTokenContentRequest failed",
//                                                   error: error)
//                  }).disposed(by: self.disposeBag)
//        }).disposed(by: self.disposeBag)
//    }
//
//    private func emptyPasteboard() {
//        UIPasteboard.general.string = ""
//    }
//}
