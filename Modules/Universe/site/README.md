# site

## 介绍

这个是 `iOS` 的组件官网。

## 环境配置

### 安装 Node.js
首先，需要安装 [`nvm`](https://github.com/nvm-sh/nvm#installing-and-updating)，完成安装后我们再安装 Node

```bash
# 安装 12 的版本
nvm install v12.18.3

# 设置 v12.18.3 的为默认 node 版本
nvm alias default v12.18.3

# 新开一个终端执行，确认一下版本是否符合
node -v
```

### 设置 npm 源，安装 yarn
因为公司提供了 npm 内部源，所以需要切换到公司源，除此之外还需要安装 yarn 来进行依赖管理
```bash
npm config set registry http://bnpm.byted.org

brew install yarn --ignore-dependencies
```

### 安装 Eden

```bash
npm install -g @byted/eden-cli

# 确认一下是否安装成功
eden -v
```

## 本地启动
参考以下命令来启动本地服务
```bash
cd site

# 更新依赖包
yarn

# 启动本地服务
npm run start
```
启动后访问 [http://localhost:5007/develop/iOS](http://localhost:5007/develop/iOS) 即可

### command
- `yarn generate-routes`: 更新路由配置文件后运行一下
- `yarn copy`: 更新网站主框架代码


### 图片资源
图片资源存放于 [CDN](https://ife.bytedance.net/cdn)



