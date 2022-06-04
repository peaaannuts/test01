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

public class LIS_SyncDoorCloser : UdonSharpBehaviour
{
    //コントローラクラス
    LIS_SyncDoorController m_controller;

    void Start()
    {

    }
    
    public override void Interact(){
        SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "Close");
    }

    public void Close(){
        m_controller.Close();
    }

    //コントローラインスタンスをセット
    public void SetController(LIS_SyncDoorController _controller){
        m_controller = _controller;
    }
}
