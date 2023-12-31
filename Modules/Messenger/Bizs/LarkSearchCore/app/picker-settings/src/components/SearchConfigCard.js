import React, { memo } from "react";
import { NavLink } from "react-router-dom";
import { IconArrowRight } from "@arco-design/web-react/icon";
import { Card, Link, Tag, Radio } from "@arco-design/web-react";
import { getEntityName, getEntities } from "@/utils/utils";
const SearchConfigCard = memo(({ entities }) => {
  return (
    <NavLink to="/search-config" className="w-full">
      <div className="px-2">
        <Card title="搜索配置" hoverable extra={<IconArrowRight />}>
          <div className="grid grid-cols-4 gap-x-2 gap-y-0 pr-2">
            {entities.map((entity, index) => {
              console.log("entities:", entity, index);
              return (
                entities.length > 0 && (
                  <div className="p-0.5" key={index}>
                    <Tag bordered>{getEntityName(entity)}</Tag>
                  </div>
                )
              );
            })}
          </div>
        </Card>
      </div>
    </NavLink>
  );
});

export default SearchConfigCard;
