using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AddressableAssets;

public class DataProvider : MonoBehaviour
{
    // Addressablesによって読み込むデータのラベルを指定
    public const string LABEL = "entity";
    public const float XZ_SCALE = 0.001f;
    public const float Y_SCALE = 100;

    public Vector2Int minBounds = new Vector2Int(-5, -5);
    public Vector2Int maxBounds = new Vector2Int(5, 5);
    public int blockSize = 16;

    private HashSet<Vector2Int> initFlags;
    private Dictionary<string, GameObject> prefabs;

    public void Start()
    {
        initFlags = new HashSet<Vector2Int>();
        prefabs = new Dictionary<string, GameObject>();

        // Addressablesによってリソースの初回読み込み
        var resourceLocationsHandle = Addressables.LoadResourceLocationsAsync(LABEL);
        foreach (var resourceLocation in resourceLocationsHandle.WaitForCompletion())
        {
            var prefabHandle = Addressables.LoadAssetAsync<GameObject>(resourceLocation);
            prefabs.Add(resourceLocation.PrimaryKey, prefabHandle.WaitForCompletion());
        }
        Addressables.Release(resourceLocationsHandle);
    }

    public void Update()
    {
        var originBlockIdx = new Vector2Int(
            Mathf.FloorToInt(transform.position.x / blockSize),
            Mathf.FloorToInt(transform.position.z / blockSize)
        );
        var worldMinBounds = originBlockIdx + minBounds;
        var worldMaxBounds = originBlockIdx + maxBounds;

        // データの生成
        for (var y = worldMinBounds.y; y <= worldMaxBounds.y; y++)
        {
            for (var x = worldMinBounds.x; x <= worldMaxBounds.x; x++)
            {
                var blockIdx = new Vector2Int(x, y);

                if (!initFlags.Contains(blockIdx))
                {
                    for (var ly = 0; ly < blockSize; ly++)
                    {
                        for (var lx = 0; lx < blockSize; lx++)
                        {
                            var position = new Vector2Int(
                                blockIdx.x * blockSize + lx,
                                blockIdx.y * blockSize + ly
                            );

                            var v00 = Noise.ErosionFBMNoise(position.x * XZ_SCALE, position.y * XZ_SCALE) * Y_SCALE;
                            var v01 = Noise.ErosionFBMNoise((position.x + 1) * XZ_SCALE, position.y * XZ_SCALE) * Y_SCALE;
                            var v10 = Noise.ErosionFBMNoise(position.x * XZ_SCALE, (position.y + 1) * XZ_SCALE) * Y_SCALE;

                            var height = v00;
                            var normal = new Vector3(v01 - v00, 1, v10 - v00).normalized;
                            var color = new Color(Mathf.Pow(Vector3.Dot(normal, Vector3.up), 10), 0, 0, 0);

                            SurfaceContext.main.SetPoint(position, height, color);
                        }
                    }

                    {
                        var position = new Vector2(
                            blockIdx.x * blockSize + Random.value * (blockSize - 1),
                            blockIdx.y * blockSize + Random.value * (blockSize - 1)
                        );
                        var point = SurfaceContext.main.ComputePoint(position);


                        EntityContext.main.AddEntity(new Entity(
                            prefabs["Stone"],
                            point.position,
                            Quaternion.AngleAxis(Random.value * 360, point.normal)
                                * Quaternion.AngleAxis(-90, Vector3.Cross(point.normal, Vector3.up))
                                * Quaternion.LookRotation(point.normal)
                        ));
                    }

                    {
                        var position = new Vector2(
                            blockIdx.x * blockSize + Random.value * (blockSize - 1),
                            blockIdx.y * blockSize + Random.value * (blockSize - 1)
                        );
                        var point = SurfaceContext.main.ComputePoint(position);

                        if (0.8f < Vector3.Dot(point.normal, Vector3.up))
                        {
                            EntityContext.main.AddEntity(new Entity(
                                prefabs["Branch"],
                                point.position,
                                Quaternion.AngleAxis(Random.value * 360, point.normal)
                                    * Quaternion.AngleAxis(-90, Vector3.Cross(point.normal, Vector3.up))
                                    * Quaternion.LookRotation(point.normal)
                            ));
                        }
                    }

                    {
                        var position = new Vector2(
                            blockIdx.x * blockSize + Random.value * (blockSize - 1),
                            blockIdx.y * blockSize + Random.value * (blockSize - 1)
                        );
                        var point = SurfaceContext.main.ComputePoint(position);

                        if (0.8f < Vector3.Dot(point.normal, Vector3.up))
                        {
                            EntityContext.main.AddEntity(new Entity(
                                prefabs["Thatch"],
                                point.position,
                                Quaternion.AngleAxis(Random.value * 360, point.normal)
                                    * Quaternion.AngleAxis(-90, Vector3.Cross(point.normal, Vector3.up))
                                    * Quaternion.LookRotation(point.normal)
                            ));
                        }
                    }

                    if (0.9f < Random.value)
                    {
                        var position = new Vector2(
                            blockIdx.x * blockSize + Random.value * (blockSize - 1),
                            blockIdx.y * blockSize + Random.value * (blockSize - 1)
                        );
                        var point = SurfaceContext.main.ComputePoint(position);

                        if (0.8f < Vector3.Dot(point.normal, Vector3.up))
                        {
                            EntityContext.main.AddEntity(new Entity(
                                prefabs["TreeHigh"],
                                point.position,
                                Quaternion.AngleAxis(Random.value * 360, Vector3.up)
                            ));
                        }
                    }

                    if (0.8f < Random.value)
                    {
                        var position = new Vector2(
                            blockIdx.x * blockSize + Random.value * (blockSize - 1),
                            blockIdx.y * blockSize + Random.value * (blockSize - 1)
                        );
                        var point = SurfaceContext.main.ComputePoint(position);

                        if (0.8f < Vector3.Dot(point.normal, Vector3.up))
                        {
                            EntityContext.main.AddEntity(new Entity(
                                prefabs["TreeMid"],
                                point.position,
                                Quaternion.AngleAxis(Random.value * 360, Vector3.up)
                            ));
                        }
                    }

                    if (0.9f < Random.value)
                    {
                        var position = new Vector2(
                            blockIdx.x * blockSize + Random.value * (blockSize - 1),
                            blockIdx.y * blockSize + Random.value * (blockSize - 1)
                        );
                        var point = SurfaceContext.main.ComputePoint(position);

                        if (0.8f < Vector3.Dot(point.normal, Vector3.up))
                        {
                            EntityContext.main.AddEntity(new Entity(
                                prefabs["Rock"],
                                point.position,
                                Quaternion.AngleAxis(Random.value * 360, point.normal)
                                    * Quaternion.AngleAxis(-90, Vector3.Cross(point.normal, Vector3.up))
                                    * Quaternion.LookRotation(point.normal)
                            ));
                        }
                    }

                    initFlags.Add(blockIdx);
                }
            }
        }
    }
}
