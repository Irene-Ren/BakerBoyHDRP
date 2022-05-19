# BakerBoyHDRP使用说明书 Usage of the BakerBoyHDRP 

适用版本 Unity 2021.2.10f1以上 Requires Unity 2021.2.10f1 or higher

## 使用方法 Process 

将物体拖动到场景中，确认物体拥有Mesh Renderer组件 

Drag the model asset into the scene, make sure it have Mesh Renderer Component.

赋予其BakerBoyHDRP材质，或新建材质使用HDRP/Custom/BakerBoyHDRP着色器，之后给材质贴上法线贴图（必选），颜色贴图（可选）


Assign it a BakerBoyHDRP material, or create a new material using the HDRP/Custom/BakerBoyHDRP shader, assign Normal map (required) and Albedo map (optional).

点击物体信息界面下的Add Component，添加BakerBoy组件

Press Add Component and Add a BakerBoy class.

单击BakerBoy中的Bake按钮烘焙BentNormal和AO，这两张图将被存在存放法线贴图（如果赋予了颜色贴图，则在颜色贴图）的路径下

Press 'Bake' in BakerBoy to obtain the BentNormal map and AO map, these two maps will be saved under the same path of the Normal map (or Albedo map if assigned earlier)


新建一个新的HDRP材质来覆盖之前的BakerBoyHDRP材质，将对应贴图放进对应的位置，并将Advanced Options里的Specular Occlusion Mode调整为From AO and Bent Normals

Create a new HDRP material to replace the BakerBoyHDRP material, place the Albedo, Normal, BentNormal and AO in corresponding slots, and change the Specular Occlusion Mode to 'From AO and Bent Normals' in the Advanced Options. 
