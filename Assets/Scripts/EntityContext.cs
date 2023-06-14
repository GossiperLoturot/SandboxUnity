using System.Collections.Generic;
using UnityEngine;

public struct EntityGroup
{
    public Vector2 minBounds;
    public Vector2 maxBounds;
    public HashSet<Entity> entities;

    public EntityGroup(Vector2 minBounds, Vector2 maxBounds, HashSet<Entity> entities)
    {
        this.minBounds = minBounds;
        this.maxBounds = maxBounds;
        this.entities = entities;
    }
}

public class EntityContext
{
    public static EntityContext main = new EntityContext();
    public const int BLOCK_SIZE = 16;

    private Dictionary<Vector2Int, HashSet<Entity>> entities;
    private HashSet<Tracking> trackings;

    public EntityContext()
    {
        entities = new Dictionary<Vector2Int, HashSet<Entity>>();
        trackings = new HashSet<Tracking>();
    }

    public void AddEntity(Entity entity)
    {
        var blockIdx = new Vector2Int(
            Mathf.FloorToInt(entity.position.x / BLOCK_SIZE),
            Mathf.FloorToInt(entity.position.z / BLOCK_SIZE)
        );

        if (!entities.ContainsKey(blockIdx))
        {
            entities.Add(blockIdx, new HashSet<Entity>());
        }
        var block = entities[blockIdx];

        if (!block.Contains(entity))
        {
            block.Add(entity);
        }

        foreach (var tracking in trackings)
        {
            if (tracking.minBounds.x <= entity.position.x && entity.position.x < tracking.maxBounds.x
                && tracking.minBounds.y <= entity.position.y && entity.position.y < tracking.maxBounds.y)
            {
                tracking.callback.Invoke();
            }
        }
    }

    public void RemoveEntity(Entity entity)
    {
        var blockIdx = new Vector2Int(
            Mathf.FloorToInt(entity.position.x / BLOCK_SIZE),
            Mathf.FloorToInt(entity.position.z / BLOCK_SIZE)
        );
        var block = entities[blockIdx];

        if (block.Contains(entity))
        {
            block.Remove(entity);
        }

        foreach (var tracking in trackings)
        {
            if (tracking.minBounds.x <= entity.position.x && entity.position.x < tracking.maxBounds.x
                && tracking.minBounds.y <= entity.position.y && entity.position.y < tracking.maxBounds.y)
            {
                tracking.callback.Invoke();
            }
        }
    }

    public EntityGroup ComputeEntityGroup(Vector2 minBounds, Vector2 maxBounds)
    {
        var entities = new HashSet<Entity>();

        var minBlockIdx = new Vector2Int(
            Mathf.FloorToInt(minBounds.x / BLOCK_SIZE),
            Mathf.FloorToInt(minBounds.y / BLOCK_SIZE)
        );
        var maxBlockIdx = new Vector2Int(
            Mathf.FloorToInt(maxBounds.x / BLOCK_SIZE),
            Mathf.FloorToInt(maxBounds.y / BLOCK_SIZE)
        );

        for (var y = minBlockIdx.y; y <= maxBlockIdx.y; ++y)
        {
            for (var x = minBlockIdx.x; x <= maxBlockIdx.x; ++x)
            {
                foreach (var entity in this.entities[new Vector2Int(x, y)])
                {
                    if (minBounds.x <= entity.position.x && entity.position.x < maxBounds.x
                        && minBounds.y < entity.position.z && entity.position.z < maxBounds.y)
                    {
                        entities.Add(entity);
                    }
                }
            }
        }

        return new EntityGroup(minBounds, maxBounds, entities);
    }

    public void AddTracking(Tracking tracking)
    {
        trackings.Add(tracking);
    }

    public void RemoveTracking(Tracking tracking)
    {
        trackings.Remove(tracking);
    }
}
