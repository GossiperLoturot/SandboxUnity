using System;
using System.Collections.Generic;
using UnityEngine;

public struct SurfacePoint
{
    public Vector3 position;
    public Vector3 normal;
    public Color color;

    public SurfacePoint(Vector3 position, Vector3 normal, Color color)
    {
        this.position = position;
        this.normal = normal;
        this.color = color;
    }
}

public class SurfaceContext
{
    public static SurfaceContext main = new SurfaceContext();

    private Dictionary<Vector2Int, (float, Color)> points;
    private HashSet<Tracking> trackings;

    public SurfaceContext()
    {
        points = new Dictionary<Vector2Int, (float, Color)>();
        trackings = new HashSet<Tracking>();
    }

    public void SetPoint(Vector2Int position, float height, Color color)
    {
        if (points.ContainsKey(position))
        {
            points[position] = (height, color);
        }
        else
        {
            points.Add(position, (height, color));
        }

        foreach (var tracking in trackings)
        {
            if (tracking.minBounds.x <= position.x && position.x < tracking.maxBounds.x
                && tracking.minBounds.y <= position.y && position.y < tracking.maxBounds.y)
            {
                tracking.callback.Invoke();
            }
        }
    }

    public SurfacePoint ComputePoint(Vector2 position)
    {
        var p00 = Vector2Int.FloorToInt(position);
        var p01 = p00 + Vector2Int.right;
        var p11 = p00 + Vector2Int.one;
        var p10 = p00 + Vector2Int.up;

        var t = position - p00;

        var (h00, c00) = points[p00];
        var (h01, c01) = points[p01];
        var (h11, c11) = points[p11];
        var (h10, c10) = points[p10];
        var height = Mathf.Lerp(Mathf.Lerp(h00, h01, t.x), Mathf.Lerp(h10, h11, t.x), t.y);
        var color = Color.Lerp(Color.Lerp(c00, c01, t.x), Color.Lerp(c10, c11, t.x), t.y);

        var normal = Vector3.Cross(
            new Vector3(1, h11 - h00, 1),
            new Vector3(1, h10 - h01, -1)
        ).normalized;

        return new SurfacePoint(
            new Vector3(position.x, height, position.y),
            normal,
            color
        );
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
