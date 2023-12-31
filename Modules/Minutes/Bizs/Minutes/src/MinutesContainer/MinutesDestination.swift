//
//  MinutesDestination.swift
//  Minutes
//
//  Created by panzaofeng on 2022/5/24.
//

import Foundation

public enum MinutesDestination {
    case detail
    case detailComment(String, String)
    case summaryMention(String)
    case ccmCommentAdd(String, String?)
}
