//
//  MinutesAPIPath.swift
//  MinutesFoundation
//
//  Created by yangyao on 2022/12/12.
//

import Foundation

public struct MinutesAPIPath {
    /// core
    public static let baseInfo: String = "/minutes/api/base-info"
    public static let simpleBaseInfo: String = "/minutes/api/simple-base-info"
    public static let status: String = "/minutes/api/status"
    public static let subtitles: String = "/minutes/api/subtitles_v2"
    public static let keywords: String = "/minutes/api/keywords"
    public static let summaries: String = "/minutes/api/summaries"
    public static let speakersSummaries: String = "/minutes/api/summaries_v2"
    public static let speakers: String = "/minutes/api/speakers"
    
    /// audio
    public static let create: String = "/minutes/api/audio/create"
    public static let upload: String = "/minutes/api/audio/upload"
    public static let audioLanguage: String = "/minutes/api/audio/language"
    public static let audioStatus: String = "/minutes/api/audio/status"

    /// ...
    public static let listBatchStatus: String = "/minutes/api/batch-status"
    public static let timelineMerge: String = "/minutes/api/highlight/timeline/merge"

}
