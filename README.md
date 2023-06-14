![GitHub](https://img.shields.io/github/license/GossiperLoturot/SandboxUnity)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/GossiperLoturot/SandboxUnity)

# Sandbox Unity

Unity上で作成されたサンドボックスゲーム

## Feature

### Dither Smoke & Custom Shader Animation
![title](/img/title.jpg)
**光源処理に対応したパーティクル**
パーティクルに対してディザ法を使用して半透明を実現し, 光源処理を半透明の材質に適用する.

### Custom Grass Shader & Custom Defered Sharder
![grass](/img/grass.jpg)
**低負荷でフォトリアルな草** シェーダを使用して擬似的な影を草に投影, Defered Renderingを変更して投影された擬似影をGBuffer合成時に計算する.

### Dynamic Mesh
![dyn_mesh](/img/dyn_mesh.jpg)
**動的に生成されるメッシュ** 高さデータをもとにメッシュを動的生成する. データ変更に対して最低限の計算量でメッシュ更新を行う.

### Procedural Terrain
![procedural](/img/procedural.jpg)
**自動生成される地形** 浸食効果を適用したfBMノイズを使用して地形データをリアルタイムで生成する.

### Dynamic Environment
![dyn_env_day](/img/dyn_env_day.jpg)
![dyn_env_dawn](/img/dyn_env_dawn.jpg)
![dyn_env_night](/img/dyn_env_night.jpg)
**動的に計算されるライティング環境** Sky Shaderを変更して太陽が沈んだ際の夜空を描写可能にし, CommandBufferによるSkyboxのレンダリングでフォグテクスチャと環境光を動的に計算する.

## Reference
- https://learn.microsoft.com/ja-jp/dotnet/api
- https://docs.unity3d.com/ScriptReference/
- https://thebookofshaders.com/