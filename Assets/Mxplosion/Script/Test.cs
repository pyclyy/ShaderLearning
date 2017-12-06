using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Test : MonoBehaviour
{

    public Material ExplosionMaterial;

    private bool isClicked;



    void Update()
    {
        if (this.isClicked || this.ExplosionMaterial == null)
        {
            return;
        }

        if (Input.GetMouseButton(0))
        {
            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            RaycastHit Hit;
            if (Physics.Raycast(ray, out Hit))
            {
                MeshRenderer[] renderers = Hit.collider.GetComponentsInChildren<MeshRenderer>();
                this.ExplosionMaterial.SetFloat("_StartTime", Time.timeSinceLevelLoad);

                for (int i = 0; i < renderers.Length; i++)
                {
                    renderers[i].material = this.ExplosionMaterial;
                }
                this.isClicked = true;
            }
        }
    }
}
