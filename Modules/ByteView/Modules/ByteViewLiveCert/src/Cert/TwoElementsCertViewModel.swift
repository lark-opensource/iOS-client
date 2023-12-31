//
//  TwoElementsCertViewModel.swift
//  ByteView
//
//  Created by fakegourmet on 2020/8/11.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RichLabel
import ByteViewCommon
import ByteViewUI
import UniverseDesignColor
import ByteViewNetwork

final class TwoElementsCertViewModel: CertBaseViewModel {

    override var title: String { return I18n.View_G_RealNameAuthentication }

    override var detail: NSAttributedString {
        return NSAttributedString(string: I18n.View_G_RealNameAuthenticationInfo, config: .body)
    }

    enum IDCardNumLength {
        static let fifteen: Int = 15
        static let eighteen: Int = 18
    }

    var name: String = ""
    var code: String = ""

    var pageName: String = I18n.View_G_RealNameAuthentication
    weak var hostViewController: UIViewController?

    private let certService: CertService
    private let callback: ((Result<Void, CertError>) -> Void)?

    init(certService: CertService, callback: ((Result<Void, CertError>) -> Void)?) {
        self.certService = certService
        self.callback = callback
        super.init()
    }

    func setDelegate(_ delegate: NetworkErrorHandler?) {
        self.certService.setDelegate(delegate)
    }

    func doCert(completion: @escaping (Result<Void, Error>) -> Void) {
        return certService.verifyTwoElement(name: name, code: code, completion: completion)
    }

    override func clickClose() {
        LiveCertTracks.trackTwoElementsPage(nextStep: false)
    }

    func fetchPolicy(type: LiveCertPolicyType, completion: @escaping (Result<([LKTextLink], NSAttributedString), Error>) -> Void){
        certService.fetchLiveCertPolicy(for: type) {
            completion($0.map({ linkText -> ([LKTextLink], NSAttributedString) in
                var links: [LKTextLink] = []
                let linkFont = VCFontConfig.bodyAssist.font
                for component in linkText.components {
                    var link = LKTextLink(range: component.range, type: .link,
                                          attributes: [.foregroundColor: UIColor.ud.primaryContentDefault, .font: linkFont],
                                          activeAttributes: [:])
                    link.linkTapBlock = { [weak self] (_, _) in
                        guard let url = component.url, let from = self?.hostViewController else { return }
                        self?.open(url: url, from: from)
                    }
                    links.append(link)
                }
                let attributedString = NSAttributedString(string: linkText.result, config: .bodyAssist, alignment: .left)
                let mutable = NSMutableAttributedString(attributedString: attributedString)
                mutable.addAttributes([.foregroundColor: UIColor.ud.textCaption],
                                      range: NSRange(location: 0, length: attributedString.length))
                return (links, mutable)
            }))
        }
    }

    func fetchLiveCertPolicy(for type: LiveCertPolicyType, completion: @escaping (Result<LinkText, Error>) -> Void) {
        certService.fetchLiveCertPolicy(for: type, completion: completion)
    }

    func open(url: URL, from: UIViewController) {
        certService.openURL(url, from: from)
    }

    func createLivenessCertViewModel() -> LivenessCertViewModel {
        return LivenessCertViewModel(certService: certService, name: name, callback: callback)
    }

    func isCodeValid(_ text: String) -> Bool {
        var value = text
        value = value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        var length: Int = 0
        length = value.count
        if length != IDCardNumLength.fifteen && length != IDCardNumLength.eighteen {
            // 不满足15位和18位，即身份证错误
            return false
        }
        var regularExpression: NSRegularExpression?
        var numberofMatch: Int?
        var year = 0
        if length == IDCardNumLength.fifteen {
            // 获取年份对应的数字
            let valueNSStr = value as NSString
            let yearStr = valueNSStr.substring(with: NSRange.init(location: 6, length: 2)) as NSString
            year = yearStr.integerValue + 1900
            if year % 4 == 0 || (year % 100 == 0 && year % 4 == 0) {
                // 创建正则表达式 NSRegularExpressionCaseInsensitive：不区分字母大小写的模式
                // 测试出生日期的合法性
                regularExpression = try? NSRegularExpression.init(pattern: "^[1-9][0-9]{5}[0-9]{2}((01|03|05|07|08|10|12)(0[1-9]|[1-2][0-9]|3[0-1])|(04|06|09|11)(0[1-9]|[1-2][0-9]|30)|02(0[1-9]|[1-2][0-9]))[0-9]{3}$", options: NSRegularExpression.Options.caseInsensitive)
            } else {
                // 测试出生日期的合法性
                regularExpression = try? NSRegularExpression.init(pattern: "^[1-9][0-9]{5}[0-9]{2}((01|03|05|07|08|10|12)(0[1-9]|[1-2][0-9]|3[0-1])|(04|06|09|11)(0[1-9]|[1-2][0-9]|30)|02(0[1-9]|1[0-9]|2[0-8]))[0-9]{3}$", options: NSRegularExpression.Options.caseInsensitive)
            }
            numberofMatch = regularExpression?.numberOfMatches(in: value, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSRange.init(location: 0, length: value.count))
            if numberofMatch! > 0 {
                return true
            } else {
                return false
            }
        }
        return true
    }
}
