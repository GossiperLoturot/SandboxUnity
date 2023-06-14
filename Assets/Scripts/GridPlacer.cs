using System.Linq;
using System.Collections.Generic;
using UnityEngine;

public class GridPlacer : MonoBehaviour
{
    public GameObject chunk;
    public Vector2Int minBounds = new Vector2Int(-5, -5);
    public Vector2Int maxBounds = new Vector2Int(5, 5);
    public int gridScale = 32;

    private Dictionary<Vector2Int, GameObject> chunks = new Dictionary<Vector2Int, GameObject>();

    public void Update()
    {
        var originChunkKey = new Vector2Int(
            Mathf.FloorToInt(transform.position.x / gridScale),
            Mathf.FloorToInt(transform.position.z / gridScale)
        );
        var worldMinBounds = originChunkKey + minBounds;
        var worldMaxBounds = originChunkKey + maxBounds;

        // 範囲内で表示されてないものを追加
        for (var y = worldMinBounds.y; y <= worldMaxBounds.y; ++y)
        {
            for (var x = worldMinBounds.x; x <= worldMaxBounds.x; ++x)
            {
                var key = new Vector2Int(x, y);
                if (!chunks.ContainsKey(key))
                {
                    var instance = Instantiate(chunk, new Vector3(x * gridScale, 0, y * gridScale), Quaternion.identity);
                    chunks.Add(key, instance);
                }
            }
        }

        // 範囲外で表示されているものを追加
        foreach (var key in chunks.Keys.ToList())
        {
            if (key.x < worldMinBounds.x || worldMaxBounds.x < key.x || key.y < worldMinBounds.y || worldMaxBounds.y < key.y)
            {
                chunks.Remove(key, out var chunk);
                Destroy(chunk);
            }
        }
    }
}