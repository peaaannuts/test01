using System.Collections;
using System.Collections.Generic;

using UnityEngine;
using Cinemachine;

public class DrawingRoute : MonoBehaviour
{
    [SerializeField] CinemachinePathBase cinemachinePath;
    [SerializeField] CinemachinePath.PositionUnits units;
    [SerializeField] GameObject trackMesh;
    [SerializeField] uint meshLength = 1;

    void Start()
    {
    }
    public void DrawingMesh()
    {
        

        Vector3 position;
        Quaternion rotation;
        GameObject editObj = new GameObject();
        editObj.transform.SetParent(null);
        editObj.transform.position = transform.position;
        editObj.transform.rotation = transform.rotation;
        editObj.name = "routeObj";
        for (float pos = 0; pos+meshLength <= cinemachinePath.PathLength; pos += meshLength)
        {
            position = cinemachinePath.EvaluatePositionAtUnit(pos, units);
            rotation = cinemachinePath.EvaluateOrientationAtUnit(pos, units);
            GameObject railParts;
            railParts = Instantiate(trackMesh, position, rotation, editObj.transform);
            Transform connecter = railParts.transform.Find("Armature").Find("B");
            position = cinemachinePath.EvaluatePositionAtUnit(pos, units);
            rotation = cinemachinePath.EvaluateOrientationAtUnit(pos, units);
            connecter.SetPositionAndRotation(position, rotation);
            //if(pos+meshLength >= cinemachinePath.PathLength) break;
            connecter = railParts.transform.Find("Armature").Find("A");
            position = cinemachinePath.EvaluatePositionAtUnit(pos+meshLength, units);
            rotation = cinemachinePath.EvaluateOrientationAtUnit(pos+meshLength, units);
            connecter.SetPositionAndRotation(position, rotation);
        }
    }

}
