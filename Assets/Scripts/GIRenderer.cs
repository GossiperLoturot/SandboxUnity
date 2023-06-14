using UnityEngine;
using UnityEngine.Rendering;

[RequireComponent(typeof(ReflectionProbe))]
public class GIRenderer : MonoBehaviour
{
    public int renderSize = 16;
    public Mesh mesh;
    public Material skyboxMaterial;
    public float ambientIntensity = 1.151f;

    public RenderTexture skyboxRt;
    private CommandBuffer commandBuffer;
    private float zNear = 0.1f;
    private float zFar = 1000f;

    public void Start()
    {
        skyboxRt = new RenderTexture(renderSize, renderSize, 0, RenderTextureFormat.ARGBFloat);
        skyboxRt.dimension = TextureDimension.Cube;

        var tempRt = Shader.PropertyToID("_Temp");

        // skyboxRtにキューブマップとしてスカイボックスを描写
        commandBuffer = new CommandBuffer();
        commandBuffer.name = "GIRenderer";

        commandBuffer.GetTemporaryRT(tempRt, renderSize, renderSize, 0, FilterMode.Point, RenderTextureFormat.ARGBFloat);
        commandBuffer.SetRenderTarget(tempRt);

        // FOVが90度の射影行列で6方向分をRtに描写し, 面ごとにskyboxRtにコピー
        for (var i = 0; i < 6; i++)
        {
            var lookMatrix = i switch
            {
                0 => Matrix4x4.LookAt(Vector3.zero, Vector3.right, Vector3.up),
                1 => Matrix4x4.LookAt(Vector3.zero, Vector3.left, Vector3.up),
                2 => Matrix4x4.LookAt(Vector3.zero, Vector3.up, Vector3.forward),
                3 => Matrix4x4.LookAt(Vector3.zero, Vector3.down, Vector3.back),
                4 => Matrix4x4.LookAt(Vector3.zero, Vector3.back, Vector3.up),
                5 => Matrix4x4.LookAt(Vector3.zero, Vector3.forward, Vector3.up),
            };

            var scaleMatrix = Matrix4x4.TRS(Vector3.zero, Quaternion.identity, new Vector3(-1, -1, -1));
            var viewMatrix = scaleMatrix * lookMatrix.inverse;
            var projectionMatrix = Matrix4x4.Perspective(90, 1, zNear, zFar);

            commandBuffer.ClearRenderTarget(true, true, Color.clear);
            commandBuffer.SetViewProjectionMatrices(viewMatrix, projectionMatrix);
            commandBuffer.DrawMesh(mesh, Matrix4x4.identity, skyboxMaterial);
            commandBuffer.CopyTexture(tempRt, 0, 0, skyboxRt, i, 0);
        }

        commandBuffer.ReleaseTemporaryRT(tempRt);

        // リフレクションプローブにskyboxRtを設定
        GetComponent<ReflectionProbe>().customBakedTexture = skyboxRt;
    }

    public void LateUpdate()
    {
        Graphics.ExecuteCommandBuffer(commandBuffer);
        AsyncGPUReadback.Request(skyboxRt, 0, OnCompleteReadback);
    }

    // 環境光にskyboxRtを適用
    private void OnCompleteReadback(AsyncGPUReadbackRequest request)
    {
        var skyColor = new Color();
        var equatorColor = new Color();
        var groundColor = new Color();

        for (int i = 0; i < request.layerCount; ++i)
        {
            var accColor = new Color();

            // 平均色を算出
            var rawData = request.GetData<float>(i);
            for (var y = 0; y < request.height; y++)
                for (var x = 0; x < request.width; x++)
                {
                    accColor += new Color(
                        rawData[(x + y * request.width) * 4 + 0],
                        rawData[(x + y * request.width) * 4 + 1],
                        rawData[(x + y * request.width) * 4 + 2]
                    );
                }
            var meanColor = accColor / (request.width * request.height);

            // 面の方向ごとに影響する環境光へ適用
            switch (i)
            {
                case 0 | 1 | 4 | 5:
                    equatorColor += meanColor * 0.25f;
                    break;
                case 2:
                    skyColor = meanColor;
                    break;
                case 3:
                    groundColor = meanColor;
                    break;
            }
        }

        RenderSettings.ambientMode = AmbientMode.Trilight;
        RenderSettings.ambientSkyColor = skyColor * ambientIntensity;
        RenderSettings.ambientEquatorColor = equatorColor * ambientIntensity;
        RenderSettings.ambientGroundColor = groundColor * ambientIntensity;
    }
}
