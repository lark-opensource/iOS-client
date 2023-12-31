// 该文件由generate-routes.js自动生成，请不要修改该文件
import React, { ReactElement } from 'react';
import { RouteItem } from './type';
import { MdParse } from '@universe-design/site-template/esm/components/md-parse';
import { ContentWrapper } from '@universe-design/site-template/esm/components/content-wrapper';

export const routes: RouteItem = {
  path: '/develop/iOS',
  menus: [
    {
      title: '开发指南',
      icon: '//tosv.byted.org/obj/eden-internal/rsboeh7vhoubz/es-design/sider/started.svg',
      subMenus: [
        {
          title: '开始使用',
          path: '/start',
          altText: 'theme-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Docs/README.md').default} /></ContentWrapper>,
        },
      ],
    },
    {
      title: '通用',
      icon: '//tosv.byted.org/obj/eden-internal/rsboeh7vhoubz/es-design/sider/universal.svg',
      subMenus: [
        {
          title: '颜色 Color',
          path: '/color',
          altText: 'Color-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignColor/docs/README.md').default} /></ContentWrapper>,
        },
        {
          title: '图标 Icon',
          path: '/icon',
          altText: 'Icon-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignIcon/docs/README.md').default} /></ContentWrapper>,
        },
        {
          title: '阴影 Shadow',
          path: '/shadow',
          altText: 'Shadow-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignShadow/docs/README.md').default} /></ContentWrapper>,
        },
        {
          title: '字体 Font',
          path: '/font',
          altText: 'Font-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignFont/docs/README.md').default} /></ContentWrapper>,
        },
      ],
    },
    {
      title: '导航',
      icon: '//tosv.byted.org/obj/eden-internal/rsboeh7vhoubz/es-design/sider/guidline.svg',
      subMenus: [
        {
          title: '面包屑 Breadcrumb',
          path: '/breadcrumb',
          altText: 'Breadcrumb-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignBreadcrumb/docs/README.md').default} /></ContentWrapper>,
        },
        {
          title: '菜单 Menu',
          path: '/menu',
          altText: 'Menu-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignMenu/docs/README.md').default} /></ContentWrapper>,
        },
        {
          title: '页签 Tabs',
          path: '/tabs',
          altText: 'Tabs-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignTabs/docs/README.md').default} /></ContentWrapper>,
        },
      ],
    },
    {
      title: '数据录入',
      icon: '//tosv.byted.org/obj/eden-internal/rsboeh7vhoubz/es-design/sider/datainsert.svg',
      subMenus: [
        {
          title: '按钮 Button',
          path: '/button',
          altText: 'Button-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignButton/docs/README.md').default} /></ContentWrapper>,
        },
        {
          title: '选择框 CheckBox',
          path: '/checkbox',
          altText: 'Checkbox-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignCheckBox/docs/README.md').default} /></ContentWrapper>,
        },
        {
          title: '颜色选择器 Color Picker',
          path: '/colorpicker',
          altText: 'Colorpicker-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignColorPicker/docs/README.md').default} /></ContentWrapper>,
        },
        {
          title: '输入框 Input',
          path: '/input',
          altText: 'Input-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignInput/docs/README.md').default} /></ContentWrapper>,
        },
        {
          title: '评分 Rate',
          path: '/rate',
          altText: 'Rate-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignRate/docs/README.md').default} /></ContentWrapper>,
        },
        {
          title: '开关 Switch',
          path: '/switch',
          altText: 'Switch-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignSwitch/docs/README.md').default} /></ContentWrapper>,
        },
        {
          title: '日期选择器 Date Picker',
          path: '/datepicker',
          altText: 'DatePicker-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignDatePicker/docs/README.md').default} /></ContentWrapper>,
        },
        {
          title: '图片墙 Image List',
          path: '/imageList',
          altText: 'ImageList-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignImageList/README.md').default} /></ContentWrapper>,
        },
      ],
    },
    {
      title: '数据展示',
      icon: '//tosv.byted.org/obj/eden-internal/rsboeh7vhoubz/es-design/sider/datadisplay.svg',
      subMenus: [
        {
          title: '头像 Avatar',
          path: '/avatar',
          altText: 'Avatar-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignAvatar/docs/README.md').default} /></ContentWrapper>,
        },
        {
          title: '徽标 Badge',
          path: '/badge',
          altText: 'Badge-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignBadge/docs/README.md').default} /></ContentWrapper>,
        },
        {
          title: '空状态 Empty',
          path: '/empty',
          altText: 'Empty-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignEmpty/docs/README.md').default} /></ContentWrapper>,
        },
        {
          title: '标签 Tag',
          path: '/tag',
          altText: 'Tag-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignTag/docs/README.md').default} /></ContentWrapper>,
        },
      ],
    },
    {
      title: '反馈',
      icon: '//tosv.byted.org/obj/eden-internal/rsboeh7vhoubz/es-design/sider/feedback.svg',
      subMenus: [
        {
          title: '动作面板 Action Panel',
          path: '/actionpanel',
          altText: 'ActionPanel-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignActionPanel/docs/README.md').default} /></ContentWrapper>,
        },
        {
          title: '弹窗 Dialog',
          path: '/dialog',
          altText: 'Dialog-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignDialog/docs/README.md').default} /></ContentWrapper>,
        },
        {
          title: '常驻提示 Notice',
          path: '/notice',
          altText: 'Notice-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignNotice/docs/README.md').default} /></ContentWrapper>,
        },
        {
          title: '进度条 Process',
          path: '/process',
          altText: 'Process-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignProgressView/docs/README.md').default} /></ContentWrapper>,
        },
        {
          title: '临时提示 Toast',
          path: '/toast',
          altText: 'Toast-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignToast/docs/README.md').default} /></ContentWrapper>,
        },
      ],
    },
    {
      title: '其他',
      icon: '//tosv.byted.org/obj/eden-internal/rsboeh7vhoubz/es-design/sider/others.svg',
      subMenus: [
        {
          title: '消息卡片 Card Header',
          path: '/cardheader',
          altText: 'CardHeader-altText',
          component: (): ReactElement => <ContentWrapper><MdParse content={require('../../../Components/UniverseDesignCardHeader/docs/README.md').default} /></ContentWrapper>,
        },
      ],
    },
  ],
};
