import os
import json

def read_setting_func(filename: str, funcname: str) -> str:
  with open(filename) as f:
    setting_script = f.readlines()
  setting_func = []
  setting_func.append(f"def {funcname}():")
  setting_func.extend(map(lambda x: "  " + x, setting_script))
  return "\n".join(setting_func)

VERSION_CODE = 5021000
USER_IN_VC_OR_RTC = False

PC_SUB_KEY_DESCRIPTION = {
    "floating": "悬浮窗",
    "pin_as": "缩略视图或者 PIN, AS",
    "pin_small": "缩略视图或者 PIN 小图",
    "pin_small_sip": "缩略视图或者 PIN 小图 SIP/Room",
    "speech_as": "演讲者视图或焦点视频 AS",
    "speech_small": "演讲者视图或焦点视频 小图",
    "speech_small_sip": "演讲者视图或焦点视频 小图 SIP/Room",
    "share_screen": "共享屏幕大图",
    "share_screen_row": "共享屏幕/共享文档 顶部小图",
    "share_screen_row_sip": "共享屏幕/共享文档 顶部小图, sip/room",
}

PHONE_SUB_KEY_DESCRIPTION = {
    "new_grid_full": "全屏查看，放大 & pin",
    "new_grid_half": "二宫格",
    "new_grid_half_sip": "二宫格 sip/room",
    "new_grid_6": "3 ~ 6 宫格",
    "new_grid_6_sip": "3 ~ 6 宫格 sip/room",
    "grid_float": "最小化悬浮窗",
    "grid_float_sip": "最小化悬浮窗 sip/room",
    "grid_share_screen": "共享屏幕大图",
    "grid_share_row": "共享屏幕/共享文档 顶部小图",
    "grid_share_row_sip": "共享屏幕/共享文档 顶部小图, sip/room",
}

PAD_SUB_KEY_DESCRIPTION = {
    "grid_full": "全屏查看, 放大 & pin",
    "grid_float": "最小化悬浮窗",
    "grid_float_sip": "最小化悬浮窗 sip/room",
    "grid_share_screen": "共享屏幕大图",
    "grid_share_row": "共享屏幕/共享文档 顶部小图",
    "grid_share_row_sip": "共享屏幕/共享文档 顶部小图, sip/room",
}


def get_last_cell_count(gallery_subconfig, cur_cell_count):
  # type: (list, int) -> int
  for rule in reversed(gallery_subconfig):
    if rule["max"] < cur_cell_count:
      return rule["max"]
  return 0

def print_gallery_subconfig(gallery_subconfig, fp):
  for rule in gallery_subconfig:
    cell_count = rule["max"]
    last_cell_count = get_last_cell_count(gallery_subconfig, cell_count) + 1
    sub = rule["conf"]
    room_or_sip = rule.get("room_or_sip", None)
    if last_cell_count == cell_count:
      desc = f"{cell_count} 宫格"
    else:
      desc = f"{last_cell_count} ~ {cell_count} 宫格"
    if room_or_sip:
      desc = f"{desc} room/sip"
    print_sub_table_line(sub, desc, fp)

def print_sub_table_header(fp):
  print("| 场景 | 分辨率 | 帧率 | 弱网基线 |", file=fp)
  print("| - | :-: | :-: | :-: |", file=fp)

def print_sub_table_line(sub, desc, fp):
  res = sub["res"]
  fps = sub["fps"]
  good_res = sub.get("good_res", 0)
  good_fps = sub.get("good_fps", 0)
  bad_res = sub.get("bad_res", 0)
  bad_fps = sub.get("bad_fps", 0)
  print(f"| {desc} | {res} | {fps} | {good_res}@{good_fps} - {bad_res}@{bad_fps} |", file=fp)

def print_pub_config(cfg, fp):
  channels = cfg["channel"]
  print(f"| 分辨率 | 帧率 | Max Bitrate |", file=fp)
  print(f"| :-: | :-: | :-: |", file=fp)
  for ch in channels:
    res = ch["res"]
    fps = ch["fps"]
    max_bitrate = ch["max_bitrate"]
    print(f"| {res} | {fps} | {max_bitrate} |", file=fp)

def print_high_pub_config(cfg, fp):
  channels = cfg["channel_high"]
  print(f"| 分辨率 | 帧率 | Max Bitrate |", file=fp)
  print(f"| :-: | :-: | :-: |", file=fp)
  for ch in channels:
    res = ch["res"]
    fps = ch["fps"]
    max_bitrate = ch["max_bitrate"]
    print(f"| {res} | {fps} | {max_bitrate} |", file=fp)


def print_phone_sub_config(multires_config, fp):
  print_sub_table_header(fp)
  # print phone
  subconfig = multires_config["phone"]["subscribe"]
  for (key, desc) in PHONE_SUB_KEY_DESCRIPTION.items():
    sub = subconfig.get(key, None)
    if sub:
      print_sub_table_line(sub, desc, fp)


def print_pad_sub_config(multires_config, fp):
  print_sub_table_header(fp)
  # print phone
  subconfig = multires_config["pad"]["subscribe"]
  gallery_subconfig = subconfig["gallery"]
  print_gallery_subconfig(gallery_subconfig, fp)
  for (key, desc) in PAD_SUB_KEY_DESCRIPTION.items():
    sub = subconfig.get(key, None)
    if sub:
      print_sub_table_line(sub, desc, fp)


def print_pc_config(multires_config, fp):
  high_end_sub = multires_config["configs"][1]["subscribe"]
  high_end_pub = multires_config["configs"][1]["publish"]
  low_end_sub = multires_config["configs"][2]["subscribe"]
  low_end_pub = multires_config["configs"][2]["publish"]

  print("\n\n# PC 高端机型", file=fp)

  print("\n\n## 高清发布分辨率", file=fp)
  print_high_pub_config(multires_config["configs"][0]["publish"], fp)

  print("\n\n## 发布分辨率", file=fp)
  print_pub_config(high_end_pub, fp)

  print("\n\n## 订阅分辨率", file=fp)
  print_sub_table_header(fp)
  for (key, desc) in PC_SUB_KEY_DESCRIPTION.items():
    sub = high_end_sub.get(key, None)
    if sub:
      print_sub_table_line(sub, desc, fp)
  gallery_subconfig = high_end_sub["grid"]
  print_gallery_subconfig(gallery_subconfig, fp)

  print("\n\n# PC 低端机型", file=fp)

  print("\n\n## 发布分辨率", file=fp)
  print_pub_config(low_end_pub, fp)

  print("\n\n## 订阅分辨率", file=fp)
  print_sub_table_header(fp)
  for (key, desc) in PC_SUB_KEY_DESCRIPTION.items():
    sub = low_end_sub.get(key, None)
    if sub:
      print_sub_table_line(sub, desc, fp)
  gallery_subconfig = low_end_sub["grid"]
  print_gallery_subconfig(gallery_subconfig, fp)


def build_multi_res_table(fp):
  # build mobile high end table
  globals()["version_code"] = VERSION_CODE
  globals()["bytebench"] = {"overall_score": 9.5}
  globals()["user_in_vc_or_rtc"] = USER_IN_VC_OR_RTC
  globals()["user_id"] = 0
  globals()["device_id"] = 0

  print("# 多分辨率配置", file=fp)

  globals()["device_platform"] = "windows"
  cfg = multi_resolution()
  print_pc_config(cfg, fp)

  globals()["device_platform"] = "iphone"

  globals()["device_model"] = "iPhone12,1"
  globals()["bytebench"] = {"overall_score": 9.5}
  cfg = multi_resolution()
  print("\n\n", file=fp)
  print("# Mobile 高端机型", file=fp)
  print("\n\n## Phone 高清发布分辨率", file=fp)
  print_high_pub_config(cfg["phone"]["publish"], fp)
  print("\n\n## Pad 高清发布分辨率", file=fp)
  print_high_pub_config(cfg["pad"]["publish"], fp)
  print("\n\n", file=fp)
  print("## Phone 发布分辨率", file=fp)
  print_pub_config(cfg["phone"]["publish"], fp)
  print("\n\n", file=fp)
  print("## Pad 发布分辨率", file=fp)
  print_pub_config(cfg["pad"]["publish"], fp)
  print("\n\n", file=fp)
  print("## Phone 订阅分辨率", file=fp)
  print_phone_sub_config(cfg, fp)
  print("\n\n", file=fp)
  print("## Pad 订阅分辨率", file=fp)
  print_pad_sub_config(cfg, fp)

  globals()["device_model"] = "iPhone12,1"
  globals()["bytebench"] = {"overall_score": 7.8}
  cfg = multi_resolution()
  print("# Mobile 中端机型", file=fp)
  print("\n\n", file=fp)
  print("## Phone 发布分辨率", file=fp)
  print_pub_config(cfg["phone"]["publish"], fp)
  print("\n\n", file=fp)
  print("## Pad 发布分辨率", file=fp)
  print_pub_config(cfg["pad"]["publish"], fp)
  print("\n\n", file=fp)
  print("## Phone 订阅分辨率", file=fp)
  print_phone_sub_config(cfg, fp)
  print("\n\n", file=fp)
  print("## Pad 订阅分辨率", file=fp)
  print_pad_sub_config(cfg, fp)

  globals()["device_model"] = "iPhone12,1"
  globals()["bytebench"] = {"overall_score": 7.1}
  cfg = multi_resolution()
  print("# Mobile 低端机型", file=fp)
  print("\n\n", file=fp)
  print("## Phone 发布分辨率", file=fp)
  print_pub_config(cfg["phone"]["publish"], fp)
  print("\n\n", file=fp)
  print("## Pad 发布分辨率", file=fp)
  print_pub_config(cfg["pad"]["publish"], fp)
  print("\n\n", file=fp)
  print("## Phone 订阅分辨率", file=fp)
  print_phone_sub_config(cfg, fp)
  print("\n\n", file=fp)
  print("## Pad 订阅分辨率", file=fp)
  print_pad_sub_config(cfg, fp)


def test_multi_res():
  test_cases = [
      {
        "version_code": 5013000,
        "user_id": 0,
        "device_platform": "windows",
        "device_model": "",
        "bytebench": {"overall_score": 9.5}
      },
      {
        "version_code": 5019000,
        "user_id": 0,
        "device_platform": "windows",
        "device_model": "",
        "bytebench": {"overall_score": 9.5}
      },
      {
        "version_code": 5020000,
        "user_id": 0,
        "device_platform": "windows",
        "device_model": "",
        "bytebench": {"overall_score": 9.5}
      },
      {
        "version_code": 5021000,
        "user_id": 0,
        "device_platform": "windows",
        "device_model": "",
        "bytebench": {"overall_score": 9.5}
      },

      {
        "version_code": 5019000,
        "user_id": 0,
        "device_platform": "iphone",
        "device_model": "iPhone12,1",
        "bytebench": {"overall_score": 9.5}
      },
      {
        "version_code": 5019000,
        "user_id": 0,
        "device_platform": "iphone",
        "device_model": "iPhone10,1",
        "bytebench": {"overall_score": 7.8}
      },
      {
        "version_code": 5019000,
        "user_id": 0,
        "device_platform": "iphone",
        "device_model": "iPhone8,1",
        "bytebench": {"overall_score": 7.1}
      },

      {
        "version_code": 5021000,
        "user_id": 0,
        "device_platform": "iphone",
        "device_model": "iPhone12,1",
        "bytebench": {"overall_score": 9.5}
      },
      {
        "version_code": 5021000,
        "user_id": 0,
        "device_platform": "iphone",
        "device_model": "iPhone10,1",
        "bytebench": {"overall_score": 7.8}
      },
      {
        "version_code": 5021000,
        "user_id": 0,
        "device_platform": "iphone",
        "device_model": "iPhone8,1",
        "bytebench": {"overall_score": 7.1}
      },
  ]
  for test_case in test_cases:
    test_case["user_in_vc_or_rtc"] = True
    globals().update(test_case)
    print(f"testing: {test_case}\n\n")
    cfg = multi_resolution()
    print(json.dumps(cfg, indent=2, sort_keys=True))

    test_case["user_in_vc_or_rtc"] = False
    globals().update(test_case)
    print(f"testing: {test_case}\n\n")
    cfg = multi_resolution()
    print(json.dumps(cfg, indent=2, sort_keys=True))


if __name__ == "__main__":
  cur_dir = os.path.abspath(os.path.dirname(__file__))
  proj_root_dir = os.path.dirname(cur_dir)
  setting_path = os.path.join(cur_dir, "multi_resolution.py")
  multi_res_md_path = os.path.join(cur_dir, "multi_resolution.md")
  json_dir = os.path.join(proj_root_dir, "Modules/ByteViewSetting/resources/simulcast")

  func = read_setting_func(setting_path, "multi_resolution")
  ret = exec(func)
  with open(multi_res_md_path, "w") as fp:
    build_multi_res_table(fp)

  globals()["version_code"] = VERSION_CODE
  globals()["device_platform"] = "iphone"
  globals()["user_in_vc_or_rtc"] = USER_IN_VC_OR_RTC
  globals()["user_id"] = 0
  globals()["device_id"] = 0

  high_end_json_path = os.path.join(json_dir, "simulcast_high_end.json")
  mid_end_json_path = os.path.join(json_dir, "simulcast_mid_end.json")
  low_end_json_path = os.path.join(json_dir, "simulcast_low_end.json")

  globals()["bytebench"] = {"overall_score": 9.5}
  globals()["device_model"] = "iPhone12,1"
  cfg = multi_resolution()
  with open(high_end_json_path, "w") as fp:
    json.dump(cfg, fp, separators=(',', ':'), sort_keys=True)

  globals()["bytebench"] = {"overall_score": 7.8}
  globals()["device_model"] = "iPhone10,1"
  cfg = multi_resolution()
  with open(mid_end_json_path, "w") as fp:
    json.dump(cfg, fp, separators=(',', ':'), sort_keys=True)

  globals()["bytebench"] = {"overall_score": 7.1}
  globals()["device_model"] = "iPhone8,1"
  cfg = multi_resolution()
  with open(low_end_json_path, "w") as fp:
    json.dump(cfg, fp, separators=(',', ':'), sort_keys=True)

  test_multi_res()
