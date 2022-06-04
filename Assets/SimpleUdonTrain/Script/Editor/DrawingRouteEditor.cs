using UnityEditor;
using UnityEngine;
[CustomEditor(typeof(DrawingRoute), true), CanEditMultipleObjects]
public class DrawingRouteEditor : Editor
{
    // Start is called before the first frame update
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();
        DrawingRoute trackCreator = (DrawingRoute)target;
        if(GUILayout.Button("Generate Route Mesh"))
        {
            trackCreator.DrawingMesh();
        }

    }
}
