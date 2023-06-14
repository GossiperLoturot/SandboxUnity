using UnityEngine;

public class LightProperty : MonoBehaviour
{
    public Vector3 rotationAxis = new Vector3(1, 1, 0);
    public float rotationInterval = 300;
    public float startRotationAngle = 45;

    public void Update()
    {
        var light = RenderSettings.sun.GetComponent<Light>();

        var rotationAngle = startRotationAngle + Time.time / rotationInterval * 360;
        var rotation = Quaternion.AngleAxis(rotationAngle, rotationAxis);
        light.transform.rotation = rotation;

        if (Vector3.Dot(light.transform.forward, Vector3.up) < 0)
        {
            light.enabled = true;
        }
        else
        {
            light.enabled = false;
        }
    }
}
