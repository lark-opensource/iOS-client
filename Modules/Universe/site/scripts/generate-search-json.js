// 生成es-design搜索内容
const fs = require('fs');
const path = require('path');

function generateIosSearchMenus() {
  const routesConfigJson = JSON.parse(
    fs.readFileSync(path.resolve(__dirname, '../routes.config.json'), { encoding: 'UTF8' })
  );
  let menus = [];
  routesConfigJson.zh_cn.menus.forEach(menu => {
    menu.subMenus.forEach(item => {
      const subMenu = {
        title: 'iOS',
        subTitle: item.title,
        link: `/develop/iOS${item.path}`,
        altText: item.altText,
      };
      menus.push(subMenu);
    });
  });
  fs.writeFileSync(path.resolve(__dirname, '../ios-develop-menus.json'), JSON.stringify(menus, null, 2), 'utf8');
}

generateIosSearchMenus();
