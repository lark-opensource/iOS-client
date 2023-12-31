import React, { memo } from "react";
import { Cell } from "@arco-design/mobile-react";
import NavBarComponent from "@/components/NavBarComponent";

const BusinessConfigPage = memo(() => {
  const columns = [
    {
      title: "Name",
      dataIndex: "name",
    },
    {
      title: "Salary",
      dataIndex: "salary",
    },
    {
      title: "Address",
      dataIndex: "address",
    },
    {
      title: "Email",
      dataIndex: "email",
    },
  ];
  const data = [
    {
      key: "1",
      name: "Jane Doe",
      salary: 23000,
      address: "32 Park Road, London",
      email: "jane.doe@example.com",
    },
    {
      key: "2",
      name: "Alisa Ross",
      salary: 25000,
      address: "35 Park Road, London",
      email: "alisa.ross@example.com",
    },
    {
      key: "3",
      name: "Kevin Sandra",
      salary: 22000,
      address: "31 Park Road, London",
      email: "kevin.sandra@example.com",
    },
    {
      key: "4",
      name: "Ed Hellen",
      salary: 17000,
      address: "42 Park Road, London",
      email: "ed.hellen@example.com",
    },
    {
      key: "5",
      name: "William Smith",
      salary: 27000,
      address: "62 Park Road, London",
      email: "william.smith@example.com",
    },
  ];

  return (
    <>
      <NavBarComponent title={"业务配置"} />
      <Cell.Group header={<div>IM</div>}>
        <Cell label="+号选择面板，选择CCM文档场景" showArrow />
      </Cell.Group>
      <Cell.Group header={<div>CCM</div>}>
        <Cell label="CCM Space 各列表搜索" showArrow />
        <Cell label="CCM Wiki 首页搜索" showArrow />
        <Cell label="CCM Wiki 目录树搜索" showArrow />
        <Cell label='CCM "移动/快捷方式/副本"场景三栏搜索' showArrow />
        <Cell label="CCM 文件夹搜索" showArrow />
        <Cell label="CCM 搜索 Wiki 空间" showArrow />
        <Cell label="CCM 搜索场景过滤文件夹二级搜索" showArrow />
        <Cell label="CCM 搜索场景过滤所有者二级搜索" showArrow />
        <Cell label="CCM 搜索场景过滤所在会话二级搜索" showArrow />
      </Cell.Group>
      <Cell.Group header={<div>日历 </div>}>
        <Cell label="日历有效会议关联文档场景" showArrow />
        <Cell label="日历场景选择共享人" showArrow />
      </Cell.Group>
    </>
  );
});

export default BusinessConfigPage;
