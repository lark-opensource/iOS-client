//
//  CTAModel.swift
//  CTADialog
//
//  Created by aslan on 2023/10/11.
//

import Foundation

struct CTAResponse: Decodable {
    var code: Int
    var message: String?
    var data: CTAModel?
}

struct CTAModel: Decodable {
    var extra_info: CTAExtraInfo?
    var content: CTAContent?
}

struct CTAExtraInfo: Decodable {
    var function_category: String?
    var admin_flag: String?
    var is_single_sku: String?
}

struct CTAContent: Decodable {
    var type: String?
    var title: CTATitle?
    var body: CTABody?
    var footer: [CTAFooter]?
}

struct CTATitle: Decodable {
    var content: String?
    var fields: [CTAField]?
}

struct CTAField: Decodable {
    var content: String?
    var key: String?
    var type: String? /// "user"、"plain_text"、img
}

struct CTABody: Decodable {
    var img: CTAImage?
    var text: [CTAText]?
}

struct CTAImage: Decodable {
    var img_url: String?
}

struct CTAText: Decodable {
    var content: String?
    var fields: [CTAField]?
}

struct CTAFooter: Decodable {
    var tag: String?
    var type: String?
    var content: String?
    var action: CTAAction?
    var style: String?
}

struct CTAAction: Decodable {
    var url: String?
}
