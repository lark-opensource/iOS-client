//
//  V3SetUpTeamProtocol.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/8/18.
//

import Foundation
import RxSwift

typealias V3SetUpTeamViewModel = V3SetUpTeamProtocol & V3ViewModel

protocol V3SetUpTeamProtocol {
    var flowType: String { get }
    
    var title: String { get }
    var subtitle: String { get }
    var img: String { get }
    var nextButtonText: String { get }
    var placeholderName: String? { get }
    var pageName: String { get }
    var tenantName: String { get set }
    var userName: String { get set }
    var defaultTenantName: String? { get }

    var inputContainerInfoList: [V3InputContainerInfo] { get }

    var optIn: Bool? { get set }
    var showOptIn: Bool { get }
    var optInDefaultValue: Bool { get }
    var optInText: NSAttributedString { get }

    var industryTypeList: [V3Industry]? { get }
    var staffSizeList: [V3StaffScale]? { get }
    var supportedRegionList: [Region]? { get }
    var topRegionList: [Region]? { get }
    var currentRegion: String? { get }
    var beforeSelectRegionText: String? { get }
    var afterSelectRegionText: String? { get }
    var industryInfo: (main: V3Industry, sub: V3Industry?)? { get set }
    var scaleInfo: V3StaffScale? { get set }
    var selectedRegion: Region? { get set }

    //可信邮箱相关
    var showTrustedMail: Bool? { get }
    var trustedMailTitle: String? { get }
    var trustedMailHover: String? { get }
    func shouldShowTrustMailLabel() -> Bool
    func getTrustedMailTips() -> NSAttributedString
    func getTurstedMailHover() -> NSAttributedString
    func getLearnMoreTips() -> NSAttributedString

    func trackNextClick()
    func trackViewAppear()
    func create() -> Observable<Void>
    func hasInputContainerForType(type: V3InputContainerType) -> Bool
    func inputContainerInfoFor(type: V3InputContainerType) -> V3InputContainerInfo?
    func isLastInput(inputContainerInfo: V3InputContainerInfo) -> Bool
    func hasRegionInput() -> Bool

}
