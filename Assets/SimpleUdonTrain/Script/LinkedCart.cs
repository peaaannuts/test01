
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
using Cinemachine;

[UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
public class LinkedCart : UdonSharpBehaviour
{
    public TrainController m_ParentCart;
    public LinkedCart m_FrontCart;
    Transform cart;
    public float m_LinkedLength=6.8f;
    public Animator m_Animator;
    public float m_Position;
    CinemachinePathBase path;
    CinemachinePathBase.PositionUnits positionUnits = CinemachinePathBase.PositionUnits.Distance;
    int prevStatus = 0;
    
    void Start()
    {
        if(cart==null)cart=this.transform;
        path = m_ParentCart.m_Path;

        if(m_Animator == null) m_Animator = GetComponent<Animator>();
    }
    void Update() {
        if(prevStatus != m_ParentCart.trainStatus && m_Animator != null)
        {
            m_Animator.SetInteger("trainStatus",m_ParentCart.trainStatus);
            prevStatus = m_ParentCart.trainStatus;
        }    
        
    }
    private void FixedUpdate() {
        if(m_FrontCart == null)m_Position = m_ParentCart.m_Position - m_LinkedLength;
        else m_Position = m_FrontCart.m_Position - m_LinkedLength;

        if(m_Position<0) m_Position = 0;
        SetCartPosition(m_Position);
    }
    void SetCartPosition(float distanceAlongPath)
    {
        if (path != null)
        {
            m_Position = path.StandardizeUnit(distanceAlongPath, positionUnits);
            cart.position = path.EvaluatePositionAtUnit(m_Position, positionUnits);
            cart.rotation = path.EvaluateOrientationAtUnit(m_Position, positionUnits);
            
        }
    }
}
