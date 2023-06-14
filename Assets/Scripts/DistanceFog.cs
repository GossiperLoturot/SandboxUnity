using UnityEngine;
using UnityEngine.Rendering;

[RequireComponent(typeof(Camera))]
public class DistanceFog : MonoBehaviour
{
    public Mesh mesh;
    public Material skyboxMaterial;
    public Material material;

    private Camera camera;
    private int fogRt;
    private int swapRt;
    private CommandBuffer commandBuffer;

    void Start()
    {
        camera = GetComponent<Camera>();
        fogRt = Shader.PropertyToID("_Fog");
        swapRt = Shader.PropertyToID("_Swap");
    }

    public void OnPreRender()
    {
        var lookMatrix = Matrix4x4.LookAt(Vector3.zero, transform.forward, transform.up);
        var scaleMatrix = Matrix4x4.TRS(Vector3.zero, Quaternion.identity, new Vector3(1, 1, -1));
        var viewMatrix = scaleMatrix * lookMatrix.inverse;

        commandBuffer = new CommandBuffer();
        commandBuffer.name = "DistanceFog";

        commandBuffer.GetTemporaryRT(fogRt, -1, -1, 0, FilterMode.Point, RenderTextureFormat.ARGBHalf);
        commandBuffer.GetTemporaryRT(swapRt, -1, -1, 0, FilterMode.Point, RenderTextureFormat.ARGBHalf);

        // fogRtに現在のカメラと同じ射影行列でスカイボックスのみを描写
        commandBuffer.SetRenderTarget(fogRt);
        commandBuffer.ClearRenderTarget(true, true, Color.clear);
        commandBuffer.SetViewMatrix(viewMatrix);
        commandBuffer.DrawMesh(mesh, Matrix4x4.identity, skyboxMaterial);

        // fogRtと現在のRtを含めてディスタンスフォグを適用
        commandBuffer.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);
        commandBuffer.Blit(BuiltinRenderTextureType.CameraTarget, swapRt);
        commandBuffer.Blit(swapRt, BuiltinRenderTextureType.CameraTarget, material);

        commandBuffer.ReleaseTemporaryRT(fogRt);
        commandBuffer.ReleaseTemporaryRT(swapRt);

        camera.AddCommandBuffer(CameraEvent.AfterImageEffectsOpaque, commandBuffer);
    }

    public void OnPostRender()
    {
        camera.RemoveCommandBuffer(CameraEvent.AfterImageEffectsOpaque, commandBuffer);
    }
}