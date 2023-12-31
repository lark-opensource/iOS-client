import React, { memo, useContext } from "react";
import { NavLink } from "react-router-dom";
import { IconArrowRight } from "@arco-design/web-react/icon";
import { Card, Link, Tag, Radio } from "@arco-design/web-react";
import { ConfigContext } from "@/Context";

const RecommendConfigCard = memo(() => {
  const context = useContext(ConfigContext);
  const { state, dispatch } = context;

  const ContentComponent = ({ type }) => {
    console.log("ContentComponent", type);
    switch (type) {
      case "contact":
        return <div>联系人列表</div>;
      case "search":
        return <div>大搜空搜</div>;
      case "none":
        return <div>无推荐列表</div>;
      default:
        return null;
    }
  };
  return (
    <NavLink to="/recommend-config" className="w-full">
      <div className="px-2 w-full">
        <Card
          title="推荐界面配置"
          hoverable
          extra={
            <Link>
              <IconArrowRight />
            </Link>
          }
        >
          <ContentComponent type={state?.config?.recommendType} />
        </Card>
      </div>
    </NavLink>
  );
});

export default RecommendConfigCard;
