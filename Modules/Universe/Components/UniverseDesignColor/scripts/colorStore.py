import colorTools

# 生成 UDColor+Store.swift
def generate_udcolor_store_file():
    swift_code = f'''//
//  UDColor+Store.swift
//  UniverseDesignColor
//
//  Created by {colorTools.git_username} on {colorTools.formatted_time}.
//  ！！本文件由脚本生成，如需改动，请修改 colorBase.py 脚本！！
//

import Foundation
import LKLoadable

extension UDColor {{
    // swiftlint:disable all
    static func getToken() -> [UDColor.Name: UIColor] {{
        var store: [UDColor.Name: UIColor] = [:]
        SwiftLoadable.startOnlyOnce(key: "UniverseDesignColor_UDColor_registToken")

        if UIDevice.current.userInterfaceIdiom == .pad {{
            store[UDColor.Name("bg-base")] = UDColor.N100 & UDColor.rgb(0x171717)
        }} else {{
            store[UDColor.Name("bg-base")] = UDColor.N100 & UDColor.N00
        }}
'''
    swift_code += generate_color_dict_in_udcolor()
    swift_code += '''
        return store
    }
    // swiftlint:enable all
}
'''
    colorTools.replace_file('UDColor+Store.swift', swift_code)


def generate_color_dict_in_udcolor() -> str:
    # 定义颜色字典并忽略前两行
    color_dict = {}
    for row in colorTools.tokens_Sheet.iter_rows(min_row=3):
        if row[1].value and row[4].value and row[5].value:
            token = str(row[1].value).replace(" ", "").replace("/","-")
            light_color = str(row[4].value).replace(" ", "")
            dark_color = str(row[5].value).replace(" ", "")
            if "gradient" in light_color or "gradient" in dark_color:
                continue
            light_color = colorTools.process_value(light_color)
            dark_color = colorTools.process_value(dark_color)
            if light_color == dark_color:
                color_dict[token] = f"UDColor.{light_color}"
            else:
                color_dict[token] = f"UDColor.{light_color} & UDColor.{dark_color}"

    for row in colorTools.biz_token_sheet.iter_rows(min_row=3):
        if row[1].value and row[6].value and row[8].value:
            token = str(row[1].value).replace(" ", "").replace("/","-")
            biz = str(row[2].value).replace(" ", "").replace("/","-")
            light_color = str(row[6].value).replace(" ", "")
            dark_color = str(row[8].value).replace(" ", "")
            if "UD" in biz:
                light_color = colorTools.process_value(light_color)
                dark_color = colorTools.process_value(dark_color)
                if light_color == dark_color:
                    color_dict[token] = f"UDColor.{light_color}"
                else:
                    color_dict[token] = f"UDColor.{light_color} & UDColor.{dark_color}"
            
    # 生成代码
    code_str = "\n".join([f'        store[UDColor.Name("{key}")] = {value}' for key, value in color_dict.items()])
    return code_str
