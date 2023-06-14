using UnityEngine;

public class Entity
{
    public GameObject gameObject;
    public Vector3 position;
    public Quaternion rotation;
    public Vector3 scale;

    public Entity(GameObject gameObject, Vector3 position, Quaternion rotation)
    {
        this.gameObject = gameObject;
        this.position = position;
        this.rotation = rotation;
    }
}
