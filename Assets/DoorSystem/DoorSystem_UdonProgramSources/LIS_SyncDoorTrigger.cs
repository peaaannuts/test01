/*
* Copyright 2021 Lily at Lily's
*
* This software is released under the MIT License.
* http://opensource.org/licenses/mit-license.php
*/
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class LIS_SyncDoorTrigger : UdonSharpBehaviour
{
    //アニメーション（inspectorから指定）
    [SerializeField] Animator m_anim;

    //アニメーション変数名（inspectorから指定）
    [SerializeField] string m_valName = "t_open";

    void Start()
    {
        
    }
    
    public override void Interact(){
        SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "Open");
    }
    
    public void Open(){
        if(m_anim != null) m_anim.SetTrigger(m_valName);
    }

}
