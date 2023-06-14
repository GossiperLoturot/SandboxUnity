using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class EntityPlacer : MonoBehaviour
{
    public Vector2Int minBounds = new Vector2Int(0, 0);
    public Vector2Int maxBounds = new Vector2Int(16, 16);
    public Vector2Int trackingMinBounds = new Vector2Int(0, 0);
    public Vector2Int trackingMaxBounds = new Vector2Int(16, 16);

    private Dictionary<Entity, GameObject> entities;
    private Tracking tracking;

    public void OnEnable()
    {
        entities = new Dictionary<Entity, GameObject>();

        UpdateGameObject();

        var gameObjectPosition = transform.position;
        tracking = new Tracking(
            new Vector2Int(
                (int)gameObjectPosition.x + trackingMinBounds.x,
                (int)gameObjectPosition.z + trackingMinBounds.y
            ),
            new Vector2Int(
                (int)gameObjectPosition.x + trackingMaxBounds.x,
                (int)gameObjectPosition.z + trackingMaxBounds.y
            ),
            UpdateGameObject
        );
        EntityContext.main.AddTracking(tracking);
    }

    public void UpdateGameObject()
    {
        var gameObjectPosition = transform.position;
        var entityGroup = EntityContext.main.ComputeEntityGroup(
            new Vector2(gameObjectPosition.x, gameObjectPosition.z) + minBounds,
            new Vector2(gameObjectPosition.x, gameObjectPosition.z) + maxBounds
        );

        // データに存在するが表示されてないものを追加
        foreach (var entity in entityGroup.entities)
        {
            if (!entities.ContainsKey(entity))
            {
                var gameObject = Instantiate<GameObject>(entity.gameObject, entity.position, entity.rotation);
                entities.Add(entity, gameObject);
            }
        }

        // 表示されているがデータに含まれてないものは削除
        foreach (var entity in entities.Keys.ToArray())
        {
            if (!entityGroup.entities.Contains(entity))
            {
                entities.Remove(entity);
            }
        }
    }

    public void OnDisable()
    {
        foreach (var entity in entities)
        {
            Destroy(entity.Value);
        }

        EntityContext.main.RemoveTracking(tracking);
    }
}
