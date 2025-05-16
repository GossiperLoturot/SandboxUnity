![GitHub](https://img.shields.io/github/license/GossiperLoturot/SandboxUnity)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/GossiperLoturot/SandboxUnity)

# Sandbox Unity

\* 本プロジェクトは古いプロジェクトであり Unity 2022.3.1f1 の built-in レンダリングパイプライン Deffered Rendering で動作する点に注意してください。

**Sandbox Unity** は、Unity 上で開発された技術デモ用のサンドボックス型ゲームです。  
標準的な Unity の機能では実現が難しい、特殊なビジュアル表現や描画手法の検証・実装を目的としています。

## Feature

### Dither Smoke & Custom Shader Animation
![title](/img/title.jpg)
**光源処理に対応したパーティクル**

ディザリングを用いることで半透明なパーティクルを表現し、さらに光源処理との両立を実現しています。  
カスタムシェーダによる動的なアニメーション制御も可能です。

### Custom Grass Shader & Custom Defered Sharder
![grass](/img/grass.jpg)
**低負荷でフォトリアルな草**

フォトリアルな草を軽量に表現するシェーダを開発。  
草に対して擬似的な影を投影し、ディファードレンダリングのパイプラインを一部変更することで、Gバッファへの統合を実現しています。

### Dynamic Mesh
![dyn_mesh](/img/dyn_mesh.jpg)
**動的に生成されるメッシュ**

高さデータに基づいたリアルタイムメッシュ生成。  
データが変更された際にも、最小限の計算コストで効率的にメッシュを更新します。

### Procedural Terrain
![procedural](/img/procedural.jpg)
**自動生成される地形**

fBM ノイズと浸食アルゴリズムを用いて、地形をリアルタイムで自動生成します。  
サンドボックス型の地形表現における応用を意識した実装です。

### Dynamic Environment
![dyn_env_day](/img/dyn_env_day.jpg)
![dyn_env_dawn](/img/dyn_env_dawn.jpg)
![dyn_env_night](/img/dyn_env_night.jpg)
**動的に計算されるライティング環境**

Sky Shader をカスタマイズし、昼夜の変化に応じた空と星が浮かぶ夜空の描画を実現。  
`CommandBuffer` によって Skybox を制御し、フォグテクスチャや環境光を動的に再計算しています。

## Reference
- https://learn.microsoft.com/ja-jp/dotnet/api
- https://docs.unity3d.com/ScriptReference/
- https://thebookofshaders.com/
