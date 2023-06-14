using System;
using System.Collections.Generic;
using UnityEngine;

[Flags]
public enum MeshInstanceMask
{
    None = 0,
    Red = 1,
    Green = 2,
    Blue = 4,
    Alpha = 8,
    Black = 16,
}

public class MeshInstanceRenderer : MonoBehaviour
{
    public Vector2Int minBounds = new Vector2Int(0, 0);
    public Vector2Int maxBounds = new Vector2Int(7, 7);
    public Mesh srcMesh;
    public MeshInstanceMask mask;
    public int density = 4;
    public Vector3 minScale = new Vector3(1, 1, 1);
    public Vector3 maxScale = new Vector3(1, 1, 1);
    public Vector2Int trackingMinBounds = new Vector2Int(-1, -1);
    public Vector2Int trackingMaxBounds = new Vector2Int(8, 8);

    private Vector3[] srcVertices;
    private int[] srcTriangles;
    private Vector2[] srcUvs;
    private Vector3[] srcNormals;

    // texcoord1にはそれぞれ配置されたMeshの原点位置を出力 (nodePosition)
    // texcoord2にはそれぞれ配置されたMeshの原点位置における表面の法線を出力 (nodeNormal)
    private Mesh mesh;
    private List<Vector3> vertices;
    private List<int> triangles;
    private List<Vector3> normals;
    private List<Vector2> uvs;
    private List<Vector4> nodePositions;
    private List<Vector3> nodeNormals;
    private Tracking tracking;

    public void OnEnable()
    {
        srcVertices = srcMesh.vertices;
        srcTriangles = srcMesh.triangles;
        srcUvs = srcMesh.uv;
        srcNormals = srcMesh.normals;

        mesh = new Mesh();
        mesh.MarkDynamic();

        var meshFilter = GetComponent<MeshFilter>();
        meshFilter.sharedMesh = mesh;

        vertices = new List<Vector3>();
        triangles = new List<int>();
        normals = new List<Vector3>();
        uvs = new List<Vector2>();
        nodePositions = new List<Vector4>();
        nodeNormals = new List<Vector3>();

        UpdateMesh();

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
            UpdateMesh
        );
        SurfaceContext.main.AddTracking(tracking);
    }

    public void UpdateMesh()
    {
        var gameObjectPosition = transform.position;

        var vertexIndex = 0;
        var triangleIndex = 0;
        var nodeIndex = 0;

        for (var y = minBounds.y; y <= maxBounds.y; y++)
            for (var x = minBounds.x; x <= maxBounds.x; x++)
                for (var i = 0; i < density; i++)
                {
                    var point = SurfaceContext.main.ComputePoint(new Vector2(
                        gameObjectPosition.x + x + Noise.Hash01(x, y, i, 0),
                        gameObjectPosition.z + y + Noise.Hash01(x, y, i, 1)
                    ));

                    if (mask.HasFlag(MeshInstanceMask.Red) && 0.5f < point.color.r
                        || mask.HasFlag(MeshInstanceMask.Green) && 0.5f < point.color.g
                        || mask.HasFlag(MeshInstanceMask.Blue) && 0.5f < point.color.b
                        || mask.HasFlag(MeshInstanceMask.Alpha) && 0.5f < point.color.a
                        || mask.HasFlag(MeshInstanceMask.Black) && point.color.r <= 0.5f && point.color.g <= 0.5f && point.color.b <= 0.5f && point.color.a <= 0.5f)
                    {
                        var position = point.position - gameObjectPosition;
                        var angle = Noise.Hash01(x, y, i, 2) * 360;
                        var rotation = Quaternion.AngleAxis(angle, point.normal);
                        var scale = Vector3.Lerp(minScale, maxScale, Noise.Hash01(x, y, i, 3));

                        for (var j = 0; j < srcTriangles.Length; j++)
                        {
                            triangles.Add(vertexIndex + srcTriangles[j]);
                            triangleIndex++;
                        }

                        for (int j = 0; j < srcVertices.Length; j++)
                        {
                            var vertex = position + Vector3.Scale(rotation * srcVertices[j], scale);
                            var nodePosition = new Vector4(position.x, position.y, position.z, nodeIndex);

                            vertices.Add(vertex);
                            normals.Add(srcNormals[j]);
                            uvs.Add(srcUvs[j]);
                            nodePositions.Add(nodePosition);
                            nodeNormals.Add(point.normal);

                            vertexIndex++;
                        }
                    }

                    nodeIndex++;
                }

        mesh.Clear();
        mesh.SetVertices(vertices);
        mesh.SetTriangles(triangles, 0);
        mesh.SetNormals(normals);
        mesh.SetUVs(0, uvs);
        mesh.SetUVs(1, nodePositions);
        mesh.SetUVs(2, nodeNormals);
        mesh.RecalculateBounds();

        vertices.Clear();
        triangles.Clear();
        normals.Clear();
        uvs.Clear();
        nodePositions.Clear();
        nodeNormals.Clear();
    }

    public void OnDisable()
    {
        SurfaceContext.main.RemoveTracking(tracking);
    }
}