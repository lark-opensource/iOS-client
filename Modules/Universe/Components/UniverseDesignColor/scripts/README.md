## UniverseDesignColor 脚本使用指南

## 说明
1. UDColor 中的 Token 均维护在 [VNext Tokens and Keys]("https://bytedance.feishu.cn/sheets/shtcnVflDod3WTZcDYCPa7tEoLc?sheet=mpZmcH&table=tblGRBqDseJSXSfV&view=vew4e9dknh")中。
2. UDColor 新色彩遵循[V-Next](https://bytedance.feishu.cn/wiki/D5EEw55odike0Tkz4ypcFYpnnXc) 的色彩设计规范要求。


## 使用指南
### 下载 色彩 Token xlsx 表
1. 前往 [VNext Tokens and Keys]("https://bytedance.feishu.cn/sheets/shtcnVflDod3WTZcDYCPa7tEoLc?sheet=mpZmcH&table=tblGRBqDseJSXSfV&view=vew4e9dknh") 下载为本地 Excel 表格
2. 将下载的文件移动到[当前目录](./)
3. 确保表格中工作表的顺序为【keys】【Tokens】【业务线 Token 收集】 
4. 执行下列命令即可

```bash
python3 main.py
```

## 问题说明
1. 本脚本依赖 openpyxl ，可能需要手动 pip 安装一下
