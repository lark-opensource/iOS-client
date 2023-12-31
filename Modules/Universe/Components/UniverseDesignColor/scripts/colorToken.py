import colorTools

# 生成 UDColor+Token.swift
def generate_udcolor_token_file():
    swift_code = f'''//
//  UDColor+Token.swift
//  UniverseDesignColor
//
//  Created by {colorTools.git_username} on {colorTools.formatted_time}.
//  ！！本文件由脚本生成，如需改动，请修改 colorBase.py 脚本！！
//

import UIKit
import Foundation
import UniverseDesignTheme

// swiftlint:disable all
'''
    swift_code += generate_color_token_in_color_name()
    swift_code += generate_color_token_in_udcolor()
    swift_code += generate_color_token_in_extension()
    colorTools.replace_file("UDColor+Token.swift", swift_code)


def generate_color_token_in_color_name() -> str:
    # 定义颜色字典并忽略前两行
    code_str = '''/// UDColor Name Extension
public extension UDColor.Name {
    /// bgBase, Value: "bg-base"
    static let bgBase = UDColor.Name("bg-base")
    '''
    for row in colorTools.tokens_Sheet.iter_rows(min_row=3):
        if row[1].value and row[4].value and row[5].value:
            token_name = str(row[1].value).replace(" ", "").replace("/","-")
            light_color = str(row[4].value).replace(" ", "").replace("/","-")
            if "gradient" in light_color:
                continue
            token = colorTools.process_value(token_name)
            code_str += f'\n    /// {token}, Value: "{token_name}"\n'
            code_str += f'    static let {token} = UDColor.Name("{token_name}")\n'

    for row in colorTools.biz_token_sheet.iter_rows(min_row=3):
        if row[0].value and row[2].value:
            token_name = str(row[0].value).replace(" ", "").replace("/","-")
            light_color = str(row[6].value).replace(" ", "").replace("/","-")
            if "gradient" in light_color:
                continue
            if "udtoken" in token_name:
                token = colorTools.process_value(token_name)
                code_str += f'\n    /// {token}, Value: "{token_name}"\n'
                code_str += f'    static let {token} = UDColor.Name("{token_name}")\n'
            
    # 生成代码
    code_str += '}'
    return code_str

def generate_color_token_in_udcolor() -> str:
    # 定义颜色字典并忽略前两行
    color_dict = {}
    code_str = '''
    
/// UDColor Token
extension UDColor {
    /// Light: N100, Dark: N00
    public static var bgBase: UIColor {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return UDColor.getValueByKey(.bgBase) ?? UDColor.N100 & UDColor.rgb(0x171717)
        } else {
            return UDColor.getValueByKey(.bgBase) ?? UDColor.N100 & UDColor.N00
        }
    }
    '''
    for row in colorTools.tokens_Sheet.iter_rows(min_row=3):
        if row[1].value and row[4].value and row[5].value:
            token_name = str(row[1].value).replace(" ", "").replace("/","-")
            light_color = str(row[4].value).replace(" ", "").replace("/","-")
            dark_color = str(row[5].value).replace(" ", "").replace("/","-")
            if "gradient" in light_color or "gradient" in dark_color:
                continue
            token = colorTools.process_value(token_name)
            light_color = colorTools.process_value(light_color)
            dark_color = colorTools.process_value(dark_color)
            if light_color == dark_color:
                temp_str = f"return UDColor.getValueByKey(.{token}) ?? UDColor.{light_color}"
            else:
                temp_str = f"return UDColor.getValueByKey(.{token}) ?? UDColor.{light_color} & UDColor.{dark_color}"

            code_str += f'\n'
            code_str += f'    /// Light: {light_color}, Dark: {dark_color}\n'
            code_str += f'    public static var {token}: UIColor {{\n'
            code_str += f'        {temp_str}\n'
            code_str += f'    }}\n'

    for row in colorTools.biz_token_sheet.iter_rows(min_row=3):
        if row[1].value and row[6].value and row[8].value:
            token_name = str(row[1].value).replace(" ", "").replace("/","-")
            biz = str(row[2].value).replace(" ", "").replace("/","-")
            light_color = str(row[6].value).replace(" ", "").replace("/","-")
            dark_color = str(row[8].value).replace(" ", "").replace("/","-")
            if "UD" in biz:
                token = colorTools.process_value(token_name)
                light_color = colorTools.process_value(light_color)
                dark_color = colorTools.process_value(dark_color)
                if light_color == dark_color:
                    temp_str = f"return UDColor.getValueByKey(.{token}) ?? UDColor.{light_color}"
                else:
                    temp_str = f"return UDColor.getValueByKey(.{token}) ?? UDColor.{light_color} & UDColor.{dark_color}"

                code_str += f'\n'
                code_str += f'    /// Light: {light_color}, Dark: {dark_color}\n'
                code_str += f'    public static var {token}: UIColor {{\n'
                code_str += f'        {temp_str}\n'
                code_str += f'    }}\n'
    code_str += "}\n"
    return code_str


def generate_color_token_in_extension() -> str:
    # 定义颜色字典并忽略前两行
    color_dict = {}
    code_str = '''
    
/// UDColor Name Extension
extension UDComponentsExtension where BaseType == UIColor {

    /// Light: N100, Dark: N00
    public static var bgBase: UIColor { return UDColor.bgBase }
    '''
    for row in colorTools.tokens_Sheet.iter_rows(min_row=3):
        if row[1].value and row[4].value and row[5].value:
            token_name = str(row[1].value).replace(" ", "")
            light_color = str(row[4].value).replace(" ", "")
            dark_color = str(row[5].value).replace(" ", "")
            if "gradient" in light_color or "gradient" in dark_color:
                continue
            token = colorTools.process_value(token_name)
            light_color = colorTools.process_value(light_color)
            dark_color = colorTools.process_value(dark_color)
            code_str += f'\n'
            code_str += f'    /// Light: {light_color}, Dark: {dark_color}\n'
            code_str += f'    public static var {token}: UIColor {{ return UDColor.{token} }}\n'

    for row in colorTools.biz_token_sheet.iter_rows(min_row=3):
        if row[0].value and row[6].value and row[8].value:
            token_name = str(row[0].value).replace(" ", "")
            biz = str(row[2].value).replace(" ", "")
            light_color = str(row[6].value).replace(" ", "")
            dark_color = str(row[8].value).replace(" ", "")
            if "UD" in biz:
                token = colorTools.process_value(token_name)
                light_color = colorTools.process_value(light_color)
                dark_color = colorTools.process_value(dark_color)

                code_str += f'\n'
                code_str += f'    /// Light: {light_color}, Dark: {dark_color}\n'
                code_str += f'    public static var {token}: UIColor {{ return UDColor.{token} }}\n'
    code_str += "}"
    return code_str
