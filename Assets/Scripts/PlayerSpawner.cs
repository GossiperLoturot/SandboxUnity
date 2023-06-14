using UnityEngine;

public class PlayerSpawner : MonoBehaviour
{
    public const float MAX_Y = 1000;

    public GameObject player;
    public Vector2 minBounds = new Vector2(-64, -64);
    public Vector2 maxBounds = new Vector2(64, 64);

    public void Update()
    {
        var randomPosition = new Vector3(Random.Range(minBounds.x, maxBounds.x), MAX_Y, Random.Range(minBounds.y, maxBounds.y));
        if (Physics.Raycast(randomPosition, Vector3.down, out var hit))
        {
            player.transform.position = hit.point;

            Destroy(this);
        }
    }
}
