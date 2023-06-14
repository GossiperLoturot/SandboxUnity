using System;
using UnityEngine;

public class Tracking
{
    public Vector2Int minBounds;
    public Vector2Int maxBounds;
    public Action callback;

    public Tracking(Vector2Int minBounds, Vector2Int maxBounds, Action callback)
    {
        this.minBounds = minBounds;
        this.maxBounds = maxBounds;
        this.callback = callback;
    }
}