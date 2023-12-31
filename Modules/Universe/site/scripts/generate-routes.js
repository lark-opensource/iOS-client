// 主体框架能力 - 自动生成路由
const fs = require('fs');
const path = require('path');
const minimist = require('minimist');
const { execSync } = require('child_process');
const chalk = require('chalk');
const prettier = require('prettier');

const args = minimist(process.argv.slice(2));

const configJsonFile = args.source || 'routes.config.json';
const targetFile = args.source ? `src/routes/${args.source.replace('.json', '.tsx')}` : 'src/routes/routes.config.tsx';

const projectPath = execSync('git rev-parse --show-toplevel', { encoding: 'utf8' }).replace(/\n/g, '');

function getDocComp(docPath, targetFilePath) {
  const docPathDir = path.resolve(projectPath, docPath);
  const relativePath = path.relative(path.dirname(targetFilePath), docPathDir);
  return `(): ReactElement => <ContentWrapper><MdParse content={require('${relativePath}').default} /></ContentWrapper>`;
}

function generateRoutesConfig() {
  console.log(chalk.yellow('开始生成路由文件'));
  // 查找site或者client文件夹
  const sitePath = ['./site', './client'].reduce((mem, cur) => {
    if (fs.existsSync(path.resolve(projectPath, cur))) {
      return path.resolve(projectPath, cur);
    }
    return mem;
  }, '');

  if (!sitePath) {
    console.log(chalk.red('项目目录下没有site目录或者client目录'));
    return;
  }

  const configPath = path.resolve(sitePath, configJsonFile);
  const targetFilePath = path.resolve(sitePath, targetFile);

  if (!fs.existsSync(configPath)) {
    console.log(chalk.red(`路由配置文件不存在：${configPath}`));
    return;
  }

  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));

  const { routePath, zh_cn: zhCN } = config;

  const keyCompMapping = {};

  let menus = [];

  if (zhCN && zhCN.menus) {
    let count = 1;
    menus = zhCN.menus.map(menu => {
      if (menu && menu.subMenus) {
        menu.subMenus = menu.subMenus.map(subMenu => {
          if (subMenu && subMenu.docPath) {
            const key = `@@${count}@@`;
            keyCompMapping[key] = getDocComp(subMenu.docPath, targetFilePath);
            subMenu.component = key;
            count += 1;
            delete subMenu.docPath;
          }
          return subMenu;
        });
      }
      return menu;
    });
  }

  const routesPrefix = `
  // 该文件由generate-routes.js自动生成，请不要修改该文件
  import React, { ReactElement } from 'react';
  import { RouteItem } from './type';
  import { MdParse } from '@universe-design/site-template/esm/components/md-parse';
  import { ContentWrapper } from '@universe-design/site-template/esm/components/content-wrapper';

  export const routes: RouteItem = `;
  const menuStr =
    routesPrefix +
    JSON.stringify(
      {
        path: routePath,
        menus,
      },
      null,
      2
    );

  let res = prettier.format(menuStr, {
    printWidth: 100,
    singleQuote: true,
    tabWidth: 2,
    trailingComma: 'es5',
    parser: 'typescript',
  });

  res = res.replace(/'(@@\d+@@)'/g, (allStr, value) => keyCompMapping[value]);

  fs.writeFileSync(targetFilePath, res, 'utf8');
  console.log(chalk.green('路由文件生成成功'));
}

generateRoutesConfig();
