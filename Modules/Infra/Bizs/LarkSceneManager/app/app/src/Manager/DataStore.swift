//
//  DataStore.swift
//  SceneDemo
//
//  Created by 李晨 on 2021/1/3.
//

import Foundation

struct Item: Codable {
    var id: String = UUID().uuidString
    var title: String
    var detail: String
    var date: TimeInterval

    init(
        id: String = UUID().uuidString,
        title: String,
        detail: String,
        date: TimeInterval = Date().timeIntervalSince1970
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.date = date
    }
}

class DataStore {

    struct Noti {
        static let DataChange = Notification.Name(rawValue: "data.change")
        static let DataUpdate = Notification.Name(rawValue: "data.update")
        static let DataDelete = Notification.Name(rawValue: "data.delete")
        static let DataCreate = Notification.Name(rawValue: "data.create")
    }

    static func setup() {
        if let data = UserDefaults.standard.data(forKey: "datas"),
           let values = try? JSONDecoder().decode([Item].self, from: data) {
            self.datas = values
        }
    }

    static func save() {
        if let data = try? JSONEncoder().encode(self.datas) {
            UserDefaults.standard.setValue(data, forKey: "datas")
        }
    }

    private static var datas: [Item] = [] {
        didSet {
            NotificationCenter.default.post(name: Noti.DataChange, object: datas)
            save()
        }
    }

    static func fetch() -> [Item] {
        return datas
    }

    static func create(title: String, detail: String) {
        let data = Item(title: title, detail: detail)
        datas.append(data)
        NotificationCenter.default.post(name: Noti.DataCreate, object: data)
    }

    static func delete(data: Item) {
        datas.removeAll { (d) -> Bool in
            return d.id == data.id
        }
        NotificationCenter.default.post(name: Noti.DataDelete, object: data)
    }

    static func update(data: Item) {
        if let index = datas.firstIndex(where: { (d) -> Bool in
            return d.id == data.id
        }) {
            var d = data
            d.date = Date().timeIntervalSince1970
            datas[index] = d
            NotificationCenter.default.post(name: Noti.DataUpdate, object: d)
        }
    }

}
