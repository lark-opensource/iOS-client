//
//  PodcastBacground.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/4/7.
//

import Foundation

public struct PodcastBacground: Codable {

    public let imageUrls: [URL]

    private enum CodingKeys: String, CodingKey {
        case imageUrls = "podcast_bg_imgs"
    }
}
