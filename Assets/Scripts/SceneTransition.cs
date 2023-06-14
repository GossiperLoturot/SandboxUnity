using UnityEngine;
using UnityEngine.SceneManagement;

public class SceneTransition : MonoBehaviour
{
    public void MoveToMainScene()
    {
        SceneManager.LoadScene("MainScene", LoadSceneMode.Single);
    }
}
