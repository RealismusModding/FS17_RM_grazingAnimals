# FS17_RM_grazingAnimals

Let your sheep and cows graze freely in the pastures to enjoy fresh grass. Grass throughs will be filled automatically every hour as long as grass exists in the meadow. When walking in the sheep and cow pastures the available grass will be shown in the top left menu.

This mod requires map preparation.

## Changes to map.i3d
Add the following code to the map.i3d. The files to be included can be copied from the resources folder in the mod. Ensure that ids are not already used elsewhere in the map.i3d file.

Under `<Files>` include:

    <File fileId="127" filename="map01/grazing_density.png" relativePath="true"/>
    <File fileId="128" filename="map01/grazing_mask_diffuse.png" relativePath="true"/>

Under `<Materials>` include:

    <Material name="grazing_mask_mat" materialId="265" ambientColor="1 1 1" customShaderId="87">
      <Texture fileId="128"/>
      <CustomParameter name="alphaBlendStartEnd" value="70 75 0 0"/>
      <CustomParameter name="cellSizeTerrainSizeScaleXZScaleY" value="16 1024 2 255"/>
    </Material>

The customShaderId should be pointing to the windrowFoliageShader.xml
Under `<Layers>` include:

    <FoliageMultiLayer densityMapId="127" numChannels="5" numTypeIndexChannels="0">
      <FoliageSubLayer name="grazingCows" numDensityMapChannels="1" materialId="265" cellSize="8" viewDistance="0" objectMask="16711935" decalLayer="0" atlasSize="1" atlasOffsets="1 0" numBlocksPerUnitDefault="1.8" numBlocksPerUnitMin="1.8" numBlocksPerUnitMax="1.8" width="0.8" height="0.3" widthVariance="0.1" heightVariance="0.1" horizontalPositionVariance="0.3" blockShapeId="1"/>
      <FoliageSubLayer name="grazingSheep" densityMapChannelOffset="1" numDensityMapChannels="1" materialId="265" cellSize="8" viewDistance="0" objectMask="16711935" decalLayer="0" atlasSize="1" atlasOffsets="1 0" numBlocksPerUnitDefault="1.8" numBlocksPerUnitMin="1.8" numBlocksPerUnitMax="1.8" width="0.8" height="0.3" widthVariance="0.1" heightVariance="0.1" horizontalPositionVariance="0.3" blockShapeId="1"/>
      <FoliageSubLayer name="extraChannels" densityMapChannelOffset="4" numDensityMapChannels="3" materialId="354" cellSize="8" viewDistance="0" objectMask="0" decalLayer="0" atlasSize="1" atlasOffsets="1 0" numBlocksPerUnitDefault="0" numBlocksPerUnitMin="0" numBlocksPerUnitMax="0" width="2" height="2" widthVariance="0" heightVariance="0" horizontalPositionVariance="0"/>
    </FoliageMultiLayer>

## Painting the grass areas in Giants Editor
After including the above, the grazingCows and grazingSheep foliage layer will be visible under Terrain Editing in GE. Paint the cow and sheep meadows with the respective layers. In order to see the layers on the screen, change viewDistance of the FoliageSubLayer to a higher value than 0, for instance to 80. Paint grazingCows with channel 0 and grazingSheep with channel 1. When you're done painting, don't forget to revert to a viewDistance of 0.

## Creating a transform group to improve performance
Create a transform group on the root called "grazingAreas". In the next level include two groups called "sheep" and "cow". Within each group there should be a parallelogram (as they are defined for field defs) that encompass the respective painted areas. It is useful to create the parallelograms under the "fields" transformGroup so their visible extent can be seen on screen.
The transform group should have the following structure (make sure the parent and first childs have the correct name):

- grazingAreas
  - sheep
    - corner01_1
        - corner01_2
        - corner01_3
  - cow
    - corner01_1
        - corner01_2
        - corner01_3
        
The grazingAreas transform group (parent) need a user attribute (script callback) named "onCreate" with the value "FS17_RM_grazingAnimals.onCreate". When including the scripts in a map the value needs to be "modOnCreate.grazingArea".

