using UnityEngine;

public class SurfaceRenderer : MonoBehaviour
{
    public Mesh srcMesh;
    public Vector2Int trackingMinBounds;
    public Vector2Int trackingMaxBounds;

    private MeshFilter meshFilter;
    private MeshCollider meshCollider;
    private Mesh mesh;
    private Vector3[] vertices;
    private Vector3[] normals;
    private Color[] colors;
    private Tracking tracking;

    public void OnEnable()
    {
        mesh = Instantiate(srcMesh);
        mesh.MarkDynamic();

        meshFilter = GetComponent<MeshFilter>();
        meshCollider = GetComponent<MeshCollider>();

        vertices = mesh.vertices;
        normals = mesh.normals;
        colors = mesh.colors;

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

        for (int i = 0; i < vertices.Length; ++i)
        {
            var point = SurfaceContext.main.ComputePoint(new Vector2(
                gameObjectPosition.x + vertices[i].x,
                gameObjectPosition.z + vertices[i].z
            ));

            vertices[i] = point.position - gameObjectPosition;
            normals[i] = point.normal;
            colors[i] = point.color;
        }

        mesh.vertices = vertices;
        mesh.normals = normals;
        mesh.colors = colors;
        mesh.RecalculateBounds();

        meshFilter.sharedMesh = mesh;
        meshCollider.sharedMesh = mesh;
    }

    public void OnDisable()
    {
        SurfaceContext.main.RemoveTracking(tracking);
    }
}