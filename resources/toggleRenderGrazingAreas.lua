-- Author:Giants, Ziuta
-- Name:GRAZING AREAS - Toggle Render
-- Description:Toggles the visualization of the grazing areas
-- Icon:
-- Hide: no

function toggleRenderGrazingAreas_drawCallback()
    --local r,g,b,a = 0,0.1,1,0.4; -- blue like fields
    local r,g,b,a = 0,1,0.1,0.4; -- own green
    local areasNode = g_renderGrazingAreasDrawNode;
    local terrain = getChild(getChildAt(getRootNode(), 0), "terrain");
    if terrain ~= 0 and areasNode ~= nil then
        local numAreas = getNumOfChildren(areasNode);
        for i=0, numAreas-1 do
            local areaNode = getChildAt(areasNode, i);
             if areaNode ~= 0 then
                local numAreas = getNumOfChildren(areaNode);
                for d=0, numAreas-1 do
                    local aNode = getChildAt(areaNode, d);
                    if getNumOfChildren(aNode) >= 2 then
                        local aNode1 = getChildAt(aNode, 0);
                        local aNode2 = getChildAt(aNode, 1);
                        local x,y,z = getWorldTranslation(aNode);
                        local x1,y1,z1 = getWorldTranslation(aNode1);
                        local x2,y2,z2 = getWorldTranslation(aNode2);
                        local x3,y3,z3 = x+x2-x1, y+y2-y1, z+z2-z1;
                        if terrain ~= 0 then
                            y = getTerrainHeightAtWorldPos(terrain, x,y,z);
                            y1 = getTerrainHeightAtWorldPos(terrain, x1,y1,z1);
                            y2 = getTerrainHeightAtWorldPos(terrain, x2,y2,z2);
                            y3 = getTerrainHeightAtWorldPos(terrain, x3,y3,z3);
                        end
                        drawDebugTriangle(x,y,z, x1,y1,z1, x2,y2,z2, r,g,b,a, false);
                        drawDebugTriangle(x,y,z, x2,y2,z2, x3,y3,z3, r,g,b,a, false);

                        drawDebugTriangle(x,y,z, x2,y2,z2, x1,y1,z1, r,g,b,a, false);
                        drawDebugTriangle(x,y,z, x3,y3,z3, x2,y2,z2, r,g,b,a, false);
                    end
                end
            end
        end
    end

end

if g_renderGrazingAreasDrawCallback ~= nil then
    removeDrawListener(g_renderGrazingAreasDrawCallback);
    g_renderGrazingAreasDrawCallback = nil;
    g_renderGrazingAreasDrawNode = nil
else
    local node = getSelection(0)
    if node ~= 0 and getName(node) == "grazingAreas" then
        if getUserAttribute(node, "onCreate") == "FS17_RM_grazingAnimals.onCreate" or getUserAttribute(node, "onCreate") == "modOnCreate.grazingArea" then
            g_renderGrazingAreasDrawNode = node;
            g_renderGrazingAreasDrawCallback = addDrawListener("toggleRenderGrazingAreas_drawCallback");
        else
            print("Error: Please add onCreate to grazingAreas!")
            return
        end
    else
        print("Error: Please select grazingAreas!")
        return
    end
end