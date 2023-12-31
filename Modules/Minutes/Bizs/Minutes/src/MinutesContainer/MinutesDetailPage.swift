//
//  MinutesDetailPage.swift
//  Minutes
//
//  Created by 陈乐辉 on 2023/9/4.
//

import Foundation

enum MinutesPageType {
    case summary
    case text
    case speaker
    case info
    case chapter

    var isRightPageType: Bool {
        switch self {
            case .speaker, .info:
                return false
            default:
                return true
        }
    }
}

extension MinutesPageType {
    var title: String {
        switch self {
        case .summary:
            return BundleI18n.Minutes.MMWeb_M_MeetingNotesShort_Tab
        case .text:
            return BundleI18n.Minutes.MMWeb_G_Transcription
        case .speaker:
            return BundleI18n.Minutes.MMWeb_G_Speakers_Tab
        case .info:
            return BundleI18n.Minutes.MMWeb_G_MeetingInfo_Tab
        case .chapter:
            return BundleI18n.Minutes.MMWeb_M_SmartChaptersShort_Tab
        }
    }
}

protocol MinutesDetailPage {
    var pageType: MinutesPageType { get }
    var pageController: UIViewController { get }
}

extension MinutesSummaryViewController: MinutesDetailPage {
    var pageType: MinutesPageType { .summary }

    var pageController: UIViewController { self }
}

extension MinutesSpeakersViewController: MinutesDetailPage {
    var pageType: MinutesPageType { .speaker }

    var pageController: UIViewController { self }
}

extension MinutesInfoViewController: MinutesDetailPage {
    var pageType: MinutesPageType { .info }

    var pageController: UIViewController { self }
}

extension MinutesSubtitlesViewController: MinutesDetailPage {
    var pageType: MinutesPageType { .text }

    var pageController: UIViewController { self }
}

extension MinutesChapterViewController: MinutesDetailPage {
    var pageType: MinutesPageType { .chapter }

    var pageController: UIViewController { self }
}

