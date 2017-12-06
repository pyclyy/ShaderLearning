using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotateForDemo : MonoBehaviour {

	
	void Update () {
        transform.localRotation = Quaternion.AngleAxis(10 * Time.deltaTime, Vector3.up) * transform.localRotation;
    }
}
