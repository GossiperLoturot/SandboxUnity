using UnityEngine;

public class DataInteractor : MonoBehaviour
{
    void Update()
    {
        {
            if (Input.GetMouseButtonDown(0)
                && Physics.Raycast(Camera.main.transform.position, Camera.main.transform.forward, out var hit))
            {
                var position = new Vector2Int(Mathf.RoundToInt(hit.point.x), Mathf.RoundToInt(hit.point.z));

                var point = SurfaceContext.main.ComputePoint(position);
                SurfaceContext.main.SetPoint(position, point.position.y - 0.25f, new Color(0, 1, 0, 0));
            }
        }

        {
            if (Input.GetMouseButtonDown(1)
                && Physics.Raycast(Camera.main.transform.position, Camera.main.transform.forward, out var hit))
            {
                var position = new Vector2Int(Mathf.RoundToInt(hit.point.x), Mathf.RoundToInt(hit.point.z));

                var point = SurfaceContext.main.ComputePoint(position);
                SurfaceContext.main.SetPoint(position, point.position.y + 0.25f, new Color(0, 1, 0, 0));
            }
        }
    }
}
