import React, { memo } from "react";
import { NavLink } from "react-router-dom";
import { Card, Link, Tag, Radio } from "@arco-design/web-react";
import { IconArrowRight } from "@arco-design/web-react/icon";

const UIConfigCard = memo(() => {
  return (
    <NavLink to="/ui-config" className="w-full">
      <div className="px-2 w-full">
        <Card
          title="UI配置"
          hoverable
          extra={
            <Link>
              <IconArrowRight />
            </Link>
          }
        >
          <div className="grid grid-cols-4 gap-x-2 gap-y-0 pr-2"></div>
        </Card>
      </div>
    </NavLink>
  );
});

export default UIConfigCard;
