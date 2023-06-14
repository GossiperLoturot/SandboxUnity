using UnityEngine;

[RequireComponent(typeof(CapsuleCollider), typeof(Rigidbody))]
public class Player : MonoBehaviour
{
    public float defaultSpeed = 2;
    public float sprintSpeed = 5;

    public float defaultAccelaration = 20;
    public float inAirAccelaration = 1;

    public float rayRadius = 0.5f;
    public float groundMargin = 0.1f;
    public float jumpInterval = 0.8f;
    public float jumpForce = 10;

    private Rigidbody rigidbody;
    private Vector3 velocity;
    private Vector3 accelaration;
    private float jumpElapsed;

    public void Start()
    {
        rigidbody = GetComponent<Rigidbody>();
    }

    public void Update()
    {
        var view = Camera.main.transform;

        var viewDir = new Vector2(view.forward.x, view.forward.z).normalized;
        var inputDir = new Vector2(Input.GetAxis("Horizontal"), Input.GetAxis("Vertical")).normalized;

        var speed = defaultSpeed;
        if (Input.GetKey(KeyCode.LeftShift))
        {
            speed = sprintSpeed;
        }

        var isGrounded = Physics.SphereCast(transform.position + Vector3.up * (rayRadius + 0.001f), rayRadius, Vector3.down, out _, groundMargin);

        var accelaration = defaultAccelaration;
        if (!isGrounded)
        {
            accelaration = inAirAccelaration;
        }

        if (Input.GetKeyDown(KeyCode.Space) && jumpInterval < jumpElapsed && isGrounded)
        {
            rigidbody.AddForce(new Vector3(0, jumpForce, 0), ForceMode.Impulse);
            jumpElapsed = 0;
        }
        jumpElapsed += Time.deltaTime;

        var targetVelocity = Matrix4x4.LookAt(Vector3.zero, new Vector3(viewDir.x, 0, viewDir.y), Vector3.up) * new Vector3(inputDir.x, 0, inputDir.y) * speed;
        velocity = Vector3.MoveTowards(velocity, targetVelocity, accelaration * Time.deltaTime);
    }

    public void FixedUpdate()
    {
        rigidbody.MovePosition(rigidbody.position + velocity * Time.deltaTime);
    }
}
