//
//  MindnoteThemeModel.swift
//  SpaceKit
//
//  Created by chengqifan on 2019/9/5.
//  

import Foundation

struct MindnoteThemeModel {
    var activeStructureKey: String?
    var structures: [ThemeItem]?
    var activeThemeKey: String?
    var themes: [ThemeItem]?
}

struct ThemeItem {
    var key: String?
    var normalImg: String?
    var activeImg: String?
    var title: String?
}
